# Forever-Coaching

Forever Coaching combines talent builds, class guides, combat recording and fight
reviews for World of Warcraft: Forever. The live rotation engine, icon strip,
swing prompts and `/fcrotation` settings have been removed.

Combat Review and fight timelines remain available. They report accessible local
observations. Combat Review > Warcraft Logs adds file-logging controls and imports
of externally analyzed Forever Warcraft Logs fights, with timestamped evidence
and conservative comparisons against verified 100-percentile references.
See [Warcraft Logs setup and limitations](docs/warcraftlogs.md). Upload and analysis
are external steps; the addon does not automatically fetch website results.

Class-guide references use **Wowhead Forever**, matched to the selected class,
specialization and role. Practical summaries are checked against current tuning;
see [the guide source review](docs/research/wowhead-guides.md).

**Gear → Professions** explains profession choices by class/spec and goal. Profession item references remain available; live consumable prompts have been removed. See [profession guidance](docs/professions.md).
**Talent Builds → Custom Builds** also supports importing and sharing current
Wowhead Forever talent links.

Class data is reviewed against the November 3 launch tuning. Run **Check-ForeverTuning.cmd** to check for newer spells, talents or official notes. A daily GitHub Actions check is included; current build adaptations are planning starting points, with old simulation rankings withheld. See [tuning maintenance](docs/forever-spell-audit.md).

Scenarios, Learn and Gear include class/spec menus for browsing guides. Scenarios and Learn also offer a direct scenario/lesson picker. Browsing does not activate a talent build. Combat Review defaults to a short summary; **Show details** reveals the complete findings. See [guide browsing](docs/guide-browsing.md).

Choose **Language** at the right of the dashboard's tab row for English (default), Romana (shown without diacritics, which the game font lacks), Español, Français, Deutsch or Português. `/fclanguage` opens the selector. Class, spell and talent names stay unchanged. The browser preview has a separate saved language selector.

**Talent Builds → Custom Builds** opens the built-in calculator. Left-click to add points, right-click to remove them, then save and choose **Use this build**. Your saved point order drives the existing talent-window highlight and specialization artwork when an in-game point is available. See [custom build instructions](docs/custom-builds.md).

In-game animation research preview: type `/fcpreview` to browse all current talent designs without leveling or spending points. Use `/fcpreview assassination` to open a specific design and `/fcpreview off` to close it. The preview supports 32, 48, and 64 pixel icons and uses the addon's actual animation renderer.

After each recorded fight, a reminder offers **Review fight** to see what went well and what needs improving. Dismiss it for that fight, or choose **Silence reminders** to save your preference. Recording continues while reminders are silenced. Toggle **Analysis reminders** in Combat Review, or use `/fcreminders on` and `/fcreminders off`. Reminders disappear after 20 seconds or when another fight starts.
