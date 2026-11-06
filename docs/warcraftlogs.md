# Warcraft Logs Forever combat reviews

Source: https://forever.warcraftlogs.com/ (separate from foreverlogs.gg).

The prominent Warcraft Logs section at the top of Combat Review provides
file-logging controls, a copyable website address and review import directly in
the page. There is no separate popup. The dashboard remains movable by dragging
its header. Scroll below this section to read fight findings. Start file logging
before combat. The addon attempts
to enable Advanced Combat Logging and confirms the logging state when possible.
This API behavior still requires verification in the actual Forever client.
Do not stop logging that another raid tool still needs.

WoW writes the log; this addon cannot read/upload that file or call the website.
Upload using a method currently supported by Warcraft Logs. This integration
does not require or launch Archon, and does not implement a browser uploader for
Warcraft Logs. Website upload availability is not verified here. An analyzed
website report must exist before detailed review can be imported. There is no
automatic website-to-addon connection or instant full-log postcombat analysis.

## Prepare a report review

The external analysis tool requires Node 18+ and Warcraft Logs API credentials.
Keep WCL_CLIENT_ID and WCL_CLIENT_SECRET (or WCL_ACCESS_TOKEN) in the process
environment. Never put credentials in addon Lua, import codes, screenshots or git.
Client-credentials access is for accessible public reports. This tool does not
implement the user authorization flow needed for private reports.

```powershell
node tools/Review-WarcraftLogs.cjs --report https://forever.warcraftlogs.com/reports/REPORT_CODE_HERE --player YourName --realm YourRealm --metric dps --partition PARTITION_ID
```

Use a real 16-character report code. Pick the leaderboard partition for the
fight's tuning period from Warcraft Logs. Omit --partition to collect factual
fight observations without benchmark discovery. Use hps for healing references;
DPS/HPS comparisons are not tank execution grades.

The collector checks every completed boss attempt involving this character in
the supplied report, including wipes; it does not crawl all reports on the site.
It follows event pagination up to 100 pages per fight and labels partial results.
It considers at most 20 leaderboard entries and retrieves up to five verified
100-percentile examples per fight. API limits, unavailable reports and unrecognized
ranking response shapes reduce reference coverage rather than inventing it.

Output defaults to .local/warcraftlogs (ignored by git). Open a fight's .fcwcl.txt,
copy its contents and paste into Combat Review > Warcraft Logs > Import review.
The import contains observations and source links, not executable Lua or secrets.
It is bound to character name, realm, class and the current character GUID.
Previous/Next navigates up to 30 retained imports. Each import identifies its
report and fight; it is not automatically matched to the latest local fight.
Finishing a new local fight switches back to the local review to avoid showing a
stale external analysis. Imports persist through SavedVariables.

## What the review can establish

The review shows successful casts, interrupts/dispels, deaths and final incoming
hits, plus a bounded timestamped timeline of casts, auras and utility events.
A death is an outcome requiring investigation, not proof of player error.

Cast-rate comparisons require a complete target kill and at least three complete,
verified historical 100-percentile parses with matching boss, difficulty, class, specialization,
game version and ranking zone. Durations must be within 20%, and references within
seven days. A lower cast rate becomes a question to investigate, not a verdict.
Gear, talents, patch/hotfix equivalence, assignments, external buffs and phases
are not independently matched. Missing casts do not prove missed cooldowns,
unused inventory items or unavailable defensives. Timelines are not optimal APLs.
Every comparison carries its reference report links and coverage limits.

## Validation

node tests/WarcraftLogs.Tests.cjs checks synthetic API events, pagination, reference
filtering, report-wide attempt collection, import validation, logging and UI.
node tests/RunClassCoverageTests.cjs checks shared functionality.
Live OAuth/schema compatibility, actual reports, rankings, uploads and in-game
behavior remain unverified until credentials, a real report and a game client
are available. No bundled review is represented as a real player fight.

API references:
- https://www.warcraftlogs.com/api/docs
- https://www.warcraftlogs.com/v2-api-docs/warcraft/report.doc.html
- https://www.warcraftlogs.com/v2-api-docs/warcraft/encounter.doc.html
