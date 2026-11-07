const fs=require('fs'),assert=require('assert/strict');
const {profile,compare,encodeReview}=require('../tools/warcraftlogs-client.cjs');
const {toLua}=require('../tools/foreverlogs-review.cjs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code){if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run('unpack=unpack or table.unpack');
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Core/TalentSnapshot.lua','addons/ForeverCoaching/Data/LevelingBuilds.lua','addons/ForeverCoaching/Data/SpecScenarios.lua','addons/ForeverCoaching/Core/BuildPlanner.lua','addons/ForeverCoaching/Core/EncounterCoach.lua','addons/ForeverCoaching/Core/FightRecorder.lua','addons/ForeverCoaching/UI/GuideSelectors.lua','addons/ForeverCoaching/Core/CombatReview.lua','addons/ForeverCoaching/Core/WarcraftLogs.lua','addons/ForeverCoaching/UI/ClassicTheme.lua','addons/ForeverCoaching/UI/WarcraftLogs.lua','addons/ForeverCoaching/ForeverCoaching.lua'])run(fs.readFileSync(file,'utf8'));
run(fs.readFileSync('addons/ForeverCoaching/UI/EncounterLearning.lua','utf8'));
function fixture(number){
 const actor={id:1,name:'Fixture',server:'TestRealm',subType:'Shaman',type:'Player'};
 const fight={id:number,name:'Fixture Boss '+number,encounterID:70+number,difficulty:3,gameZone:{id:30+number,name:'Fixture Dungeon '+number},startTime:0,endTime:60000,kill:true,friendlyPlayers:[1],friendlySpecs:['Enhancement']};
 const report={code:'AbCdEfGh1234567'+number,startTime:1793900000000+number*60000,zone:{id:50},masterData:{gameVersion:16,actors:[actor],abilities:[{gameID:101,name:'Stormstrike'},{gameID:102,name:'Earth Shock'},{gameID:103,name:'Lightning Bolt'}]},fights:[fight]};
 const events=ids=>({complete:true,events:ids.map((abilityGameID,i)=>({timestamp:1000+i*8000,type:'cast',sourceID:1,abilityGameID}))});
 const target=profile(report,fight,actor,events([101,103,103]));
 const peers=[1,2,3].map(i=>{const peer={...actor,name:'Peer'+i};const p=profile({...report,code:'PeerCode0000000'+i,masterData:{...report.masterData,actors:[peer]}},fight,peer,events([101,102,103,102,102,102]));p.percentile=100;return p;});
 const analysis=compare(target,peers);return {code:encodeReview(target,analysis),comparison:analysis.comparison};
}
const a=fixture(1),b=fixture(2);
run(`
local fc=ForeverCoaching
fc.EncounterCoach.GetCombatContext=function()return {class='SHAMAN',tree=2}end
function VisibleText(value)
 for _,frame in ipairs(TestFrames)do if frame:IsShown() and frame.text==value then return true end end
 return false
end
fc:OpenCombatReview()
assert(VisibleText('Spec') and VisibleText('Instance / encounter'),'Two clear selectors must replace the instruction cards')
local model=fc.WarcraftLogs:GetComparisonModel()
assert(model.selectedSpec=='SHAMAN:enhancement','Default to the actual current spec')
assert(#model.specs==27,'All nine supported classes should expose their three specs')
assert(not model.ready and #model.rows==0 and #model.encounters==0,'Missing live data must not invent rankings or instances')
local panel
for _,frame in ipairs(TestFrames)do if frame.text=='Instance / encounter' and frame:IsShown()then panel=frame.parent end end
local controls=0
for _,frame in ipairs(TestFrames)do
 if frame:IsShown()then
  if frame.frameType=='Button'then
   local parent=frame.parent
   while parent do if parent==panel then controls=controls+1;break end;parent=parent.parent end
  end
  if type(frame.text)=='string'then
   for _,removed in ipairs({'YOUR REPORT','100-PARSE REFERENCES','COMPARE ON WARCRAFT LOGS','Review-My-Run.cmd','Save report','Start file logging','Previous review','Show details','Use this spec','Advanced import','API key'})do
    assert(not frame.text:find(removed,1,true),'Remove old review controls and instruction cards: '..removed)
   end
  end
 end
end
assert(controls==2,'Only the spec and encounter dropdowns belong on the comparison panel')
`);
run('FirstComparison='+toLua(a.comparison)+';FirstCode='+toLua(a.code));
run(`
local w=ForeverCoaching.WarcraftLogs
assert(w:Import(FirstCode,FirstComparison))
local model=w:GetComparisonModel()
assert(model.ready and #model.rows>=3 and #model.encounters==1)
assert(VisibleText('YOU') and VisibleText('100-PARSE PLAYERS') and VisibleText('NEXT FIGHT'))
assert(VisibleText('Earth Shock') and VisibleText('0.0 casts/min') and VisibleText('4.0 casts/min'),'Render separate measured player and reference values')
assert(model.nextFight:find('Earth Shock',1,true),'Give one evidence-linked practice goal')
assert(w:SetComparisonSpec('MAGE:fire'))
assert(not w:GetComparisonModel().ready and not VisibleText('0.0 casts/min'),'Spec changes must clear stale player rows')
assert(not VisibleText('NEXT FIGHT'),'Do not keep old advice for another spec')
assert(w:SetComparisonSpec('SHAMAN:enhancement'))
`);
run('SecondComparison='+toLua(b.comparison)+';SecondCode='+toLua(b.code));
run(`
local w=ForeverCoaching.WarcraftLogs
assert(w:Import(SecondCode,SecondComparison))
assert(#w:GetComparisonModel().encounters==2,'List all available matching instance/encounter snapshots')
assert(w:SetComparisonEncounter('32:72:3'))
assert(w:GetComparisonModel().metrics:find('Fixture Dungeon 2',1,true))
assert(w:SetComparisonEncounter('31:71:3'))
assert(w:GetComparisonModel().metrics:find('Fixture Dungeon 1',1,true))
assert(not w:SetComparisonSpec('MAGE:invented') and not w:SetComparisonEncounter('fake'),'Reject unavailable selections')
local before=#w:GetReviews()
FirstComparison.context.referencePlayers[1].percentile=99.99
assert(not w:Import(FirstCode,FirstComparison) and #w:GetReviews()==before,'Reject a rounded or lower-percentile structured benchmark')
FirstComparison.context.referencePlayers[1].percentile=100
FirstComparison.context.instanceId=999
assert(not w:Import(FirstCode,FirstComparison),'Do not mix references from another instance')
FirstComparison.context.instanceId=31
UnitGUID=function()return 'another-character'end
local model=w:GetComparisonModel()
assert(model.ready and model.nextFight==nil,'Other characters may browse reference data without receiving someone else advice')
for _,row in ipairs(model.rows)do assert(row.you=='No matching fight','Never label another character actions as yours')end
ForeverCoachingDB.warcraftLogs.reviews={}
ForeverCoaching.WarcraftLogsCatalog={schema=1,source='Warcraft Logs',entries={FirstComparison,SecondComparison}}
local catalog=w:GetComparisonModel()
assert(catalog.ready and #catalog.encounters==2,'A supplied multi-instance reference catalog can be browsed before the player has a matching fight')
for _,row in ipairs(catalog.rows)do assert(row.you=='No matching fight')end
assert(catalog.nextFight==nil,'Reference-only browsing must not invent a personal correction')
ForeverCoaching.WarcraftLogsCatalog={schema=1,source='Warcraft Logs',entries={}}
assert(not w:GetComparisonModel().ready,'Replacing the catalog clears stale instance rows')
`);
run(`
local fc=ForeverCoaching;local w=fc.WarcraftLogs
fc.WarcraftLogsCatalog={schema=1,source='Warcraft Logs',entries={FirstComparison,SecondComparison}}
local parent=CreateFrame('Frame');parent:SetSize(800,440);parent:Show()
fc:BuildEncounterLearningPage(parent,'Scenarios')
local view=fc.parserScenarioView
assert(view and view.specPicker and view.encounterPicker,'Scenarios uses the same two reference selectors')
assert(VisibleText('Recorded rotation (6 / 6 recorded)'))
assert(VisibleText('1.  1.0s — Stormstrike') and VisibleText('2.  9.0s — Earth Shock'),'Render the reference spell order and fight-relative times')
assert(VisibleText('Item-use details were not exposed in this reference.'))
assert(not VisibleText('Your next fight'),'Reference-only browsing cannot supply a personal verdict')
assert(w:SetComparisonEncounter('32:72:3'))
assert(VisibleText('Enhancement / Fixture Dungeon 2 / Fixture Boss 2'),'Encounter changes refresh Scenarios')
assert(w:SetComparisonSpec('MAGE:fire'))
assert(VisibleText('No matching 100-parse scenario data is connected for this selection.'))
assert(not VisibleText('1.  1.0s — Stormstrike'),'Switching specs hides the previous rotation')
assert(w:SetComparisonSpec('SHAMAN:enhancement'))
FirstComparison.scenario.sourceURL='https://forever.warcraftlogs.com/reports/Other00000000001#fight=1&source=1'
assert(not w:Import(FirstCode,FirstComparison),'Reject a scenario from an unverified reference')
FirstComparison.scenario.sourceURL=FirstComparison.context.referencePlayers[1].url
FirstComparison.scenario.casts[1].at=-1
assert(not w:Import(FirstCode,FirstComparison),'Reject actions outside the fight')
FirstComparison.scenario.casts[1].at=1
FirstComparison.scenario.items={{at=3,name='Unidentified potion',spellID=101}}
FirstComparison.scenario.itemCount=1
assert(not w:Import(FirstCode,FirstComparison),'Item uses require explicit item identity')
FirstComparison.scenario.items={{at=3,name='Fixture potion',itemID=900}}
assert(w:Import(FirstCode,FirstComparison))
assert(w:SetComparisonEncounter('31:71:3'))
assert(VisibleText('1.  3.0s — Fixture potion / item #900'),'Show recorded explicit item evidence')
`);
lua.lua_close(L);
console.log('PASS: two controls, no instruction cards, 27 specs/current-spec default, actual side-by-side values, next-fight goal, multi-instance filtering, stale-row clearing, exact-100/context validation and character isolation. Synthetic data only; no live rankings implied.');
