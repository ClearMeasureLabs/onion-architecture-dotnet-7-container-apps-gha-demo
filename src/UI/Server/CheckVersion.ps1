param(
    [string]$server,
    [string]$version
)

#Wait for revision to update before checking version number
Start-Sleep -Seconds 90
$uri = "$server/version"
Write-Host "Getting version $uri"
Invoke-WebRequest $uri -UseBasicParsing | Foreach {
    $_.Content.Contains($version) | Foreach {
        if(-Not($_)) {
            Throw "Incorrect version."
        }
        else {
            Write-Host "Correct version: $version"
        }
    }
}