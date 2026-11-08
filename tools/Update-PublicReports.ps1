[CmdletBinding()]
param([ValidateRange(1,1000)][int]$RequestBudget=100)
$ErrorActionPreference='Stop'
$reportProject=Split-Path $PSScriptRoot -Parent
$reportNode=Get-Command node -ErrorAction SilentlyContinue
if($reportNode){$reportNodePath=$reportNode.Source}else{
 $reportNodePath=Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio\18\Community\MSBuild\Microsoft\VisualStudio\NodeJs\node.exe'
}
if(-not (Test-Path -LiteralPath $reportNodePath)){throw 'Node.js was not found. Install Node.js or add it to PATH.'}
if(-not ($env:WCL_ACCESS_TOKEN -or ($env:WCL_CLIENT_ID -and $env:WCL_CLIENT_SECRET))){throw 'Enter WCL_CLIENT_ID and WCL_CLIENT_SECRET in this terminal first. Credentials are never saved by this script.'}
$reportArguments=@((Join-Path $PSScriptRoot 'Build-PublicReportCatalog.cjs'),'--report-pages',(Join-Path $reportProject '.local\optimization'),'--max-reports','1000','--request-budget',"$RequestBudget",'--game-root','D:\World of Warcraft\_forever_')
& $reportNodePath @reportArguments
exit $LASTEXITCODE
