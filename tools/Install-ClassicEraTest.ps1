[CmdletBinding(SupportsShouldProcess=$true)]
param([string]$WowRoot='D:\World of Warcraft')
& (Join-Path $PSScriptRoot 'Install-AddonTest.ps1') -WowRoot $WowRoot -Client ClassicEra -WhatIf:$WhatIfPreference
