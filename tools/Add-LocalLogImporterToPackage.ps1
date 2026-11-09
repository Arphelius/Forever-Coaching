param($Archive)
$ErrorActionPreference='Stop'
$importProject=Split-Path $PSScriptRoot -Parent
foreach($importFile in @('Import-MyCombatLogs.ps1','Import-MyCombatLogs.cjs','local-combat-log.cjs','coaching-delivery.cjs','lua-data.cjs','forever-dungeons.cjs')){
 [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive,(Join-Path $PSScriptRoot $importFile),('ForeverCoaching/Helpers/tools/'+$importFile),[IO.Compression.CompressionLevel]::Optimal)|Out-Null
}
[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive,(Join-Path $PSScriptRoot 'Import-MyLogs.cmd'),'ForeverCoaching/Helpers/Import-MyLogs.cmd',[IO.Compression.CompressionLevel]::Optimal)|Out-Null
[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive,(Join-Path $importProject 'data/forever-dungeons.json'),'ForeverCoaching/Helpers/data/forever-dungeons.json',[IO.Compression.CompressionLevel]::Optimal)|Out-Null
