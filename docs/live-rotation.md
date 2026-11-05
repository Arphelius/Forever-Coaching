# Live rotation HUD

The HUD stays visible above the action bars at 12% brightness outside combat and full brightness during fights, even without an enemy selected. Its idle icons are a preview, not a command to attack. It has exactly four slots: a current recommendation, then up to three dimmer conditional follow-ups. Uncertain slots stay empty. Repeated filler casts may repeat the same icon. A successful player cast matching the current recommendation produces a fading completed icon; failed casts, other players and unrelated spells do not complete it. Each refresh evaluates current conditions again, rather than blindly advancing a fixed sequence.

Enhancement Shaman opens with a learned, ready Lightning Bolt while stationary and outside melee range, then switches to weapon swings and instant abilities as the enemy closes. AUTO icons remain visible as follow-ups when melee-range data is unavailable. Main-hand and off-hand countdowns use Blizzard's native `PLAYER_SWING` events, and the corresponding icon pulses on each observed swing. Timers expire rather than inventing additional swings. An already running autoattack is not an instruction to press Attack repeatedly.

Type `/fcrotation` to open controls. Single target avoids optional area attacks. Spells placed on the ground (Blizzard, Flamestrike, Rain of Fire, Hurricane) and self-centred area spells (Arcane Explosion, Consecration, Thunder Clap, Whirlwind, Fan of Knives) have no range the game reports, so in area mode they are offered without a range check: you place them. Enable area damage only when surrounding enemies may safely be hit, and return to single target around controlled enemies. The addon cannot establish safe enemy grouping or every encounter assignment from nameplates. Use burst for the agreed cooldown window, or hold it for a later pull; burst resets after combat. Shaman still requires observed nearby targets before comparing Chain Lightning damage.

Optional items are explicitly configured by item ID and intended effect. Health items trigger below 30% Health; Mana items below 20% Mana; burst items require the enabled burst window. The engine checks ownership/equipment, usable state, use spell and cooldown, including shared item cooldowns. Equipped profession items, trinkets and consumables can use this path when those APIs expose them. Assign an item only to an effect it actually supplies; there is no universal automatic tooltip parser or item-effect simulator. The addon only recommends actions and never casts or uses an item for you.

Item assignments are tied to the current specialization and readable allocation. Switching to another spec or changing readable talent ranks suppresses those assignments until configured for that allocation.

Commands also work directly:

```
/fcrotation single
/fcrotation aoe
/fcrotation burst on
/fcrotation burst off
/fcrotation item ITEM_ID health
/fcrotation item ITEM_ID mana
/fcrotation item ITEM_ID burst
/fcrotation item ITEM_ID off
```

Live recommendations use the actual current specialization and readable learned abilities/talents. A build selected for browsing is not substituted for an unavailable live allocation. Legacy talent scans and modern talent snapshots invalidate on changes. Urgent observed interrupt, healing and dispel prompts take priority over optional damage and items; they still require the player's assignment and mechanic judgment.

Shaman retains the existing tooltip/observed-damage comparison and talent/proc interactions, now with resource-spending forecasts. Other supported classes have conservative named baseline priorities, derived from the curated scenario checklists. They check readiness, range, movement, relevant owned DoTs, execute health and combo points. Forecasts spend readable resources, avoid repeated cooldown uses and do not invent future proc or combo-point gains. They do not model future target death, every talent interaction, regeneration, cooldown recovery or every encounter. Healing follows observed needs rather than inventing four future injuries.

## Tank priorities

Protection Paladin, Protection Warrior and Bear follow MythicSim's Forever tank APLs ([mythicsim-forever-engine-go](https://github.com/sage3648/mythicsim-forever-engine-go), MIT; the same engine behind SimGear Forever), translated to spell names so whatever rank the character knows is used and unlearned spells drop out (a level 20 tank gets a shorter list, never an invented one).

| Tank | Single target | Area (`/fcrotation aoe`) |
|---|---|---|
| Protection Paladin | Lay on Hands below 10% Health; Righteous Fury if missing; Judgement while Seal of Righteousness is on; Seal of Righteousness (refreshed at 1 s); Holy Shield if missing; Hammer of Wrath below 20%; Holy Strike | Hammer of the Righteous, Consecration |
| Protection Warrior | Defensive Stance if outside it; Shield Slam; Revenge; Battle Shout if missing; Sunder Armor to 5 stacks; Heroic Strike at 45+ Rage; Sunder Armor | Thunder Clap, Cleave at 45+ Rage |
| Bear | Faerie Fire (Feral) and Demoralizing Roar if missing; Primal Bite; Lacerate to 5 stacks (refreshed at 4.5 s); Maul at 25+ Rage; Lacerate | Swipe |

Forever has no Shield of Righteousness, Devastate, Shockwave, Mangle (Bear) or Swipe (Bear); Primal Bite takes Mangle's place. The sim also casts Consecration and Thunder Clap on a single target; here they wait for area mode so crowd-controlled enemies are not broken. Battle Shout and Lay on Hands are additions to the sim lists (the sim casts Battle Shout before the pull and never needs Lay on Hands). Unreadable buffs, stances, stacks or Health never trigger a suggestion.

These priorities are not a claim of simulator-proven optimal play across all builds. Client validation, additional per-build proc rules and simulation comparisons remain necessary. Restricted inputs suppress affected recommendations or forecasts instead of being treated as known. The browser preview cannot validate real WoW APIs, protected-action behavior or the native HUD animations.

Validation: `tests/RunLiveRotationTests.cjs` and `tests/RunCombatReviewTests.cjs --combat-only` exercise the Lua engine and HUD with controlled API/event mocks.
