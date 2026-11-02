# Compact layout and actionable reviews

The dashboard follows SimGear Forever's panel layout (2026-11-02):

- **One window size**, 940 × 620, on every tab. It scales down when the screen is smaller.
- **Slim header**, 62 pixels: an icon, the title and the character on one line, then one row
  of tabs (Combat Review, Talent Builds, Scenarios, Learn, Gear, Resources), each as wide as
  its label, with **Language** at the right. The sidebar, slogan and motto are gone.
- **One toolbar row per page** under a one-line heading: class and specialization pickers
  first, then the page's own controls (Previous / n of m / Next and the direct picker; Use this
  spec and Show details on Combat Review). Buttons widen to their translated text; when a row
  would run past the panel, the direct picker gives up width and cuts its label with "...".
  A language change re-fits the tabs and rebuilds the open page.
- **Background kept**, `Media/ClassicTheme/ClassicBackdrop.tga`. The content panel is
  translucent (0.55) so the art shows; reading panels (0.82) and text groups keep darker
  strips behind the text. Secondary text is a warm light grey.
- **Talent Builds** runs at scale 1 (no 0.8 shrink) and starts with its recommendation line,
  since the tab names the page.

Sizes live in `UI/ClassicTheme.lua` (`Theme.METRICS`); `Theme:FitButton` and `Theme:Toolbar`
are shared by every page. `tests/ReadingPages.Tests.cjs` checks the window size, fitted tabs
and that toolbar controls never overlap or leave the panel.

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
