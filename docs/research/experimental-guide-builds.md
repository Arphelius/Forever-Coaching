# Experimental PvP, leveling and dungeon plans

Collected October 22, 2026. These are guide/template starting points for later
combat comparison, not Forever Logs results or a new measured ranking.

## Added templates

The [published template snapshot](published-build-templates.json) contains:

- Level 60 Survival Hunter PvP.
- Level 60 Subtlety Rogue PvP.
- Level 60 Affliction Warlock PvP.
- Level 40 Beast Mastery Hunter leveling.
- Level 40 Combat Rogue leveling.
- Level 40 Enhancement Shaman leveling.
- Level 40 Arms Warrior leveling.

Each entry links to its specific authored/published allocation at DamageMeters,
for example [Hunter PvP](https://damagemeters.com/forever/builds/hunter/60-pvp)
and [Rogue leveling](https://damagemeters.com/forever/builds/rogue/40-leveling).
The publisher calls these optimizer templates. The addon imports the talent
allocation only, not the site's gear set, rotation, rating or claimed advantages.
October 22 is the collection date, not an asserted author update date.

Each included allocation has the expected level budget, named talents in the
pinned layout, ranks within their maxima and sufficient earlier-row points.
These checks do not establish performance or replace a full current-client
prerequisite check. No undocumented spare points were allocated to fix a source.

The [source issue report](published-build-source-issues.json) records eleven
excluded pages, with incomplete point budgets or talents incompatible with our
snapshot. Their exclusion means that this update does not fill experimental
level-60 PvP coverage for all nine classes.

## Existing plans and labels

The published Discipline level-60 group PvP allocation is now explicitly labeled
Experimental, alongside the three new level-60 PvP templates. All are 51-point
destinations, separate from the 26-point level-30 tournament submissions.

The Discipline 33/18/0 PvE proposal now matches both dungeon and raid healing,
as its author explicitly discusses both. The existing Wowhead Holy Paladin
dungeon mana-recovery variant remains available, as do the level-30 healer
guide plans. Neither a raid DPS reference nor a raid tank reference is silently
reclassified as a dungeon winner.

Leveling templates are final level-40 allocations, not a verified step-by-step
route for a level-10 character. The UI now has a level-40 preview. Experimental
entries receive Experimental / Experimental fit badges and cannot receive the
Best reference or measured Recommended badges from these data alone.

## Future combat comparison

Catalog entries retain their stable ID, talent string, level, source and layout
snapshot. Non-simulation entries carry
`validationStatus="awaiting_combat_comparison"`; simulation references retain
`sim_reference`. This is a data status, not an implemented Forever Logs importer.
When access becomes available, comparisons must match actual talent ranks,
patch, level, role, encounter/activity, gear context and relevant outcome
(damage, useful healing, survival, etc.). PvP data availability must be confirmed
before promising tournament/matchup comparisons. No rankings were invented in
anticipation of API access.

Recollect with `tools/Collect-PublishedBuilds.ps1`; rebuild using
`tools/Import-MythicSimBuilds.ps1`. Existing source snapshots and tournament
provenance are preserved. The expanded catalog has 87 entries, including its
retained overview-only source entry and player-attributed duplicate allocations.
