# Warcraft Logs access and 100-parse comparisons

Warcraft Logs is the destination for uploaded reports, rankings and timeline
comparisons: https://forever.warcraftlogs.com/ . Forever Coaching provides easy
report access and displays supplied snapshots. It does not replace Warcraft Logs
with a local rotation coach or a second player application.

## Player flow

1. Record and upload with the logging tools supported by Warcraft Logs.
2. Paste the report link in Combat Review and click **Save report**. It is saved
   for this character independently of other characters' links.
3. Click **Your report**, press Ctrl+C, and paste the selected link in a browser.
   Compare the uploaded fight with matching 100-percentile parses on Warcraft
   Logs. **100-parse references** selects a supplied reference link when a
   qualifying snapshot exists; otherwise it selects the site and explains that
   a reference must be chosen there.

The normal page has no API-key setup, companion launcher, generated-code import,
spec fallback picker or local coaching controls. Player packages exclude the
companion application. Developer utilities remain in the repository.

Links are selectable; the addon does not open a browser, embed the site, upload
logs or fetch live website results. A saved URL is a bookmark, not a retrieved
review. Automatic fresh in-game results are not implemented by link access alone.
Existing supplied comparisons remain viewable and identify their encounter,
spec and fight ID.

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
- `node tests/WarcraftLogsAccess.Tests.cjs`: actual Lua review UI, removed setup
  controls and suppression of false local-analysis notices.
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
