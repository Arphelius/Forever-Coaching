$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$url='http://127.0.0.1:4317'
$openUrl=$url+'/?page=scenarios'
$server=Join-Path $PSScriptRoot 'talent-preview-server.cjs'
# Restart only our own preview process when its server code has changed.
$serverFiles=@($server,(Join-Path $PSScriptRoot 'foreverlogs-bridge.cjs'),(Join-Path $PSScriptRoot 'foreverlogs-review.cjs'),(Join-Path $PSScriptRoot 'foreverlogs-players.cjs'),(Join-Path $PSScriptRoot 'foreverlogs-config.cjs'),(Join-Path $project '.local/foreverlogs-api-key.txt'),(Join-Path $PSScriptRoot 'encounter-decisions.cjs'),(Join-Path $PSScriptRoot 'preview-encounter.lua'))
$serverStamp=($serverFiles | Where-Object {Test-Path -LiteralPath $_} | ForEach-Object {(Get-Item -LiteralPath $_).LastWriteTime} | Sort-Object -Descending | Select-Object -First 1)
$health=$null
try {
    $health=Invoke-WebRequest "$url/health" -UseBasicParsing -TimeoutSec 1
}catch{}
if($health){
    if($health.Content -ne 'ForeverCoachingPreview'){throw 'Port 4317 is occupied by another application.'}
    $current=$false
    try {
        $version=Invoke-RestMethod "$url/preview-version" -TimeoutSec 2
        $current=$version.version -eq 'encounter-replay-v1' -and ([DateTimeOffset]::Parse($version.startedAt)).UtcDateTime -ge $serverStamp.ToUniversalTime()
    }catch{}
    if($current){Start-Process $openUrl;exit 0}
    # Health identifies our service before looking up its listening PID. This
    # fallback also works where querying Win32_Process is unavailable.
    $listener=netstat.exe -ano -p tcp | Select-String '^\s*TCP\s+127\.0\.0\.1:4317\s+\S+\s+LISTENING\s+(\d+)\s*$'
    if(-not $listener){throw 'Could not identify the stale preview listener.'}
    $previewProcessId=[int]$listener.Matches[0].Groups[1].Value
    Stop-Process -Id $previewProcessId -ErrorAction Stop
}
$nodeCommand=Get-Command node -ErrorAction SilentlyContinue
$runtime=if($nodeCommand){$nodeCommand.Source}else{Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'}
if(-not (Test-Path -LiteralPath $runtime)){throw 'Install Node.js to run the preview, then launch this file again.'}
$oldElectron=$env:ELECTRON_RUN_AS_NODE
try {
    if(-not $nodeCommand){$env:ELECTRON_RUN_AS_NODE='1'}
    $setupLog=Join-Path $project '.local\preview-runtime-setup.log'
    $setupError=Join-Path $project '.local\preview-runtime-setup-error.log'
    [IO.Directory]::CreateDirectory((Split-Path $setupLog -Parent))|Out-Null
    $setup=Join-Path $PSScriptRoot 'prepare-preview-runtime.cjs'
    $setupProcess=Start-Process -FilePath $runtime -ArgumentList ('"'+$setup+'"') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $setupLog -RedirectStandardError $setupError
    $setupOutput=@(Get-Content -LiteralPath $setupLog -ErrorAction SilentlyContinue)
    if($setupOutput -notcontains 'ForeverCoachingLuaReady'){
        $setupDetail=(Get-Content -LiteralPath $setupError -ErrorAction SilentlyContinue)-join ' '
        throw ('Could not prepare the Lua preview runtime. '+$setupDetail+' Check your internet connection and launch Preview-Addon.cmd again.')
    }
    $server=Join-Path $PSScriptRoot 'talent-preview-server.cjs'
    $process=Start-Process -FilePath $runtime -ArgumentList ('"'+$server+'"') -WorkingDirectory $project -WindowStyle Hidden -PassThru
} finally {$env:ELECTRON_RUN_AS_NODE=$oldElectron}
for($attempt=0;$attempt -lt 30;$attempt++){
    Start-Sleep -Milliseconds 200
    try{
        $health=Invoke-WebRequest "$url/health" -UseBasicParsing -TimeoutSec 1
        if($health.Content -eq 'ForeverCoachingPreview'){Start-Process $openUrl;Write-Host "Preview running at $openUrl (process $($process.Id)). Close it with Stop-Process -Id $($process.Id)";exit 0}
    }catch{}
}
throw 'The preview server did not start. Run tools/talent-preview-server.cjs with Node.js to see the error.'
