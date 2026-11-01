# October 23 build/recommendation audit

## Changes

- Refreshed all 33 reference builds linked from MythicSim's public race index,
  and their available tier-board positions. All use the pinned engine revision.
- Added eight complete authored Mobalytics default allocations: Beast Mastery,
  Combat, Protection Warrior, Frost Mage, Shadow Priest, Feral Druid,
  Retribution and Affliction. Enhancement's existing level-20 source remains.
  Exact factual rank maps are in `mobalytics-audit-builds.json`.
- The Feral source has a complete 51-point allocation. One immediately adjacent
  rank line initially escaped text extraction; Berserk was recovered from the
  source's actual chart, not allocated by guesswork.
- Hunter and Affliction default charts spend 26 points at level 30. Both retain
  the explicit five-extra-point requirement; the importer now records that
  requirement for guide entries as well as tournament entries.
- Named All builds menu exposes every complete source allocation for the chosen
  class, including each MythicSim alternative, without cycling blindly. Selecting
  an entry retains the player's choice independently of recommendation.
- Recommendation labels now include properly scoped tournament references.
  Completed opponent-versus-opponent finals series are counted from Raider.IO's
  bracket, excluding byes. Counts guide selection among observed submissions;
  they are not causal evidence that talents won those matches.

## Dungeon recommendation scope

Explicit dungeon guides take precedence. Where a class lacks an exact dungeon
allocation, a published damage leveling plan can be suggested as a **provisional
dungeon starting point**. That is this addon's editorial inference, not a claim
that the source measured it as the best dungeon build. The UI explicitly marks
these provisional recommendations. Raid DPS references are not used as dungeon
proof. Talent strengths are summarized from the corresponding authored guide.

## Evidence and coverage

`tools/Audit-BuildCoverage.cjs` loads the actual bundled Lua catalog and planner,
checks each catalog entry through GetPlan, and writes
[the source-coverage matrix](build-coverage-audit.md). The audit finds at least
one sourced or explicitly provisional pick for all **36 class/activity pairs**
at preview level 30. This is not coverage of all 108 spec/activity pairs, not
proof of 36 optimal builds, and not 36 builds usable at the player's current
level. Some are level-60 destinations; PvP entries are level-30 duel submissions.
Those scopes remain visible. The catalog has 86 entries including attributed
duplicates and an overview entry; 33 are MythicSim reference allocations.

Sources:

- [MythicSim reference board](https://mythicsim.com/wow-forever/tier-list):
  fixed raid setting, not leveling, AoE or PvP optimization.
- [Mobalytics class guides](https://mobalytics.gg/wow-forever/classes): individual
  guide URLs, source dates, exact point totals and short rationales are retained
  with every allocation. Source ranks were extracted from the actual default
  talent chart. Hidden variants are not inferred from their titles.
- [Raider.IO finals bracket](https://raider.io/events/the-forever-open/brackets/finals):
  attributed submissions and observed series outcomes. No seed-based performance
  ranking or extrapolation to battlegrounds/level 60.

Forever Logs integration remains pending. No source used here proves a universal
best build for every encounter, matchup, level and equipment set. In-game visuals
and combat behavior were not exercised by the data-coverage audit.
