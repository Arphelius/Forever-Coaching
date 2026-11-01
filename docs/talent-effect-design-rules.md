# Talent effect direction

Fire Mage v2: much thicker coil fitted against the talent border, starting at
the exact bottom-left corner. Larger head and stronger continuous fire breath,
broader layered plume, more flame wisps and twice as many embers. Source:
`Fire-DragonsBreath-v2`.

Fire Mage: Dragon's Breath-inspired custom fiery dragon. Tapered tail starts
bottom-left, body coils around bottom/right/top, and long neck ends in a horned
head at top-left facing inward. Animate flame wisps, sparks and a layered fire
breath over the talent. Keep rank clear. Source: `Fire-DragonsBreath-v1`,
generator `New-FireDragonAnimation.ps1`, atlas `Fire.tga`.

Arcane v19: swap circle positions: surging pink power circle inside at radius
218; separate ornate rune band outside at radius 300. Preserve all motion and
colors. Source: `Arcane-Spellslinger-v19`.

Arcane v18: separate the surging pink power circle outside the rune circle.
Keep the tight rune band readable; move filaments, pulses and surging arcs
to radius approximately 300 instead of drawing over its glyphs. Source:
`Arcane-Spellslinger-v18`.

Arcane v17: restore the earlier strong surge as two bright twisting filaments,
20 luminous moving pulses and thicker energized rim arcs. Keep it confined to
the tight rune band, with no splinters or center beams. Source:
`Arcane-Spellslinger-v17`.

Arcane v16: fit the rune circle tightly around the talent (inner radius 195,
outer 240). Add moving power arcs along its rims and traveling rune brightness
waves. No splinters or center beams. Source: `Arcane-Spellslinger-v16`.

Arcane v15: remove splinters and all connecting surge/filaments/pulses. Keep
only the ornate rotating rune circle and its sigil strokes, at the same size,
brightness and color. Source: `Arcane-Spellslinger-v15`.

Arcane v14: bring the outer rune band inward until its inner rim meets the
splinter/link circle, removing the empty gap. Preserve v13 speed, color and
surge. Source: `Arcane-Spellslinger-v14`.

Arcane v13: halve splinter rotation again, restore the larger outer rune circle
at its original radius, and brighten/saturate runes, seals and splinter colors.
Keep surging restricted to splinter connections. Source: `Arcane-Spellslinger-v13`.

Arcane v12: halve spin speed and remove outer missile wakes. Keep the surge
only in the links between splinters; preserve the ornate rune-circle design.
Slightly brighten violet/cyan splinter colors. Source: `Arcane-Spellslinger-v12`.

Arcane v11 reset: restore compact continuous playback at 2.4 highlight scale,
18 fps. Remove staged growth, accelerated runtime rotation, black-hole switch
and animation erasure. Keep the ornate rune circle replacing the thick pink
ring, fast inward-facing splinters and perimeter missiles; intensify shard glow,
rune brightness and link pulses. Source: `Arcane-Spellslinger-v11`. This fully
supersedes the black-hole finale instructions below.

Arcane finale: accelerate spin while increasing render scale in five two-second
steps (2.4, 4, 6.5, 10, 16 times highlight size), spanning the talent-tree area.
At ten seconds switch to a spiraling black hole, contract/fade over two seconds,
then leave the animation erased until the target changes or preview reloads.
Keep this explicit 12-second lifecycle identical in Lua and browser. Circle
source remains `Arcane-Spellslinger-v10`; collapse source `Arcane-Collapse-v1`,
generator `New-ArcaneCollapseAnimation.ps1`, atlas `ArcaneCollapse.tga`.

Arcane v10: play at 18 fps (50% faster), with 16 independently shaped outer
missiles, longer varied wakes, bright cores and stronger glow. Retain continuous
surge and rune circle. Source: `Arcane-Spellslinger-v10`.

Arcane v9: outer missiles and link pulses use independent speeds that do not
advance by exact repeated-element spacings per frame. Avoid temporal aliasing
that makes them appear stationary. Keep v8 fast splinters and strong surge.
Source: `Arcane-Spellslinger-v9`.

Arcane v8: double continuous spin speed; intensify filaments and increase to
12 link pulses and 12 bright perimeter wakes. Preserve rune circle, inward
splinters and clear center. Source: `Arcane-Spellslinger-v8`.

Arcane v7: keep the ornate rune circle AND strong surge. Restore bright twisting
filaments and separate fast power wakes outside the rune band, without the thick
solid pink ring or center beams. Source: `Arcane-Spellslinger-v7`.

Arcane v6: replace the thick rotating pink energy ring with the finer ornate
rune circle, moved inward to the splinters. Remove duplicate inner rune rings
and broad perimeter wakes. Keep spinning splinters, bright moving pulses and
faint connecting filaments. Source: `Arcane-Spellslinger-v6`.

Arcane v5: add reference-inspired fine concentric spell circles, bands of varied
angular magenta runes and paired radial sigil strokes. Preserve the accepted
spinning splinters, links and perimeter surge; do not add center lasers. Source:
`Arcane-Spellslinger-v5`.

Arcane v4: no lasers/discharges through the center. Concentrate stronger energy
on spinning splinters and connections: thicker luminous links, twisting
filaments, denser pulses, stronger shard glow and fast perimeter power wakes.
Source: `Arcane-Spellslinger-v4`.

Arcane v3: continuously spinning inward-facing splinters and permanent connected
links. Sustain the arcane surge without pauses: stronger violet/white links,
five pulses per connection and eight bright moving energy discharges. Source:
`Arcane-Spellslinger-v3`.

Arcane v2: splinters remain visible permanently at fixed radius, with their
pointed tips aimed inward at the talent. Links form first, then the connected
formation spins and sends arcane power pulses/discharges through the icon.
No shard fade-out or fly-in. Source: `Arcane-Spellslinger-v2`.

Arcane Mage: Spellslinger-inspired splinters gather around the icon, link in
sequence, then surge with moving arcane pulses and short discharges across
the talent. Fade and reset the formation. Custom-drawn source:
`Arcane-Spellslinger-v1`, generator `New-ArcaneSpellslingerAnimation.ps1`,
atlas `Arcane.tga`. Keep the talent points counter clear.

Restoration Druid v3: offset both antlers outward to clear the bottom-right
talent points counter. Preserve smaller antler size and healing swirl. Source:
`RestorationDruid-KeeperOfTheGrove-v3`.

Restoration Druid v2: reduce antlers 12% around the icon center. Preserve the
healing swirl and motes. Source: `RestorationDruid-KeeperOfTheGrove-v2`.

Restoration Druid: Keeper of the Grove inspiration. Branching tapered wooden
antlers frame the icon, with small leaves, a flowing green healing spiral and
rising motes. Keep talent/rank readable. Custom-drawn source:
`RestorationDruid-KeeperOfTheGrove-v1`, generator `New-GroveKeeperAnimation.ps1`,
atlas `RestorationDruid.tga`.

Bear v7 USER DRAWING is authoritative: fingertips/claws point UPPER-LEFT, palm
and wrist sit LOWER-RIGHT, and the complete hand DRAGS DOWN-RIGHT. Facing and
travel are deliberately opposite. Do not reinterpret this as claws leading
the motion. Preserve skin/fur and fangs. Source: `Bear-DruidOfTheClaw-v7`.

Bear v6 correction: swipe TOP-LEFT to BOTTOM-RIGHT. Flip the connected palm and
knuckles together with the talons so claws lead the stroke and the wrist trails
above-left. Preserve skin/fur and fangs. Source: `Bear-DruidOfTheClaw-v6`.

Bear v5: restore the connected fleshy/furred paw and knuckles behind the claws.
Flip talon facing 180 degrees, preserving the existing bottom-right/top-left
travel path. Changing facing must not reverse travel. Keep fangs/no brown ring.
Source: `Bear-DruidOfTheClaw-v5`.

Bear v4: reverse swipe travel bottom-right to top-left along the same diagonal.
Preserve current talon shapes, rightward inclination and fangs. Do not redesign
the claw when adjusting movement. Source: `Bear-DruidOfTheClaw-v4`.

Bear v3: restore upper/lower fangs and small teeth, without the circular brown
muzzle. Remove blocky paw. Four large hooked talons swipe upper-left to
lower-right with a rightward curve and inclination, leaving fading scratches.
Source: `Bear-DruidOfTheClaw-v3`.

Bear v2: remove the brown circular mouth and fangs. One huge connected furred
bear paw with four curved ivory claws sweeps across the icon and leaves fading
scratches. Source: `Bear-DruidOfTheClaw-v2`.

Bear/Feral tank: Druid of the Claw inspiration. A dark furred open mouth fully
surrounds the talent, with long upper/lower canines and smaller teeth. Three
talons rake the icon and leave fading warm-edged scratches. Keep the rank clear.
Source: `Bear-DruidOfTheClaw-v1`, generator `tools/New-BearClawAnimation.ps1`,
atlas `Bear.tga`. Custom-drawn only.

Feral v6: clearly distinct broad five-lobed leaves, long curved pointed blades
and fern sprigs with separate paired leaflets. Reduce overlap so silhouettes
remain recognizable. Preserve fur and eye. Source: `Feral-Wildstalker-v6`.

Feral v5: surround the eye socket with layered brown/violet tiger fur, pointed
tufts, fine strands and dark stripes. Mix serrated, narrow and broad leaves,
vary their scale/colors and add independent gentle sway. Keep the eye visible
through the foliage. Source: `Feral-Wildstalker-v5`.

Feral v4: eye reduced 14%; increase surrounding foliage to 38 leaves and bring
the bush closer around the eye while preserving a small gap. Source:
`Feral-Wildstalker-v4`.

Feral v3: remove the leafy arch/branches. Surround the whole tilted eye with
smaller irregular green/purple leaves, leaving a narrow dark gap around the
eye opening. Reference guides composition only. Source: `Feral-Wildstalker-v3`.

Feral v2: cluster dense overlapping leaves and branches around the eye itself,
above and at its corners, like a bush concealing the stalking tiger. Preserve
the visible amber opening and blink. Source: `Feral-Wildstalker-v2`.

Feral DPS: Wildstalker inspiration. One large amber tiger eye peers from deep
shadow above the talent, with a slit pupil, iris fibers, heavy brow and tiger
stripes. Slow blinking and a restrained pupil shift convey watchfulness; dark
leaves frame the edges. No generated imagery. Source: `Feral-Wildstalker-v1`,
generator `tools/New-FeralWildstalkerAnimation.ps1`, atlas `Feral.tga`.

Balance v4: remove the orb's surrounding corona, halo and radial flares. Keep
the split sun/eclipse disk and vibrant rays falling onto the icon. Source:
`Balance-ElunesChosen-v4`.

Balance v3: more vibrant saturated eclipse/sun beams, brighter thicker traveling
rays, stronger corona flares and brighter stars. Preserve the split orb layout.
Current source: `Balance-ElunesChosen-v3`.

Balance v2: split the orb vertically: left half is a dark total eclipse with
a blue lunar rim and violet-blue eclipse rays; right half is an unveiled golden
sun casting warm sunlight on its corresponding side of the talent. Source:
`Balance-ElunesChosen-v2`.

Balance Druid: Elune's Chosen inspiration, custom-drawn total eclipse above the
icon. Combine a dark moon disk, cool lunar rim and warm solar corona; cast cool
moonbeams and warm sunlight onto the talent beneath, with gentle eclipse shadow
and stars at the edges. Source: `Balance-ElunesChosen-v1`, generator
`tools/New-BalanceEclipseAnimation.ps1`, atlas `Balance.tga`.

Survival v5: remove the dark shroud entirely. Keep steel jaws, fire trap,
smaller glacier trap and falling frost mist. No spear. Source: `Survival-Ambush-v5`.

Survival v4: remove spear and impact completely. Reduce freezing trap about
16% and add pale frost smoke spilling downward and spreading as it falls.
Keep fire, bear trap and dark shroud. Current source: `Survival-Ambush-v4`.

Survival v3: fire uses layered irregular flickering flame sheets, hot white/yellow
roots, translucent orange-red tips and rising embers. Ice trap is surrounded by
asymmetric jagged glacier slabs with shaded facets, bright ridges and low frost
mist. Preserve spear, bear trap and shroud. Source: `Survival-Ambush-v3`.

Survival v2: enlarge the spear 60% and the fire/ice traps 45%. Make the dark
shroud broader and denser, with faint charcoal curls visible against the dark
HUD. Keep bear-trap framing and ambush timing. Source: `Survival-Ambush-v2`.

Survival: dark drifting shroud, an open steel bear trap fully surrounding the
talent with inward teeth, a fire trap at lower-left and an ice trap at lower-right.
A spear emerges from upper-right darkness and strikes the center, holds, then
fades for the next ambush. Keep the rank clear. Custom-drawn source:
`Survival-Ambush-v1`, generator `tools/New-SurvivalAnimation.ps1`, atlas `Survival.tga`.

Marksmanship Sentinel v5: remove the wings entirely. Keep the fixed large owl
eyes, bullseye and arcane shots unchanged. Source: `Marksmanship-Sentinel-v5`.

Marksmanship Sentinel v4: attach the wing roots to the icon's upper corners,
reduce wings about 20%, and lower fixed eyes toward the top border. Keep the
large eye shapes and arcane shots. Source: `Marksmanship-Sentinel-v4`.

Marksmanship Sentinel v3: remove scanning gaze. Enlarge the fixed menacing eyes
about 60%, and enlarge/reposition each wing to spread from its own upper side
of the icon. Preserve arcane shots. Source: `Marksmanship-Sentinel-v3`.

Marksmanship Sentinel v2: keep only spread wings and narrow menacing cyan eyes
with a subtle side-to-side tracking gaze. Remove owl body, head outline, beak,
feet and crescent. Keep bullseye and arcane shots. Source:
`Marksmanship-Sentinel-v2`.

Marksmanship Sentinel v1: add a custom-drawn owl perched above the icon with
spread feathered wings, tufted head, cyan eyes and a crescent of arcane energy.
Keep the bullseye and fast arcane shots with impacts. No generated imagery.
Current source: `Marksmanship-Sentinel-v1`.

Marksmanship v8: use four clearly visible concentric red archery bullseye rings
on the talent, centered on the arrows' impact point. Keep the center hollow,
fast large arcane arrows, embedded shafts and explosions. Current source:
`Marksmanship-ArcaneBullseye-v8`.

Marksmanship v7: enlarge flying and embedded arrows by approximately 15%,
preserving fast flight and impacts. Source: `Marksmanship-ArcaneBullseye-v7`.

Marksmanship v6: arrow flight takes two frames instead of eight (four times
faster), with impact and embedded-arrow timing adjusted to match. Keep existing
shot intervals and explosion style. Source: `Marksmanship-ArcaneBullseye-v6`.

Marksmanship v5: large luminous arcane arrows with broadheads and coiling energy
strike the bullseye, explode into a violet shockwave and radial sparks, and stay
embedded in the icon until the loop restarts. Current source:
`Marksmanship-ArcaneBullseye-v5`.

Marksmanship v4: remove the filled red Hunter's Mark arrow from the center;
keep the red bullseye rings. Three arcane arrows approach from different
directions in sequence, strike the center and produce brief violet impact
sparks, then disappear. Current source: `Marksmanship-ArcaneBullseye-v4`.

Marksmanship v3: Hunter's Mark sits directly on the talent artwork, not above
it. Bullseye rings and sights are red; arcane runes/charges/sparks are faint
accents only. Wait for the user's direction before adding more features.
Current source: `Marksmanship-ArcaneBullseye-v3`.

Marksmanship v2 bullseye: add a bold red downward Hunter's Mark arrow above
the talent, pointing onto its top edge. Preserve arcane targeting and charges.
Current source: `Marksmanship-ArcaneBullseye-v2`.

Marksmanship replacement: remove Dark Ranger entirely from playback. Use an
arcane bullseye lock with segmented targeting rings, inward sights, subtle center
crosshair, orbiting runes and three loading arcane charges beneath the icon.
No cowl, mask, red eyes, shroud or bow. Current source:
`Marksmanship-ArcaneBullseye-v1`, generator `New-ArcaneBullseyeAnimation.ps1`.

Marksmanship mask adjustment (v3): raise the mask slightly and reduce its width
8% and height 14% to expose more talent artwork. Keep the red eyes, cowl, shroud,
bow and arrow. Current source: `Marksmanship-DarkRanger-v3`.

Marksmanship v2: join the mask directly to the cowl edges, with narrow glowing
red eyes in the opening above it. Replace purple surrounding haze with very
dark drifting smoke. Preserve the approved right-facing bow and dark-energy
arrow unchanged. Current source: `Marksmanship-DarkRanger-v2`.

Marksmanship: custom-drawn Dark Ranger design. A dark peaked cowl frames the
upper icon and a cloth mask covers its lower edge without hiding the rank.
Drifting purple-black shadow surrounds it. A recurved bow and nocked arrow point
right, with animated dark energy coiling along the shaft and gathering at the
broadhead. Source: `Marksmanship-DarkRanger-v1`, generator
`tools/New-DarkRangerAnimation.ps1`, atlas `Marksmanship.tga`.

Beast Mastery eyes placement (v6): lower the amber top pair and raise the green
left pair slightly. Keep the right pair and exterior bow/quiver lean unchanged.
Current source: `BeastMastery-PackLeader-v6`.

Beast Mastery exterior lean (v5): keep the 24-degree equipment tilt, but place
the bow's outermost upper tip against the outside of the icon's left border.
The bow, string and quiver must not phase through the talent artwork. Source:
`BeastMastery-PackLeader-v5`.

Beast Mastery contact correction (v4): move the entire bow/quiver assembly inward
and increase its lean to 24 degrees so the upper limb visibly rests against
the icon's left edge, with the quiver hanging below. Source:
`BeastMastery-PackLeader-v4`.

Beast Mastery placement revision (v3): remove the separate nocked arrow; keep
arrows in the quiver. Strap quiver visibly to the bow and tilt the whole assembly
against the icon. Shift the right eye pair slightly left. Current source:
`BeastMastery-PackLeader-v3`.

Beast Mastery equipment revision (v2): arrows sit inside a leather quiver strapped
to the bow's lower limb; one poison arrow is nocked to its string. No loose arrows
floating below the icon. Eyes have narrow slanted shapes and dark heavy brows.
Current source: `BeastMastery-PackLeader-v2`.

Beast Mastery first pass: Pack Leader inspiration, custom-drawn only; no
generated animal artwork or full beast bodies. Three animal eye pairs (amber,
green slit pupils and cyan) watch around the icon with separate blink timing.
A hunting bow hugs the left side; poison-tipped arrows sit below, with dripping
venom and drifting green wisps. Source: `BeastMastery-PackLeader-v1`, generator
`tools/New-BeastMasteryAnimation.ps1`, atlas `BeastMastery.tga`.

Restoration internal rain (v11): add distinct rainfall clipped to the talent
face, preserving the submerged treatment, pool, mirrored crossing water swirls
and no-cloud design. Current source: `Restoration-Farseer-v11`.

Restoration crossing zigzags (v10): as they rise, each spirit alternates outside
the icon, through its center, outside the other side, and back through again.
Use three broad alternating lobes; the second spirit mirrors the first. They
start together and converge/fade above the icon. This supersedes exterior-only
paths. Current source: `Restoration-Farseer-v10`.

Restoration mirrored zigzags (v9): preserve graceful curling wakes while the
two spirits rise together in mirrored zigzag paths outside opposite sides of
the icon. Avoid straight vertical rails and clipping corners. They converge
above the icon and fade together. Current source: `Restoration-Farseer-v9`.

Restoration exterior paths (v8): mirrored water spirits rise outside the talent's
left/right edges and converge only above its top edge. Keep wakes, foam and
glow off the button and rank label to preserve talent identification. Retain
the pool, light rain, submerged treatment and synchronized fade/restart.
Current source: `Restoration-Farseer-v8`.

Restoration synchronized ascent (v7): two mirrored water spirits start together
at the pool, rise on opposite sides, converge at one point above the icon, then
fade out together before restarting. Preserve rain, submerged icon and pool.
Current source: `Restoration-Farseer-v7`.

Restoration Farseer v5: spirits rise bottom-to-top from the pool in curling
helical paths beside and across the icon, inspired by the reference's ascending
water swirls. Softly emerge at the pool and dissolve above the icon rather than
cutting out at its corners. Keep light rain and the submerged icon.
Current source: `Restoration-Farseer-v5`.

Restoration Farseer v4: add sparse light rain without a cloud. Water spirits
complete uninterrupted full orbits: no timed disappearance or rectangular rank
cutout clipping the streams at corners. Draw each complete current once.
Keep the submerged icon and pool. Current source: `Restoration-Farseer-v4`.

Restoration Farseer v3: remove rain/cloud, totems, fixed orbs and stone bowl.
Keep the icon submerged with an undulating waterline and bubbles, above a pool.
Water spirits use Enhancement's opposing tilted orbits and staggered timing,
at two revolutions per loop rather than three, with smoother broad water wakes.
Current source: `Restoration-Farseer-v3`; generator `New-FarseerAnimation.ps1`.

Restoration correction (Farseer v2): retain the approved v7 rain/cloud, flooded
icon, enlarged totems and large dripping watery orbs. Add slow flowing water
spirals along a rounded outer perimeter encompassing all four icon edges and
corners, rather than an orbit inside its face. Generator composites the original
`Restoration-animation-v7` frames with new currents. Current source:
`Restoration-Farseer-v2`. This supersedes the v1 replacement design.

Elemental playback: no start animation or simultaneous opening burst. Begin
the regular `Elemental.tga` loop immediately in the addon and browser preview.
This supersedes all earlier Elemental intro instructions below.

Restoration Farseer rework: replace the previous rain/totem effect with a clear
pool beneath the icon feeding broad curling water currents. Follow Enhancement's
tilted circular motion through and around the icon, slower (one revolution per
loop), with zigzag ripples along a bottom-left/top-right diagonal. Use open water
vortices, foam and droplets; preserve rank visibility. Source:
`Restoration-Farseer-v1`, generator `tools/New-FarseerAnimation.ps1`, packaged as
`Restoration.tga`. No image generation.

Elemental final ground decision (v11): remove the platform entirely. No rock
ledge, split slabs, fissure or debris. Keep the storm cloud, lightning and
original lava effects. Current source: `Elemental-Stormbringer-v11`.

Elemental ledge revision (v10): replace the exploding platform with one solid
cupped dark-rock ledge touching the icon's underside, with raised jagged sides
and shaded rock facets. No separating disk or blue fissure. Keep the lava and
lightning. Current source: `Elemental-Stormbringer-v10`.

Elemental platform revision (v9): replace the brown strip and luminous blue
fissure with a single jagged dark basalt platform, angular top facets and thick
broken edges. Heavy lightning strikes trigger radial chunk separation, lift,
rotation and flying fragments; the pieces settle before the next impact.
Preserve the lava rendering. Current source: `Elemental-Stormbringer-v9`.

Elemental Stormbringer upgrade (v8): retain the existing simultaneous opening,
staggered lightning and unchanged `Lava`/`VolcanicVents` artwork and motion. Add
a compact curling thundercloud, heavy branching downward strikes, and solid
earth slabs lifting beside a cold-lit fissure beneath the icon. Generator flag:
`-Effect Elemental -Stormbringer`. Source: `Elemental-Stormbringer-v8`, packaged
as `Elemental.tga`. Do not modify Enhancement's accepted v18 motion/v17 body.

Enhancement movement correction (v18): keep the long flowing-current algorithm
from v15 (0.24-cycle wake and sustained trail opacity). Separate each element
through distinct orbit radii/tilts, opposing directions, and irregular start
intervals/durations. Do not substitute brief isolated floating-orb passes again.
Current sources: `Enhancement-Totemic-v18-front` and `Enhancement-Totemic-v18-rear`;
bird-head body remains v17.

Enhancement head update (v17): no candle-like flames above the head. Use a carved
raptor head with layered wooden feather plates, heavy glowing brows and a long
hooked beak. Preserve the wings, size, elemental wakes and lightning. Body source:
`Enhancement-Totemic-v17-body`; elemental sources remain v16 front/rear.

Enhancement separation correction (v16): fast movement does not mean all four
elements stay visible together. Stagger independent appearances, use distinct
tilts and radii, alternate directions and vary speed. Substantial individual
wakes must fade to transparent before joining another element. Current sources:
`Enhancement-Totemic-v16-front` and `Enhancement-Totemic-v16-rear`.

Enhancement continuous flow (v15): triple the elemental orbit speed and keep
long overlapping wakes visible continuously, instead of intermittent isolated
orbs. Reduce the leading vortex size so the flowing elements dominate. Preserve
opposing directions, front/rear layering and restored lightning. Current sources:
`Enhancement-Totemic-v15-front` and `Enhancement-Totemic-v15-rear`.

Enhancement lightning restoration (v14): restore the original six fast seeded
blue-white lightning channels over the icon, keeping the current totem and
elemental vortices. No hammer or old side totems. Foreground source is now
`Enhancement-Totemic-v14-front`; rear remains `Enhancement-Totemic-v13-rear`.

Enhancement silhouette update (v13): avoid a solid round head attached to a thin
tail. Use open broken vortex curls, broad billowing wakes and scattered curved
flecks. Preserve elemental materials, staggered timing and opposing orbits.
Current sources: `Enhancement-Totemic-v13-front` and `Enhancement-Totemic-v13-rear`.

Enhancement wake update (v12): retain staggered independent orbs, opposing
directions and front/rear circular layering. Each orb pulls a broad tapered
elemental wake: curled flame tongues, wispy wind curls, water ribbons with
droplets, or green earth flow carrying solid rocks. Wakes remain separate,
not a continuous shared ring. Current elemental sources:
`Enhancement-Totemic-v12-front` and `Enhancement-Totemic-v12-rear`.

Enhancement motion update (v11): independent short-lived elemental orbs appear
at staggered times, moving in opposite directions at different speeds around
the tilted circular path. Keep their wakes short so they do not form a connected
ring. Front/rear atlases use `Enhancement-Totemic-v11-front` and `-v11-rear`.

Enhancement placement update (v8): render the totem at 1.7 times the highlight size,
centered with equal overall extent above and below the icon. The complete
totem is behind the button (`Enhancement.tga`); elemental orbs and their wakes
follow rounded looping paths around the icon with inward sweeps through its face
in a separate foreground atlas (`EnhancementElements.tga`) at 2.4 times the
highlight size. Sources: `Enhancement-Totemic-v7-body` and
`Enhancement-Totemic-v8-elements`. This supersedes older size and motion notes.

Apply these rules to every future specialization effect:

- Compose the effect across the talent icon and in the space beside its edges.
  Include clear side details, not only content inside the icon.
- Give each specialization its own shapes, materials, visual theme, and animation.
  Shared placement and texture playback do not mean shared visual design.
- Use movement appropriate to the material. Lightning can branch and jump;
  earth should separate, lift, and fracture as solid ground.
- Aim for bold fantasy visuals with a clear silhouette at actual talent size.
  Avoid generic circles, isolated thin lines, and brightness-only animation.
- Keep overlays mouse-transparent. Highlight only the selected route's eligible
  next talent; do not change talent buttons or spend points.
- Show the actual packaged texture in the local preview, and distinguish browser
  appearance from unverified game rendering.

Enhancement: custom-drawn artwork only. Do not generate images or use the supplied
Totemic reference as an asset. The reference guides the feel of a complete
connected totem, broad carved wings, intimidating eyes and elemental orb swirls.
Current design includes a layered wood-grain trunk, engraved bands, animated
crown flames and staggered fire/wind/water/earth orbs with rotating spiral cores
and curved diagonal orbit wakes. The animation sits behind the talent button
to preserve its label and rank. Source: `Enhancement-Totemic-v4-custom`, generator
`tools/New-TotemicAnimation.ps1`, packaged as `Enhancement.tga`. Generated v3
artwork is archived and is no longer used in playback.

Elemental: begin with twelve simultaneous lightning strikes, using the existing
bolt artwork with four extra channels. The opening lasts 0.5 seconds at 12 fps,
then plays the unchanged Elemental loop from its first frame. Pack the opening
separately as `ElementalIntro.tga`; do not regenerate `Elemental.tga` for this change.

Restoration: no tubes or connecting trails. Keep the totems with floating water
orbs, gently rotating watery surface ripples, and separate leaking droplets.
Keep the cloud, falling rain and flowing water inside the icon.
Totems are 15% larger; orbs are 75% larger again relative to each totem, with
larger, brighter droplets for visibility at talent-icon size.
Current source: `Restoration-animation-v7`.

Holy Paladin: a huge golden column descends through the talent into a fallen
sword below the icon. Traveling light sheets, rising resurrection sparks,
large upward-sweeping golden wings and solar rays evoke the user's Herald of
the Sun reference. No shoulder armor. Three-second, 36-frame loop at 12 fps, packaged as
The larger gold-rimmed blue shield lies tilted on top of the fallen sword as one
overlapping pile immediately beside the bottom-left corner of the talent. Only the blade tip and handle stick out.
Keep the entire pile clear of the talent's spent-points number.
`HolyPaladin.tga`. Source: `HolyPaladin-animation-v7`, generated with
`tools/New-HolyPaladinAnimation.ps1`. Preview uses the packaged atlas; game
rendering remains unverified.

Retribution: Templar-inspired planted golden greatsword with a blue guard gem,
fractured ground lit from its cracks, descending holy shafts and spreading sparks.
A closed silver gauntlet fist, with folded knuckles and thumb across the palm,
matches the user's Silver Hand tabard reference above the talent. Keep the central
talent readable. Source: `Retribution-animation-v2`, generated by
`tools/New-RetributionAnimation.ps1`, packaged as `Retribution.tga` at 12 fps.

Protection Paladin: Lightsmith-inspired crowned helm and layered golden shoulder
armor fitted close against the icon, stacking downward rather than diagonally.
A large light sword on the left and broad bastion shield on the right sit lower,
close to the body. Give the shield a crowned top, reinforced ribs, thick glowing
rim and radiant cross to convey an imposing defender of the Light;
no hammers. A translucent shield of
light covers the icon, with ascending light chevrons and forging sparks. Keep
the bottom-right talent rank clear; the bastion shield is offset farther right
to leave the number visible. Source: `Protection-animation-v4`, generator
`tools/New-ProtectionAnimation.ps1`, atlas `ProtectionPaladin.tga`, 36 frames at
12 fps. Browser previews the packaged atlas; in-game rendering is unverified.
crown flames and four continuous fire/wind/water/earth orb systems with rotating
spiral cores, smaller orbiting satellites, wind curls, embers, droplets and rocks.
Enhancement renders at 3.4 times the highlight size with a downward offset so
the connected carved trunk is visible below the button. Source:
`Enhancement-Totemic-v6-custom`. Current generator and atlas remain the same.
