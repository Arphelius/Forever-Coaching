# Role-specific combat guidance

The addon retains one short emergency warning at a time. The rotation engine,
icon strip, threat bar and action-button highlights have been removed.

Warnings require readable observations: critical health, actual aggro trouble
with an assigned group tank, critical assigned-healer mana, or an explicitly
dangerous encounter opportunity. Hidden values do not establish an emergency.
Critical self-health warnings give general advice to seek safety and healing;
they no longer select a defensive, healing spell or item through the rotation engine.

Tank warnings retain observed threat loss and can name a known taunt when far
behind. They no longer select a threat-building attack. Rising threat and another
tank holding the target remain informational states without emergency toasts.

Encounter rules require evidence, instance scope and exposed triggers. The
encounter-specific catalog is currently empty. There is no automatic boss-strategy
download or inferred safe positioning.

Warning transitions remain recorded as `role_warning` events in fight timelines.
Simulated checks: `tests/GroupThreatWarnings.Tests.cjs`,
`tests/WarningToast.Tests.cjs` and `tests/RotationRemoval.Tests.cjs`.
Actual client rendering and encounter behavior require live-game verification.
