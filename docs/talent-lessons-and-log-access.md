# Talent lessons and Forever Logs access

Talent slides now have three separate explanations: the effect at the selected
rank, its application to the selected build, and practical use around combat
conditions. One talent is shown at a time in the browser. In game, Learn has an
ability/talent toggle with Previous/Next navigation.

The effect importer (`tools/Import-TalentLessons.cjs`) reads all nine cached
class snapshots from the same pinned MythicSim engine as the build catalog.
It applies the engine's talent audits and retains observed, extrapolated and
classic-derived rank provenance. Newer/renamed talents missing from those
captures use attributed qualitative summaries of beta-client data or engine
implementation. Every allocated talent in the bundled catalog is covered;
unknown future talents retain an explicit missing-source fallback.

The importer also compares the formatted rank's numeric sequence with the
engine's beta confirmation table. Conflicting older numbers are withheld.
Effects are snapshot evidence; usage guidance is derived coaching, not proof
that a talent or rotation is globally optimal. Current client tooltips take
precedence. Personal simulation comparisons are not implemented here.

## Connect the key

Open Combat Review → Forever Logs → Owner tools. Paste an `events:read` API key into the
password field and press Connect. Enter it there rather than in chat or source
code. The local helper keeps the credential in memory; disconnecting or closing
the process clears it. It is not embedded in the addon or review exports.

Alternatively, launch the helper with `FOREVERLOGS_API_KEY` configured in its
environment for the player service. Unlocking owner tools still requires entering
that key explicitly; a configured environment key is not browser owner authentication.
The separate Check-ForeverLogs.cmd access checker does not configure or retain
the preview helper's key.

Reports can be paged with Previous reports / Next reports. Optional **Watch for
processed reports** refreshes the first report page every 60 seconds while the
logs panel remains mounted. It stops on a request error, page departure, or
disconnect. It does not overwrite the selected fight's review automatically.

The public API contract was retrieved on 2026-10-28 and cached as
`docs/research/foreverlogs-openapi.json`. Its report endpoint lists public,
fully processed reports. A key authorizes only its available scopes; it does
not provide direct game access, private/unrestricted database access, video,
or a live event stream. Live in-game prompts continue to use the local observer.

Authenticated production testing requires a key entered through this connection
flow. Offline tests cover configured-versus-verified state, rejected keys,
pagination and credential-free responses; replay tests exercise the running
server and the rendered talent slides. No live authenticated access is claimed.
