# To do

## Waiting on in-game checks
- **Red nameplate when a tank loses aggro** (Phase B, step 4 of the 2026-11-02 plan). Build it after these
  results come back from a dungeon, out of combat and in combat with a mob targeted:
  ```
  /dump C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit("target")
  /dump UnitDetailedThreatSituation("player","target")
  /dump issecretvalue and issecretvalue(UnitDetailedThreatSituation("player","target"))
  ```
  - The plan is an overlay of our own (a red border plus "!"), parented to UIParent and anchored over the enemy's
    plate. Blizzard's nameplate is never recoloured or reparented. The overlay clears on
    `NAME_PLATE_UNIT_REMOVED` or when you take the mob back.
  - If threat is a secret value in combat, the marker falls back to the current target only, judged by
    `UnitIsUnit("targettarget","player")`.

## To confirm in game
- Tab order, class icons in the dropdowns, the Talent Builds sizes (3-row progression, taller trees).
- Protection Paladin in a dungeon:
  - the threat bar;
  - the "Lost aggro on X — …" line;
  - the red border on Hand of Reckoning (far behind) or on the threat spell (close);
  - the yellow border while threat slips;
  - "Aggro back".
- Decide whether a close loss should also point at the taunt. At the moment it points at the threat spell and
  saves the taunt cooldown.

## Known
- Bear `Faerie Fire (Feral)` is filtered out by the spell catalog check, which only lists "Faerie Fire".
- Six test suites fail on main as well: EncounterSystems, GearAndRecorder, PreviewEncounterReplay (needs the local
  server on port 4317), RunCombatReviewTests, RunRoleWarningsTests, TalentLessons.

## Done on branch `ui-compact` (2026-11-01 – 2026-11-02)
- Merged the brother's update with the tank-coach work.
- UI revamp:
  - 820×540 window, text tabs in the header, flat buttons, dropdowns and joined choices;
  - the Language dropdown opens above the window;
  - Romanian is shown without the diacritics the font lacks;
  - every tab fits 804px.
- Tab order: Talent Builds, Learn, Combat Review, Scenarios, Gear, Resources.
- Class dropdowns show each class's icon and name (as SimGear).
- Talent Builds: bigger class icons, a compact 10-60 progression, taller trees.
- Tank guide:
  - calm threat lines;
  - a yellow or red border on the action button to press;
  - that spell beside a larger threat bar.
