# Live rotation HUD

The HUD appears above the action bars when an actionable recommendation is available. It has exactly four slots: a bright current recommendation, then up to three dimmer conditional forecasts. Uncertain slots stay empty. Repeated filler casts may repeat the same icon. A successful player cast matching the current recommendation produces a fading completed icon; failed casts, other players and unrelated spells do not complete it. Each refresh evaluates current conditions again, rather than blindly advancing a fixed sequence.

Type `/fcrotation` to open controls. Single target avoids optional area attacks. Enable area damage only when surrounding enemies may safely be hit, and return to single target around controlled enemies. The addon cannot establish safe enemy grouping or every encounter assignment from nameplates. Use burst for the agreed cooldown window, or hold it for a later pull; burst resets after combat. Shaman still requires observed nearby targets before comparing Chain Lightning damage.

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

These priorities are not a claim of simulator-proven optimal play across all builds. Client validation, additional per-build proc rules and simulation comparisons remain necessary. Restricted inputs suppress affected recommendations or forecasts instead of being treated as known. The browser preview cannot validate real WoW APIs, protected-action behavior or the native HUD animations.

Validation: `tests/RunLiveRotationTests.cjs` and `tests/RunCombatReviewTests.cjs --combat-only` exercise the Lua engine and HUD with controlled API/event mocks.
