[CmdletBinding(SupportsShouldProcess=$true)]
param([string]$WowRoot='D:\World of Warcraft',[ValidateSet('ClassicEra','Retail')][string]$Client='ClassicEra')
$ErrorActionPreference='Stop'
$workspace=Split-Path -Parent $PSScriptRoot
$source=Join-Path $workspace 'addons\ForeverCoaching'
$folder='_classic_era_';$executable='WowClassic.exe';$product='wow_classic_era';$label='Classic Era';$tocSuffix='Vanilla'
if ($Client -eq 'Retail') { $folder='_retail_';$executable='Wow.exe';$product='wow';$label='Retail';$tocSuffix='Mainline' }
$era=Join-Path $WowRoot $folder
if (-not (Test-Path -LiteralPath (Join-Path $era $executable))) { throw "$label was not found at $era" }
$flavor=Get-Content -LiteralPath (Join-Path $era '.flavor.info') -Raw
if (($flavor -split '\r?\n') -notcontains $product) { throw "The selected client is not $label." }
$buildLines=Get-Content -LiteralPath (Join-Path $WowRoot '.build.info')
$columns=$buildLines[0].Split('|')
$productIndex=-1; $versionIndex=-1
for ($i=0;$i -lt $columns.Length;$i++) {
 if ($columns[$i] -like 'Product!*') { $productIndex=$i }
 if ($columns[$i] -like 'Version!*') { $versionIndex=$i }
}
if ($productIndex -lt 0 -or $versionIndex -lt 0) { throw 'Cannot read the installed client build metadata.' }
$version=$null
foreach ($line in $buildLines | Select-Object -Skip 1) {
 $fields=$line.Split('|')
 if ($fields[$productIndex] -eq $product) { $version=$fields[$versionIndex]; break }
}
if ($version -notmatch '^(\d+)\.(\d+)\.(\d+)\.') { throw "Cannot determine the installed $label version." }
$interface=([int]$Matches[1]*10000)+([int]$Matches[2]*100)+[int]$Matches[3]
$manifest=Get-Content -LiteralPath (Join-Path $source 'ForeverCoaching.toc') -Raw
$manifest=$manifest -replace '(?m)^## Interface:.*$',"## Interface: $interface"
$manifest=$manifest -replace '(?m)^## Notes:.*$',"## Notes: $label testing copy. Build and spell guidance uses WoW Forever rules."
foreach ($line in $manifest -split '\r?\n') {
 if ($line.Trim() -and -not $line.StartsWith('#') -and -not (Test-Path -LiteralPath (Join-Path $source $line.Trim()))) { throw "Missing addon file: $line" }
}
$target=Join-Path $era 'Interface\AddOns\ForeverCoaching'
$resolvedEra=[IO.Path]::GetFullPath($era).TrimEnd('\')+'\'
$resolvedTarget=[IO.Path]::GetFullPath($target)
if (-not $resolvedTarget.StartsWith($resolvedEra,[StringComparison]::OrdinalIgnoreCase)) { throw "Installation target is outside $label." }
if ((Test-Path -LiteralPath $target) -and ((Get-Item -LiteralPath $target).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Refusing to overwrite an addon directory junction or symbolic link.' }
Write-Host "$label $version / Interface $interface"
Write-Host "Source: $source"
Write-Host "Target: $target"
if ($PSCmdlet.ShouldProcess($target,"Back up the existing addon and install the current $label testing copy")) {
 if (Test-Path -LiteralPath $target) {
  $backup=Join-Path $era ('ForeverCoaching-TestBackups\'+[DateTime]::Now.ToString('yyyyMMdd-HHmmss-fff'))
  New-Item -ItemType Directory -Path $backup -Force | Out-Null
  Get-ChildItem -LiteralPath $target -Force | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $backup -Recurse -Force }
  Write-Host "Previous addon backed up to $backup"
 }
 New-Item -ItemType Directory -Path $target -Force | Out-Null
 Get-ChildItem -LiteralPath $source -Force | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force }
 $encoding=New-Object Text.UTF8Encoding($false)
 foreach ($name in @('ForeverCoaching.toc',"ForeverCoaching_$tocSuffix.toc")) { [IO.File]::WriteAllText((Join-Path $target $name),$manifest,$encoding) }
 Write-Host "Installed. Restart $label, enable Forever Coaching in AddOns, and test on a character."
 Write-Host 'Your WTF settings and the Forever installation were not modified.'
}
