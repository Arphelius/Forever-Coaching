$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$project=Split-Path $PSScriptRoot -Parent
$source=[IO.Path]::GetFullPath((Join-Path $project 'addons/ForeverCoaching'))
$output=Join-Path $project 'dist'
[IO.Directory]::CreateDirectory($output)|Out-Null
$package=Join-Path $output ('ForeverCoaching-preview-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.zip')
$zip=[IO.Compression.ZipFile]::Open($package,[IO.Compression.ZipArchiveMode]::Create)
try {
 foreach($file in Get-ChildItem -LiteralPath $source -Recurse -File){
  if($file.Name -match ' - Copy\.|\.backup\.|\.log$'){continue}
  $relative=$file.FullName.Substring($source.Length+1).Replace('\','/')
  if($relative.StartsWith('Companion/')){continue}
  # Imported raw reviews are owner work files, never distributable addon data.
  if($relative -eq 'Data/CompanionReviews.lua'){
   $entry=$zip.CreateEntry('ForeverCoaching/'+$relative)
   $writer=New-Object IO.StreamWriter($entry.Open())
   try{$writer.Write("-- Personal companion reviews are not distributed.`nForeverCoaching=ForeverCoaching or {}`nForeverCoaching.CompanionReviews={}`n")}finally{$writer.Dispose()}
   continue
  }
  if($relative -eq 'Data/ForeverLogsReview.lua'){
   $entry=$zip.CreateEntry('ForeverCoaching/Data/ForeverLogsReview.lua')
   $writer=New-Object IO.StreamWriter($entry.Open())
   try{$writer.Write("-- Owner review imports are excluded from distributed packages.`nForeverCoaching=ForeverCoaching or {}`nForeverCoaching.ForeverLogsReview=nil`n")}finally{$writer.Dispose()}
   continue
  }
  [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,('ForeverCoaching/'+$relative),[IO.Compression.CompressionLevel]::Optimal)|Out-Null
 }
}finally{$zip.Dispose()}
Write-Output $package
