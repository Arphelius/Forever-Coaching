# Role-specific combat guidance

The addon displays one short emergency warning at a time above the rotation. Routine opportunities remain rotation guidance. Persistent conditions do not repeatedly interrupt the player.

Warnings require combat and observed urgency: own or healing-target Health below 20%, actual aggro trouble with an available registered group tank, or an explicitly dangerous interrupt, dispel or validated encounter mechanic. Tanks may also receive a warning when an assigned healer falls below 5% Mana during combat. Ordinary interrupts, removable effects, moderate health loss, rising threat and preparation between pulls do not produce warning toasts. These thresholds are coaching policy.

## Tank threat

Forever shows threat to addons only for your target (and focus or group targets), so the tank coach reads your target only. For you and each group member it reads `UnitDetailedThreatSituation`, and gives one of these states:

| State | When | Advice | Threat bar |
|---|---|---|---|
| Held | You have it, nobody at 80% of the pull point | None | Green |
| Warning | You have it, someone at 80% or more | None; informational bar only | Yellow |
| Another tank | A group member assigned as tank has it | None | Blue |
| Lost, close | Someone else has it and you are at 70% or more | Do not taunt; use your next ready threat spell | Red |
| Lost, far | Someone else has it and you are below 70% | Taunt (Taunt, Growl; Hand of Reckoning only if the character knows it), otherwise your threat spell | Red |
| Unknown | Threat hidden or unreadable | None | Hidden |

"Your next ready threat spell" is the ready spell with the most threat per cast at your level, from SimGear Forever's MythicSim tank sims (`Data/TankThreat.lua`, generated: levels 30, 40, 50 and 60; between them the lower level's values are used). Area spells count only in area mode. Without data for your class or level it falls back to the first ready spell of your priority. 80% and 70% are coaching policy, not game rules. The bar sits under the rotation icons, filled to the closest other player's share (or yours after a loss). It never plays a sound and is only shown in combat.

Role comes from the assigned group role, or the actual current specialization when available. Healer detection for other group members requires their exposed assigned role; a Mana bar alone is not evidence that someone is the healer. Hidden or unreadable observations do not establish an emergency.

Encounter-specific movement, stop-DPS and positioning instructions use the validated rule path in `Core/RoleWarnings.lua`. Rules belong in `Data/EncounterWarnings.lua` and require a source, instance ID, real spell ID, trigger and explicit instruction. Known movement/stop rules suppress ordinary rotation icons while active. Unknown or restricted values do not trigger a rule. Generic role warnings work immediately; **the encounter-specific catalog is currently empty**. There are no invented spell IDs, universal ground-detection claims, inferred safe coordinates or automatically downloaded boss strategies. Exact stand-here guidance, ground hazards without an exposed trigger and comprehensive boss coverage still require verified encounter data and supported observations.

Warning transitions are recorded as `role_warning` events, visible in the native fight timeline and the browser's Coaching evidence filter after importing a fight. Automated checks: `tests/GroupThreatWarnings.Tests.cjs`, `tests/WarningToast.Tests.cjs`, `tests/EncounterSystems.Tests.cjs`, and `tests/RunLiveRotationTests.cjs`. Client rendering and actual encounter behavior still require game testing.
