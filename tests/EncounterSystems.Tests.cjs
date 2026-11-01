const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const {evaluateDecisions}=require('../tools/encounter-decisions.cjs');
const identity={reportId:42,encounterId:7,actorId:1};
const context=JSON.parse(fs.readFileSync('docs/encounter-context.example.json','utf8'));
context.rules[0].triggerEventIds=['enemy-cast'];
const events=[{id:'enemy-cast',timestamp_ms:10000,event_type:'cast',source_id:2,target_id:1,spell_id:999}];
assert.equal(evaluateDecisions(context,events,identity,true).findings[0].kind,'wrong');
assert.equal(evaluateDecisions(context,events,identity,false).findings[0].kind,'investigate');
context.rules[0].availability.inRange=false;
assert.equal(evaluateDecisions(context,events,identity,true).findings[0].kind,'investigate');
events.push({id:'kick',timestamp_ms:11000,event_type:'interrupt',source_id:3,target_id:2,spell_id:8042});
assert.equal(evaluateDecisions(context,events,identity,true).findings[0].kind,'investigate','A teammate cannot satisfy your assignment');
events[1].source_id=1;
assert.equal(evaluateDecisions(context,events,identity,true).findings[0].kind,'good');
assert.equal(evaluateDecisions(context,[],identity,true).findings.length,0);
assert.throws(()=>evaluateDecisions(context,events,{...identity,actorId:8},true),/different actorId/);
const runtime=path.join(require('os').tmpdir(),'fc-lua-test-runtime/node_modules/fengari');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(runtime);
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/AbilityLessons.lua','addons/ForeverCoaching/Core/EncounterCoach.lua','tests/EncounterCoach.Tests.lua','addons/ForeverCoaching/Data/SpecScenarios.lua','addons/ForeverCoaching/Data/ScenarioActions.lua','addons/ForeverCoaching/Data/CombatSituations.lua','addons/ForeverCoaching/Core/SpecScenarios.lua','addons/ForeverCoaching/UI/EncounterLearning.lua']){
 if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(file+': '+to_jsstring(lua.lua_tostring(L,-1)));
}
// Build actual in-game lessons/scenarios with mocked frames to catch missing methods.
if(lauxlib.luaL_dostring(L,to_luastring(`
ForeverCoaching:BuildEncounterLearningPage(UIParent,'Learn')
GetPrimaryTalentTree=function() return 2 end
local parent=CreateFrame('Frame',nil,UIParent)
ForeverCoaching:BuildEncounterLearningPage(parent,'Scenarios')
local function within(frame) while frame do if frame==parent then return true end;frame=frame.parent end end
local function visible(text) for _,frame in ipairs(TestFrames) do if within(frame) and frame:IsShown() and frame.text==text then return true end end end
assert(visible('Single target (ST)') and not visible('Cleave (two targets)'),'Only one scenario should be visible')
for _,frame in ipairs(TestFrames) do if frame.parent==parent and frame.text=='Next' then frame.scripts.OnClick(frame);break end end
assert(visible('Cleave (two targets)') and not visible('Single target (ST)'),'Next should replace the scenario slide')
`))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
lua.lua_close(L);
const integrated=lauxlib.luaL_newstate();lualib.luaL_openlibs(integrated);
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/AbilityLessons.lua','addons/ForeverCoaching/Core/EncounterCoach.lua','tests/EncounterCoach.Tests.lua','addons/ForeverCoaching/Core/CombatReview.lua','addons/ForeverCoaching/Data/SpecScenarios.lua','addons/ForeverCoaching/Data/ScenarioActions.lua','addons/ForeverCoaching/Data/CombatSituations.lua','addons/ForeverCoaching/Core/SpecScenarios.lua','addons/ForeverCoaching/UI/EncounterLearning.lua','addons/ForeverCoaching/ForeverCoaching.lua']){
 if(lauxlib.luaL_dostring(integrated,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(file+': '+to_jsstring(lua.lua_tostring(integrated,-1)));
}
const flow=`
local function fire(event,...)
 for _,frame in ipairs(TestFrames) do if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame,event,...) end end
end
TestNow=20;ForeverCoachingDB.reviews={};TestTimers={}
fire('PLAYER_REGEN_DISABLED')
C_Spell.GetSpellCooldown=function() return {startTime=0,duration=0,isEnabled=true} end
ForeverCoaching.EncounterCoach:Sample()
fire('UNIT_SPELLCAST_SENT','player','Ally','integrated-cast',331)
TestNow=21;fire('UNIT_SPELLCAST_SUCCEEDED','player','integrated-cast',331)
TestNow=25;fire('PLAYER_REGEN_ENABLED')
for _,fn in ipairs(TestTimers) do fn() end
assert(ForeverCoachingDB.reviews[1].encounterCoaching,'Situational decisions must persist in the actual combat review')
local summary=ForeverCoaching.CombatReview:GetLatestSummary()
assert(summary.metrics:find('Local encounter decisions',1,true))
assert(summary.goodText:find('Response time',1,true))
for _,label in ipairs({'Scenarios','Learn'}) do
 for _,frame in ipairs(TestFrames) do if frame.text==label and frame.parent and frame.parent.scripts.OnClick then frame.parent.scripts.OnClick(frame.parent);break end end
end
`;
if(lauxlib.luaL_dostring(integrated,to_luastring(flow))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(integrated,-1)));
lua.lua_close(integrated);
console.log('PASS: evidence rules, actor identity, partial coverage, unavailable actions and in-game lesson/scenario pages.');
