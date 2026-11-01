$ErrorActionPreference = 'Stop'
$accessTestState = @{ requests = 0 }
function Read-Host {
    param($Prompt, [switch]$AsSecureString)
    if (-not $AsSecureString) { throw 'Key input must be hidden' }
    ConvertTo-SecureString 'fixture-access-key' -AsPlainText -Force
}
function Invoke-RestMethod {
    param($Method, $Uri, $Headers, $TimeoutSec)
    if ($Uri -ne 'https://foreverlogs.gg/api/public/v1/reports?limit=1') { throw 'Wrong permission-check endpoint' }
    if ($Headers.Authorization -ne 'Bearer fixture-access-key') { throw 'Wrong fixture header' }
    $accessTestState.requests++
    [pscustomobject]@{success=$true;reports=@()}
}
$previous = $env:FOREVERLOGS_API_KEY
try {
    $env:FOREVERLOGS_API_KEY = ''
    $output = & (Join-Path $PSScriptRoot '..\tools\Test-ForeverLogsAccess.ps1')
    if ($accessTestState.requests -ne 1) { throw 'Expected one scoped endpoint request' }
    if (-not ($output -match 'Access confirmed')) { throw 'Successful access was not reported' }
    if (($output -join ' ').Contains('fixture-access-key')) { throw 'Key leaked to output' }
    if (-not [string]::IsNullOrEmpty($env:FOREVERLOGS_API_KEY)) { throw 'Key left in environment' }
    Write-Output 'PASS: masked input, events-scoped endpoint, valid empty report list, no key output or persistence.'
} finally { $env:FOREVERLOGS_API_KEY = $previous }
