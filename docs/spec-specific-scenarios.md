# Specialization-specific scenarios

Scenarios now uses a shared Lua curriculum for all nine classes' three primary
talent specializations. Each profile describes its contribution, actions,
resources and utility. Eleven slides now cover ST, two-target cleave, AoE/group
healing pressure, PvP, kiting, healing/self-recovery, interrupts, burst, movement,
dispels/group utility and resource pressure. Each provides an entry condition
that explains when to leave the ordinary damage/healing priority.

Cleave retains a kill target while adding a safe second-target effect. AoE
uses the specialization's pack/group tools. PvP adds coordinated control before
the spec's named target sequence. Kiting gives named slows/control and an escape
route. Healing uses confirmed heals or conditional inventory-based self-recovery
for classes without an authored ally heal. An unavailable interrupt is explicit;
a slow, dispel or stun is not presented as a guaranteed boss interrupt. Pet
Spell Lock requires readable pet spell knowledge in the current-character view.
Each slide now uses authored conditional action checklists: a named spell,
the condition for using it, the target/action, the reason, and a specific mistake
to avoid. The older prose templates are not used for reactions. Instructions
distinguish self cooldowns, friendly targets and hostile targets.

Current-character steps require readable learned-spell confirmation. Passive
talent interactions such as Maelstrom Weapon also require the actual talent or
verified spell knowledge. Missing/unreadable actions are excluded and listed
explicitly rather than replaced with "an eligible spell". Browser walkthroughs
filter talent-dependent steps against the selected allocation and identify
their preview status; training, cooldown and range conditions still apply.

These are conditional walkthroughs, not live readiness prompts or mathematically
proven rotations. Survival and encounter assignments override the walkthrough.

In game, the current talent tree/readable active allocation takes precedence
over a browsed build. Detection can use primary-tree information, the active
talent snapshot, legacy talent-tab points or readable specialization information.
An unavailable or tied allocation is not silently replaced with the selected
plan. Group role and a verified matching allocation refine role-specific cases
such as Feral Bear and damage-oriented Discipline. Talent changes refresh an
open scenario page. Abilities described by a profile are possible toolkit tools;
only currently learned abilities should be used. Client restrictions can prevent
exact detection, in which case the page says so.

The browser cannot read a live character. Selecting a build produces an explicit
allocation preview with specialization-specific guidance and a collapsed list of
that allocation's sourced talent effects. No build means a selection prompt,
instead of generic class advice masquerading as current-spec guidance.

Sources for build/talent mechanics remain attached to the build and talent
lessons. Usage advice is derived coaching: it is not an authenticated assessment
of an encounter or proof that a specialization is best for that encounter.

Tests cover all 27 base profiles, different reactions between specs, actual
talent inference, active-spec precedence over a mismatched plan, unavailable
state, catalog previews, and one-slide-at-a-time rendering in game and browser.
