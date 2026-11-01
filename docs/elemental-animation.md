# Elemental talent effect

Elemental has its own atlas: `Media/TalentEffects/Elemental.tga`.
It plays 36 frames at 12 FPS using the same mouse-transparent talent overlay
and exact-atlas browser preview as Enhancement.

The v2 design uses molten vents on both sides, dark floating crust, ballistic
lava droplets, and spills overlapping the lower corners. Separate descending
lightning strikes hit both sides and the icon in quick succession: three staggered
flashes per second in v4, increased to six staggered strikes per second from six
positions in v5. V6 increases this to eight positions and eight staggered strikes
per second, with slightly shorter and thinner bolts. Each jagged channel stays
rigid during its flash. This does not use
Enhancement's continuously moving bolts.
Actual game rendering still needs client testing.

Source frames: `art/krita/Elemental-animation-v6`. Import the PNG sequence into
Krita to edit. Generate a fresh version with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/New-EnhancementStormAnimation.ps1 -Effect Elemental -OutputDirectory art/krita/Elemental-animation-v3
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/Export-TalentAnimation.ps1 -SourceDirectory art/krita/Elemental-animation-v3 -OutputPath addons/ForeverCoaching/Media/TalentEffects/Elemental.tga
```

Reopen `Preview-Addon.cmd` after server changes, select Shaman and an Elemental
build, and enable "Show effects without available points" if needed.
