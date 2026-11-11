[CmdletBinding()]
param([ValidateRange(1,24)][int]$Hours=4,[string]$GameRoot='D:\World of Warcraft\_forever_')
$ErrorActionPreference='Stop'
$reportRoot=Split-Path $PSScriptRoot -Parent
if($GameRoot.Contains('"')){throw 'Invalid game root.'}
if(-not (Test-Path -LiteralPath (Join-Path $GameRoot 'Interface\AddOns\ForeverCoaching\ForeverCoaching.toc'))){throw 'The installed ForeverCoaching addon was not found in this game root.'}
$runtime=Get-Command node -ErrorAction SilentlyContinue
$nodePath=if($runtime){$runtime.Source}else{Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio\18\Community\MSBuild\Microsoft\VisualStudio\NodeJs\node.exe'}
if(-not (Test-Path -LiteralPath $nodePath)){throw 'Install Node.js before enabling automatic updates.'}
$privateDirectory=Join-Path $reportRoot '.local\optimization'
[IO.Directory]::CreateDirectory($privateDirectory)|Out-Null
$clientId=if($env:WCL_CLIENT_ID){$env:WCL_CLIENT_ID.Trim()}else{(Read-Host 'Warcraft Logs Client ID').Trim()}
$secret=if($env:WCL_CLIENT_SECRET){ConvertTo-SecureString $env:WCL_CLIENT_SECRET -AsPlainText -Force}else{Read-Host 'Warcraft Logs Client Secret' -AsSecureString}
if(-not $clientId -or $secret.Length -eq 0){throw 'Client ID and secret are required.'}
# Windows DPAPI encrypts the secret for this Windows user on this computer.
$credential=[Management.Automation.PSCredential]::new($clientId,$secret)
$credential | Export-Clixml -LiteralPath (Join-Path $privateDirectory 'automatic-credentials.xml')
$identity=[Security.Principal.WindowsIdentity]::GetCurrent().Name
$action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+(Join-Path $PSScriptRoot 'Run-AutomaticPublicReports.ps1')+'" -Hours '+$Hours+' -GameRoot "'+$GameRoot+'"') -WorkingDirectory $reportRoot
$timer=New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15)
$logon=New-ScheduledTaskTrigger -AtLogOn -User $identity
$principal=New-ScheduledTaskPrincipal -UserId $identity -LogonType Interactive -RunLevel Limited
$settings=New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 3) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName 'ForeverCoaching-PublicReports' -Action $action -Trigger @($timer,$logon) -Principal $principal -Settings $settings -Description 'Refresh public dungeon examples; resume cached batches without changing an incomplete catalog.' -Force | Out-Null
Start-ScheduledTask -TaskName 'ForeverCoaching-PublicReports'
Write-Output "Automatic updates enabled: new scan every $Hours hours while you are signed into Windows; unfinished batches retry every 15 minutes."
Write-Output ('Status log: '+(Join-Path $privateDirectory 'automatic-update.log'))
Write-Output 'Use /reload in WoW after Catalog saved. This does not publish a CurseForge release.'
