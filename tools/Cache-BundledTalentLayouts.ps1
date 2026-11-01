# Recover the factual pinned layouts already bundled by the importer, without
# needing another network request. No talent descriptions or engine code.
$ErrorActionPreference='Stop'
$commit='a667dce8492bd9fb94269a9f864289cb74006775'
$path=Join-Path $PSScriptRoot '../addons/ForeverCoaching/Data/LevelingBuilds.lua'
$lua=[IO.File]::ReadAllText($path)
if(-not $lua.Contains($commit)){throw 'Bundled engine revision is not the expected snapshot'}
$section=$lua.Substring($lua.IndexOf('ForeverCoaching.TalentTrees = {'))
$layouts=@{};$class=$null;$tree=$null
foreach($line in $section.Split("`n")) {
    if($line -match '^  (\w+)=\{'){$class=$Matches[1].ToLower();$layouts[$class]=@();continue}
    if($line -match '^    \{name="([^"]+)", nodes=\{'){$tree=@{name=$Matches[1];talents=@()};$layouts[$class]+=$tree;continue}
    if($line -match '^      \{name="([^"]+)", spellId=(\d+), maxRank=(\d+), row=(\d+), col=(\d+)') {
        $tree.talents+=@{fancyName=$Matches[1];spellId=[int]$Matches[2];maxPoints=[int]$Matches[3];location=@{rowIdx=[int]$Matches[4];colIdx=[int]$Matches[5]}}
    }
}
if($layouts.Count -ne 9){throw 'Bundled class layouts are incomplete'}
foreach($trees in $layouts.Values){if($trees.Count -ne 3){throw 'Bundled trees are incomplete'}}
$destination=Join-Path $PSScriptRoot ('../docs/research/talent-layouts-'+$commit+'.json')
[IO.File]::WriteAllText($destination,($layouts | ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
Write-Output 'Cached nine pinned talent layouts from the existing bundled export.'
