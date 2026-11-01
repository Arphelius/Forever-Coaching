[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$previousKey = $env:FOREVERLOGS_API_KEY
$apiKey = $previousKey
$secureKey = $null
$keyPointer = [IntPtr]::Zero
try {
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        $secureKey = Read-Host 'Paste your Forever Logs API key (hidden), then press Enter' -AsSecureString
        $keyPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
        $apiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($keyPointer)
    }
    if ([string]::IsNullOrWhiteSpace($apiKey)) { throw 'No key entered.' }
    try {
        # Unlike /health, this documented endpoint requires events:read.
        $response = Invoke-RestMethod -Method Get -Uri 'https://foreverlogs.gg/api/public/v1/reports?limit=1' -Headers @{
            Authorization = "Bearer $apiKey"
            Accept = 'application/json'
        } -TimeoutSec 30
    } catch {
        $status = 0
        if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
        switch ($status) {
            401 { throw 'The key was rejected. Check that you copied the current key.' }
            403 { throw 'This key does not have events:read access yet. Confirm which key the owner upgraded.' }
            429 { throw 'Rate limit reached. Wait before trying again.' }
            default { throw "Access check failed (HTTP $status). No key was saved." }
        }
    }
    if ($response.success -ne $true -or $null -eq $response.reports) {
        throw 'The server did not return the expected report-list response; access could not be confirmed.'
    }
    Write-Output 'Access confirmed: this key can use events:read endpoints.'
    Write-Output 'No key was saved. Send the access result and a public fight/report URL to continue.'
} finally {
    if ($keyPointer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPointer) }
    if ($secureKey) { $secureKey.Dispose() }
    $apiKey = $null
    $env:FOREVERLOGS_API_KEY = $previousKey
}
