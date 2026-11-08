# Forever-Coaching

Forever Coaching combines talent builds, class guides, combat recording and fight
reviews for World of Warcraft: Forever. The live rotation engine, icon strip,
swing prompts and `/fcrotation` settings have been removed.

Optimization shows **full combat rotations from the highest-output matching dungeon run**; personal
comparisons are paused. Select **Spec → Dungeon → Encounter** to follow the selected
class/spec winner's entire trash and boss sequences, with timing and repeat counts.
The collector scores available runs by dungeon DPS, healer HPS, or tank DPS;
it follows discovery pages and keeps each winning run coherent across encounters.
Player names and non-combat actions are hidden. Search limits and unavailable
reports are disclosed; this is not a verified ranking across every log on the service.
Optimization uses the same scrollable reading panel and highlighted cards as Learn
and Scenarios. The encounter picker separates **Trash mobs** and each named boss;
only the chosen section is displayed, with its complete sequence.
Fights are still being logged and combat is still being tested: these examples
are not guaranteed to be the best possible outcome. Use them at your discretion.
The catalog starts with a real cached Shadowfang Keep excerpt and expands as
supplied public reports are retrieved. Refresh the source reports for new data.

Optimization supports the **35 pre-raid dungeons/wings** in
[the dungeon roster](data/forever-dungeons.json). Missing report data is labeled
**awaiting reports for this spec**; supported scope is not presented as populated
coverage. Raids are excluded from the current public-report collector.
See [public report data and limitations](docs/warcraftlogs.md).

Class-guide references use **Wowhead Forever**, matched to the selected class,
specialization and role. Practical summaries are checked against current tuning;
see [the guide source review](docs/research/wowhead-guides.md).

**Gear → Professions** explains profession choices by class/spec and goal. Profession item references remain available; live consumable prompts have been removed. See [profession guidance](docs/professions.md).
**Talent Builds → Custom Builds** also supports importing and sharing current
Wowhead Forever talent links.

Class data is reviewed against the November 3 launch tuning. Run **Check-ForeverTuning.cmd** to check for newer spells, talents or official notes. A daily GitHub Actions check is included; current build adaptations are planning starting points, with old simulation rankings withheld. See [tuning maintenance](docs/forever-spell-audit.md).

Scenarios is restored to the original class/spec combat guides, with a situation picker and previous/next controls. Learn and Gear also retain their class/spec guides. These pages are independent of Optimization's public-report selections. Browsing does not activate a talent build. See [guide browsing](docs/guide-browsing.md).

Choose **Language** at the right of the dashboard's tab row for English (default), Romana (shown without diacritics, which the game font lacks), Español, Français, Deutsch or Português. `/fclanguage` opens the selector. Class, spell and talent names stay unchanged. The browser preview has a separate saved language selector.

**Talent Builds → Custom Builds** opens the built-in calculator. Left-click to add points, right-click to remove them, then save and choose **Use this build**. Your saved point order drives the existing talent-window highlight and specialization artwork when an in-game point is available. See [custom build instructions](docs/custom-builds.md).

In-game animation research preview: type `/fcpreview` to browse all current talent designs without leveling or spending points. Use `/fcpreview assassination` to open a specific design and `/fcpreview off` to close it. The preview supports 32, 48, and 64 pixel icons and uses the addon's actual animation renderer.

After each recorded fight, a reminder offers **Review fight** to see what went well and what needs improving. Dismiss it for that fight, or choose **Silence reminders** to save your preference. Recording continues while reminders are silenced. Toggle **Analysis reminders** in Combat Review, or use `/fcreminders on` and `/fcreminders off`. Reminders disappear after 20 seconds or when another fight starts.
