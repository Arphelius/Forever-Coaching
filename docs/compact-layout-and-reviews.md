# Compact layout and actionable reviews

The dashboard follows SimGear Forever's panel layout (2026-11-02, second pass after in-game screenshots):

- **One window size**, 820 × 540, on every tab. It scales down when the screen is smaller.
- **One control vocabulary** (`UI/ClassicTheme.lua`): tabs are text with a gold underline on the
  open one; dropdowns are a dark field with the value and a small arrow; buttons are flat (20 px,
  dark fill, bronze border, gold on hover); joined choices such as Published / Custom and
  Dungeons / Leveling / Raids / PvP mark the selected one in gold. The red panel-button template
  is no longer used in the dashboard.
- **Header**, 56 px: icon, title and character on one line, then the tabs and the **Language**
  dropdown. Its list belongs to the dashboard and opens above it; `/fclanguage` opens it too.
  Romanian is shown without ă, â, î, ș, ț, which the game font lacks; the translation file keeps
  the proper spelling, and the menu names it "Romana".
- **One toolbar row per page** under a one-line heading: class and specialization dropdowns, then
  the page's own controls (`<` n / m `>` and the direct picker on Scenarios and Learn; Use this
  spec and Show details on Combat Review). When a row would leave the panel, the direct picker
  narrows and cuts its label with "...".
- **Talent Builds**: class icons, activity and VFX on one row; a 168 px column of compact spec
  rows (name, role, Recommended); the build's title, meta and status lines; three 186 px trees
  and the progression squares (11 per row) in one scroll area; level preview, Talent code and
  Mobalytics in the footer. **Custom Builds** uses the same columns: a class dropdown, name,
  role and points on one row, saved builds on the left, Delete apart from New / Reset / Save /
  Use this build.
- **Background kept**, `Media/ClassicTheme/ClassicBackdrop.tga`, behind translucent panels.

`tests/ReadingPages.Tests.cjs` checks the window size, fitted tabs, non-overlapping toolbars,
that nothing on Talent Builds runs past 804 px and that the Language list belongs to the
dashboard; `tests/Localization.Tests.cjs` checks that Romanian has no letters the font lacks.

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

In-game anchoring and font rendering are checked by eye in the client; the tests use mocked
frames and estimate text widths.

## Third pass (2026-11-02)
- Tab order: Talent Builds, Learn, Combat Review, Scenarios, Gear, Resources. The dashboard opens on Talent
  Builds; a finished fight still opens Combat Review.
- Class dropdowns show each class's icon and name in class colours (as SimGear's class menu); the field shows the
  chosen class's icon. Helper: `Theme:SetClassIcon(texture, token)`.
- Talent Builds: 34px class icons with a gold ring on the selected one; the 10-60 progression uses 28px squares
  on three rows; the trees are 392px tall.

## Tank guide
The rotation HUD, threat bar and spell highlights have been removed. Independent
role warnings retain observed threat loss and known taunts. See role-warnings.md.
