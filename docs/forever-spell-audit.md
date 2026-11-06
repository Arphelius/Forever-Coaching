# Forever class tuning maintenance

Reviewed **November 3, 2026**, client **1.60.1.70753**, against
[Blizzard's launch development notes](https://us.forums.blizzard.com/en/wow/t/2360696/9)
and the current [ForeverChanges spellbooks, talents and notes](https://foreverchanges.pro/patch-notes).
The notes announce launch changes that need not yet appear in the beta client's tooltips.
Officially announced behavior takes precedence over older client data. Numeric values
Blizzard has not published remain unknown; spell IDs are never guessed.

The bundled catalog covers **518 spells and 468 talents across all nine classes**.
Full talent rank effects, current positions, caps and prerequisites are imported from
the calculator pages; the old changes-only list missed unchanged talents.
New spells without IDs, including Shank and Death Mark, have descriptions and icons.
Live recommendations resolve their real IDs by name and require a positive learned-spell
check from the client. No ID is fabricated to make a preview look complete.

## What changed

- Warrior: current talent ranks and prerequisites, Fury additions, Slam timing and
  Defensive Stance threat. Reckless Swings is not an automatic health-spending filler.
- Paladin: current Holy, Protection and Retribution trees; Oath of Light, Boundless
  Light, Shieldsworn and Unsealed Wrath; Light's Vigil has friendly targeting only.
- Hunter: updated shots and buffs, Barrage and Lightning Reflexes; all traps share
  one 30-second cooldown. Survival's gearing explanation uses melee weapons.
- Rogue: Shank, passive Venom, Death Mark, current tree structure and renamed talents;
  removed Thousand Cuts/Cutthroat advice. Shank requires Energy headroom; Boot Knife
  is not forecast as guaranteed extra Combo Points.
- Priest: current effects and the shield, Shadow Word: Death, Vampiric Embrace and
  Devouring Contagion changes. No change to a rotation is inferred from a bug fix alone.
- Shaman: no Lava Burst in any active priority; Lightning Mastery and Totemic Call;
  current damage/cost/cast metadata, Riptide as periodic healing only and new talent ranks.
- Mage: current tree structure, Accelerant/Precision, Arcane Blast and Ice Barrier;
  Missile Barrage is consumed once at channel start in the forecast.
- Warlock: current Wrack, Shadow and Flame, Improved Drains and pet effects. Spellstone
  is Shadow-only; no Fire gearing benefit is inferred from the fixed bug.
- Druid: current Feral/Restoration structure, no Berserk, current bleed and weapon
  scaling, Wild Growth cast time, Bloom and the Cat/Bear destination talents.

All 91 allocations use current names, ranks, positions and legal prerequisite/point
orders. Where the original destination is no longer legal, a deterministic planning
adaptation preserves its spec and role using the explicitly reviewed priorities in
`docs/research/tuning-2026-11-03.json`. These are **adapted starting points, not fresh
published guides or optimal builds**. The UI labels them Updated Plan. Original source
URLs remain for attribution. Old DPS/threat board ranks expire for this tuning; a
suggested planning order is never called the author's published leveling route.

Saved custom builds resolve talents by name before using indices. Removed talents,
excess ranks or illegal new orders block selection and show a repair message. The
original saved record is preserved; Reset points permits creating an updated allocation.

Recorded damage samples carry the tuning revision and cannot influence current
recommendations after tuning changes. Historical reviews remain readable. Old SimGear
threat-per-cast weights are retained as research but excluded from current ranking;
the tank guide falls back to its conditional spell priority until matching simulations
are supplied with the current `tuningRevision`.

## Check future tuning

Run **Check-ForeverTuning.cmd**, or:

```powershell
powershell -NoProfile -File tools/Check-ForeverTuning.ps1
```

It downloads all nine spellbooks and talent trees, follows the latest official forum
link from the patch-notes page, and compares data fingerprints and official notes with
the committed reviewed baseline. It writes `.tmp/forever-tuning-check/tuning-report.md`,
a JSON report and a candidate catalog. It does not overwrite the addon or saved builds.
Exit 0 means no change, 2 means review required; download/parser failures are errors.
If Node is unavailable locally it can use VS Code's bundled Node runtime.

`.github/workflows/forever-tuning.yml` performs the same check daily and on demand
**after it is pushed to GitHub**. A changed source fails the check and preserves the
downloaded candidate/report as an artifact. GitHub notification delivery follows the
account's Actions settings. No gameplay code is automatically published.

## Apply a reviewed update

1. Read the official notes, including mechanical changes not visible in tooltips.
2. Preserve named allocations before importing new tree positions:
   `node tools/Export-ForeverBuilds.cjs .tmp/forever-tuning-check/allocations-before.json`.
3. Review the candidate manifest's build/date and create a dated review-rules JSON.
   The existing November 3 rules are an example, not approval for future automatic
   allocation choices. Obtain new published/simulated allocations where available.
4. Import facts with `node tools/Import-ForeverSpellCatalog.cjs .tmp/forever-tuning-check`.
   For explicitly reviewed planning adaptations, use
   `node tools/Adapt-ForeverBuilds.cjs .tmp/forever-tuning-check/allocations-before.json .tmp/forever-tuning-check docs/research/tuning-YYYY-MM-DD.json`.
5. Update live priorities, conditions, scenario actions, learning explanations,
   stat interactions and combat-review assumptions for the affected mechanics. Do not
   manufacture simulator rankings from tooltip multipliers. Replace new source
   allocations directly when supplied and validate them against the current trees.
6. Run `tests/TuningUpdate.Tests.cjs`, `tests/ForeverSpellAudit.Tests.cjs`,
   `tests/RotationRemoval.Tests.cjs`, `tests/ReadingPages.Tests.cjs` and
   `tests/ForeverSpellPreview.Tests.cjs` with Node. Update dated expected facts
   intentionally; investigate failures before accepting a new baseline.
7. Only after review and tests, run
   `node tools/Check-ForeverTuning.cjs .tmp/forever-tuning-check --accept-baseline`.
   Commit the reviewed code, manifest and baseline together. Run the appropriate
   install script to test in game. Test-client installation is separate from fetching data.

Raw HTML snapshots stay untracked locally; the GitHub check retains temporary artifacts
for 14 days. The old MythicSim importer is guarded because it rebuilds the historical
70425 layout; it must not silently undo the current class tuning.
