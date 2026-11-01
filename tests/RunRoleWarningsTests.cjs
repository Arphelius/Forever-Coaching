const fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(require('os').tmpdir(),'fc-lua-test-runtime/node_modules/fengari'));
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Core/LiveRotation.lua','addons/ForeverCoaching/Core/RoleWarnings.lua','tests/RoleWarnings.Tests.lua','addons/ForeverCoaching/UI/RoleWarnings.lua','addons/ForeverCoaching/UI/CombatHUD.lua']){
 if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(file+': '+to_jsstring(lua.lua_tostring(L,-1)));
}
if(lauxlib.luaL_dostring(L,to_luastring(`
local warnings=ForeverCoaching.RoleWarnings
local sample=warnings.Sample
warnings.alerts={{key='one',kind='stop',message='STOP DPS',blocksRotation=true},{key='two',kind='health',message='LOW HEALTH'},{key='three',kind='interrupt',message='INTERRUPT'},{key='four',kind='mana',message='MANA'}}
warnings.Sample=function(self)return self.alerts end
ForeverCoachingRoleWarnings.scripts.OnUpdate(ForeverCoachingRoleWarnings,1)
assert(not ForeverCoaching.roleWarningsLastError,ForeverCoaching.roleWarningsLastError)
local shown=0;for _,frame in ipairs(TestFrames)do if frame.parent==ForeverCoachingRoleWarnings and frame:IsShown()then shown=shown+1;assert(frame.text~='MANA')end end
assert(shown==3,'Only the top three warnings appear')
ForeverCoachingCombatHUD.scripts.OnUpdate(ForeverCoachingCombatHUD,1)
assert(not ForeverCoaching.combatHUDLastError,ForeverCoaching.combatHUDLastError)
assert(not ForeverCoachingRotationStrip:IsShown(),'Stop warning clears normal rotation display')
warnings.Sample=sample
warnings:Sample()
ForeverCoachingRoleWarnings.scripts.OnUpdate(ForeverCoachingRoleWarnings,1)
for _,frame in ipairs(TestFrames)do if frame.parent==ForeverCoachingRoleWarnings then assert(not frame:IsShown(),'Cleared warnings disappear')end end
print('PASS: three-alert rendering, warning clearing and native rotation suppression.')
`))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
lua.lua_close(L);
