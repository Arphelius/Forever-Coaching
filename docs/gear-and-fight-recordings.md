# Gear guide and fight recordings

Select an allocation in Talent Builds, then open Gear. The guide explains equipment requirements, useful stats, and relevant selected talent effects. It supplies qualitative guidance, not personal numerical stat weights or guaranteed upgrade rankings.

The companion link opens https://www.curseforge.com/wow/addons/simgearforever in the browser preview; the in-game guide provides a copyable URL. Install SimGearForever separately and use its guide, item tooltips, and MythicSim workflow. Its item scores use stat weights; healer weights are labeled curated placeholders. No embedded companion integration is included.

In game, combat starts a bounded automatic recording of readable unit events and state changes. Combat Review → View fight timeline opens the latest timeline. Export fight produces JSON that can be pasted into the browser preview's Recorded fight import form. Imported recordings stay in that browser's memory.

The recorder keeps five recent fights, with at most 12,000 events per fight. Short precombat cast history is explicitly marked. Coverage includes observable casts, targets, health/resources, movement, auras, ability state, client errors and coaching observations. Missing or restricted information is flagged; health changes do not establish their source, an interrupt attempt does not prove an enemy cast was interrupted, and a cancelled cast does not automatically establish a mistake. Raw restricted combat-log details and video are not captured.

The browser's initial recording is a labeled simulated example. Real automatic recording runs inside WoW; the browser cannot access game memory.
