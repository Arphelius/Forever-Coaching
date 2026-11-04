[CmdletBinding()]
param([string]$Version='0.1.0-beta.1')
$ErrorActionPreference='Stop'
if ($Version -notmatch '^\d+\.\d+\.\d+(?:-[a-z0-9.]+)?$') { throw 'Invalid release version.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$root=Split-Path $PSScriptRoot -Parent
$source=Join-Path $root 'addons/ForeverCoaching'
$manifest=Get-Content (Join-Path $source 'ForeverCoaching.toc') -Raw
if ($manifest -notmatch '(?m)^## Interface: 16001\s*$') { throw 'Expected Forever Interface 16001.' }
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
  if ($file.Name -match ' - Copy\.|\.backup\.|\.log$' -or ($file.Extension -eq '.toc' -and $file.Name -ne 'ForeverCoaching.toc')) { continue }
  if ($relative -eq 'Data/ForeverLogsReview.lua') {
   $entry=$zip.CreateEntry('ForeverCoaching/'+$relative)
   $writer=New-Object IO.StreamWriter($entry.Open())
   try { $writer.Write("-- Personal imported reviews are not distributed.`nForeverCoaching=ForeverCoaching or {}`nForeverCoaching.ForeverLogsReview=nil`n") } finally { $writer.Dispose() }
  } else {
   [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,'ForeverCoaching/'+$relative,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
  }
 }
} finally { $zip.Dispose() }
Get-FileHash -LiteralPath $path -Algorithm SHA256 | Format-List
Write-Output $path
