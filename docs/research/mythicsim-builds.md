# MythicSim build snapshots

## Full catalog update, 2026-10-22

The catalog now includes all 33 reference presets linked from MythicSim's race
index, across all nine classes, plus eight healer/leveling source entries.
This replaces the three-entry snapshot described further below.

- [Collected reference metadata](mythicsim-catalog.json): exact codes, engine,
  generation time, scenario dimensions and optional public board position.
- [Healer source allocations](healer-catalog.json): four level-30 healer
  allocations, one level-30 Discipline damage allocation, a Discipline healer
  overview with no asserted allocation, and two proposed level-60 Holy Paladin
  variants. Zero-point overview entries are explicitly not complete builds.
- Collector: `tools/Collect-MythicSimCatalog.ps1`. Importer:
  `tools/Import-MythicSimBuilds.ps1`. All 33 baseline requests currently use
  the same pinned engine; the importer refuses a different engine until its
  matching layout is incorporated.

### Comparisons implemented

The page retains every entry when the activity changes. It can show reference
raid DPS ranks or reference tank threat ranks from MythicSim's tier-list cards,
and choose the highest listed reference within the selected class. These ranks
are from the tier list (including its trinket assumptions), not from comparing
race-board DPS values. Race-board requests supply the exact talent allocations.
Ranking links and baseline links are stored separately. Unranked Hunter variants
remain unranked. Tank threat is not a survival score.

Level 60 references are not recommended to lower-level characters. Level-30
guide matches are not extended into level-60 plans. A single matching guide can
be opened using Show suggested, explicitly as a guide option without a measured
winner. Players can preview their own level, 30, or 60. All activity descriptions
are kept to two lines in the UI.

### Source issues and unfinished evidence

- Mobalytics' [Discipline guide](https://mobalytics.gg/wow-forever/classes/discipline-priest-guide)
  explicitly says its current focus is damage leveling; the displayed 16/0/5
  allocation is therefore labeled damage, not healing. Wowhead's
  [Discipline overview](https://www.wowhead.com/forever/guide/classes/priest/discipline/overview-pve-healer)
  establishes the shield/Penance role but supplies no verified complete allocation
  in the retrieved overview. The catalog exposes this gap instead of inventing
  talent points.
- Mobalytics' [Restoration Shaman guide](https://mobalytics.gg/wow-forever/classes/restoration-shaman-guide)
  has inconsistent prose and chart. Its displayed chart spends points in Totemic
  Focus and Mana Tide, while the written order describes a different allocation.
  The chart is preserved and flagged; it is excluded from suggestions.
- [Holy Priest](https://mobalytics.gg/wow-forever/classes/holy-priest-guide),
  [Restoration Druid](https://mobalytics.gg/wow-forever/classes/restoration-druid-guide),
  and [Holy Paladin](https://mobalytics.gg/wow-forever/classes/holy-paladin-guide)
  allocations are the default level-30 charts retrieved on October 22, not an
  assumed level-60 variant hidden behind a website selector.
- The [Wowhead community Holy Paladin guide](https://www.wowhead.com/forever/guide/wow-forever-raid-dungeon-healer-holy-paladin-guide-35023)
  publishes 31/8/12 raid and 31/7/13 dungeon allocations. The author explicitly
  lists unresolved beta checks, so these are proposed variants rather than
  measured recommendations. October 7 is the author's reported observation
  date, not a claim that the current client was verified.

All five healing specializations can be browsed. A complete verified healer
allocation is still missing for Discipline. There is no measured healer ranking,
AoE winner, PvP comparison, tank survival ranking, gear-dependent optimization,
per-encounter comparison or level-by-level recommendation in this implementation.
The activities are selectable, but unsupported comparisons clearly say no
verified winner. Covering those requires matching datasets or simulation runs,
not extrapolation from a single-target DPS board.

The 33 references are not an exhaustive enumeration of every legal talent
combination or every player-made community build. MythicSim's community-build
page is a changing catalog; it was not included in this reference snapshot.

## Original three-entry snapshot

Checked 2026-10-22. The Talent Builds page now uses MythicSim reference presets,
replacing the previous third-party leveling routes.

| Preset | Distribution | Exact engine talent string |
| --- | --- | --- |
| [Enhancement](https://mythicsim.com/wow-forever/races?class=shaman&spec=enhancement-shaman) | 18/33/0 | `453003102-055030031005102251` |
| [Elemental](https://mythicsim.com/wow-forever/races?class=shaman&spec=elemental-shaman) | 31/7/13 | `5501331020011351-052-05305` |
| [Fury](https://mythicsim.com/wow-forever/races?class=warrior&spec=warrior) | 18/31/2 | `20305213002-05353005102010501-2` |

All three boards publish the baseline request, generated
2026-10-21T16:55:01Z, for client 70425 and engine
`a667dce8492bd9fb94269a9f864289cb74006775`.
Talent names, ordering and maximum ranks come from that exact engine's
[`ui/sim/talents/trees`](https://github.com/sage3648/mythicsim-forever-engine-go/tree/a667dce8492bd9fb94269a9f864289cb74006775/ui/sim/talents/trees)
data. The importer uses factual allocation fields only; it checks rank limits
and published per-tree totals before writing the catalog. No simulation code is bundled.

Scenario: level 60 character, level 63 raid boss, duration 120 seconds with
15 seconds variation, raid buffs/consumables, empty trinket slots. These are
fixed comparison presets, not evidence of an optimal solo leveling order,
personal gear optimization, PvP or healing performance. No DPS ranking is
inferred from their talent allocations.

The addon displays all final ranks even below level 60, explicitly as a reference.
It does not spend points or compare current player talents. Talent codes are
MythicSim engine strings, not promised Blizzard import strings. The source URL
is visible and copyable in-game. This is a bundled snapshot; updating requires
a new catalog, rather than an in-game HTTP request.

Regenerate the pinned catalog with `tools/Import-MythicSimBuilds.ps1`.
For a new snapshot, verify the baseline requests and update the pinned engine,
date, strings and tree totals together.
