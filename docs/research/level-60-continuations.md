# Level 60 continuations — 2026-10-23

Source: https://bytetavern.com/wow-forever-leveling-talents/

The author publishes a 10–60 order for nine classes, using client build 70374.
Levels 31–60 are explicitly an untested plan, not measured level-60 performance.
This is a new guide source, not a continuation attributed to Mobalytics or Raider.IO.

The supplemental `Data/Level60Builds.lua` records seven factual published
sequences (Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Druid). Before making
one available it checks talent names, rank caps, tree row spending and a total
of 51 points against the addon's recorded layout. An incompatible sequence is
withheld and its reason retained in `ForeverCoaching.LevelingRouteIssues`.
This checks recorded row/rank constraints; it is not client or prerequisite testing.

Two routes were deliberately not transcribed: Mage calls for Piercing Ice,
which is absent from the recorded layout, and five ranks of Elemental Precision,
whose recorded maximum is three. Warlock calls for Malediction, absent from the
recorded layout. Substituting similarly named talents would invent an allocation.

Only level-60 allocations now enter the talent UI's choices and recommendations.
The original level-30 sources remain archived in the generated catalog. No
tournament result is relabeled as level-60 evidence.

Each selected build has a Level 10–60 path button. Sourced routes show each
level/rank and client spell descriptions where available, with the guide's short
class rationale as fallback. Exact effect tooltips are accessible on hover.
Client descriptions may describe the spell's base rank, rather than the displayed
target talent rank. Existing final-only MythicSim allocations explicitly report
that their source does not supply a matching leveling order.

Final-only allocations now receive an explicitly labelled suggested planning
order from `BuildPlanner:GetTalentProgression`. It keeps every target rank,
prioritizes the tree containing the most allocated points, and fills lower rows
before higher rows while checking each tree's spending gate. It does not claim
to be the source author's order or an optimal leveling strategy. Prerequisite
links are absent from the bundled layout, so link legality still needs in-game
confirmation. Published orders remain separate and take precedence.

The inline UI displays one entry per baseline point. Partial beta allocations
end when their recorded points run out; no missing level-60 ranks are invented.
Extra Legacy points are not applied to the suggested baseline level labels.
