# Forever Coaching

A compact class companion for World of Warcraft: Forever (1.60.1).

- Talent builds, a custom talent calculator, and Wowhead Forever link import/export.
- Class and specialization guides: abilities, scenarios, stat priorities, and professions.
- Optimization: recorded class rotations and compact damage meters from the highest-output dungeon runs in the supplied public catalog.
- My Logs: import your own local combat log, compare class ability usage, and get specific points to review for your next fight.
- Combat file-logging controls and optional quiet reminders.
- English, Romanian, Spanish, French, German, and Portuguese interface text. Class, spell, and talent names stay unchanged.

Extract the `ForeverCoaching` folder into `World of Warcraft/_forever_/Interface/AddOns/`, restart the game, and enable Forever Coaching in the AddOns list. Open the dashboard from its minimap button.

For personal comparisons, enable logging before your dungeon. After the run,
open `Interface/AddOns/ForeverCoaching/Helpers` and run `Import-MyLogs.cmd`, then
type `/reload`. The bundled helper requires Node.js and imports the latest local
combat log without API credentials. Choose your fight and the spec you played in
My Logs. Your personal log data is not included in release ZIPs.

We recommend [Archon](https://www.archon.gg/download) for uploads and live logging
to Warcraft Logs. Configure logging in the app; local addon imports are a separate
step. Archon is optional for local comparisons.

Fights are still being logged and combat is still being tested. The catalog is not
a verified ranking across every Warcraft Logs report. Spec selection must match
what you played; exact reference difficulty is not verified by the catalog's
general dungeon category. Gear, talents, level and group conditions affect results.
Comparisons are review prompts, not proof that a player made a mistake.

Live-client behavior still needs in-game validation. Client restrictions can limit combat recording. The addon never casts spells, uses items, or spends talent points automatically.

Class data was reviewed against November 3 launch tuning, build 1.60.1.70753. Adapted talent plans are planning starting points, not freshly simulated optimal builds. Wowhead provides practical guide references; conflicting advice is withheld in favor of reviewed tuning and readable client tooltips.

Source and issues: https://github.com/Arphelius/Forever-Coaching
