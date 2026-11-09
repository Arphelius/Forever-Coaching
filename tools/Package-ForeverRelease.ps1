[CmdletBinding()]
param([string]$Version)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$root=Split-Path $PSScriptRoot -Parent
$source=Join-Path $root 'addons/ForeverCoaching'
$manifest=Get-Content (Join-Path $source 'ForeverCoaching.toc') -Raw
if ($manifest -notmatch '(?m)^## Version:\s*(\S+)\s*$') { throw 'Missing addon version in ForeverCoaching.toc.' }
$manifestVersion=$Matches[1]
if (-not $Version) { $Version=$manifestVersion }
if ($Version -notmatch '^\d+\.\d+\.\d+(?:-[a-z0-9.]+)?$') { throw 'Invalid release version.' }
if ($Version -ne $manifestVersion) { throw "Package version must match ForeverCoaching.toc ($manifestVersion)." }
if ($manifest -notmatch '(?m)^## Interface: 16001\s*$') { throw 'Expected Forever Interface 16001.' }
$manifestNames=@('ForeverCoaching.toc','ForeverCoaching_Forever.toc','ForeverCoaching_Camelot.toc')
foreach ($name in $manifestNames) {
 $candidate=Join-Path $source $name
 if (-not (Test-Path -LiteralPath $candidate)) { throw "Missing client discovery manifest: $name" }
 $text=Get-Content -LiteralPath $candidate -Raw
 if (($text -replace '\r\n',"`n").TrimEnd() -ne ($manifest -replace '\r\n',"`n").TrimEnd()) { throw "Client manifest differs from the main load list: $name" }
}
foreach ($line in $manifest -split '\r?\n') {
 if ($line.Trim() -and -not $line.StartsWith('#') -and -not (Test-Path -LiteralPath (Join-Path $source $line.Trim()))) { throw "Missing addon file: $line" }
}
$output=Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$path=Join-Path $output "ForeverCoaching-$Version-forever.zip"
if (Test-Path -LiteralPath $path) { throw "Package already exists: $path" }
$zip=[IO.Compression.ZipFile]::Open($path,[IO.Compression.ZipArchiveMode]::Create)
try {
 foreach ($file in Get-ChildItem -LiteralPath $source -Recurse -File) {
  $relative=$file.FullName.Substring($source.Length+1).Replace('\','/')
  if($relative.StartsWith('Companion/')){continue}
  if($relative.StartsWith('Helpers/')){continue}
  if($relative -eq 'Data/PersonalCombatLog.lua'){
   $entry=$zip.CreateEntry('ForeverCoaching/'+$relative);$writer=New-Object IO.StreamWriter($entry.Open())
   try{$writer.Write("-- Private logs are excluded from releases.`nForeverCoaching=ForeverCoaching or {}`nForeverCoaching.PersonalCombatLog={}`n")}finally{$writer.Dispose()}
   continue
  }
  if ($file.Name -match ' - Copy\.|\.backup\.|\.log$' -or ($file.Extension -eq '.toc' -and $manifestNames -notcontains $file.Name)) { continue }
  if ($relative -eq 'Data/CompanionReviews.lua') {
   $entry=$zip.CreateEntry('ForeverCoaching/'+$relative)
   $writer=New-Object IO.StreamWriter($entry.Open())
   try { $writer.Write("-- Personal companion reviews are not distributed.`nForeverCoaching=ForeverCoaching or {}`nForeverCoaching.CompanionReviews={}`n") } finally { $writer.Dispose() }
  } elseif ($relative -eq 'Data/ForeverLogsReview.lua') {
   $entry=$zip.CreateEntry('ForeverCoaching/'+$relative)
   $writer=New-Object IO.StreamWriter($entry.Open())
   try { $writer.Write("-- Personal imported reviews are not distributed.`nForeverCoaching=ForeverCoaching or {}`nForeverCoaching.ForeverLogsReview=nil`n") } finally { $writer.Dispose() }
  } else {
   [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,'ForeverCoaching/'+$relative,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
  }
 }
 & (Join-Path $PSScriptRoot 'Add-LocalLogImporterToPackage.ps1') -Archive $zip
} finally { $zip.Dispose() }
Get-FileHash -LiteralPath $path -Algorithm SHA256 | Format-List
Write-Output $path
