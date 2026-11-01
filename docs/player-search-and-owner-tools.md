# Player search and owner tools

The default Forever Logs page is now player-first: search by name, select a
matching fight, then see damage/healing per second, deaths, one positive finding
and one improvement. Progress lists up to five reviewed fights against the same
encounter during this helper session. Search results use encounter start times
where available. Names alone do not establish realm/class/build identity.

**More advanced statistics** is optional for players. It shows ability totals
and other players' performance in that fight. It does not expose raw events,
internal report/actor IDs, encounter-rule editing or addon imports.

**Owner tools** requires entering the configured API key. Successful verification
issues an ephemeral owner session; raw report actions require that session on
the server, including reports, actors, raw reviews, imports and disconnect.
Configuring a key in the helper environment does not grant owner access to a
browser. Leaving owner tools revokes the session while retaining the backend
key for player searches. Restarting the helper clears owner sessions. The key
and session are not stored in browser storage or generated addon files.

Owner-imported raw review snapshots remain local owner files. The packaging
script replaces that snapshot with an empty stub in distributable ZIPs, so an
owner review is not accidentally shipped to normal addon users.

The helper is local-only. This separates player and owner capabilities within
that helper; it is not a deployed shared service or an account/login system for
all addon users. A hosted backend with authenticated owner accounts would be
needed to serve other machines without distributing the key. Nothing here is
published or deployed.

## API boundaries checked 2026-10-29

The public contract has no player-directory or player-parse endpoint. Search
therefore scans processed public report rosters on demand, with at most twelve
encounter roster inspections and four reports per search page. Opaque
continuations resume within a report rather than skipping remaining encounters.
**Search older fights** continues the search; this is not an exhaustive indexed
search of the whole site. Search selections and reviewed progress are bounded
in helper memory and are not redistributed as a dataset.

No player parse percentile is fabricated. Same-fight damage position is labeled
as a comparison across all roles, without normalization for class, build, gear,
pet ownership or assignments. Partial streams do not show a damage position.
Rates are calculated with integer arithmetic to preserve exact event amounts.

Optional minute-by-minute checking finds newly processed fights for the current
query. It stops when leaving the player page or on errors. It does not stream
in-progress combat; live addon coaching still uses local observations.

The visible source attribution links to Forever Logs. Owner-only controls apply
to this addon/helper, not to independently public pages on the source website.

Validation covers name matching, pet exclusion, bounded search and continuation,
redacted summaries, comparisons, session progress, owner-token enforcement and
revocation, and the simplified rendered player page. Authenticated production
search still requires the owner's key.

## Search continuation fix

The browser continues through up to four pages per action (up to 48 rosters),
shows progress and retains **Search older fights** if more remain. Processed
rosters and report details are cached; report-list pages are cached for 60
seconds. Matching ignores spaces, punctuation and accents. It searches character
names recorded in fights, not account/profile display names.

Rate-limited responses preserve partial matches and the failed roster position.
The browser shows the upstream waiting period instead of implying the player
does not exist. The helper honors the cooldown before another upstream request.
Tests cover automatic continuation, cached repeats, normalized names and
resumption after throttling. Live authenticated testing confirmed a known
player from a real public roster could be found. A limited search without a
match does not establish that a player has no logs.
