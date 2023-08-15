. .\BuildFunctions.ps1
$startTime = 
$projectName = "ChurchBulletin"
$base_dir = resolve-path .\
$source_dir = "$base_dir\src"
$unitTestProjectPath = "$source_dir\UnitTests"
$integrationTestProjectPath = "$source_dir\IntegrationTests"
$acceptanceTestProjectPath = "$source_dir\AcceptanceTests"
$uiProjectPath = "$source_dir\UI\Server"
$databaseProjectPath = "$source_dir\Database"
$projectConfig = $env:BuildConfiguration
$framework = "net7.0"
$version = $env:BUILD_BUILDNUMBER

$verbosity = "minimal"

$build_dir = "$base_dir\build"
$test_dir = "$build_dir\test"


$aliaSql = "$source_dir\Database\scripts\AliaSql.exe"
$databaseAction = $env:DatabaseAction
if ([string]::IsNullOrEmpty($databaseAction)) { $databaseAction = "Rebuild"}
$databaseName = $projectName
if ([string]::IsNullOrEmpty($databaseName)) { $databaseName = $projectName}
$script:databaseServer = "(LocalDb)\MSSQLLocalDB"
if ([string]::IsNullOrEmpty($script:databaseServer)) { $script:databaseServer = "(LocalDb)\MSSQLLocalDB"}
$databaseScripts = "$source_dir\Database\scripts"

if ([string]::IsNullOrEmpty($version)) { $version = "1.0.0"}
if ([string]::IsNullOrEmpty($projectConfig)) {$projectConfig = "Release"}
 
Function Init {
	& cmd.exe /c rd /S /Q build
	
	md $build_dir > $null

	exec {
		& dotnet clean $source_dir\$projectName.sln -nologo -v $verbosity
		}
	exec {
		& dotnet restore $source_dir\$projectName.sln -nologo --interactive -v $verbosity  
		}
    

    Write-Output $projectConfig
    Write-Output $version
}


Function Compile{
	exec {
		& dotnet build $source_dir\$projectName.sln -nologo --no-restore -v `
			$verbosity -maxcpucount --configuration $projectConfig --no-incremental `
			/p:TreatWarningsAsErrors="true" `
			/p:Version=$version /p:Authors="Programming with Palermo" `
			/p:Product="Church Bulletin"
	}
}

Function UnitTests{
	Push-Location -Path $unitTestProjectPath

	try {
		exec {
			& dotnet test /p:CollectCoverage=true -nologo -v $verbosity --logger:trx `
			--results-directory $test_dir\UnitTests --no-build `
			--no-restore --configuration $projectConfig `
			--collect:"XPlat Code Coverage"
		}
	}
	finally {
		Pop-Location
	}
}

Function IntegrationTest{
	Push-Location -Path $integrationTestProjectPath

	try {
		exec {
			& dotnet test /p:CollectCoverage=true -nologo -v $verbosity --logger:trx `
			--results-directory $test_dir\IntegrationTests --no-build `
			--no-restore --configuration $projectConfig `
			--collect:"XPlat Code Coverage"
		}
	}
	finally {
		Pop-Location
	}
}

Function AcceptanceTest{
	$serverProcess = Start-Process dotnet.exe "run --project $source_dir\UI\Server\UI.Server.csproj --configuration $projectConfig -nologo --no-restore --no-build -v $verbosity" -PassThru
	Start-Sleep 1 #let the server process spin up for 1 second

	Push-Location -Path $acceptanceTestProjectPath

	try {
		exec {
			& dotnet test /p:CollectCoverage=true -nologo -v $verbosity --logger:trx `
			--results-directory $test_dir\AcceptanceTests --no-build `
			--no-restore --configuration $projectConfig `
			--collect:"XPlat Code Coverage"
		}
	}
	finally {
		Pop-Location
		Stop-Process -id $serverProcess.Id
	}
}

Function MigrateDatabaseLocal {
	exec{
		#start mssqllocaldb and check if db exists. If so, drop it first. Then create the database
		sqllocaldb start mssqllocaldb
		$connectionString = "Data Source=$databaseServer;Initial Catalog=master;Integrated Security=True"
		$connection = New-Object System.Data.SqlClient.SqlConnection
		$connection.ConnectionString = $connectionString
		$connection.Open()
		$query = "SELECT database_id FROM sys.databases WHERE Name = '$databaseName'"
		$command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
		$result = $command.ExecuteScalar()
		if ($result -ne $null) {
			# The database exists, so drop it
			$query = "DROP DATABASE [$databaseName]"
			$command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
			$command.ExecuteNonQuery()
		}		
		$command = New-Object System.Data.SqlClient.SqlCommand
		$command.Connection = $connection
		$command.CommandText = "CREATE DATABASE [$databaseName]"
		$command.ExecuteNonQuery()
		$connection.Close()

		#install entity framework cli
		dotnet tool install --global dotnet-ef
		#generate the context model
		dotnet ef dbcontext scaffold "Server=$databaseServer;Database=$databaseName;Trusted_Connection=True" Microsoft.EntityFrameworkCore.SqlServer -f
		# run the migration scripts
		& dotnet ef database update --project ./src/Database/Database.csproj
	}
}

Function PackageUI {    
    exec{
        & dotnet publish $uiProjectPath -nologo --no-restore --no-build -v $verbosity --configuration $projectConfig
    }
	exec{
		& dotnet-octo pack --id "$projectName.UI" --version $version --basePath $uiProjectPath\bin\$projectConfig\$framework\publish --outFolder $build_dir  --overwrite
	}
}

Function PackageDatabase {    
    exec{
		& dotnet-octo pack --id "$projectName.Database" --version $version --basePath $databaseProjectPath --outFolder $build_dir --overwrite
	}
}

Function PackageAcceptanceTests {       
    # Use Debug configuration so full symbols are available to display better error messages in test failures
    exec{
        & dotnet publish $acceptanceTestProjectPath -nologo --no-restore -v $verbosity --configuration Debug
    }
	exec{
		& dotnet-octo pack --id "$projectName.AcceptanceTests" --version $version --basePath $acceptanceTestProjectPath\bin\Debug\$framework\publish --outFolder $build_dir --overwrite
	}
}

Function PackageScript {    
    exec{
        & dotnet publish $uiProjectPath -nologo --no-restore --no-build -v $verbosity --configuration $projectConfig
    }
	exec{
		& dotnet-octo pack --id "$projectName.Script" --version $version --basePath $uiProjectPath --include "*.ps1" --outFolder $build_dir  --overwrite
	}
}

Function Package{
	Write-Output "Packaging nuget packages"
	dotnet tool install --global Octopus.DotNet.Cli | Write-Output $_ -ErrorAction SilentlyContinue #prevents red color is already installed
    PackageUI
    PackageDatabase
    PackageAcceptanceTests
	PackageScript
}

Function PrivateBuild{
	$projectConfig = "Debug"
	[Environment]::SetEnvironmentVariable("containerAppURL", "localhost:7174", "User")
	$sw = [Diagnostics.Stopwatch]::StartNew()
	Init
	Compile
	UnitTests
	MigrateDatabaseLocal
	IntegrationTest
	AcceptanceTest
	$sw.Stop()
	write-host "BUILD SUCCEEDED - Build time: " $sw.Elapsed.ToString() -ForegroundColor Green
}

Function CIBuild{
	$sw = [Diagnostics.Stopwatch]::StartNew()
	Init
	Compile
	UnitTests
	MigrateDatabaseLocal
	IntegrationTest
	Package
	$sw.Stop()
	write-host "BUILD SUCCEEDED - Build time: " $sw.Elapsed.ToString() -ForegroundColor Green
}