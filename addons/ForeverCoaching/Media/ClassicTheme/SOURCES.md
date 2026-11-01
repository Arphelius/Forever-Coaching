# Original Classic artwork

No AI-generated artwork is used by this theme.

- `ClassicBackdrop.jpg`: Blizzard Entertainment's original coastal-cliff concept artwork, archived as `Vanilla/Vanilla-Wallpaper-03.bmp` in [ArchiveCraft's Vanilla wallpaper collection](https://archivecraft.com/download-house/). Cropped to the scenery to exclude the archive wallpaper bars. Original archive: https://archivecraft.com/wp-content/uploads/downloads/wallpapers/archivecraft_vanilla_wallpapers_20120307.zip . Artwork remains copyrighted by Blizzard Entertainment.
- `CLASS-INDEX.jpg`: original Classic talent-interface artwork, served by Wowhead's asset CDN: `https://wow.zamimg.com/images/wow/talents/backgrounds/classic/ID.jpg`. Tree order and IDs are listed below. Artwork remains copyrighted by Blizzard Entertainment.
- `.tga` files contain the same artwork resized to power-of-two dimensions and converted to uncompressed BGRA for the game client. `tools/Convert-ClassicTheme.ps1` reproduces the conversion. Fading is applied by the UI, not painted into the images.
- Native buttons reference the client's `Interface\Buttons\UI-Panel-Button-Up`, `Down`, and `Highlight` textures. Browser buttons approximate these controls with CSS bevels and red/gold colors.

| Class | Tree 1 | Tree 2 | Tree 3 |
|---|---|---|---|
| Druid | 283 Balance | 281 Feral | 282 Restoration |
| Hunter | 361 Beast Mastery | 363 Marksmanship | 362 Survival |
| Mage | 81 Arcane | 41 Fire | 61 Frost |
| Paladin | 382 Holy | 383 Protection | 381 Retribution |
| Priest | 201 Discipline | 202 Holy | 203 Shadow |
| Rogue | 182 Assassination | 181 Combat | 183 Subtlety |
| Shaman | 261 Elemental | 263 Enhancement | 262 Restoration |
| Warlock | 302 Affliction | 303 Demonology | 301 Destruction |
| Warrior | 161 Arms | 164 Fury | 163 Protection |

These are Classic tree backgrounds, not newly drawn build-specific backgrounds or VFX-off borders. All files are local; no external image request is required while viewing the addon or its preview.
