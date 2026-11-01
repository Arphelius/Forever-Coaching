# Combat Review and Forever Logs

## Encounter coaching expansion (2026-10-28)

The local review now retains separate summaries for every player in the selected
encounter, the selected player's ability totals and target IDs, and a ten-second
death timeline including incoming healing and other actions involving the player.
Evidence includes opaque event IDs and source/target IDs for attribution.
This uses every retrieved encounter event, rather than fetching only the selected
player. It does not search all reports in the database or grade other players.

The review also exposes ten decision areas: mechanics/movement, interrupts,
mana/recovery, cooldowns/burst, ability choices, range, targets/control,
buffs/dispels/cures, healing/defensives, and movement speed/preparation. Each
area lists the context needed to assess it and a next-pull practice prompt.
These prompts are not findings that the player made a mistake.

Scenarios and Learn in the browser preview now use the build selected in Talent
Builds, its role, source and talent allocation. They provide preparation,
response and self-assessed practice exercises. Talent explanations are displayed
only when supplied by the catalog; missing explanations are explicitly identified.
The preview selection is never silently treated as a logged player's actual build.
The in-game addon now loads `Data/AbilityLessons.lua`, `Core/EncounterCoach.lua`
and `UI/EncounterLearning.lua` from both supported TOCs. Learn lists curated
when/how/why lessons across all nine classes, filtered to learned ranks, plus
additional exposed spellbook abilities and their live client descriptions.
Scenarios tracks observed interrupt, healing, cleansing and resource opportunities
and targeted response counts by selected build. Uncurated interactions are labeled.

The live observer samples readable group health, debuffs, target casts, mana and
movement at four samples per second. It checks learned abilities, usability,
cooldowns and range before offering an action. Cast-SENT target identity is
matched to cast-SUCCEEDED; an ally's or wrong-target cast does not satisfy a
response. Friendly-target prompts are visible; action-button glows require the
observed target to be selected. Low mana preparation prompts also work between
pulls. The 20% mana and 35% health thresholds are addon policy, not sim results.

At combat start, the selected build and exposed actual talent ranks are captured.
The lesson page checks actual ranks against the selected allocation. At combat
end, opportunities, responses, cast/resource samples and movement transitions
are saved with the normal review. Movement is never assumed to be a mistake.
Reviews and imported findings now grow vertically instead of clipping to fixed
cards or truncating imported sections after two findings.

The helper accepts optional encounter context in the review's JSON field.
See `encounter-context.example.json` for the schema. IDs must match the report,
encounter and player. Rules specify real trigger-event IDs, target, response
spells and window, source URL, assignment and availability conditions. All ten
decision domains can be evaluated using this contract. A missing response is
only classified as a missed supplied assignment when the stream is complete and
the supplied availability covers the window. These assertions remain explicitly
labeled user-supplied, never independently verified mechanic facts. Missing
trigger evidence skips the rule; teammate responses never count as the player's.

Remaining work for the full coaching goal:

- Automatically join local character/build snapshots to external reports. Local
  fight snapshots and externally supplied identified snapshots exist, but are
  not yet synchronized automatically.
- Supply a verified encounter mechanic/assignment database. The rule evaluator
  exists; it does not manufacture this missing database from generic casts.
- Extend curated lessons to every class-specific interaction. Client spellbook
  descriptions and practice counts exist; they do not establish class mastery.
- Join comparable Forever Logs samples with matching MythicSim build, engine,
  targets, duration and movement assumptions. Existing catalog build links are
  references, not simulation evidence that an individual cast was wrong.
- Extend live observation to mechanic-specific positioning, pull planning,
  priority targets, food/buffs and cooldown decisions using verified rules.
- Add optional video attachment and timestamp alignment. No video retrieval or
  analysis is implemented, and an API key does not grant access to video footage.
- Extend gear analysis and SimGear integration after encounter coaching.

No new authenticated live API verification was performed for this expansion.
Offline tests validate attribution and presentation, not mechanic correctness.

New system validation: `tests/EncounterSystems.Tests.cjs` tests actual Lua
observation, targeted responses, hidden readiness, persisted practice, both
in-game lesson pages, the full combat-save-summary flow, and external decision
rules with wrong actors, absent triggers and partial streams. Existing combat,
HUD, review-page and Forever Logs integration suites also pass. The separate
legacy full build-planner suite currently fails on a reference-build talent-step
validation assumption; no build catalog/planner behavior was changed here.

The review has three sections: **What you did well**, **What went wrong**, and
**What to improve**. Findings explain the observation, why it matters, what to
check next, and the supporting encounter-relative timestamps.

## Connect and review a fight

1. Open `Preview-Addon.cmd` and select **Combat Review**.
2. Enter the full developer-issued API key in the local password field and click
   **Connect**. The key must have `events:read`. A `FOREVERLOGS_API_KEY` environment
   variable is also supported; click **Load recent reports** if it is configured.
3. Choose a public report, or enter a report ID. Select its encounter and player.
4. Click **Analyze this fight**. Data is fetched only on these explicit actions.
5. Expand **View event evidence** under a finding to inspect its timestamps,
   event types, spell IDs, and recorded amounts.

The key stays in the local helper process's memory. It is not stored in the
browser, generated addon files, URLs, or SavedVariables. **Disconnect** clears
it. Closing the local helper also ends the connection.

The browser's **Local demo** is clearly labeled simulated. It does not contain
the player's real events.

## View an imported review in WoW

WoW Lua cannot call the web API directly. After analyzing a fight, click
**Import this review into the addon**. This writes a key-free, attributed review
snapshot to `addons/ForeverCoaching/Data/ForeverLogsReview.lua` in the workspace.
Copy the updated addon into WoW and restart the game, then select
**Source: Forever Logs (imported)** on Combat Review. **Source: Local fight**
continues to show the addon's own observed fights. The imported review names the
selected player and encounter and is never silently presented as a live fight.

## Evidence and limits

The implementation follows the official
[Forever Logs public API contract](https://foreverlogs.gg/api/public/v1/openapi.json),
retrieved on 2026-10-27. Combat events are attributed to
[Forever Logs](https://foreverlogs.gg/).

- Read public processed reports, encounters, actors, and unfiltered event pages.
- Retrieve up to five pages of 50,000 events. Mark page-limited data as partial;
  do not infer inactivity from a partial stream.
- Keep event IDs opaque and amount strings exact using integer arithmetic.
- Isolate the selected player. Do not attribute other players' or pets' actions
  to that player without an explicit ownership relationship.
- Confirm contributions and setbacks that the stream actually records.
- A death is an outcome, not proof of fault. Cast gaps are review prompts, not
  automatically wasted time. Never claim an attack was avoidable from damage
  events alone.
- The API does not expose complete gear, talent, resource, cooldown, or mechanic
  context. It cannot by itself establish a full rotation grade or an optimal
  alternative for every cast.

Validation uses offline fixture events for pagination, exact amounts, actor
isolation, partial encounters, death-spanning gaps, local request checks,
credential-free exports, and the addon's source selection. Live authenticated
validation requires a key entered through the local connection form.

Run the checks with Node: `node tests/ForeverLogsReview.Tests.cjs` and
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/ForeverLogsHelper.Tests.ps1`.
