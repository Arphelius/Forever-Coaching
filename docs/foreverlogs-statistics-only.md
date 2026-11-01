# Forever Logs: statistics-only scope

Player search, individual parses and external fight-review integration are
deferred until release. The default Forever Logs view now uses only the
`stats:read` endpoints `/phases`, `/bosses` and `/statistics`.

Rankings compare class/spec aggregate average, median or maximum performance.
The visible page now has no phase, difficulty, encounter or metric controls.
It automatically chooses available current content across difficulties and
shows five ranking cards: overall damage, boss damage, trash damage, healing,
and tank damage. Each lists the top five specializations with class colors,
median output and fixed-size Previous/Next pages. Sample counts are available on each row.
Class/spec names come from the API rather than a hardcoded list. Trash damage
is a content category, not a controlled AoE simulation. Tank damage is not a
survivability score. Empty cards show a no-rankings message.

Aggregate responses are cached in memory for 30 minutes, per API guidance.
They use the configured local key without calling event/report endpoints to
verify it. No key is exposed to the browser. Player-search and external player
review actions return HTTP 410 with the deferred-scope explanation. Owner raw
report tools remain protected and are absent from the normal interface; the
existing local observer and simulated replay are unchanged.

Loading a statistics selection also writes a key-free aggregate snapshot to
`addons/ForeverCoaching/Data/ForeverLogsStatistics.lua`. Both addon TOCs load
it. The imported Forever Logs source shows class/spec medians, sample coverage
and comparison context rather than personal-mistake headings. Copy the updated
addon into WoW and restart the game to update that snapshot.

Live validation on 2026-10-29 confirmed the Beta phase was available and the
checked aggregate slice returned no samples. No ranking values are invented.
