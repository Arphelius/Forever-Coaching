$ErrorActionPreference='Stop'
$companionRoot=Split-Path $PSScriptRoot -Parent
$companionUrl='http://127.0.0.1:4318'
$companionServer=Join-Path $PSScriptRoot 'coaching-companion.cjs'
$companionFiles=@('coaching-companion.cjs','coaching-oauth.cjs','coaching-delivery.cjs','warcraftlogs-client.cjs','peer-coaching.cjs','Review-WarcraftLogs.cjs','coaching-companion/config.json')
$companionStamp=($companionFiles | ForEach-Object {Get-Item -LiteralPath (Join-Path $PSScriptRoot $_)} | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1).LastWriteTimeUtc
$companionHealth=$null
try {$companionHealth=Invoke-RestMethod "$companionUrl/health" -TimeoutSec 2}catch{}
if($companionHealth){
 if($companionHealth.service -ne 'ForeverCoachingCompanion'){throw 'The companion port is being used by another program.'}
 if(([DateTimeOffset]::Parse($companionHealth.startedAt)).UtcDateTime -ge $companionStamp){Start-Process $companionUrl;exit 0}
 $companionListener=netstat.exe -ano -p tcp | Select-String '^\s*TCP\s+127\.0\.0\.1:4318\s+\S+\s+LISTENING\s+(\d+)\s*$'
 if(-not $companionListener -or [int]$companionListener.Matches[0].Groups[1].Value -ne [int]$companionHealth.pid){throw 'Could not identify the old companion process.'}
 Stop-Process -Id ([int]$companionHealth.pid)
}
$companionNodeCommand=Get-Command node -ErrorAction SilentlyContinue
$companionNode=if($companionNodeCommand){$companionNodeCommand.Source}else{$null}
if(-not $companionNode){
 $companionCachedRoot=Join-Path $companionRoot '.local\companion-runtime'
 $companionCached=Get-ChildItem -LiteralPath $companionCachedRoot -Directory -ErrorAction SilentlyContinue | Where-Object {$_.Name -match '^node-v24\.\d+\.\d+-win-x64$'} | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
 if($companionCached -and (Test-Path -LiteralPath (Join-Path $companionCached.FullName 'node.exe'))){$companionNode=Join-Path $companionCached.FullName 'node.exe'}
}
if($companionNode){
 $companionNodeVersion=& $companionNode --version
 if($companionNodeVersion -notmatch '^v(\d+)\.' -or [int]$Matches[1] -lt 18){$companionNode=$null}
}
if(-not $companionNode){
 $companionCandidates=@('C:\Program Files\nodejs\node.exe','C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Microsoft\VisualStudio\NodeJs\node.exe')
 $companionNode=$companionCandidates | Where-Object {Test-Path -LiteralPath $_} | Select-Object -First 1
}
if(-not $companionNode){
 Write-Host 'Preparing Forever Coaching for its first launch...'
 $companionRuntime=Join-Path $companionRoot '.local\companion-runtime'
 [IO.Directory]::CreateDirectory($companionRuntime)|Out-Null
 $companionSums=(Invoke-WebRequest 'https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt' -UseBasicParsing).Content
 $companionMatch=[regex]::Match($companionSums,'(?m)^([a-f0-9]{64})\s+(node-v24\.\d+\.\d+-win-x64\.zip)\s*$')
 if(-not $companionMatch.Success){throw 'Could not prepare the companion runtime. Please try again later.'}
 $companionArchive=Join-Path $companionRuntime $companionMatch.Groups[2].Value
 Invoke-WebRequest ('https://nodejs.org/dist/latest-v24.x/'+$companionMatch.Groups[2].Value) -OutFile $companionArchive -UseBasicParsing
 if((Get-FileHash -LiteralPath $companionArchive).Hash.ToLowerInvariant() -ne $companionMatch.Groups[1].Value){throw 'The companion runtime download could not be verified.'}
 $companionNode=Join-Path (Join-Path $companionRuntime ([IO.Path]::GetFileNameWithoutExtension($companionArchive))) 'node.exe'
 if(-not (Test-Path -LiteralPath $companionNode)){Expand-Archive -LiteralPath $companionArchive -DestinationPath $companionRuntime}
}
$companionProcess=Start-Process -FilePath $companionNode -ArgumentList ('"'+$companionServer+'"') -WorkingDirectory $companionRoot -WindowStyle Hidden -PassThru
for($companionAttempt=0;$companionAttempt -lt 30;$companionAttempt++){
 Start-Sleep -Milliseconds 200
 try {$companionHealth=Invoke-RestMethod "$companionUrl/health" -TimeoutSec 1;if($companionHealth.service -eq 'ForeverCoachingCompanion'){Start-Process $companionUrl;exit 0}}catch{}
}
throw 'Forever Coaching could not start. Close other companion windows and try again.'
