const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['tests/CombatReviewHarness.lua','tests/RotationCoachHarness.lua','addons/ForeverCoaching/Core/LiveRotation.lua'])run(fs.readFileSync(file,'utf8'));
run(`local live=ForeverCoaching.LiveRotation
Enum={PlayerSwingType={MainHand=0,OffHand=1,Ranged=2}}
UnitAttackSpeed=function()error('Weapon speed must not seed a swing timer')end
UnitIsDeadOrGhost=function()return false end
RotationState.attacking=true;RotationState.meleeRange=true;RotationState.combat=true;InstallAttackButton()
local spec={available=true,treeIndex=2}
local event
for _,frame in ipairs(TestFrames)do if frame.events.PLAYER_SWING then event=frame end end
local function fire(name,...)event.scripts.OnEvent(event,name,...)end
local function rec()return live:WithShamanSwings({spellID=8042,spellName='Earth Shock',icon=8042,targetHostile=true},spec)end
assert(#rec().queue==2 and not rec().queue[2].swingEnds,'No timing before the first native event')
TestNow=10;fire('PLAYER_SWING',2,0)
local q=rec().queue;assert(q[2].swingEnds==12 and q[2].swingDuration==2 and q[2].hand==0)
TestNow=10.5;fire('PLAYER_SWING',1.8,1)
q=rec().queue;assert(#q==3 and q[2].hand==0 and q[3].hand==1,'Dual-wield hands keep separate native anchors')
fire('PLAYER_SWING',1,2);assert(#rec().queue==3,'Ranged events cannot reset melee timers')
live.GetRecommendation=function()return rec()end
`);
run(fs.readFileSync('addons/ForeverCoaching/UI/CombatHUD.lua','utf8'));
run(`local live=ForeverCoaching.LiveRotation
local hud=ForeverCoachingCombatHUD
local function tick()hud.scripts.OnUpdate(hud,.2);assert(not ForeverCoaching.combatHUDLastError,ForeverCoaching.combatHUDLastError)end
local engineEvent,uiEvent
for _,frame in ipairs(TestFrames)do if frame.events.PLAYER_SWING then if frame.events.PLAYER_REGEN_ENABLED then engineEvent=frame else uiEvent=frame end end end
local function fire(name,...)engineEvent.scripts.OnEvent(engineEvent,name,...)end
tick()
assert(ForeverCoachingRotationSlot2.caption.text=='M 1.5' and ForeverCoachingRotationSlot3.caption.text=='O 1.8','Countdowns use native end time minus GetTime')
local spellPlays=ForeverCoachingRotationSlot1.enter.plays or 0
local autoPlays=ForeverCoachingRotationSlot2.enter.plays or 0
TestNow=12;fire('PLAYER_SWING',1.5,0);uiEvent.scripts.OnEvent(uiEvent,'PLAYER_SWING',1.5,0)
assert(ForeverCoachingRotationSlot2.enter.plays==autoPlays+1,'Native swing pulses its AUTO icon')
assert((ForeverCoachingRotationSlot1.enter.plays or 0)==spellPlays,'Swing does not falsely complete Earth Shock')
tick();assert(ForeverCoachingRotationSlot2.caption.text=='O 0.3' and ForeverCoachingRotationSlot3.caption.text=='M 1.5','Haste-adjusted native duration replaces the old anchor and hands reorder by next swing')
TestNow=13.6;tick();assert(ForeverCoachingRotationSlot2.caption.text=='AUTO' and not ForeverCoachingRotationSlot3.icon.texture,'Expired timers are not extrapolated into fake swings')
local secret={};issecretvalue=function(v)return v==secret end
fire('PLAYER_SWING',secret,0);fire('PLAYER_SWING',2,secret);fire('PLAYER_SWING',0,0);fire('PLAYER_SWING',math.huge,0)
assert(#live:GetUpcomingSwings()==0,'Unreadable and invalid durations never create timers')
fire('PLAYER_SWING',2,0);fire('PLAYER_LEAVE_COMBAT');assert(#live:GetUpcomingSwings()==0,'Stopping autoattack clears native anchors')
fire('PLAYER_SWING',2,0);fire('PLAYER_DEAD');assert(#live:GetUpcomingSwings()==0,'Death clears anchors')
fire('PLAYER_SWING',2,0);fire('PLAYER_ENTERING_WORLD');assert(#live:GetUpcomingSwings()==0,'Reload/world entry never manufactures a running swing')
print('PASS: Blizzard PLAYER_SWING anchors, per-hand countdowns/order, real-event pulses, new durations, expiration, stop/death/reload reset, secret guards and no weapon-speed estimates.')
`);
lua.lua_close(L);
