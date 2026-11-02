const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));
run(`ForeverCoaching={};UnitClass=function()return 'Mage','MAGE'end
ForeverCoaching.EncounterCoach={GetBuildContext=function()return {class='MAGE'}end}
ForeverCoaching.SpecScenarios={ForCurrent=function()return {available=true,treeIndex=2,role='damage'}end}
`);
run(fs.readFileSync('addons/ForeverCoaching/Core/CombatReview.lua','utf8'));
run(`local review=ForeverCoaching.CombatReview
local events;for _,frame in ipairs(TestFrames)do if frame.events.PLAYER_REGEN_DISABLED then events=frame end end
local function fire(event,...)events.scripts.OnEvent(events,event,...)end
fire('PLAYER_REGEN_DISABLED');fire('UNIT_SPELLCAST_SUCCEEDED','player','cast',133);TestNow=(TestNow or 10)+5;fire('PLAYER_REGEN_ENABLED')
local timers=TestTimers;TestTimers={};for _,fn in ipairs(timers)do fn()end
local recorded=ForeverCoachingDB.reviews[1]
assert(recorded.class=='MAGE' and recorded.specTree==2 and recorded.specRole=='damage','Actual combat class/spec metadata must persist independently of the guide browser')
local arcane={class='MAGE',specTree=1,specRole='damage',character='OtherMage-Realm',casts=7,duration=10}
local fire={class='MAGE',specTree=2,specRole='damage',character='OtherMage-Realm',casts=8,duration=10}
local bear={class='DRUID',specTree=2,specRole='tank',character='Bear-Realm',casts=9,duration=10}
ForeverCoachingDB.reviews={fire,bear,arcane,recorded}
local summary=review:GetLatestSummary({class='MAGE',tree=1,role='damage'})
assert(summary.goodText:find('7 successful casts'),'Selection must retrieve a matching saved fight even on another character')
assert(not review:MatchesFilter(fire,{class='MAGE',tree=1}),'Different specs must not mix')
assert(not review:MatchesFilter(bear,{class='DRUID',tree=2,role='damage'}),'Cat and bear roles must not mix')
assert(not review:MatchesFilter({class='MAGE'},{class='MAGE',tree=1}),'Unknown specialization must not be guessed')
assert(review:GetLatestSummary({class='PRIEST',tree=1}).metrics=='No recorded fight for this class/spec','Missing data must show an empty state')
assert(review:GetLatestSummary().goodText:find('1 successful casts'),'Unfiltered review must still belong to the current character')
print('PASS: actual class/spec metadata, cross-character matching, spec/role separation, unknown and absent data, and current-character defaults.')`);
