# Tournament submissions and additional guides

Retrieved 2026-10-22. There are now 80 catalog entries: the previous 41,
36 Forever Open finals submissions, and three additional Discipline guide
allocations. This includes the retained overview-only entry; it does not mean
80 distinct or proven optimal talent combinations.

## Primary tournament source

- [Raider.IO finals bracket](https://raider.io/events/the-forever-open/brackets/finals)
- Public page data: `https://raider.io/api/events/the-forever-open/brackets/finals`
- Each game's `syncRosterType=forever-talents` records its submitted roster
  in `syncRosterValue`: serialization version, entrant ID, class, talent code,
  and calculator revision. Entrant names/profile URLs are taken from bracket
  team objects, rather than inferred from news reports or character names.
- Raider.IO's public page script links those submissions to
  `https://warcraftforever.com/talents/{class}/{code}?v={revision}`.
  The calculator's own revision-specific definitions supply `tree.ordinal`
  and `talent.encodingIndex`; underscores separate the three tree codes.

[Collected records](forever-open-builds.json) preserve every attributed finals
submission found in the bracket: 36 entrants, four per class. Multiple match
occurrences of the same player's same revision/code are deduplicated, while
different players with identical allocations remain separate attributed entries.
Match IDs, seed, player, event date, stage, profile, original code/revision,
calculator URL and factual archived tree layouts are retained. No copyrighted
talent descriptions or website implementation code is bundled.

All 36 submissions have 26 points at level 30, requiring five points beyond the
normal 21-point level budget. The addon shows this requirement and does not
infer that the player has purchased the required Legacy perks. These entries
are observational duel examples, excluded from automatic best-build rankings.
No win rate, matchup advantage, tournament placement or battleground strength
is inferred from seed or talent submission alone. Qualifier submissions are
not part of this finals snapshot.

Build-specific archived layouts are used when drawing tournament trees, so a
current-layout reorder cannot change what a submitted digit means. The copy
button exposes the original calculator URL, including revision, rather than
pretending that an internal normalized code is a Blizzard import string.

## Additional Discipline coverage

[Graham Smith's guide](https://leprestore.com/guides/world-of-warcraft-forever/wow-forever-discipline-priest-guide-best-builds-race-professions/),
updated October 21, supplies a complete healing-first level-30 milestone and
explicit 33/18/0 PvE and 31/20/0 PvP level-60 allocations. Ranks are recorded in
[additional-guide-builds.json](additional-guide-builds.json). Level-60 variants
retain the author's provisional/theorycraft status. The level-30 build follows
the updated published leveling table, not the older allocation in search snippets.
The previously missing Discipline healer allocation is now filled by this source;
the Wowhead overview stays available as a separate source entry.

## Updating

Run `tools/Collect-ForeverOpenBuilds.ps1`, then
`tools/Import-MythicSimBuilds.ps1`. The latter now reads a pinned factual layout
cache, so rebuilding the catalog does not require repeated GitHub API calls.
`tools/Cache-BundledTalentLayouts.ps1` can recover that cache from an existing
bundled export of the same engine revision. Additional published guide builds
can be added through the additional-guide catalog without changing Lua by hand.

PvE/PvP library filters retain every original catalog entry. Activity selection
continues to distinguish general PvP from the level-30 duel context. This does
not fill the missing AoE, encounter-specific, gear-dependent or tank survival
comparisons described in the MythicSim source notes.
