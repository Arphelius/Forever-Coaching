# Leveling build routes

Historical research: the Talent Builds catalog now uses MythicSim presets.
See [the current source notes](mythicsim-builds.md). The routes below are no
longer shown by the addon.

Reviewed 2026-10-22. These are sourced guide routes, not measured DPS rankings.
The page previews planned ranks; it does not inspect or spend a player's talent
points. Extra Legacy points are outside the baseline route.

## Shaman, Enhancement, levels 10-30

Shared order: Thundering Strikes 5, Mental Dexterity 3, Improved Ghost Wolf 2,
Shamanistic Focus 1, Elemental Weapons 3, Ancestral Knowledge 1, Stormstrike 1.

- Mana sustain: Flurry 4, then Improved Stormstrike 1 at level 30. Source:
  [WoW4EverNews's published route](https://wow4evernews.com/en/articles/wow-forever-shaman-leveling-build),
  updated October 9, snapshot 1.60.1.70170.
- Attack speed: Flurry 5 through level 30. Source:
  [Talents Forever's published leveling order](https://talentsforever.com/shaman/builds/enhancement),
  counted October 18 after build 70425. That site's popularity figures measure
  plans, not performance; they are not treated as optimization evidence.

The final-point choice is a guide preference. Do not assert one universally wins.
Different pages disagree on full 1-60 routes and milestone timing. This catalog
does not combine those routes or invent a continuation above 30.

## Existing Warrior route

The pre-existing Fury guide entry remains browsable with its original
[source](https://wow4evernews.com/en/articles/wow-forever-warrior-leveling-build)
and update date. This change wires it into the UI; it does not constitute a
new simulation or current-client validation of that route.

## Checks

`BuildPlanner` checks baseline budgets, continuous level order, maximum ranks,
and supplied tiers/prerequisites. It does not independently reconstruct the
entire current client's talent tree. Offline Lua tests exercise all three
routes at levels 1-60, the Shaman milestones, unsupported classes, invalid
routes, and the UI's level/route/class navigation. Rendering and beta tree
compatibility still need confirmation inside the game.
