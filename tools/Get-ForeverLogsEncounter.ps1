[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [long]::MaxValue)]
    [long]$ReportId,
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [long]::MaxValue)]
    [long]$EncounterId,
    [ValidateRange(1, 5)]
    [int]$MaxPages = 3,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\.local\ForeverLogs')
)

$ErrorActionPreference = 'Stop'
$apiKey = $env:FOREVERLOGS_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw 'Set FOREVERLOGS_API_KEY locally to a key with events:read access. Do not put the key in addon files.'
}
$baseUri = 'https://foreverlogs.gg/api/public/v1'
$headers = @{ Authorization = "Bearer $apiKey"; Accept = 'application/json' }

function Read-PublicEndpoint([string]$RelativePath) {
    try {
        $response = Invoke-RestMethod -Method Get -Uri ($baseUri + $RelativePath) -Headers $headers -TimeoutSec 30
    } catch {
        # Avoid dumping request/exception objects that may contain credentials.
        $status = 0
        if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
        switch ($status) {
            401 { throw 'Forever Logs rejected the key. Check the local key configuration.' }
            403 { throw 'Access denied. Encounter events require events:read access from Forever Logs.' }
            404 { throw 'Report or encounter not found, not public, or outside event retention.' }
            429 { throw 'Forever Logs rate limit reached. Wait before retrying.' }
            default { throw "Forever Logs request failed (HTTP $status). No export was written." }
        }
    }
    if ($response.success -eq $false) { throw 'Forever Logs returned an unsuccessful response.' }
    return $response
}

$report = Read-PublicEndpoint "/reports/$ReportId"
if ($report.report.id -ne $ReportId -or -not (@($report.encounters.id) -contains $EncounterId)) {
    throw 'The requested encounter does not belong to the returned report.'
}
$actors = Read-PublicEndpoint "/reports/$ReportId/encounters/$EncounterId/actors"
if ($actors.encounter_id -ne $EncounterId) { throw 'Actor response has the wrong encounter ID.' }
$pages = @()
$seenCursors = @{}
$cursor = $null
$complete = $false
for ($index = 0; $index -lt $MaxPages; $index++) {
    $endpoint = "/reports/$ReportId/encounters/$EncounterId/events?limit=50000"
    if ($cursor) { $endpoint += '&cursor=' + [Uri]::EscapeDataString($cursor) }
    $page = Read-PublicEndpoint $endpoint
    if ($page.report_id -ne $ReportId -or $page.encounter_id -ne $EncounterId -or -not $page.pagination) {
        throw 'Event response does not match the requested encounter or lacks pagination.'
    }
    $pages += $page
    if ($page.pagination.has_more -eq $false) { $complete = $true; break }
    $cursor = $page.pagination.next_cursor
    if (-not $cursor -or $seenCursors.ContainsKey($cursor)) { throw 'Invalid or repeated pagination cursor.' }
    $seenCursors[$cursor] = $true
}
$export = [ordered]@{
    source = 'Forever Logs'
    sourceUrl = 'https://foreverlogs.gg/'
    apiVersion = 'public/v1'
    retrievedAtUtc = [DateTime]::UtcNow.ToString('o')
    reportId = $ReportId
    encounterId = $EncounterId
    complete = $complete
    report = $report
    actors = $actors
    pages = $pages
}
$resolvedOutput = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $resolvedOutput -Force | Out-Null
$destination = Join-Path $resolvedOutput ("report-{0}-encounter-{1}-{2}.json" -f $ReportId, $EncounterId, [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff'))
$export | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $destination -Encoding UTF8
Write-Output "Saved local research export: $destination"
if (-not $complete) { Write-Warning 'Page limit reached. This is an incomplete encounter, not a complete combat sample.' }
