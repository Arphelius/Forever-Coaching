const fs=require('fs'),assert=require('assert/strict');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code){if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run('unpack=unpack or table.unpack');
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Core/TalentSnapshot.lua','addons/ForeverCoaching/Data/LevelingBuilds.lua','addons/ForeverCoaching/Core/BuildPlanner.lua','addons/ForeverCoaching/Core/EncounterCoach.lua','addons/ForeverCoaching/Core/FightRecorder.lua','addons/ForeverCoaching/UI/GuideSelectors.lua','addons/ForeverCoaching/Core/CombatReview.lua','addons/ForeverCoaching/Core/WarcraftLogs.lua','addons/ForeverCoaching/UI/ClassicTheme.lua','addons/ForeverCoaching/UI/WarcraftLogs.lua','addons/ForeverCoaching/ForeverCoaching.lua'])run(fs.readFileSync(file,'utf8'));
run(`
local fc=ForeverCoaching
fc:OpenCombatReview()
assert(fc.CombatReview:GetSource()=='warcraftlogs')
local required={['YOUR REPORT']=false,['100-PARSE REFERENCES']=false,['COMPARE ON WARCRAFT LOGS']=false}
for _,frame in ipairs(TestFrames)do
 if frame:IsShown() and type(frame.text)=='string' then
  if required[frame.text]~=nil then required[frame.text]=true end
  for _,removed in ipairs({'Review-My-Run.cmd','4318','Use this spec','Advanced import','View fight timeline','Local review','API key'})do
   assert(not frame.text:find(removed,1,true),'Normal review must not expose '..removed)
  end
 end
end
for text,visible in pairs(required)do assert(visible,'Missing Warcraft Logs access section: '..text)end
local events
for _,frame in ipairs(TestFrames)do if frame.events.UNIT_SPELLCAST_FAILED_QUIET then events=frame end end
ForeverCoachingDB.combatAnalysisReady=false
events.scripts.OnEvent(events,'PLAYER_REGEN_DISABLED')
events.scripts.OnEvent(events,'UNIT_SPELLCAST_SUCCEEDED','player','cast',403)
TestNow=15;events.scripts.OnEvent(events,'PLAYER_REGEN_ENABLED')
for _,callback in ipairs(TestTimers)do callback()end
assert(#ForeverCoachingDB.reviews==1,'Local diagnostics may still be retained')
assert(not ForeverCoachingDB.combatAnalysisReady,'Do not announce local captures as new Warcraft Logs analysis')
assert(fc.CombatReview:GetLatestSummary().metrics=='Warcraft Logs / Report access')
assert(not fc.CombatReview:GetLatestSummary().goodText:find('successful casts',1,true),'Local cast totals must not masquerade as Warcraft Logs findings')
`);
lua.lua_close(L);
const source=fs.readFileSync('addons/ForeverCoaching/UI/WarcraftLogs.lua','utf8');
assert(!source.includes('Review-My-Run.cmd')&&!source.includes('127.0.0.1')&&!source.includes('API key'));
console.log('PASS: real review UI routes to Warcraft Logs, removes companion/import/local coaching setup, and does not announce local casts as website analysis. Simulated UI only.');
