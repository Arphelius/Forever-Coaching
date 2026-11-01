# Local talent preview

Double-click **Preview-Addon.cmd** at the project root. It starts a local server
and opens `http://127.0.0.1:4317` in your browser. No beta client or API key is
required. The server listens only on this computer.

Choose a class, activity and build, then click **Learn highlighted talent**.
The preview defaults to level 60; the level control is hidden. You can also click
individual talent nodes to simulate a different allocation.

The server executes the actual `LevelingBuilds.lua`, `Level60Builds.lua` and
`BuildPlanner.lua` using Fengari. Every request reloads those files, so edits to
the catalog/planner appear on the next interaction. Browser code only handles
the simulated character and drawing. Character changes are temporary, and no
addon SavedVariables or installed game files are modified.

The display uses abbreviated talent names rather than client icons. It is a
layout approximation, not an emulator of WoW's frames. It includes a styled
addon window and smooth Canvas approximations of spec effects. Colors and spec
mapping are read from the actual Lua effect catalog; Canvas artwork and motion
are a separate browser renderer, not a pixel-identical WoW effect simulation.
Enable **Show effects without available points** to inspect the selected build's
theme without changing the simulated character's points. The next-point
selection follows the returned route and simulated ranks, with recorded row
spending gates; Blizzard prerequisite links and API behavior remain unverified.

## Runtime

The launcher automatically prepares a pinned Fengari runtime in
`tools/preview-runtime/node_modules`. First setup (or repairing missing files)
requires internet access. Package archives are checked against npm integrity
metadata, and no package lifecycle scripts run. Node/npm installation is not
required when VS Code is installed. Later launches reuse the checked local
runtime without downloading it again; clearing Windows temporary files does
not remove it. Setup diagnostics are saved in `.local/preview-runtime-setup.log`
and `.local/preview-runtime-setup-error.log`.

The launcher uses Node.js when installed, or the local VS Code executable's Node
runtime. Fengari is loaded from `tools/preview-runtime/node_modules/fengari`, or
the existing cached runtime in `%TEMP%/fc-lua-test-runtime/node_modules/fengari`.
If neither exists, install Node.js and run this from the project terminal:

```powershell
npm install --prefix tools/preview-runtime fengari@0.1.4
```

The launcher prints the background process ID and a `Stop-Process` command.
Closing the browser does not stop that process. Running the launcher again
reopens the existing preview. This is a development tool; don't ship it inside
the WoW addon folder.
# Encounter coaching replay

`Preview-Addon.cmd` now opens Scenarios directly. Open
`http://127.0.0.1:4317/?page=scenarios` or `/?page=learn` after launching it.
Each sidebar section now has its own content. Scenarios displays one practice
situation at a time; Learn displays one ability or talent at a time. Both have
Previous/Next buttons and a selector. Gear contains only its gear status.
The **Try the encounter observer** panel is available only in Combat Review,
under **Simulated replay**, with separate Timeline, What went well, Investigate,
and Next attempt views. **Forever Logs** is a separate source view.
The replay executes the actual `Core/EncounterCoach.lua` with synthetic
inputs, not just prewritten review text. Try correct-target responses, unanswered
prompts, wrong-target casts and hidden cooldown data. The timeline and review
update when you change the case. No API key or build selection is required.

The class selector changes the toolkit and lessons. The build selector on each
coaching page adds the selected allocation and reference. Simulated abilities
are enabled regardless of level; this replay verifies observer behavior rather
than spell acquisition or real encounter correctness. Actual game-client testing
is still required for in-game behavior.

The launcher checks the running service version and startup time before reusing
it, with a health-checked listener lookup when process metadata is unavailable.
Reload an already-open tab after updating. Assets are served without caching.

