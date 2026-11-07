# Warcraft Logs side-by-side comparisons

Warcraft Logs supplies the report and reference data. Combat Review displays a
simple comparison: **Action | You | 100-parse players**, followed by one
**Next fight** practice goal. Rates and coverage use the reference median;
opening sequences use the observed common reference pattern.

**Current data status:** no live Warcraft Logs project connection is configured.
The UI and structured-data path are implemented and tested with synthetic data;
there is no claim that all logged instances or current rankings are being fetched.
Missing data produces one short status line. Synthetic rows are never bundled as
real reference data.

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
node tools/Review-WarcraftLogs.cjs --report "REPORT_URL" --player "NAME" --realm "REALM" --metric dps --partition auto
```

Configure authorized API access in the process environment (`WCL_CLIENT_ID` and
`WCL_CLIENT_SECRET`, or `WCL_ACCESS_TOKEN`). Credentials never enter addon Lua,
review codes or analysis exports. Client credentials access public reports;
user-authorized developer tools can access permitted reports through the user
endpoint. The previous OAuth companion is retained as a developer utility and
excluded from player packages.

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
