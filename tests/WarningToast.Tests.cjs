const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));
run('ForeverCoaching={RoleWarnings={Sample=function()return {}end}}');
run(fs.readFileSync('addons/ForeverCoaching/UI/RoleWarnings.lua','utf8'));
run(`local toast=ForeverCoaching.WarningToast;local frame=ForeverCoachingRoleWarnings
local labels={};for _,f in ipairs(TestFrames)do if f.parent==frame then labels[#labels+1]=f end end
assert(#labels==1,'Only one warning label is allowed');local label=labels[1]
toast:Observe({{key='routine',kind='interrupt',priority=1,message='Routine cast'}});assert(not label:IsShown(),'Routine opportunities must not become warnings')
local health={key='health',kind='health',emergency=true,priority=2,message='Long health message'}
local healing={key='healing',kind='healing',emergency=true,priority=2,message='Long heal message'}
local mana={key='mana',kind='mana',emergency=true,priority=5,message='Long mana message'}
toast:Observe({health,healing,mana});assert(label:IsShown() and label.text=='Low health — use a defensive or heal.')
toast:Advance(2.2);assert(label.alpha>0 and label.alpha<1,'Warning must fade after two seconds')
toast:Observe({health,healing,mana});toast:Advance(.7);assert(not label:IsShown(),'Warning must disappear within three seconds')
for i=1,100 do toast:Advance(.2);toast:Observe({health,healing,mana})end
assert(not label:IsShown(),'Persistent conditions must not repeat or queue lower priorities')
toast:Advance(4);toast:Observe({health});assert(label:IsShown(),'A resolved condition may warn on a fresh recurrence')
toast:Advance(.1);toast:Observe({health,{key='new-ally',kind='healing',priority=2}})
assert(toast.current==health,'Another low-health target must not stack or replace the current alert')
local mechanic={key='mechanic',kind='move',emergency=true,priority=1,message='Move out now',blocksRotation=true}
toast:Observe({health,mechanic});assert(toast.current==mechanic and label.text=='Move out now','Urgent mechanic must preempt a lesser warning')
toast:Advance(3);assert(not label:IsShown());toast:Observe({mechanic});assert(not label:IsShown(),'Persistent mechanic must not restart its toast')
print('PASS: single compact warning, short copy, timed fade, persistent-condition suppression, no alert queue, recurrence and urgent preemption.')`);
const hud=fs.readFileSync('addons/ForeverCoaching/UI/CombatHUD.lua','utf8');
if(hud.includes('encounterText:Show()'))throw Error('Persistent explanatory HUD text must remain removed');
