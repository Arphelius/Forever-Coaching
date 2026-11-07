const fs = require('fs');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('../tools/preview-runtime/node_modules/fengari');
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
function run(code) {
  if (lauxlib.luaL_dostring(L, to_luastring(code)) !== lua.LUA_OK) {
    throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
  }
}
run(fs.readFileSync('tests/CombatReviewHarness.lua', 'utf8'));
run(`
local create = CreateFrame
CreateFrame = function(...)
 local frame = create(...)
 local register = frame.RegisterEvent
 frame.RegisterEvent = function(self, event)
  if event == 'UNIT_SPELLCAST_FAILED_QUIET' then error('Unknown event') end
  return register(self, event)
 end
 return frame
end
`);
run(fs.readFileSync('addons/ForeverCoaching/Core/CombatReview.lua', 'utf8'));
run(`
local review = ForeverCoaching.CombatReview
assert(review.listenerReady, 'Unsupported event must not abort listener initialization')
assert(review.unavailableEvents[1] == 'UNIT_SPELLCAST_FAILED_QUIET')
local combat, blocked
for _, frame in ipairs(TestFrames) do
 if frame.events.PLAYER_REGEN_DISABLED then combat = frame end
 if frame.events.ADDON_ACTION_FORBIDDEN then blocked = frame end
end
assert(combat.scripts.OnEvent and blocked.scripts.OnEvent)
combat.scripts.OnEvent(combat, 'PLAYER_REGEN_DISABLED')
combat.scripts.OnEvent(combat, 'UNIT_SPELLCAST_SUCCEEDED', 'player', 'cast', 403)
TestNow = 15
combat.scripts.OnEvent(combat, 'PLAYER_REGEN_ENABLED')
for _, callback in ipairs(TestTimers) do callback() end
assert(#ForeverCoachingDB.reviews == 1 and ForeverCoachingDB.reviews[1].casts == 1,
 'Supported combat events must still save a fight')
blocked.scripts.OnEvent(blocked, 'ADDON_ACTION_FORBIDDEN', 'OtherAddon', 'OtherOperation()')
assert(not ForeverCoachingDB.lastCombatReviewBlockedAction, 'Do not attribute another addon failure to this addon')
blocked.scripts.OnEvent(blocked, 'ADDON_ACTION_FORBIDDEN', 'ForeverCoaching', 'RestrictedOperation()')
assert(ForeverCoachingDB.lastCombatReviewBlockedAction.operation == 'RestrictedOperation()')
local status = review:GetRecordingStatusText()
assert(status:find('1 total / 1 for this character', 1, true))
assert(status:find('Review listener: ready', 1, true))
assert(status:find('UNIT_SPELLCAST_FAILED_QUIET', 1, true))
assert(status:find('ADDON_ACTION_FORBIDDEN / RestrictedOperation()', 1, true))
assert(SLASH_FOREVERCOACHINGREVIEWSTATUS1 == '/fcreviewstatus')
assert(type(SlashCmdList.FOREVERCOACHINGREVIEWSTATUS) == 'function')
`);
lua.lua_close(L);
console.log('PASS: rejected optional events preserve fight saving; blocked actions are attributed and recording status is available without /run. Simulated client only.');
