# Custom builds and talent calculator

Open **Talent Builds → Custom Builds**. Choose a class, enter a name and choose
the build's role. Left-click a talent to add a point; right-click to remove one.
The calculator enforces rank limits, five points per earlier tier, recorded
prerequisites and the 51-point level-60 budget. Removing a point is rejected if
it would invalidate a later choice. Partial builds are supported.

**Wowhead link** opens a small exchange window. **Import link** accepts current Wowhead Forever `v2` calculator links. Import
creates an editable draft; review its role, allocation and order, then save it.
**Wowhead link** copies a link for the current draft, including its point order.
In game, copy the URL to open it in a browser; the addon does not embed a website.
The local preview provides the same import and a link to open the calculator.

Wowhead's public Forever talent ordering was reviewed on **2026-11-04**. Talents
are mapped by name/tree/rank cap, so different column ordering cannot swap your
points. An encoded leveling order is preserved, including full-rank compression.
If the link has no order, a legal suggested order is generated and labeled as
such. Race, level and Talented options are preserved as link metadata; they do
not change the character's race, level or Legacy talents. Actual in-game point
availability still governs the existing highlight.

Classic/retail links, unsupported versions, incompatible ranks, invalid prerequisites
and inconsistent orders are rejected. Wowhead's current Warrior snapshot omits
Raging Blows; an allocation containing that talent cannot be exported until the
source discrepancy is resolved. No different talent is substituted. Older links
using a reused version stamp should be visually checked against their intended
allocation after tree changes.

`tools/Import-WowheadTalentLayouts.cjs` reads a saved response from
`https://nether.wowhead.com/forever/data/talents-classic`. It imports factual names,
ordering and rank caps without executing downloaded JavaScript or copying the
calculator's implementation. Review a changed link version before accepting it.

Your click order is the saved leveling order. **Save custom build** preserves
the experiment; **Use this build** explicitly selects it for the current
character's in-game guidance. Editing and saving an already active build updates
that plan. The calculator never calls the game's talent-purchase APIs.

When an unspent talent point is available, open the game's talent window. The
existing overlay highlights the next unlearned rank in the saved order, using
the dominant specialization's existing design and animation. Feral tank builds
use Bear artwork. The normal VFX switch also applies: disabled VFX uses the
static design. Locked talents, unavailable point counts and completed plans do
not produce a guessed highlight. Actual client rendering still needs in-game
verification.

Custom builds are stored in `ForeverCoachingDB.customTalentBuilds` and the active
selection in `activeTalentBuilds`, surviving reloads and logouts. Up to 50 builds
per class can be saved. Selecting another class is allowed for experimentation;
in-game guidance can only be activated for your character's class. Custom builds
are never promoted as sourced or ranked recommendations. Deletion requires a
second click and clears references to the deleted build.

The browser preview has the same subsection and uses the actual Lua calculator
for validation. It saves experiments to that browser's local storage. Browser
and in-game builds are separate; the browser cannot modify a running character.

The calculator uses the bundled talent layout and prerequisites from the pinned
Forever spell audit. It does not fetch or silently migrate trees during play.
If a saved plan becomes incompatible after a data update, guidance stops and
validation reports the incompatible allocation instead of spending or guessing.
