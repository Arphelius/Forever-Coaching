$ErrorActionPreference='Stop'
$url='https://raider.io/api/events/the-forever-open/brackets/finals'
$response=Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 30
$bracket=([Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray()) | ConvertFrom-Json).bracket
$teams=@{};$submissions=@{};$matches=[Collections.Generic.List[object]]::new()
function Visit($node) {
    if ($null -eq $node -or $node -is [string] -or $node -is [ValueType]) {return}
    if ($node -is [array]) {foreach($item in $node){Visit $item};return}
    if ($node.PSObject.Properties['games']) {
        $matches.Add($node)
        foreach($team in @($node.firstTeam,$node.secondTeam)) {if($team){$teams[[string]$team.id]=$team}}
    }
    foreach($property in $node.PSObject.Properties) {Visit $property.Value}
}
Visit $bracket.segments
foreach($match in $matches) {
    foreach($game in $match.games) {
        if($game.syncRosterType -ne 'forever-talents' -or -not $game.syncRosterValue){continue}
        $roster=$game.syncRosterValue | ConvertFrom-Json
        if($roster[0] -ne 1){throw 'Unknown tournament roster format'}
        foreach($entry in $roster | Select-Object -Skip 1) {
            $team=$teams[[string]$entry[0]]
            if(-not $team){throw 'Missing player attribution'}
            $key=[string]$entry[0]+':'+$entry[2]+':'+$entry[3]
            if(-not $submissions.ContainsKey($key)) {
                $submissions[$key]=@{TeamId=$entry[0];Player=$team.name;Class=$entry[1];Code=$entry[2];Revision=[string]$entry[3];Source='https://raider.io/events/the-forever-open/brackets/finals';Profile='https://raider.io'+$team.teamEventProfileUrl;Seed=$team.seed;MatchIds=@();Stage='Finals';EventDate='2026-10-18'}
            }
            if($match.id -notin $submissions[$key].MatchIds){$submissions[$key].MatchIds+= $match.id}
        }
    }
}
$page=(Invoke-WebRequest 'https://warcraftforever.com/talents/warrior/' -UseBasicParsing -TimeoutSec 30).Content
$scriptPath=[regex]::Match($page,'src="([^\"]*/assets/talents/page-[^\"]+\.js)"').Groups[1].Value
if(-not $scriptPath){throw 'Calculator script not found'}
$js=(Invoke-WebRequest ('https://warcraftforever.com'+$scriptPath) -UseBasicParsing -TimeoutSec 30).Content
$layouts=@{}
foreach($record in $submissions.Values) {
    $key=$record.Class+':'+$record.Revision
    if($layouts.ContainsKey($key)){continue}
    $pattern=$record.Class+':\{name:"[^"]+",revision:"([^"]+)",data:"([^"]+)",revisions:\{([^}]+|)\}'
    $metadata=[regex]::Match($js,$pattern)
    if(-not $metadata.Success){throw ('Missing calculator class metadata: '+$record.Class)}
    $path=if($record.Revision -eq $metadata.Groups[1].Value){$metadata.Groups[2].Value}else{[regex]::Match($metadata.Groups[3].Value,'"'+$record.Revision+'":"([^"]+)"').Groups[1].Value}
    if(-not $path){throw ('Unknown calculator revision: '+$key)}
    $definition=Invoke-RestMethod ('https://warcraftforever.com'+$path) -TimeoutSec 30
    $trees=@()
    foreach($tree in $definition.trees | Sort-Object ordinal) {
        $nodes=@()
        foreach($talent in $tree.talents | Sort-Object encodingIndex) {
            $nodes+=@{Name=$talent.name;Index=$talent.encodingIndex;MaxRank=$talent.ranks.Count;Row=$talent.row;Col=$talent.column;SpellId=$talent.ranks[0].spellId}
        }
        $trees+=@{Name=$tree.name;Ordinal=$tree.ordinal;Nodes=$nodes}
    }
    $layouts[$key]=@{URL='https://warcraftforever.com'+$path;Revision=$record.Revision;Trees=$trees}
}
$records=@()
foreach($record in $submissions.Values | Sort-Object Class,Player) {
    $layout=$layouts[$record.Class+':'+$record.Revision]
    $codes=$record.Code.Split('_');$ranks=@{};$points=0
    foreach($tree in $layout.Trees) {
        $code=$codes[$tree.Ordinal]
        foreach($talent in $tree.Nodes) {
            $rank=if($talent.Index -lt $code.Length){[int]::Parse($code.Substring($talent.Index,1))}else{0}
            if($rank -gt $talent.MaxRank){throw 'Tournament rank exceeds archived talent maximum'}
            if($rank -gt 0){$ranks[$talent.Name]=$rank;$points+=$rank}
        }
    }
    $record.Ranks=$ranks;$record.Points=$points
    $wins=0;$losses=0;$seenMatches=@{}
    foreach($match in $matches) {
        if($seenMatches.ContainsKey([string]$match.id) -or $match.status -ne 'complete' -or -not $match.firstTeam -or -not $match.secondTeam -or -not $match.winnerTeamId){continue}
        $seenMatches[[string]$match.id]=$true
        if($match.firstTeam.id -ne $record.TeamId -and $match.secondTeam.id -ne $record.TeamId){continue}
        if($match.winnerTeamId -eq $record.TeamId){$wins++}else{$losses++}
    }
    $record.SeriesWins=$wins;$record.SeriesLosses=$losses
    $record.Layout=$layout
    $record.Calculator='https://warcraftforever.com/talents/'+$record.Class+'/'+$record.Code+'?v='+$record.Revision
    $records+=$record
}
$destination=Join-Path $PSScriptRoot '../docs/research/forever-open-builds.json'
[IO.File]::WriteAllText($destination,($records | ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
Write-Output ('Collected '+$records.Count+' attributed finals submissions from '+$teams.Count+' players.')
