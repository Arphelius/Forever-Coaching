# Enhancement hammer and lightning

Current source: `art/krita/Enhancement-animation-v18-intro` and
`art/krita/Enhancement-animation-v18-loop`.

The hammer starts above-left, holds briefly, swings diagonally down onto the
top of the talent, then fades out. Sixteen simultaneous downward bolts flash
on impact, followed by six rapidly changing internal surge channels. The intro atlas
plays for the first three seconds of the highlight; the loop atlas continues
lightning and the two elemental totems without replaying the hammer.

Rapid descending lightning starts inside the icon's upper edge. Seeded, jagged
channels then surge through its interior. There is no sundering.

Both the addon and local preview use the intro/loop atlases. A newly highlighted
talent restarts the intro. Browser rerenders also create a fresh preview scene.
Actual WoW rendering remains unverified without a client.

Generate fresh folders with `tools/New-EnhancementStormAnimation.ps1 -Effect Enhancement`:
use `-OutputDirectory <intro-folder>` for the intro and add `-LoopOnly` for the
loop. Export them with `tools/export-talent-atlas.cjs` to `EnhancementIntro.tga`
and `Enhancement.tga` respectively in the addon's `Media/TalentEffects` folder.
