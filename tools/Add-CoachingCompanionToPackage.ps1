function Add-CoachingCompanionToPackage($CompanionZip,[string]$CompanionProject) {
 $companionPackageFiles=@('Review-My-Run.cmd','tools/Start-CoachingCompanion.ps1','tools/coaching-companion.cjs','tools/coaching-oauth.cjs','tools/coaching-delivery.cjs','tools/warcraftlogs-client.cjs','tools/peer-coaching.cjs','tools/Review-WarcraftLogs.cjs','tools/coaching-companion/index.html','tools/coaching-companion/companion.js','tools/coaching-companion/companion.css','tools/coaching-companion/config.json')
 foreach($companionRelative in $companionPackageFiles){
  $companionSource=Join-Path $CompanionProject $companionRelative
  if(-not (Test-Path -LiteralPath $companionSource)){throw "Missing companion file: $companionRelative"}
  [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($CompanionZip,$companionSource,('ForeverCoaching/Companion/'+$companionRelative),[IO.Compression.CompressionLevel]::Optimal)|Out-Null
 }
}
