# Primary guide reference: Wowhead Forever

Reviewed 2026-11-04. Wowhead's **Forever** class guides are the primary practical
reference for Learn, Scenarios, Gear, and the guide links in Talent Builds and
Resources. `Core/GuideSources.lua` resolves the selected allocation's primary
tree and role to the published overview. Its 28 overview destinations, including
separate Cat and Bear pages, are listed in Wowhead's public Forever calculator
guide index. Hybrids use their primary tree's guide as a reference, not as proof
that an author recommends their exact allocation.

Keep two kinds of provenance distinct:

- `guideReference` / `guideUrl`: practical reading on Wowhead.
- `sourceUrl` for spell/talent effects and `build.source`: the factual spell
  snapshot or original allocation publication/simulation. These are preserved.

The addon remains an offline summary. Reference links do not silently fetch or
execute web content in the game. Build evidence and simulator rankings must never
be relabeled simply because the default guide publisher changed.

## Reviewed practical changes

| Source | Published update shown | Applied summary |
| --- | --- | --- |
| [Combat Rogue rotation](https://www.wowhead.com/forever/guide/classes/rogue/combat/rotation-cooldowns-pve-dps) | October 30 | Keep Slice and Dice before spending spare points on Eviscerate. Preserve Energy for assigned utility. Launch Shank guidance remains a separate tuning addition. |
| [Fury Warrior rotation](https://www.wowhead.com/forever/guide/classes/warrior/fury/rotation-cooldowns-pve-dps) | October 29 | Keep Battle Shout; spend excess Rage on Heroic Strike without starving core attacks or utility. Area attacks still require permission. |
| [Fire Mage rotation](https://www.wowhead.com/forever/guide/classes/mage/fire/rotation-cooldowns-pve-dps) | October 31 | The practice checklist includes assigned Improved Scorch upkeep. Pyroblast's live proc rule requires three observed Heating Up stacks. Fire Blast is not restricted to movement. Scorch debuff assignment/stacks are practice guidance, not a fabricated live observation. |
| [Feral DPS rotation](https://www.wowhead.com/forever/guide/classes/druid/feral/rotation-cooldowns-pve-dps) | October 29 | Existing bleed uptime, Energy headroom and utility advice remains compatible; the removed Berserk recommendation is excluded. |
| [Destruction rotation](https://www.wowhead.com/forever/guide/classes/warlock/destruction/rotation-cooldowns-pve-dps) | November 3 | Keep conditions for Immolate and the actual Shadow and Flame rank; do not extend the guide's max-rank assumptions to every custom allocation. |

## Conflicts withheld

- [Elemental rotation](https://www.wowhead.com/forever/guide/classes/shaman/elemental/rotation-cooldowns-pve-dps)
  still refers to Lava Burst. The launch notes removed it; it cannot return to
  the spell catalog, live profile or scenarios because a guide still names it.
- The Feral guide's Berserk section predates its removal.
- [Retribution rotation](https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps)
  mixes old Twist of Light text with Unsealed Wrath. Keep the current talent
  effect and live state rather than importing the older seal behavior.

`Data/WowheadGuideNotes.lua` records these reviewed decisions. The remaining
overview links are reference destinations, not a claim that every paragraph or
allocation has been independently re-reviewed against that page. Current Blizzard
notes and readable client spell/talent behavior take precedence in a conflict.

When a tuning check flags changes, read the matching updated Forever guides,
compare recommendations with current effects and actual build ranks, revise the
short original summaries and record source/date/conflicts here. Retain live
checks for learning, resources, cooldowns, range, procs and assignments. Combat
Review must still use observed fight evidence; a guide recommendation alone
does not prove a mistake.

Validation: `tests/GuideSources.Tests.cjs`, `tests/RotationRemoval.Tests.cjs`,
`tests/ForeverSpellAudit.Tests.cjs`, `tests/ReadingPages.Tests.cjs` and
`tests/ForeverSpellPreview.Tests.cjs`.
