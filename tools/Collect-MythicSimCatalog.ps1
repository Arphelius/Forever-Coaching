$ErrorActionPreference='Stop'
$root='https://mythicsim.com'
function Get-Page([string]$url) {
    return (Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 30).Content
}
function Plain([string]$html) {
    return ([Net.WebUtility]::HtmlDecode(($html -replace '<[^>]+>',' ')) -replace '\s+',' ').Trim()
}
$index=Get-Page ($root+'/wow-forever/races')
$paths=@([regex]::Matches($index,'href="([^"]*races\?class=[^"]+)"') | ForEach-Object {[Net.WebUtility]::HtmlDecode($_.Groups[1].Value)} | Sort-Object -Unique)
if ($paths.Count -lt 33) { throw 'The public preset index is incomplete.' }
$tier=Get-Page ($root+'/wow-forever/tier-list')
$records=@()
foreach ($path in $paths) {
    $html=Get-Page ($root+$path)
    $class=[regex]::Match($path,'class=([^&]+)').Groups[1].Value
    $spec=[regex]::Match($path,'spec=([^&]+)').Groups[1].Value
    $request=$null
    foreach ($pre in [regex]::Matches($html,'(?s)<pre[^>]*>(.*?)</pre>')) {
        $json=[Net.WebUtility]::HtmlDecode(($pre.Groups[1].Value -replace '<[^>]+>',''))
        if ($json -notmatch '"talentsString"') { continue }
        $request=$json | ConvertFrom-Json
        break
    }
    if (-not $request) { throw "Missing baseline request: $spec" }
    $player=$request.raid.parties[0].players[0]
    $engine=[regex]::Match($html,'/commit/([a-f0-9]{40})').Groups[1].Value
    $generated=[regex]::Match($html,'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z').Value
    $heading=Plain ([regex]::Match($html,'(?s)<h2 id="comparison-heading"[^>]*>(.*?)</h2>').Groups[1].Value)
    if (-not $engine -or -not $generated -or -not $heading) { throw "Missing source metadata: $spec" }
    $totals=@(0,0,0)
    $codes=$player.talentsString.Split('-')
    for ($i=0;$i -lt $codes.Count;$i++) {
        foreach ($digit in $codes[$i].ToCharArray()) { $totals[$i]+=[int]::Parse([string]$digit) }
    }
    $card=Plain ([regex]::Match($tier,'(?s)<details data-spec="'+[regex]::Escape($spec)+'".*?</details>').Value)
    $rankMatch=[regex]::Match($card,'Rank\s*#\s*(\d+)\s+among\s+(DPS|tank)')
    $role=if ($spec -match 'protection|feral-bear') { 'tank' } else { 'damage' }
    $records+=@{Class=(Get-Culture).TextInfo.ToTitleCase($class);Slug=$class;Spec=$spec;Title=$heading;Code=$player.talentsString;Totals=$totals;Engine=$engine;Generated=$generated;URL=$root+$path;Role=$role;BoardRank=if($rankMatch.Success){[int]$rankMatch.Groups[1].Value}else{0};BoardGroup=$rankMatch.Groups[2].Value;Duration=$request.encounter.duration;Variation=$request.encounter.durationVariation;TargetLevel=$request.encounter.targets[0].level;Targets=$request.encounter.targets.Count}
    Write-Output ('Collected '+$records.Count+'/'+$paths.Count+': '+$heading)
}
$destination=Join-Path $PSScriptRoot '../docs/research/mythicsim-catalog.json'
[IO.File]::WriteAllText($destination,($records | ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
