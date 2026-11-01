# Offline contract tests. No real API key or network requests are used.
$ErrorActionPreference = 'Stop'
$script:mockCalls = 0
function Invoke-RestMethod {
    param($Method, $Uri, $Headers, $TimeoutSec)
    $script:mockCalls++
    if ($Headers.Authorization -ne 'Bearer fixture-key') { throw 'Fixture authorization missing' }
    if ($Uri -match '/actors$') {
        return [pscustomobject]@{ success=$true; encounter_id=7; actors=@([pscustomobject]@{id=1;name='Fixture';is_player=$true}) }
    }
    if ($Uri -match '/events\?') {
        $more = $Uri -notmatch 'cursor='
        return [pscustomobject]@{
            success=$true;report_id=42;encounter_id=7
            events=@([pscustomobject]@{id='9007199254740993';spell_id=403;amount='20';event_type='damage';timestamp_ms=1000})
            pagination=[pscustomobject]@{has_more=$more;next_cursor=$(if($more){'page-two'}else{$null})}
        }
    }
    if ($Uri -match '/reports/42$') {
        return [pscustomobject]@{success=$true;report=[pscustomobject]@{id=42};encounters=@([pscustomobject]@{id=7})}
    }
    throw 'Unexpected fixture endpoint'
}
$scriptPath = Join-Path $PSScriptRoot '..\tools\Get-ForeverLogsEncounter.ps1'
$testDir = Join-Path $PSScriptRoot 'fc-log-helper-fixtures'
$savedKey = $env:FOREVERLOGS_API_KEY
try {
    $env:FOREVERLOGS_API_KEY = ''
    $missingKeyRejected = $false
    try { & $scriptPath -ReportId 42 -EncounterId 7 -OutputDirectory $testDir } catch {
        $missingKeyRejected = $_.Exception.Message -like 'Set FOREVERLOGS_API_KEY*'
    }
    if (-not $missingKeyRejected -or $script:mockCalls -ne 0) { throw 'Missing-key guard failed' }
    $env:FOREVERLOGS_API_KEY = 'fixture-key'
    & $scriptPath -ReportId 42 -EncounterId 7 -MaxPages 1 -OutputDirectory $testDir | Out-Null
    $first = Get-ChildItem -LiteralPath $testDir -Filter '*.json' | Sort-Object LastWriteTime | Select-Object -Last 1
    $partial = Get-Content -LiteralPath $first.FullName -Raw | ConvertFrom-Json
    if ($partial.complete -ne $false -or @($partial.pages).Count -ne 1) { throw 'Partial export not marked incomplete' }
    & $scriptPath -ReportId 42 -EncounterId 7 -MaxPages 2 -OutputDirectory $testDir | Out-Null
    $last = Get-ChildItem -LiteralPath $testDir -Filter '*.json' | Sort-Object LastWriteTime | Select-Object -Last 1
    $complete = Get-Content -LiteralPath $last.FullName -Raw | ConvertFrom-Json
    if ($complete.complete -ne $true -or @($complete.pages).Count -ne 2) { throw 'Cursor pagination failed' }
    if ($complete.pages[0].events[0].id -cne '9007199254740993' -or $complete.pages[0].events[0].id -isnot [string]) { throw 'Opaque event ID lost' }
    if ((Get-Content -LiteralPath $last.FullName -Raw).Contains('fixture-key')) { throw 'Credential serialized' }
    Write-Output 'PASS: missing key, bounded pagination, incomplete marker, string event IDs, no key in export.'
} finally {
    $env:FOREVERLOGS_API_KEY = $savedKey
    if (Test-Path -LiteralPath $testDir) {
        Get-ChildItem -LiteralPath $testDir -File -Filter '*.json' | ForEach-Object { Remove-Item -LiteralPath $_.FullName }
        Remove-Item -LiteralPath $testDir
    }
}
