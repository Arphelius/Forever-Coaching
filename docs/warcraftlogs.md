# Warcraft Logs Optimization

## Overall and all scored logs

Optimization now has a fourth picker, **Log**, for every eligible scored player-run
in the collected reports. The default is the highest-output run for the selected
class/spec; other players' names remain hidden. The **Overall** encounter section
shows whole-dungeon damage and DPS over the entire elapsed run, including the time
between pulls. Trash and individual bosses retain their separate scopes.

The catalog carries all scored run summaries, rather than only the selected
winners. Winner streams already downloaded are reused to prepare compact damage
breakdowns for their other players, without extra API requests. If a selected run's
events have not been downloaded, its measured overall output remains available;
boss/trash views explicitly say their details are unavailable. Another player's
details are never substituted. Whole-run output comes from Warcraft Logs' player
totals where available; per-ability bars show recorded direct effects and can omit
pet attribution. Healer ranking uses HPS, while the Overall damage card uses the
separate damage total; missing damage totals are not inferred from healing.

## My Logs: import your own fights

**My Logs** is the personal comparison tab. Enable file logging before a dungeon,
then open the installed addon's `Helpers` folder and run `Import-MyLogs.cmd`.
The helper imports the most recently modified `WoWCombatLog*.txt` from that game's
`Logs` folder. It requires Node.js, but no API credentials, browser login or API
requests. Alternatively run `tools/Import-MyCombatLogs.ps1 -GameRoot GAME_FOLDER
-File COMBAT_LOG` to choose an older file. It supports standard and advanced
version-22 Forever combat logs, with completed/unfinished bosses kept separate and
trash combined within each recorded dungeon visit. New addon files require one
client restart after installation; later imports need only `/reload`.

The tab shows imports only for the current character's GUID. Choose a recorded
fight, the spec actually played, and your role. **Spec and role selections are user
declarations, not facts recovered from this raw log.** References match class, selected spec,
logged role, dungeon and boss/trash section. Only normal client dungeons are
currently supported. Warcraft Logs difficulty 10 is a general dungeon category,
not the client difficulty ID; the tab explicitly discloses that exact reference
difficulty cannot be verified. Heroic client runs are not substituted. The highest dungeon-output
run with a usable matching section supplies the example; unrelated encounters and
unfinished boss attempts are not substituted. Recorded direct damage, elapsed
encounter DPS and class casts per minute are compared. Effective personal healing
is also shown for healers, but encounter-specific reference healing is not yet in
the catalog. Pet damage, gear, talents, buff uptime, threat and mechanic decisions
are not graded. Frequency differences prompt review; they are not proven mistakes.

The private `Data/PersonalCombatLog.lua` contains at most 200 recent summaries from
the selected file. It replaces the previous local import. Packages always replace
it with an empty placeholder, even when a developer has imported personal fights.
Do not commit or distribute a populated personal file. The helper does not upload
anything to a website and does not execute saved log contents as code.

Recommend the [Archon App](https://www.archon.gg/download) for Warcraft Logs uploads
and live logging. Players must configure their game logging and the appropriate
Forever service in Archon. Archon uploads do not automatically update this addon;
the bundled local import helper is a separate step.

## Compact damage meters and class rotations

Optimization no longer displays timestamped boss cast-sequence cards. The raw
cast data remains available for My Logs comparisons. Damage belonging to another
class is marked `[Proc / other effect]` unless a more specific optional source is
known; this does not claim that a particular weapon caused the event.

Each encounter shows its complete damage breakdown in one meter with larger
single-line rows, abbreviated damage (`17.0k dmg`) and per-ability DPS. Boss DPS
uses that encounter's duration. Overall trash DPS uses the union of recorded trash
pull intervals, excluding boss time and time between pulls. Damage shares retain
automatic attacks and optional contributions so percentages still describe the
recorded total. Recognized racial and profession/item contributions carry bracket
labels. Racial and item actions are excluded from the class rotation; the UI
filters existing saved timelines without requiring an API refresh. The technical
run-description card and eight-ability damage-card splitting have been removed.

## Resume large public-report imports

Run the following in the terminal holding your Warcraft Logs credentials:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'D:\Forever coaching Addon\Forever-Coaching\tools\Update-PublicReports.ps1'
```

The launcher reads all saved HTML listings in `.local/optimization`, allows up to
1,000 discovered reports, and makes at most 100 new GraphQL requests per run.
OAuth requests are outside that budget, and API point limits can still interrupt
a batch before it uses all 100 requests. Use `-RequestBudget 25` for smaller runs.
Successful GraphQL responses, including individual event pages, are immediately
cached in `.local/warcraftlogs/api-cache`. Tokens, secrets and headers are never
cached. The cache is local and excluded from addon ZIPs and Git.

After **Request batch complete**, the PowerShell launcher continues automatically.
Use `-SingleBatch` to pause after one batch. The Node collector returns exit code
75 on a budget pause, 1 on a failure or rate limit, and 0 on successful delivery.
Cached responses do not consume the next batch's budget. After a rate limit, wait for the service's
limit to reset before retrying. The scan rebuilds its selection from cached data
and resumes network requests at the missing responses. Incomplete event streams
are not delivered. The existing addon catalog is preserved during batch pauses
and rate limits; only a completed collection writes a new catalog. Once it says
**Catalog saved**, use `/reload` in WoW.

Cache snapshots expire after seven days. To force a new snapshot earlier, rename
the `api-cache` folder while no collector is running. Different client identities
use separate cache keys. Previous scans made before caching was added cannot be
resumed from disk and must be fetched once by this version.

## Encounter picker and shared reading layout

Optimization now uses the same `ClassicTheme:Document` reading panel, wrapped
cards and scroll behavior as Learn and Scenarios. The toolbar has three selectors:
**Spec → Dungeon → Encounter**. The encounter menu lists **Trash mobs** and each
named boss from the selected winning run. Trash shows all its recorded pulls;
selecting a boss shows only that boss's full sequence and any recorded attempts.
Long sequences continue through additional cards without dropping later casts.
Names of source players remain hidden. The ongoing-testing/discretion notice is
retained above the selected encounter. Scenarios keeps its restored class guides.

Encounter selection is saved per character and reset when spec/dungeon changes
or a catalog refresh removes the selected boss. Stale content is hidden. If a
run has named bosses but no supplied trash boundaries, Trash mobs shows an explicit
unavailable state instead of invented casts.

The supplied report `ZT329XazM8GAphBf` is included alongside the two existing seed
reports for the next authenticated refresh. The user's example points to fight
1, source 5, phase 1; no boss name, phase timing or winning score is invented from
the URL alone. Its source-provided pull data is processed through the normal
candidate scoring and full-sequence extraction. Refresh with the existing
`Build-PublicReportCatalog.cjs` command to import it.

## Full rotations and highest-output run selection

Optimization now displays the **entire qualifying combat-cast sequence** from
the highest-output retrieved dungeon run for each class/spec and recorded role,
difficulty and game version. DPS and tanks use complete-run damage/second;
healers use healing/second. Threat remains unavailable. Rankings use the source
tables' total output divided by the whole dungeon duration, not cast frequency.
Gear/talent effects are not normalized, and this is not a universal best build.

The collector first inventories and scores the matching runs in all available
reports returned by instance discovery, then downloads the highest-scored run's
events. Lower-ranked event streams are fetched only if a higher-scored candidate
cannot be retrieved completely. Such failures make coverage explicitly incomplete.
All trash and boss sequences for a winner follow **that one run**; the addon does
not pick another player's spells for an encounter just because they cast more.
Separate encounter-only records are not ranked against full dungeon runs.

Each full sequence retains cast order and timestamps. Only consecutive identical
combat casts are compressed, with their exact count and first/last times. There
is no opener-length truncation. The UI continues in chunks of eight steps until
the end of each recorded pull, and shows all pulls in source order. Known
encounters without qualifying combat casts are identified rather than omitted
or filled with invented actions. Non-combat and automatic-attack filters remain.
Player names stay hidden; Scenarios remains the restored class/spec guide.

Discovery uses source-provided instance and ranking-zone IDs. It follows pages
without the former seven-day date filter, up to configured safety limits
(`--max-pages`, default 100 per scope; `--max-reports`, default 500 total).
Missing search access, repeated pages, API failures or limits are shown as
incomplete coverage. Only instances with actual source-provided API IDs can be
queried; names in the supported roster do not invent IDs. Exhausting the pages
the API exposes does not prove that all existing logs are publicly discoverable.
The UI reports examined reports and scored class/spec runs, not a global rank.

Refresh the public catalog once using `Build-PublicReportCatalog.cjs` to populate
full sequences and ranking metadata. Legacy opener-only records remain readable
as stored data but are not advertised as full winning rotations.

The following sections retain implementation history; this section defines the
current full-sequence and winner-selection behavior.

## Current presentation: encounter rotations; Scenarios restored

Scenarios once again uses the original class/spec situation guides and its
previous/next/direct situation controls. It does not use public reports, inherit
Optimization's filters, or show its cast history.

Optimization has just **Spec** and **Dungeon** selectors. Each dungeon appears
once, with no player-name or player-run options. It displays one compact
**Observed opener** and, where actually repeated, a **Repeated sequence** for
trash mobs and each named boss exposed by the report. Separate role examples
remain labeled where a spec was recorded in different roles. The view does not
show raw cast counts, every spell, player names, personal comparisons or automatic
mistake judgments. The ongoing testing/discretion notice remains on Optimization.

The collector requests Warcraft Logs `dungeonPulls` (name, encounter ID and
start/end times) and slices events by those source boundaries. Pulls marked
encounter ID zero are trash; named encounter pulls are bosses. Whole-dungeon
records without pull metadata are not mislabeled as a boss. Older catalog data
needs one refresh with `Build-PublicReportCatalog.cjs`; until then the view says
that encounter rotations are awaiting extraction. No boss/trash split is guessed.

Only actively cast combat abilities enter summaries: reviewed active class
spells or actions with attributed damage/heal/interrupt/dispel/debuff evidence.
Known racial combat buffs require an observed self-buff application. Automatic
melee/shoot attacks, travel/teleport, conjured food/water, mounts and unclassified
non-combat casts are excluded. Openers have at most six compact combat actions;
repeated patterns have two to four actions and must recur at least twice.
Repeated patterns/openers do not cross deaths or action gaps over fifteen
seconds. The source run is kept coherent for each encounter example, rather than
combining individual spells from different players into a made-up rotation.
These remain observed examples, not universal priority lists or a global ranking.

The older implementation notes below describe retained data/API history;
the current view follows this section.

## Current mode: public examples, comparisons paused

The supported pre-raid scope is the 35 dungeons/wings in
[`data/forever-dungeons.json`](../data/forever-dungeons.json). The addon loads the
matching generated `Data/SupportedDungeons.lua`; tests verify JS/Lua parity.
No Warcraft Logs instance/encounter IDs are invented from the names. Source IDs
remain the actual report metadata. Scarlet Monastery, Dire Maul, Stratholme and
Blackrock Spire wings remain separate. Generic parent names without an explicit
wing are not silently assigned to a wing. Common spelling/punctuation aliases
are resolved in both the collector and addon.

Optimization lists every supported dungeon for the selected spec. A dungeon without
supplied examples is selectable as **awaiting reports for this spec** and shows
no invented actions/output. Loaded coverage is counted separately from supported
scope. Choosing another spec retains the dungeon where possible. The public
collector skips raids and unsupported/ambiguous instance names before downloading
their combat events, with a coverage note. Raid support is deferred until a later
scope update after raids unlock.

Optimization uses `ForeverCoaching.PublicReportCatalog`; Scenarios uses its restored guides.
The normal pages do not read personal comparison rows, show a **You** column,
give mistake verdicts, or offer a next-fight comparison goal. Automatic companion
comparison ingestion is paused while this catalog is loaded. Legacy comparison
APIs and utilities below remain for future work, not the normal player flow.

Optimization always shows:

> Fights are still being logged and combat is still being tested. These public-report examples are not guaranteed to be the best possible outcome. Use them at your discretion.

The spec selector lists specs actually recorded in the catalog. The readable
current spec is also available as an explicit empty state if no example exists.
The encounter selector lists all supplied player/run examples for the selected
spec, across all recorded dungeons; it does not discard entries because they are
slower, have deaths, or lack a matching personal fight. Source-reported roles
remain visible; missing roles/output stay unknown. Unsuccessful and partial
segments are labeled. Spell counts from cached/truncated data are labeled as
excerpt counts, not extrapolated to full-fight cast rates. Scenarios shows the
same selected run's bounded spell sequence, self-applied buffs and explicit item
uses. These are observed actions, not an optimal APL or a ranking.

The initial bundled catalog contains a real cached Shadowfang Keep example
from `gFd1CVbHJqkKwfMN`; local refreshes can contain further retrieved entries.
No additional records are fabricated. To populate every
player/spec/dungeon segment from the two supplied public reports, run the new
developer collector in the authenticated terminal:

```powershell
node tools/Build-PublicReportCatalog.cjs --game-root "D:\World of Warcraft\_forever_"
```

Default sources are `bcVxQRyHF6qjXhLk` and `gFd1CVbHJqkKwfMN`.
`--reports CODE,CODE` supplies a different explicit public report list. No
character selection, percentile, personal comparison or public-search feature
is required. Each report segment's events are downloaded once and reused for
all its players. Missing output tables do not discard recorded spell examples.
The source `Data/PublicReportCatalog.lua` and optional installed copy are
updated; zero collected examples preserve the previous catalog. API failures
and metadata omissions are reported. Adding a new report later expands coverage;
no complete/live index of every report on Warcraft Logs is claimed.

This public-only module is intentionally included in releases. Personal review
files remain excluded. First installation adds a TOC entry and requires a game
restart; later catalog refreshes can use `/reload`.

## Retained comparison implementation (paused)

The Optimization tab replaces Combat Review. Choose **Spec** and
**Instance / encounter** to compare your actions with matching references,
followed by one **Next fight** practice goal. Scenarios shares this selection
and displays the selected reference's recorded actions and timings.

**Current data status:** the developer has successfully retrieved the supplied
Ruins of Lordaeron report through the live API. That report had no available
percentile references. The new observed-output collection, discovery and
role/output table queries still require a live test; their automated tests use
fixtures. No all-instance catalog, automatic player sync or global-best ranking
is claimed. Missing data stays empty rather than being replaced by fake rows.

## Observed references without percentiles

The new developer collector supports independent references without percentile
rankings. It selects the **highest observed matching output in the scanned
sample**, never a global best or a 100 parse. Roles come from Warcraft Logs
player details, not a spec-name guess: DPS uses damage/second, healers use
healing/second, and tanks use tank damage/second. Output comes from the source
tables' totals over the complete segment duration. Tank threat is unavailable
and is not inferred from damage, taunts or target changes. Healing output also
depends on incoming damage and assignments.

References match class, spec, logged role, encounter, instance, difficulty, game
version, known player level, dates within seven days and duration within 20%.
The reference must come from a complete event stream and completed kill.
Observed whole-run references can include deaths: the recorded death count is
displayed and sustained cast-frequency/aura-coverage coaching is withheld if
either player died. Opener examples require three recorded casts before the
first death in both runs. Whole-run output and recorded actions remain visible;
they are not converted into automatic mistakes. Percentile references retain
the separate surviving-player requirement. Self-references are excluded.
Gear and talent allocations do not filter observed references or appear in the
comparison; their effects on output still prevent a causal rotation verdict.
The old exact-100 path remains separately validated for when rankings exist.

```powershell
node tools/Optimize-WarcraftLogs.cjs --report bcVxQRyHF6qjXhLk --player "Argo Rax" --source 2
```

This follows public report-discovery pagination for each supplied game instance,
using the source report's ranking zone and a seven-day date window. Defaults are
five pages, fifty reports and thirty candidate player profiles per encounter.
`--max-pages`, `--max-reports` and `--max-profiles` permit bounded adjustments
(maximum ten pages, one hundred reports and one hundred profiles). Discovery is
cached for repeated instances; repeated pages stop instead of looping. Already
found reports remain usable if a later discovery page fails.
Coverage counts show discovery pages, report sample size, examined profiles and
the first failed matching condition for rejected segments/players. A zero-profile
scan is not presented as proof that no matching players exist. Limits and API
failures remain explicit. Additional public
report codes can be supplied with `--reference-reports CODE,CODE`; they remain
developer inputs, not player-page controls. No full-site crawler is claimed.
Events are cached per report segment. A report may represent a whole dungeon
segment; comparisons retain its supplied boundaries rather than inventing a
boss/trash split. Unknown/mismatched roles or absent output tables are withheld.

Results are saved under `.local/optimization`. Optional `--game-root PATH`
writes ready comparisons to the existing personal `Data/CompanionReviews.lua`
transport and a reference catalog. Use `/reload` after delivery. Only the
identified character receives personal **You** values; another character can
browse references. No-ready results do not overwrite existing delivered data.
Personal data is excluded from release packages. Credentials remain in the
developer process environment.

## Player flow

The review has only two controls: **Spec** and **Instance / encounter**. The spec
menu covers the 27 configured specs across nine supported classes. When readable,
the actual current spec is the default and is marked current. Choosing another
spec changes the review filter, not the player's talent build or live advice.

The encounter selector lists available matching source data. Saved selection is
kept per character; without a previous choice, the newest matching player fight
is preferred. Switching specs or encounters clears stale rows and advice. A
reference catalog can be browsed without a matching personal fight, but the
player column then says **No matching fight** and personal advice is withheld.

The three old report/reference/browser instruction cards are removed. So are the
report URL field, report-save/navigation buttons, logging buttons, import controls
and details button. The normal review does not ask players to configure API keys,
launch a helper, copy a link or paste a generated code. Player packages exclude
the companion application. Developer utilities remain in the repository.

The display consumes data supplied by the project integration. The addon itself
does not embed the website, upload logs or issue HTTP requests. A project-side
authorized data feed and coverage discovery are still required to provide fresh
comparisons across the instances Warcraft Logs has recorded. These are backend
requirements, not additional player buttons. Coverage is limited to supplied,
validated entries; the current UI does not claim a complete/live catalog.

Legacy paragraph-only snapshots cannot populate side-by-side values and are not
parsed into invented numbers. They remain readable through the legacy API for
existing integrations, but the normal review uses the structured comparison model.

## Structured comparison data

Scenarios shares the same saved spec and encounter selection. It displays one
qualifying reference player's actual spell sequence and fight-relative times,
explicitly identified item uses, and self-applied buffs. The source player is
identified as a 100-percentile reference. This is an observed run, not a universal
priority list. The player's existing comparison supplies the next-fight goal;
reference-only browsing does not invent a personal correction.

The optional `analysis.comparison.scenario` contains `sourceURL`, `duration`,
`casts`, `items`, `buffs`, and their total `castCount`, `itemCount`, `buffCount`.
Each action has `at` (seconds), `name`, and an exposed `spellID` and/or `itemID`.
The source must match a validated reference. The addon checks timestamps,
ordering, action identities and counts. Displays are bounded to the first 100
casts, 50 item uses and 50 self-applied buffs, with displayed/total counts.
Equipment alone does not prove item use, and unknown item details stay unknown.
Old comparisons without this data show a short unavailable message in Scenarios.
The authored class curriculum remains an internal fallback for integrations
without Warcraft Logs; normal Scenarios does not substitute it for missing data.

The external analysis result now includes `analysis.comparison` alongside legacy
text. It contains source/schema, class/spec, actual instance and encounter IDs,
difficulty, game version, identified report/player, independent 100-parse
reference players and typed findings. Each supported finding separates its
`comparison.action`, `you`, `reference` and `unit` (`casts/min`, `percent` or
`sequence`), with its evidence and conditional practice goal.

The existing developer transport can deliver this object with each review code.
On ingestion the addon validates the player/report identity, matching context,
exact-100 references, independent reference players, finite metric values and
supported units. It saves a normalized copy with the identified character.
Another character's personal values never appear under **You**.

A backend can also supply
`ForeverCoaching.WarcraftLogsCatalog={schema=1,source='Warcraft Logs',entries={...}}`
containing the same validated comparison objects. These provide reference-only
instance browsing until a matching player fight exists. A catalog replacement
invalidates cached rows. This contract does not implement a live server or an
all-report crawler by itself.

## Comparison rules

References must be **exactly 100 percentile**, verified through report rankings
by the external retrieval utility. The utility does not substitute 95, 99 or
99.99, or round a non-100 value upward. Old snapshots with lower-percentile or
insufficient reference labels are withheld from the 100-parse findings view.
The in-game addon cannot independently authenticate labels inside an import.

Compare separate runs of the same class, spec, encounter, actual game zone and
difficulty. Hard-mode/key levels and affixes must match. The utility also matches
game version/ranking zone, excludes known level/talent-snapshot differences,
restricts duration to within 20% and dates to within seven days, and requires
three independent qualifying players. The player's own parses and duplicate
players are not independent references.

A different dungeon can provide a general class example; it is not a direct
rotation-error benchmark for an unrelated encounter. Cast-frequency and opener
differences are observations to investigate, not proof of an incorrect spell.
Talents, availability, gear, assignments, external buffs, mechanic downtime and
tuning/hotfix changes can explain differences. Death-shortened fights are not
graded as low-frequency sustained rotations.

The documented Warcraft Logs API exposes reports, events and rankings. No
official structured mistake-verdict field has been identified in the inspected
schema. Findings produced by our comparison utility are therefore labeled
**imported comparison findings**, not official Warcraft Logs mistake judgments.

## Optional developer retrieval

This command is for integration/development, not the normal player workflow:

```powershell
node tools/Review-WarcraftLogs.cjs --report "REPORT_URL" --player "NAME" --source 2 --metric dps --partition auto
```

Configure authorized API access in the process environment (`WCL_CLIENT_ID` and
`WCL_CLIENT_SECRET`, or `WCL_ACCESS_TOKEN`). Credentials never enter addon Lua,
review codes or analysis exports. Client credentials access public reports;
user-authorized developer tools can access permitted reports through the user
endpoint. The previous OAuth companion is retained as a developer utility and
excluded from player packages.

Report links use `forever.warcraftlogs.com`; API requests use the documented
central `https://www.warcraftlogs.com/api/v2/client` (or `/user` for user OAuth).
Authentication and API HTTP failures are labeled separately. A route-level 404
does not by itself indicate bad credentials. Actual Forever report/schema support
still requires an authenticated live test.

Forever does not require players to supply a realm. The collector uses a unique
character name, optionally restricted by `--source` (the player source ID from
that report). `--realm` remains an optional metadata filter for integrations.
Source IDs apply only within a report. Ambiguous names are rejected.

The collector checks completed boss attempts for the selected player in the
supplied report; it does not crawl all reports. It considers up to 20 leaderboard
candidates and retrieves up to five independent compatible 100-percentile
references. Incompatible candidates do not fill reference slots. Partial streams,
wipes and unknown specs do not receive a rotation comparison. Automatic rules
selection requires exposed report metadata, or a sole available period for a
recent report; it does not guess between periods from recency. A developer can
supply a matching numeric partition explicitly.

Outputs default to `.local/warcraftlogs` (ignored by git). The historical
`FCWCL1` transport and character-bound importer remain for integrations. Codes
contain report/fight/character metadata, findings, links and coverage; they are
never evaluated as executable Lua. Supplied snapshots and delivery receipts
persist in SavedVariables. Distribution replaces personal data with placeholders.

The comparison utility can describe peer-aligned ability use, common three-cast
openers and observed aura coverage, with timestamps and conditional practice
goals. It does not establish an optimal APL or the best spec across all dungeons.
Unobserved pre-pull auras and ambiguous removals are excluded. Only attributed
player auras count; target deaths close intervals and overlaps are merged.

## Validation and limits

- `node tests/WarcraftLogs.Tests.cjs`: API fixtures, exact-100 filtering, per-character
  bookmarks, reference links, imported-data limits and logging controls.
- `node tests/WarcraftLogsAccess.Tests.cjs`: actual Lua review UI with exactly two
  controls, no instruction cards, all 27 specs/current-spec selection, real typed
  column values from fixtures, a next-fight goal, multi-instance filtering,
  catalog replacement, stale-row clearing and character isolation.
- `node tests/PeerCoaching.Tests.cjs`: all nine classes, attribution, independent
  peers, matching context and exact-100 observations.
- `node tests/RunClassCoverageTests.cjs`: shared class-wide checks.
- `tests/ReleasePackage.Tests.ps1`: package contents, personal-data placeholders
  and exclusion of the companion application.

These are simulated API/UI checks. Live Forever OAuth/schema compatibility,
real reports, rankings, uploads, the website comparison UI and in-game rendering
remain unverified. Synthetic examples are not real player reviews.

Primary API references:

- https://www.warcraftlogs.com/api/docs
- https://www.warcraftlogs.com/v2-api-docs/warcraft/report.doc.html
- https://www.warcraftlogs.com/v2-api-docs/warcraft/encounter.doc.html
- https://br.warcraftlogs.com/v2-api-docs/warcraft/reportfight.doc.html
- https://ru.warcraftlogs.com/v2-api-docs/warcraft/gamezone.doc.html
# Public dungeon discovery

The public catalog collector scans the zone-wide report listing for Forever zone
3000, as well as dungeon scopes learned from retrieved reports. This lets reports
from dungeons absent from the initial seed links enter the candidate pool. Only
supported, identifiable dungeons with usable completion, spec and output metadata
are included. Pagination and report limits still apply; this is not a verified
global ranking. Re-run `tools/Build-PublicReportCatalog.cjs` in the authenticated
terminal to refresh the installed catalog, then reload WoW.

