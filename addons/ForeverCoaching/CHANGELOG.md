# Changelog

## 0.1.4 — November 14, 2026

- Stopped reassigning Blizzard's shared command and Escape-frame tables during
  addon setup to reduce protected-action taint affecting actions such as raid
  target marking. Restart the game after installing to clear existing taint.

- Restored recommended starting points after removing partial builds, including
  Frost Mage, Shadow Priest and Affliction Warlock. When activity comparisons
  are unavailable, these are explicitly provisional level 60 plans.

- Removed all 49 builds that ended below level 60, including beta leveling and
  level 30 tournament entries. The bundled catalog now contains only complete
  level 60 builds.

- Fixed full level 60 builds being hidden by level 30 recommendations with the
  same specialization name, including Frost Mage, Affliction Warlock,
  Discipline Priest and Protection Warrior.
- Full level 60 destinations now remain visible across activities. Build cards
  show their level and point count so beta and endgame options are distinct.

- Added ten complete level 60 healer builds from Wowhead for Restoration Druid,
  Discipline Priest, Holy Priest, Restoration Shaman and Holy Paladin.
- All 27 talent trees now have a full 51-point level 60 build.
- Checked the new allocations against current talent ranks, tier requirements
  and prerequisites. Added regression coverage for every class and talent tree.
- Checked MythicSim's current spec index; it has no dedicated healing presets
  for the missing healer builds. No new healer simulation rankings are claimed.

Recommendation and class coverage checks pass. In-game validation is pending.
