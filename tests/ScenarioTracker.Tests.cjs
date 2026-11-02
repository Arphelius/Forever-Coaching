const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));
run(`ForeverCoaching={};ForeverCoachingDB={liveRotation={burst=false}};TestNow=10
GetTime=function()return TestNow end
local guid={player='self',target='enemy',focus='enemy',nameplate1='enemy'}
TestGUID=guid;UnitGUID=function(u)return guid[u]end
UnitCanAttack=function(_,u)return guid[u]~=nil and u~='player' end
UnitCanAssist=function(_,u)return u=='player' end
UnitIsDeadOrGhost=function()return false end
UnitAffectingCombat=function(u)return TestIdle~=true end
UnitIsPlayer=function(u)return TestPvP==true and u=='target' end
GetUnitSpeed=function()return TestSpeed or 0 end
UnitPowerType=function()return 0 end
UnitPower=function()return TestMana or 100 end;UnitPowerMax=function()return 100 end
UnitHealth=function()return TestHealth or 100 end;UnitHealthMax=function()return 100 end
UnitCastingInfo=function(u)if TestCast and u=='target' then return 'Danger',nil,nil,10000,20000,nil,'cast',false,999 end end
UnitPosition=function(u)if not TestNoPosition then return u=='player' and 0 or TestDistance or 10,0,nil,1 end end
UnitIsUnit=function(u,v)return u=='targettarget' and v=='player' end
IsInInstance=function()return false,'none' end
ForeverCoaching.EncounterCoach={currentOffers={}}
`);
for(const file of ['Core/FightRecorder.lua','Core/ScenarioTracker.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local s=fc.ScenarioTracker;local r=fc.FightRecorder
r:Begin();assert(s.flags.single and not s.flags.cleave,'GUID aliases must not count twice')
TestGUID.nameplate2='enemy2';s:Sample();assert(s.flags.cleave and not s.flags.single)
TestGUID.nameplate3='enemy3';TestPvP=true;TestSpeed=7;TestMana=10;TestHealth=20;TestCast=true
fc.EncounterCoach.currentOffers={{kind='dispel',status='observed',expires=20,reason='Poison'}}
ForeverCoachingDB.liveRotation.burst=true;TestNow=10.25;TestDistance=12;s:Sample()
for _,id in ipairs({'aoe','pvp','movement','resources','heal','interrupt','utility','burst','kite'})do assert(s.flags[id],'Missing '..id)end
assert(s.primary=='interrupt' and s:GetGuidance():find('Interrupts'))
r:Record('cast_succeeded',{unit='party1',spellName='Ally cast'})
r:Record('cast_succeeded',{unit='player',spellName='Response'})
r:Record('cast_failed',{unit='player',spellName='Failed'})
r:Record('client_error',{message='Out of range'})
r:Record('targeted_response',{unit='player',spellName='Response',message='Matched target; effect unknown.'})
assert(s.open.aoe.casts==1 and s.open.aoe.failures==1 and s.open.aoe.responses==1)
TestNoPosition=true;TestNow=10.5;s:Sample();assert(not s.flags.kite,'Missing position must not imply kiting')
TestIdle=true;TestPvP=false;TestSpeed=0;TestMana=100;TestHealth=100;TestCast=false;fc.EncounterCoach.currentOffers={};ForeverCoachingDB.liveRotation.burst=false
TestNow=11;s:Sample();assert(next(s.flags)==nil,'Idle nearby enemies are not engaged')
local fight=r:Finish();assert(fight.scenarios and not s.active and not s:GetGuidance())
local g,w,n=s:Summarize(fight.scenarios);assert(g:find('AoE') and w:find('Out of range') and w:find('Failed') and n:find('Kiting'))
assert(r:Export():find('scenario_start') and r:Export():find('scenario_end') and r:Export():find('scenarios'))
fc.ForeverSpellCatalog={classes={SHAMAN={spells={['Elemental Mastery']={ids={16166}}}}}}
C_UnitAuras={GetAuraDataByIndex=function(_,index)if index==1 then return {spellId=16166}end end}
r:Begin();s:Sample();assert(s.flags.burst,'Recognized active burst effect must detect without manual toggle');r:Finish();C_UnitAuras=nil
r:Begin();TestIdle=false;issecretvalue=function(v)return v=='enemy' end;s:Sample();assert(not s.flags.aoe,'Restricted GUID must not count')
UnitGUID=function()error('restricted')end;s:Sample();assert(not s.flags.single and not s.flags.aoe);r:Finish()
print('PASS: all 11 overlapping scenarios, GUID deduplication, engaged-only enemies, exact cast attribution, errors, transitions, unknown/secret signals, recording and export.')`);
run(fs.readFileSync('addons/ForeverCoaching/Core/CombatReview.lua','utf8'));
run(`local fc=ForeverCoaching;issecretvalue=nil;TestIdle=false;TestNoPosition=true;TestNow=30
UnitGUID=function(u)if u=='player' then return 'self' elseif u=='target' then return 'enemy' elseif u=='nameplate1' then return 'enemy2' elseif u=='nameplate2' then return 'enemy3' end end
local function fire(event,...)for _,frame in ipairs(TestFrames)do if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame,event,...)end end end
fire('PLAYER_REGEN_DISABLED');fc.ScenarioTracker:Sample();fire('UNIT_SPELLCAST_SUCCEEDED','player','test-cast',403)
TestNow=34;fire('PLAYER_REGEN_ENABLED')
fc.EncounterCoach.last={started=30,build={title='Test build'},opportunities={},casts={},movement={}}
fc.EncounterCoach.Summarize=function()return 'Observed response','','Practice' end
local pending=TestTimers;TestTimers={};for _,fn in ipairs(pending)do fn()end
local report=ForeverCoachingDB.reviews[1];assert(report and report.scenarioCoaching,'Scenario review must persist with report')
ForeverCoachingDB.fightTimelines={};local summary=fc.CombatReview:GetLatestSummary()
assert(summary.goodText:find('AoE') and summary.wrongText:find('AoE') and summary.improveText:find('AoE'),'Scenario report must survive timeline retention')
print('PASS: real combat event lifecycle and persisted scenario-specific Combat Review after detailed timeline expiry.')`);
