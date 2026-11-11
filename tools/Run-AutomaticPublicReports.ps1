[CmdletBinding()]
param([ValidateRange(1,24)][int]$Hours=4,[string]$GameRoot='D:\World of Warcraft\_forever_')
$ErrorActionPreference='Stop'
$reportRoot=Split-Path $PSScriptRoot -Parent
$reportPrivate=Join-Path $reportRoot '.local\optimization'
$credentialFile=Join-Path $reportPrivate 'automatic-credentials.xml'
$logFile=Join-Path $reportPrivate 'automatic-update.log'
try {
 $credential=Import-Clixml -LiteralPath $credentialFile
 $env:WCL_CLIENT_ID=$credential.UserName
 $env:WCL_CLIENT_SECRET=$credential.GetNetworkCredential().Password
 $runtime=Get-Command node -ErrorAction SilentlyContinue
 $nodePath=if($runtime){$runtime.Source}else{Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio\18\Community\MSBuild\Microsoft\VisualStudio\NodeJs\node.exe'}
 if(-not (Test-Path -LiteralPath $nodePath)){throw 'Node.js was not found.'}
 # Keep only the newest invocation's log, rather than growing indefinitely.
 Set-Content -LiteralPath $logFile -Value ('Started '+(Get-Date -Format o))
 & $nodePath (Join-Path $PSScriptRoot 'Refresh-PublicReports.cjs') --hours $Hours --game-root $GameRoot --request-budget 100 2>&1 | Out-File -LiteralPath $logFile -Append -Encoding utf8
 $result=$LASTEXITCODE
 exit $result
} catch {
 Add-Content -LiteralPath $logFile -Value $_.Exception.Message
 exit 1
} finally {
 Remove-Item Env:WCL_CLIENT_SECRET -ErrorAction SilentlyContinue
 Remove-Item Env:WCL_CLIENT_ID -ErrorAction SilentlyContinue
}
