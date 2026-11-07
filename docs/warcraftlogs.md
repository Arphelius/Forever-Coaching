# Warcraft Logs Forever combat reviews

Source: https://forever.warcraftlogs.com/ (separate from foreverlogs.gg).

## Simple player flow

1. Record and upload a run with your usual logging tools.
2. Double-click **Review-My-Run.cmd**. In a packaged addon this is in
   `Interface/AddOns/ForeverCoaching/Companion`.
3. Click **Sign in with Warcraft Logs** and sign in on the provider website.
4. Choose an uploaded run and your character. The helper remembers the character
   for that account and defaults to the last completed encounter involving them.
5. Click **Review my run and send to WoW**. Then type `/reload` in WoW and open
   Combat Review on that character.

Players do not create API keys, run commands, choose a numeric rules partition,
open generated files or paste review codes. The helper chooses the rules period,
retrieves independent reference players and runs the same peer-coaching engine.
The reference thresholds and evidence requirements are unchanged.

Sign-in is held in helper memory and refreshed while it runs. Restarting the
helper requires signing in again. **Disconnect** clears the session tokens.
If another group member uploaded the run, use **A group member uploaded the
run?** to open its shared report link. Personal report browsing is not a crawl
of every guild report on the site.

The launcher uses an available Node runtime, or downloads a portable Node 24
runtime from nodejs.org and verifies its published SHA-256 before first use.
It runs locally at `http://127.0.0.1:4318`. No Lua preview dependencies are needed.
The helper can display a review without a selected game installation. With an
updated addon selected, it writes only `Data/CompanionReviews.lua`; the game
imports the character-bound review after reload. It never edits SavedVariables
outside WoW or sends credentials to the addon. Consumed delivery receipts prevent
repeated reloads from importing an old review over a newer local fight.

Install the updated addon and restart WoW once so its new file list is loaded.
Subsequent companion deliveries need only `/reload`. **Advanced import** retains
the manual path for troubleshooting.

Uploading the original combat log is still separate. The helper analyzes uploaded
reports; it is not a replacement uploader. It sends coaching only when the
required matching peer sample exists, and explains missing coverage otherwise.

## One-time publisher setup

Before player sign-in can work, the project publisher must register a Warcraft
Logs OAuth app for the loopback redirect
`http://127.0.0.1:4318/callback`. Put its **public client ID** in
`tools/coaching-companion/config.json`, or set `WCL_CLIENT_ID` when launching the
helper during development. This is project setup, not a player requirement.
Never embed a client secret in this helper. Sign-in uses PKCE S256, a per-session
verifier and a single-use, expiring state. Provider tokens stay in memory and
queries use the user-authenticated endpoint. The consent request includes profile
and private-report scopes; live Forever scope/schema/redirect compatibility must
be verified with the registered app.

The repository ships with an empty client ID because no application registration
has been supplied. The UI states that sign-in is not yet enabled; it does not
present a fake successful connection. Automated provider tests are synthetic,
not live OAuth approval or validation of real player recommendations.

For automatic reference selection, the helper uses an exposed historical report
partition, or the API-provided default when it is the only available period and
the run is recent. If multiple periods exist and the report does not identify
its own period, the helper does not guess from recency.
Unknown historical tuning periods cannot silently use today's reference set.
Reference reports must resolve to the same period too.

Official authentication documentation:
https://www.warcraftlogs.com/api/docs

## Advanced/manual flow

The prominent Warcraft Logs section at the top of Combat Review provides
file-logging controls, the copyable companion address and **Advanced import**
for manual troubleshooting. There is no separate popup. The dashboard remains movable by dragging
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

The advanced command-line analysis tool requires Node 18+ and Warcraft Logs API credentials.
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
DPS/HPS comparisons are not tank execution grades. Reference players must be at
least 95th percentile by default; use `--min-percentile 100` for a narrower sample
or a threshold from 90 through 100. A percentile is checked through report
rankings, rather than assumed from a leaderboard position.

The collector checks every completed boss attempt involving this character in
the supplied report, including wipes; it does not crawl all reports on the site.
It follows event pagination up to 100 pages per fight and labels partial results.
It considers at most 20 leaderboard entries and retrieves up to five independent,
verified high-percentile players per fight. Duplicate appearances by one player
and the reviewed player are excluded. Incompatible reports do not fill the five
reference slots. API limits, unavailable reports and unrecognized
ranking response shapes reduce reference coverage rather than inventing it.

Output defaults to .local/warcraftlogs (ignored by git). Open a fight's .fcwcl.txt,
copy its contents and paste into Combat Review > Warcraft Logs > Import review.
The import contains observations and source links, not executable Lua or secrets.
It is bound to character name, realm, class and the current character GUID.
Previous/Next navigates up to 30 retained imports. Each import identifies its
report and fight; it is not automatically matched to the latest local fight.
Finishing a new local fight switches back to the local review to avoid showing a
stale external analysis. Imports persist through SavedVariables.

## Peer mentoring

Local capture and peer mentoring are separate states. The local page identifies
itself as a recording and explains that rotation quality has not been compared.
Client errors remain diagnostics; they are not presented as rotation coaching.
An imported peer review supplies strengths, differences to review, source players
and a concrete next-pull practice goal. It does not manufacture an optimal APL
from spell counts.

For compatible kills, the analysis checks:

- Ability frequency, grouped by recorded spell name so different rank IDs can
  describe the same ability. Low use becomes a spell-specific practice goal;
  near-reference use can be identified as a habit to keep.
- Opening order, when at least three independent peers share the same first
  three casts and that sequence occurs in at least 60% of the reference group.
  The player's own opening timestamps accompany the example.
- Observed self-buff and hostile-target debuff coverage, matched by spell and
  target name. At least three peers must apply the effect near the pull. Only
  intervals beginning with an observed application/refresh count; ambiguous
  removals are excluded, overlapping target intervals are merged, and target
  deaths end their aura intervals. Unobserved pre-pull auras are unknown.

Each finding explains the measured behavior, why the difference may matter,
what to practice and the evidence. Reference players, their actual recorded
specialization, percentile and report links are included. Exposed talent
snapshots are compared by recorded IDs/ranks and their coverage is reported.
Missing ranks or talent effects do not establish equivalent builds.

The reference group is scoped to the same class, recorded spec, boss, instance,
difficulty and game version, plus the actual fight `gameZone` ID (separate from
the site's ranking zone). Hard-mode/key levels and affixes must match when set.
It uses fights within 20% of the player's duration
and seven days of its date; known level/talent-snapshot differences and conflicting
requested partitions/metrics are excluded. Unexposed talent/level context remains
unknown rather than assumed to match. At least three independent qualifying players
are required. Partial streams, wipes and unknown specs cannot receive a rotation
comparison. Death-shortened player fights do not receive frequency/coverage
coaching; surviving reference players are required.

Dungeon bosses are supported through their encounter IDs. Trash packs, whole-run
route quality and server-wide spec popularity are not inferred from these boss
samples. This tool does not answer which spec is currently best in every dungeon.
That requires a separate representative dataset with instance, level and patch
coverage. Gear, tuning/hotfix equivalence, assignments, external buffs and phases
remain unverified, so observed differences are not automatically labeled mistakes.
An absent ability does not prove it was learned or ready; practice goals require
checking the player's actual toolkit and assignment.

## Other recorded outcomes

The review shows successful casts, interrupts/dispels, deaths and final incoming
hits, plus a bounded timestamped timeline of casts, auras and utility events.
A death is an outcome requiring investigation, not proof of player error.

Missing casts do not prove missed cooldowns, unused inventory items or unavailable
defensives. Timelines are not optimal APLs. Every comparison carries its reference
report links and coverage limits.

## Validation

node tests/WarcraftLogs.Tests.cjs checks synthetic API events, pagination, reference
filtering, report-wide attempt collection, import validation, logging and UI.
node tests/CoachingCompanion.Tests.cjs checks simulated PKCE sign-in, account run
browsing, automatic rules selection, full peer analysis, game-file delivery and
actual Lua consumption without a manual import. It also checks callback replay,
refresh/logout, wrong-character/combat/duplicate protection and local requests.
node tests/CoachingCompanionPage.Tests.cjs checks the normal browser flow.
node tests/PeerCoaching.Tests.cjs checks all nine supported classes with synthetic
rotation examples: habits to keep, opening differences, ability frequency,
aura coverage, practice goals, independent peers, and context/attribution limits.
node tests/RunClassCoverageTests.cjs checks shared functionality.
Live OAuth/schema compatibility, actual reports, rankings, uploads and in-game
behavior remain unverified until credentials, a real report and a game client
are available. No bundled review is represented as a real player fight.

API references:
- https://www.warcraftlogs.com/api/docs
- https://www.warcraftlogs.com/v2-api-docs/warcraft/report.doc.html
- https://www.warcraftlogs.com/v2-api-docs/warcraft/encounter.doc.html
- https://br.warcraftlogs.com/v2-api-docs/warcraft/reportfight.doc.html
- https://ru.warcraftlogs.com/v2-api-docs/warcraft/gamezone.doc.html
