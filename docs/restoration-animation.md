# Restoration Shaman talent effect

`Media/TalentEffects/Restoration.tga` contains 36 transparent frames at 12 FPS.
The theme key is `water`, mapped only to Restoration Shaman. Other Restoration
specializations retain their own themes.

Two compact carved totems flank the talent, with floating water orbs pouring
one thick swaying stream per orb over its face, with moving foam and splashes.
A translucent tide floods the icon, with rising bubbles.
A larger clearly shaded cloud pours dense rain through it. The earlier large
side waves have been removed. No lightning, lava, or earth rupture is used.

Source frames: `art/krita/Restoration-animation-v4`. Import the PNG sequence in
Krita to edit. Generate later versions using
`tools/New-EnhancementStormAnimation.ps1 -Effect Restoration -OutputDirectory <new-folder>`.
Export with `tools/export-talent-atlas.cjs <frame-folder> addons/ForeverCoaching/Media/TalentEffects/Restoration.tga`
using Node or VS Code's Electron Node runtime.

The local preview reads the same packaged atlas. Game rendering and protected
talent UI behavior remain unverified without the client.
