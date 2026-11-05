const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
function suite(files,source=''){
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 for(const code of [...files.map(file=>fs.readFileSync(file,'utf8')),source]){
  if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
 }
 lua.lua_close(L);
}
const base=['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Core/LiveRotation.lua','addons/ForeverCoaching/Core/RoleWarnings.lua'];
suite([...base,'tests/TankThreat.Tests.lua']);
suite([...base,'tests/RoleWarnings.Tests.lua']);
suite([...base,'addons/ForeverCoaching/UI/RoleWarnings.lua'],`
local fc=ForeverCoaching;local w=fc.RoleWarnings
local role='DAMAGER';local roster={};local health=100;local combat=true;local hostile=true;local hidden=false
UnitGUID=function(unit)return unit=='player' and 'self' or roster[unit] and roster[unit].guid end
UnitGroupRolesAssigned=function(unit)if hidden then error('restricted')end;return unit=='player' and role or roster[unit] and roster[unit].role end
UnitIsDeadOrGhost=function(unit)return roster[unit] and roster[unit].dead==true or false end
UnitIsConnected=function(unit)return not (roster[unit] and roster[unit].offline)end
UnitAffectingCombat=function()return combat end
UnitCanAttack=function()return hostile end
UnitHealth=function()return health end;UnitHealthMax=function()return 100 end
UnitDetailedThreatSituation=function()return true,3,100 end
local function sample()
 local alerts=w:Sample();for _,a in ipairs(alerts)do if a.kind=='threat' then return a,alerts end end
 return nil,alerts
end
assert(not sample(),'Solo DPS must not warn about threat')
roster.pet={guid='pet',role='TANK'};assert(not sample(),'A tank pet does not register a group tank')
roster.party1={guid='friend',role='DAMAGER'};assert(not sample(),'Tankless party must not warn')
assert(not w:GroupThreatRelevant('tank'),'An inferred tank spec cannot replace a registered tank role')
local injected={key='stale-threat',kind='threat',message='Check your threat.',priority=3}
fc.WarningToast:Observe({injected});assert(not fc.WarningToast.current,'The renderer must reject even injected/stale threat alerts in a tankless group')
roster.party1.role='TANK';local alert,alerts=sample();assert(alert,'Assigned dungeon tank enables threat advice')
local toast=fc.WarningToast;toast:Observe(alerts);assert(toast.current and toast.current.kind=='threat')
roster.party1=nil;sample();toast:Observe(w.alerts);assert(not toast.current,'Leaving the group immediately clears a displayed threat toast')
roster.raid1={guid='self',role='DAMAGER'};roster.raid12={guid='raid-tank',role='TANK'}
assert(sample(),'Registered raid tank enables threat advice')
IsInGroup=function()return false end;IsInRaid=function()return false end
assert(not sample(),'Stale unit tokens cannot enable warnings after leaving a group')
IsInGroup=nil;IsInRaid=nil
roster.raid12.dead=true;assert(not sample(),'Dead tank does not prompt easing off for that tank')
roster.raid12.dead=false;roster.raid12.offline=true;assert(not sample(),'Offline tank is not available')
roster.raid12.offline=false;hidden=true;assert(not sample(),'Unreadable roles cannot establish a tank');hidden=false
hostile=false;assert(not sample(),'Friendly target has no threat warning');hostile=true
combat=false;assert(not sample(),'No threat warning out of combat');combat=true
roster={};role='TANK';assert(not sample() and not w.threat and not w.threatAction,'Solo tank has no group threat UI')
roster.raid1={guid='self',role='TANK'};assert(not sample() and not w.threat,'A self-only raid roster is still solo')
roster.party1={guid='friend',role='DAMAGER'};sample();assert(w.threat,'Grouped player tank retains threat monitoring')
role='DAMAGER';health=20;local _,remaining=sample();assert(#remaining==1 and remaining[1].kind=='health','Tankless group retains relevant health warnings')
print('PASS: solo/pet/tankless party suppression, assigned party/raid tanks, dead/offline/hidden roles, hostile target/combat scope, solo versus grouped tank HUD and immediate threat-toast clearing.')
`);
