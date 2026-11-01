# Compact talents and actionable reviews

The talent dashboard is now 900 × 650 (previously 1120 × 780), with a 36-pixel
header. The six existing navigation buttons are moved into a single row inside
the talent content panel. On other pages, those same buttons move back to the
original sidebar and the window returns to 760 × 500. Talent content retains
independent build-list and progression scrolling. Redundant titles and vertical
spacing were removed; the talent page uses a 0.94 content scale.

Combat review now presents three short sections:

- **What happened:** observed successful casts, failed/interrupted attempts and,
  when recorded, recommendation agreement counts.
- **Takeaway:** the existing situation-based short explanation.
- **Next fight:** one action based on the first recorded failure or recommendation.

An interrupted cast is not automatically blamed on the player. An unmatched
recommendation is not classified as a mistake. No damage, healing, deaths or
missed interrupts are inferred from missing events. Old saved reports remain
readable; new reports retain the comparison counts in addition to the percentage.

The local preview includes the compact layout and clickable feature navigation.
Combat Review provides labelled sample cases for range failures, interruptions,
no failed casts and no fight. These examples execute `CombatReview.lua`'s actual
formatter in an isolated Lua state with dummy frame registration. They are not
real combat data. Other feature pages remain explicit placeholders.

No WoW client is installed. In-game anchoring, font sizes and event behavior
remain unverified. No in-game files were deployed and no tests were run for
this change.
