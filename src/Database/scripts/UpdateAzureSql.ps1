#
# UpdateAzureSQL.ps1
#
$DatabaseServer = $OctopusParameters["DatabaseServer"]
$DatabaseName = $OctopusParameters["DatabaseName"]
$DatabaseAction = $OctopusParameters["DatabaseAction"]
$DatabaseUser = $OctopusParameters["DatabaseUser"]
$DatabasePassword = $OctopusParameters["DatabasePassword"]
Write-Output "Recursive directory listing for diagnostics"
Get-ChildItem -Recurse
Write-Host "Executing & .\scripts\Flyway.exe $DatabaseAction $databaseServer $databaseName .\scripts $databaseUser $databasePassword"
# & .\AliaSQL.exe $DatabaseAction $DatabaseServer $DatabaseName .\ $DatabaseUser $DatabasePassword
& .\flyway\flyway.cmd migrate -url="jdbc:sqlserver://$DatabaseServer;databaseName=$DatabaseName;integratedSecurity=true" -locations="filesystem:..\Update" -user=$databaseUser -password=$databasePassword
if ($lastexitcode -ne 0) {
    throw ("Flyway had an error.")
}