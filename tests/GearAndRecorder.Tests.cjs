const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(require('os').tmpdir(),'fc-lua-test-runtime/node_modules/fengari'));
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
const files=['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/LevelingBuilds.lua','addons/ForeverCoaching/Core/BuildPlanner.lua','addons/ForeverCoaching/Core/GearGuide.lua','addons/ForeverCoaching/Core/FightRecorder.lua','addons/ForeverCoaching/UI/GearGuide.lua','addons/ForeverCoaching/UI/FightTimeline.lua'];
for(const file of files)if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(file+': '+to_jsstring(lua.lua_tostring(L,-1)));
const test=`
local fc=ForeverCoaching
local hybrid=fc.GearGuide:ForBuild('SHAMAN',{id='hybrid',title='Enhancement hybrid',role='damage',talents={{name='Stormstrike',rank=1}}},60)
assert(hybrid.available and hybrid.plan:find('Enhancement',1,true))
local hasSpell=false;for _,s in ipairs(hybrid.stats) do if s.name:find('Spell power',1,true) then hasSpell=true end end
assert(hasSpell,'Hybrid guide must include spell contribution, not only melee stats')
local healer=fc.GearGuide:ForBuild('SHAMAN',{title='Resto',role='healer',talents={}},60)
assert(healer.stats[1].name:find('Healing',1,true) and healer.limits:find('placeholder',1,true))
assert(not fc.GearGuide:ForBuild('SHAMAN',nil,10).available)
assert(hybrid.url=='https://www.curseforge.com/wow/addons/simgearforever')
local R=fc.FightRecorder
local health=100;local mana=100;local moving=0
UnitGUID=function(unit) if unit=='player' then return 'self' elseif unit=='target' then return 'enemy' end end
UnitName=function(unit) return unit=='player' and 'Fixture' or unit=='target' and 'Enemy' or nil end
UnitHealth=function()return health end;UnitHealthMax=function()return 100 end
UnitPower=function()return mana end;UnitPowerMax=function()return 100 end;UnitPowerType=function()return 0 end
UnitIsDeadOrGhost=function()return health==0 end;GetUnitSpeed=function()return moving end
TestNow=10;GetTime=function()return TestNow end
C_Spell={GetSpellInfo=function(id)return {name='Spell '..id}end}
R:Begin()
local frame;for _,f in ipairs(TestFrames)do if f.events.PLAYER_STARTED_MOVING then frame=f end end
frame.scripts.OnEvent(frame,'UNIT_SPELLCAST_SENT','player','Enemy','cast-1',403)
TestNow=11;frame.scripts.OnEvent(frame,'UNIT_SPELLCAST_SUCCEEDED','player','cast-1',403)
health=60;mana=50;moving=7;TestNow=12;R:Sample()
frame.scripts.OnEvent(frame,'UNIT_SPELLCAST_FAILED','player','cast-2',403)
frame.scripts.OnEvent(frame,'UI_ERROR_MESSAGE',1,'Out of range')
local secret={};issecretvalue=function(v)return v==secret end
frame.scripts.OnEvent(frame,'UNIT_SPELLCAST_START','target','enemy-cast',secret)
assert(R.active.missing.events,'Secret event values must be omitted and coverage marked')
issecretvalue=function()return false end
health=0;frame.scripts.OnEvent(frame,'PLAYER_DEAD');R:Sample()
TestNow=15;local fight=R:Finish();local summary=R:Analyze(fight)
assert(#fight.events>5 and fight.duration==5)
local matched=false;local deaths=0
for _,e in ipairs(fight.events)do if e.kind=='cast_succeeded' then assert(e.targetName=='Enemy');matched=true end;if e.kind=='death' and e.unit=='player' then deaths=deaths+1 end end
assert(matched and deaths==1,'Cast targets must persist; player death must be deduplicated')
assert(summary.investigate:find('1 failed',1,true))
assert(R:GetLatest().id==fight.id and R:Find(fight.id))
local export=R:Export();assert(export:find('ForeverCoachingFight-v1',1,true));FixtureRecordingJSON=export
R.limit=2;TestNow=20;R:Begin();R:Record('extra',{});R:Record('extra',{});assert(R.active.truncated);R:Finish()
for i=1,6 do TestNow=20+i;R:Begin();R:Finish() end
assert(#ForeverCoachingDB.fightTimelines==R.keep,'Saved recordings must be bounded')
fc.EncounterCoach={GetBuildContext=function()return {class='SHAMAN',id=nil}end}
fc:BuildGearGuidePage(UIParent);fc:OpenFightTimeline()
print('PASS: build-specific gear, hybrid stats, healer limits, live events, targets, state changes, secret omission, bounded history and timeline UI.')
`;
if(lauxlib.luaL_dostring(L,to_luastring(test))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
lua.lua_getglobal(L,to_luastring('FixtureRecordingJSON'));const exported=to_jsstring(lua.lua_tostring(L,-1));const recording=JSON.parse(exported);assert.equal(recording.format,'ForeverCoachingFight-v1');assert(Array.isArray(recording.fight.events));lua.lua_close(L);
