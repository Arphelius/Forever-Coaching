const fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
{const T=lauxlib.luaL_newstate();lualib.luaL_openlibs(T);for(const file of ['tests/CombatReviewHarness.lua','tests/CombatHUDHarness.lua','addons/ForeverCoaching/UI/CombatHUD.lua','tests/CombatHUD.Tests.lua']){if(lauxlib.luaL_dostring(T,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(file+': '+to_jsstring(lua.lua_tostring(T,-1)));}lua.lua_close(T);}
{const T=lauxlib.luaL_newstate();lualib.luaL_openlibs(T);for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Core/LiveRotation.lua','tests/TankRotation.Tests.lua']){if(lauxlib.luaL_dostring(T,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(file+': '+to_jsstring(lua.lua_tostring(T,-1)));}lua.lua_close(T);}
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Core/LiveRotation.lua','tests/LiveRotation.Tests.lua','addons/ForeverCoaching/UI/CombatHUD.lua']){
 if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(file+': '+to_jsstring(lua.lua_tostring(L,-1)));
}
if(lauxlib.luaL_dostring(L,to_luastring(`
ForeverCoachingCombatHUD.scripts.OnUpdate(ForeverCoachingCombatHUD,1)
assert(not ForeverCoaching.combatHUDLastError,ForeverCoaching.combatHUDLastError)
assert(ForeverCoachingRotationSlot1.icon:GetTexture()==C_Spell.GetSpellInfo('Frostbolt').iconID,'Real live engine drives HUD')
assert(ForeverCoachingRotationSlot4:IsShown(),'All four live slots are shown')
print('PASS: live engine and four-slot HUD integration.')
`))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
lua.lua_close(L);
