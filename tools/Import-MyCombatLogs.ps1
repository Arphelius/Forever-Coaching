[CmdletBinding()]
param([string]$GameRoot,[string]$File)
$ErrorActionPreference='Stop'
if(-not $GameRoot){
 $importCandidate=$PSScriptRoot
 for($importDepth=0;$importDepth -lt 7;$importDepth++){
  if((Test-Path -LiteralPath (Join-Path $importCandidate 'Logs')) -and (Test-Path -LiteralPath (Join-Path $importCandidate 'Interface\AddOns\ForeverCoaching'))){$GameRoot=$importCandidate;break}
  $importParent=Split-Path $importCandidate -Parent
  if(-not $importParent){break};$importCandidate=$importParent
 }
 if(-not $GameRoot){$GameRoot='D:\World of Warcraft\_forever_'}
}
$importNode=Get-Command node -ErrorAction SilentlyContinue
$importNodePath=if($importNode){$importNode.Source}else{Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio\18\Community\MSBuild\Microsoft\VisualStudio\NodeJs\node.exe'}
if(-not (Test-Path -LiteralPath $importNodePath)){throw 'Node.js was not found. Install Node.js or add it to PATH.'}
$importArguments=@((Join-Path $PSScriptRoot 'Import-MyCombatLogs.cjs'),'--game-root',$GameRoot)
if($File){$importArguments+=@('--file',$File)}
& $importNodePath @importArguments
exit $LASTEXITCODE
