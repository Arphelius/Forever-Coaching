# Enhancement talent animation

The Blizzard talent pointer now uses the authored Enhancement v11 frames:
independently moving lightning branches inside and around the icon, and one large
earthen chasm lying beneath it. Two small totems flank the icon: fire on the
left, green earth on the right. V10 brings both totems closer, adds surrounding
fire tongues and green earth wisps, speeds the lightning's motion by three,
and adds travelling ground upheaval with lifted plates and grit. Other spec
effects are unchanged. No AI-generated artwork is used.

## In-game check when a client is available

1. Install the entire `addons/ForeverCoaching` folder, including `Media`.
2. Restart the client after installing the new texture file.
3. Select an Enhancement build in the addon.
4. With an unspent talent point, open Blizzard's talent panel and the tree
   containing the recommended next talent.

The animation surrounds that talent, without text, at 12 FPS over 36 frames.
It does not spend points or open the panel automatically. Normal point checks
remain in place. Actual client appearance has not been verified.

## Updating the art

Export 36 transparent PNGs from Krita as `enhancement_0000.png` through
`enhancement_0035.png` into `art/krita/Enhancement-animation-v11`, then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/Export-TalentAnimation.ps1
```

The exporter packs 128-pixel cells into a 1024-square, 32-bit TGA atlas at
`addons/ForeverCoaching/Media/TalentEffects/Enhancement.tga`. The Lua player
uses the atlas directly. Lightning and semi-transparent earthen fractures now
cross the existing talent icon and extend beyond its edges.
V11 removes the detached earthen shelves and individual plates, replacing them
with a wide connected tear extending from the ground through the icon.

The original 1024-pixel PNGs remain the editable export source. V11 is authored
by `tools/New-EnhancementStormAnimation.ps1`; earlier layered static designs
are preserved separately. Import its PNG sequence into Krita to edit frames.
Brightness is
baked into those frames; the player adds no extra fading or circular particles.

The browser `Preview.html` in the source animation folder shows the original
frames, not Blizzard's UI or the downscaled game texture.
