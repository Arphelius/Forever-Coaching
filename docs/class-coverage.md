# Shared class/spec audit

Run `node tests/RunClassCoverageTests.cjs` after changing shared rotation, buff,
recommendation or talent-effect code.

- All 27 specializations plus Bear: bundled spell IDs, learned-ability checks,
  healer separation, missing targets, idle previews and four-icon limits.
- All nine classes and three specs: missing/active/expired buffs, restricted aura
  enumeration, targeted queries, secret fields, alternatives and usability.
- Nine-class buff lifecycle: confirmed aura-instance removal during restricted
  combat, persistent reminders, reapplication, repeated expiration, unrelated
  unit/instance isolation, and recovery when direct aura reads become available.
- All nine classes and four activities: recommendations at levels 1, 10, 20,
  30, 40, 50 and 60, retaining provisional evidence labels.
- All 29 visual designs: animation at four icon sizes, static-border toggles,
  layer isolation, Enhancement exterior totem pieces and priest atlas identity.
- Profession items, emergency utility, racial prompts and existing live priorities.

These tests simulate client APIs and execute the addon Lua. They do not establish
optimal damage, every talent interaction, actual spell learning on live accounts,
or how effects look in the game renderer. Native protected-frame behavior, real
combat restrictions and visual alignment still need in-game validation.
