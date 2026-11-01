# Shaman coaching evidence

Reviewed 2026-10-22. Scope: Forever beta Shaman, not retail Enhancement.
This is a research record, not proof that every situation is covered.

## Mechanics checked against primary sources

| Mechanic | Evidence | Coaching implication |
| --- | --- | --- |
| Stormstrike empowers the caster's next Lightning Bolt, Chain Lightning or Earth Shock by 20%; its cooldown is 8 seconds. | [Blizzard Shaman deep dive](https://worldofwarcraft.blizzard.com/en-us/news/24302097), [sim implementation](https://github.com/wowsims/forever/blob/master/sim/shaman/stormstrike.go) | Check the caster's debuff and melee range before recommending the setup. Do not apply its bonus to every spell. |
| Maelstrom Weapon's buff is 408505; the simulator applies cast-time and cost modifiers from ranked talent effects, 4% per point per stack. | [Simulator implementation](https://github.com/wowsims/forever/blob/master/sim/shaman/talents_enhancement.go) | Observe actual stacks. Do not deduct a cost modifier a second time after reading an effective engine cost. |
| Fire Nova erupts at the active fire totem. | [Blizzard Shaman deep dive](https://worldofwarcraft.blizzard.com/en-us/news/24302097) | Player-to-target distance alone cannot establish whether the totem will hit. |
| Rage of the Farseer increases attack speed by 30% for 25 seconds. | [Blizzard Shaman deep dive](https://worldofwarcraft.blizzard.com/en-us/news/24302097) | A melee cooldown, not direct spell damage. Actual fight duration matters. |

The simulator remains a model. Its Elemental Mastery implementation explicitly
notes an unverified charge-consumption question. Observe the player's real aura;
do not treat a simulated buff duration as an unconditional live guarantee.

## What the current score does and does not establish

The coach compares learned, usable attacks using readable range, cooldown,
resource and aura state. Damage comes from parsed client descriptions or recent
local damage-meter results, not Forever Logs. Explanations must call numerical
damage approximate. A higher score is a comparison among evaluated candidates,
not proof of a globally optimal rotation.

The 10% mana reserve and resource-pressure score are addon policy heuristics.
They are not values established by Blizzard, a simulator run, or log analysis.
The existing profile still needs swing timing, threat, survival,
immunity/resistance, target lifetime and totem-context work. It does not cover
every situation. Local damage samples are also not yet fully matched by gear,
target level, buffs and encounter conditions.

Basic movement gating now distinguishes hard casts from instant attacks and
observed instant Maelstrom casts. Offline Lua tests cover that distinction,
affordable alternatives, insufficient-power checks with hidden mana, zero-cost
casts, and effective-cost handling. These tests do not prove visual behavior or
cover every buff that might allow casting while moving.

When mana blocks damage spells, the coach can now offer the player's Attack
action in combat if an action-bar Attack range check or learned melee spell
confirms range. It also requires a readable active/inactive auto-attack state.
Active swings are displayed without a press glow, since pressing Attack again
can stop them. This is a resource fallback, not a weapon-DPS-versus-spell model.
It never starts attacks through addon code. Tests cover unknown/out-of-range
targets, active/unknown toggles, spell priority and the HUD glow lifecycle.
The read-only action checks mirror Blizzard's [action-button UI source](https://github.com/tekkub/wow-ui-source/blob/live/FrameXML/ActionButton.lua).

## Forever Logs: verified integration contract

The [published OpenAPI contract](https://foreverlogs.gg/api/public/v1/openapi.json)
was retrieved directly from the site's documented public API. Version: 1.0.0.

- Base: `https://foreverlogs.gg/api/public/v1`.
- Authentication: a profile-created key in `Authorization: Bearer ...` or
  `X-API-Key`; never put the key in a URL or addon Lua/SavedVariables.
- `stats:read` provides aggregate class/spec statistics and content metadata.
  Those aggregates do not identify the best next spell for a leveling character.
- Cast-by-cast events require `events:read`, granted by request to named projects.
  These endpoints are experimental and cover public, processed reports.
- Events are paginated. Their timestamps are encounter-relative milliseconds;
  event IDs and amounts are decimal strings. A missing/null flag is not false.
- The published event schema does not provide a player's live mana, gear,
  talents or level. The actor schema lists identity/type, not those conditions.
  Do not infer that a raid character's spell choice fits a level-2 character.
- Public presentation requires attribution linking back to Forever Logs. Bulk
  redistribution is prohibited. The helper below fetches one encounter for local
  analysis; it does not ship or publish a dataset.

No API key was available during this work. No authenticated encounters were
downloaded, and no Forever Logs calibration is active in the addon.

## Next evidence step

Use `tools/Get-ForeverLogsEncounter.ps1` with a locally configured
`FOREVERLOGS_API_KEY` and events access to collect a specific report/encounter.
The export records whether pagination finished. Incomplete exports must not be
treated as complete fights. The script is a local research helper, not an addon
importer or a live web connection.

After configuring the key in your local environment, fetch one chosen encounter:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/Get-ForeverLogsEncounter.ps1 -ReportId 123 -EncounterId 456
```

Replace the example IDs with an accessible report and its encounter. The command
sets execution policy for that process only. Offline helper checks:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/ForeverLogsHelper.Tests.ps1
```

Before changing priorities from a log, reconstruct casts, effects, targets and
melee outcomes together; obtain missing character/context information separately.
Compare alternative decisions in a reproducible model, then validate against
matching encounters. Spell popularity or a high parse alone does not establish
causation. Version any accepted rules by client build and retain source/report
references. Keep the game's live state responsible for the next recommendation.
