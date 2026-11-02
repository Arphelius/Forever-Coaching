# Retail testing

Run `Install-Retail-Test.cmd` to install the current workspace addon in `D:\World of Warcraft\_retail_\Interface\AddOns\ForeverCoaching`. A different game location can be supplied with `-WowRoot`. The installer reads the local Retail build metadata, validates every file in the load list and creates both default and `_Mainline` manifests. Existing addon files are backed up under `_retail_\ForeverCoaching-TestBackups` before replacement. WTF settings are preserved. Re-run the installer after source changes; `-WhatIf` previews its target.

Restart Retail, enable **Forever Coaching** in the character-selection **AddOns** menu, and log in. Use `/console scriptErrors 1` followed by `/reload` to expose Lua errors. Open the minimap button to inspect the dashboard, and `/fcpreview` to browse the actual animation renderer. Capture the first Lua error and the steps that caused it if loading fails.

The browser preview uses HTML/CSS and an approximation of the Blizzard talent interface. The in-game dashboard is implemented separately with Lua frames. A different client does not automatically make their layouts match. Retail can test rendering and loading, but this addon's Forever builds, classic talent layouts and spell advice are not Retail gameplay data. Test talent learning and Forever-specific mechanics on the intended Forever client.
