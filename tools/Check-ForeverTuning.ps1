param(
 [string]$SnapshotPath='.tmp/forever-tuning-check',
 [string]$NodePath='node'
)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$target=if([IO.Path]::IsPathRooted($SnapshotPath)){[IO.Path]::GetFullPath($SnapshotPath)}else{[IO.Path]::GetFullPath((Join-Path $root $SnapshotPath))}
New-Item -ItemType Directory -Force -Path $target | Out-Null
$utf8=[Text.UTF8Encoding]::new($false)
foreach($class in @('warrior','hunter','mage','rogue','priest','warlock','paladin','druid','shaman')){
 foreach($page in @(@('spellbook','forever-'),@('talents','talents-'))){
  $url='https://foreverchanges.pro/'+$page[0]+'/'+$class
  $file=Join-Path $target ($page[1]+$class+'.html')
  $response=Invoke-WebRequest -UseBasicParsing $url -TimeoutSec 60
  [IO.File]::WriteAllText($file,$response.Content,$utf8)
 }
 Write-Output ('Downloaded '+$class)
}
$patch=Invoke-WebRequest -UseBasicParsing 'https://foreverchanges.pro/patch-notes' -TimeoutSec 60
[IO.File]::WriteAllText((Join-Path $target 'patch-notes.html'),$patch.Content,$utf8)
$notesUrl=[regex]::Match($patch.Content,'https://us\.forums\.blizzard\.com/[^"\s<>\\]+').Value
if(-not $notesUrl){throw 'No official development-notes link found; review the upstream page format.'}
$notes=Invoke-WebRequest -UseBasicParsing ($notesUrl+'.json') -TimeoutSec 60
[IO.File]::WriteAllText((Join-Path $target 'official-notes.json'),$notes.Content,$utf8)
$build=[regex]::Match($patch.Content,'Beta build (1\.\d+\.\d+\.\d+)').Groups[1].Value
if(-not $build){throw 'Could not identify the current client build; bundled data was not changed.'}
$manifest=@{build=$build;reviewed=(Get-Date -Format 'yyyy-MM-dd');notesUrl=$notesUrl}
[IO.File]::WriteAllText((Join-Path $target 'manifest.json'),($manifest|ConvertTo-Json),$utf8)
if($NodePath -eq 'node' -and -not(Get-Command node -ErrorAction SilentlyContinue)){
 $code=Join-Path $env:LOCALAPPDATA 'Programs/Microsoft VS Code/Code.exe'
 if(Test-Path -LiteralPath $code){$NodePath=$code;$env:ELECTRON_RUN_AS_NODE='1'}else{throw 'Install Node.js or pass -NodePath.'}
}
Push-Location $root
try{& $NodePath (Join-Path $PSScriptRoot 'Check-ForeverTuning.cjs') $target | Out-Host;$result=$LASTEXITCODE}finally{Pop-Location}
exit $result
