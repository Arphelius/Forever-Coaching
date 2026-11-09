param([string]$ZipPath)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=Split-Path $PSScriptRoot -Parent
$source=Join-Path $root 'addons/ForeverCoaching'
$manifest=Get-Content -LiteralPath (Join-Path $source 'ForeverCoaching.toc') -Raw
if ($manifest -notmatch '(?m)^## Version:\s*(\S+)\s*$') { throw 'Missing release version.' }
if (-not $ZipPath) { $ZipPath=Join-Path $root "dist/ForeverCoaching-$($Matches[1])-forever.zip" }
$zip=[IO.Compression.ZipFile]::OpenRead($ZipPath)
function Read-Entry([string]$name) {
 $entry=$zip.GetEntry('ForeverCoaching/'+$name)
 if (-not $entry) { throw "Missing packaged file: $name" }
 $reader=New-Object IO.StreamReader($entry.Open())
 try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
}
try {
 foreach ($name in @('ForeverCoaching.toc','ForeverCoaching_Forever.toc','ForeverCoaching_Camelot.toc')) {
  $text=Read-Entry $name
  if (($text -replace '\r\n',"`n").TrimEnd() -ne ($manifest -replace '\r\n',"`n").TrimEnd()) { throw "Packaged discovery manifest differs: $name" }
 }
 foreach ($line in $manifest -split '\r?\n') {
  if ($line.Trim() -and -not $line.StartsWith('#')) {
   if (-not $zip.GetEntry('ForeverCoaching/'+$line.Trim().Replace('\','/'))) { throw "Missing loaded file: $line" }
  }
 }
 foreach ($entry in $zip.Entries) {
  if (-not $entry.FullName.StartsWith('ForeverCoaching/') -or $entry.FullName -match '\.local/|\.backup\.|/Companion/|LiveRotation\.lua|RotationCoach\.lua|CombatHUD\.lua|RotationSettings\.lua') { throw "Unexpected release entry: $($entry.FullName)" }
 }
 if ((Read-Entry 'Data/ForeverLogsReview.lua') -notmatch 'ForeverLogsReview=nil') { throw 'Personal review was not excluded.' }
 if ((Read-Entry 'Data/CompanionReviews.lua') -notmatch 'CompanionReviews=\{\}') { throw 'Personal companion reviews were not excluded.' }
 if ((Read-Entry 'Data/PersonalCombatLog.lua') -notmatch 'PersonalCombatLog=\{\}') { throw 'Private combat logs were not excluded.' }
 foreach($helper in @('Helpers/Import-MyLogs.cmd','Helpers/tools/Import-MyCombatLogs.ps1','Helpers/tools/Import-MyCombatLogs.cjs','Helpers/tools/local-combat-log.cjs','Helpers/tools/coaching-delivery.cjs','Helpers/tools/lua-data.cjs','Helpers/tools/forever-dungeons.cjs','Helpers/data/forever-dungeons.json')){Read-Entry $helper | Out-Null}
 Write-Output 'PASS: release ZIP layout, three synchronized discovery manifests, every loaded file and private/retired-file exclusions.'
} finally { $zip.Dispose() }
