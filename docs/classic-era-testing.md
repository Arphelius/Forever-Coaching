# Testing in Classic Era

Run `Install-ClassicEra-Test.cmd` to copy the current addon into `D:\World of Warcraft\_classic_era_\Interface\AddOns\ForeverCoaching`. For a different installation, run `tools\Install-ClassicEraTest.ps1 -WowRoot 'E:\World of Warcraft'` from PowerShell.

The installer reads your installed Era build, generates its Interface number, validates the load list, and writes matching default and `_Vanilla` manifests. The repository's Forever manifest stays unchanged. Any existing installed addon is backed up under `_classic_era_\ForeverCoaching-TestBackups`; account and character SavedVariables in WTF stay in place. Re-run the installer after making source changes. Use `-WhatIf` to inspect the target without copying.

1. Exit and restart Classic Era after installation so new addon files and textures are discovered.
2. At character selection, open **AddOns** and enable **Forever Coaching**.
3. Log in and type `/console scriptErrors 1`, then `/reload` to expose Lua errors.
4. Open the addon from its minimap button. Test Talent Builds, Custom Builds, language selection and Scenarios. Use `/fcpreview` to inspect the artwork and animations without spending talent points.
5. Fight an ordinary enemy. Check the live guidance, then Combat Review, its notification and **View fight timeline**. Test `/fcreminders off` and `/fcreminders on`.
6. If something fails, capture the **first** Lua error, including its file and line, and the action that caused it. Disable unrelated addons when isolating a conflict.

Classic Era is useful for testing loading, rendering, menus, the talent-window integration and readable combat events. This remains a Forever addon: its published builds, calculator data and spell priorities use Forever changes. Era cannot validate their gameplay accuracy or Forever-only spells. Saving a custom build does not spend real talent points.
