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
Write-Host "Executing & .\AliaSQL.exe $DatabaseAction $DatabaseServer $DatabaseName .\ $DatabaseUser $DatabasePassword"
& .\AliaSQL.exe $DatabaseAction $DatabaseServer $DatabaseName .\ $DatabaseUser $DatabasePassword
if ($lastexitcode -ne 0) {
    throw ("AliaSQL had an error.")
}