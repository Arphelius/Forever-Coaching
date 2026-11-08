const assert=require('assert/strict'),fs=require('fs'),os=require('os'),path=require('path');
const {collectPublicReports,writePublicCatalog}=require('../tools/Build-PublicReportCatalog.cjs');
const {toLua}=require('../tools/foreverlogs-review.cjs');
const {dungeons,resolveDungeon}=require('../tools/forever-dungeons.cjs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const specs={Druid:['Balance','Feral','Restoration'],Hunter:['Beast Mastery','Marksmanship','Survival'],Mage:['Arcane','Fire','Frost'],Paladin:['Holy','Protection','Retribution'],Priest:['Discipline','Holy','Shadow'],Rogue:['Assassination','Combat','Subtlety'],Shaman:['Elemental','Enhancement','Restoration'],Warlock:['Affliction','Demonology','Destruction'],Warrior:['Arms','Fury','Protection']};
const actors=[];for(const [subType,values]of Object.entries(specs))for(const spec of values)actors.push({id:actors.length+1,name:'Fixture '+subType+' '+spec,type:'Player',subType,spec});
function report(code){return {code,startTime:1793900000000,zone:{id:3000},masterData:{gameVersion:7,actors,abilities:[{gameID:101,name:'Fixture spell'},{gameID:102,name:'Fixture buff'}]},
 fights:[1,2].map(id=>({id,name:id===1?'Ruins of Lordaeron':'Shadowfang Keep',encounterID:100+id,gameZone:{id:200+id,name:id===1?'Ruins of Lordaeron':'Shadowfang Keep'},difficulty:10,startTime:0,endTime:60000,kill:id===1,inProgress:false,friendlyPlayers:actors.map(a=>a.id),friendlySpecs:actors.map(a=>a.spec)}))};}
async function main(){
 assert.equal(dungeons.length,35);assert.equal(new Set(dungeons.map(d=>d.key)).size,35);
 for(const dungeon of dungeons)for(const name of [dungeon.name,...dungeon.aliases])assert.equal(resolveDungeon(name,'Fixture boss')?.key,dungeon.key);
 assert.equal(resolveDungeon('Scarlet Monastery','Library')?.key,'scarlet-monastery-library');
 assert.equal(resolveDungeon('Dire Maul','West')?.key,'dire-maul-west');
 assert.equal(resolveDungeon('Stratholme','Undead')?.key,'stratholme-undead');
 assert.equal(resolveDungeon('Scarlet Monastery','Fixture boss'),null,'Never guess a wing from an ambiguous parent name');
 assert.equal(resolveDungeon('Molten Core','Fixture boss'),null,'Raids are outside the current supported scope');
 let streams=0;
 const client={report:async code=>report(code),events:async(code,fight)=>{streams++;return {complete:fight.id===1,events:actors.flatMap(a=>[
  {timestamp:1000,type:'cast',sourceID:a.id,abilityGameID:101},{timestamp:3000,type:'cast',sourceID:a.id,abilityGameID:101},
  {timestamp:4000,type:'applybuff',sourceID:a.id,targetID:a.id,abilityGameID:102},
  {timestamp:5000,type:'useitem',sourceID:a.id,itemID:900,itemName:'Fixture item'},
 ])};},observedPlayers:async(code,fight,metric)=>actors.map(a=>({id:a.id,role:['Holy','Restoration','Discipline'].includes(a.spec)?'healer':a.spec==='Protection'?'tank':'dps',total:metric==='hps'?600:1200}))};
 const catalog=await collectPublicReports({reports:['PublicReport0001','PublicReport0002'],client});
 assert.equal(catalog.examples.length,108,'Every player/spec in every supplied dungeon segment, including unsuccessful attempts');
 assert.equal(streams,4,'One event download per report/segment, shared across players');
 assert.equal(new Set(catalog.examples.map(e=>e.class+e.spec)).size,27);
 assert(catalog.examples.some(e=>e.role==='healer'&&e.metric==='hps')&&catalog.examples.some(e=>e.role==='tank'&&e.metric==='dps'));
 assert(catalog.examples.every(e=>e.scenario.items[0].itemID===900&&e.spells[0].count===2));
 assert(catalog.examples.some(e=>!e.kill&&!e.complete&&!e.spellCountsComplete));
 assert(catalog.examples.every(e=>['ruins-of-lordaeron','shadowfang-keep'].includes(e.dungeonKey)));
 let unsupportedEvents=0;
 const raids=await collectPublicReports({reports:['PublicReport0001'],client:{...client,
  report:async code=>{const r=report(code);return {...r,fights:r.fights.map(f=>({...f,name:'Fixture raid boss',gameZone:{id:999,name:'Molten Core'}}))};},
  events:async()=>{unsupportedEvents++;throw Error('Must not retrieve raid events');},
 }});
 assert.equal(raids.examples.length,0);assert.equal(unsupportedEvents,0);assert(raids.notes.some(n=>n.includes('outside the current scope')));
 const missingRoles=await collectPublicReports({reports:['PublicReport0001'],client:{...client,observedPlayers:async()=>{throw Error('fixture output unavailable');}}});
 assert.equal(missingRoles.examples.length,54,'Missing output tables must not hide recorded specs/actions');
 assert(missingRoles.examples.every(e=>e.role==='unknown'&&e.performance===undefined));
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
 run('unpack=unpack or table.unpack');
 for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/SpecScenarios.lua','addons/ForeverCoaching/Data/SupportedDungeons.lua','addons/ForeverCoaching/Data/PublicReportCatalog.lua','addons/ForeverCoaching/Core/WarcraftLogs.lua','addons/ForeverCoaching/UI/GuideSelectors.lua','addons/ForeverCoaching/UI/ClassicTheme.lua','addons/ForeverCoaching/UI/WarcraftLogs.lua','addons/ForeverCoaching/UI/EncounterLearning.lua'])run(fs.readFileSync(file,'utf8'));
 run(`assert(#ForeverCoaching.WarcraftLogs:PublicExamples()>0,'Bundled real public excerpt must validate')`);
 run('TestCatalog='+toLua(catalog)+';ExpectedDungeons='+toLua(dungeons));
 run(`
local fc=ForeverCoaching;local w=fc.WarcraftLogs
assert(#fc.SupportedDungeons==35)
for i,dungeon in ipairs(ExpectedDungeons)do assert(fc.SupportedDungeons[i].key==dungeon.key and fc.SupportedDungeons[i].name==dungeon.name,'Shared JS/Lua roster parity');assert(w:ResolvePublicDungeon(dungeon.name,'Fixture boss').key==dungeon.key);for j,alias in ipairs(dungeon.aliases)do assert(fc.SupportedDungeons[i].aliases[j]==alias and w:ResolvePublicDungeon(alias,'Fixture boss').key==dungeon.key)end end
assert(w:ResolvePublicDungeon('Scarlet Monastery','Library').key=='scarlet-monastery-library')
assert(not w:ResolvePublicDungeon('Dire Maul','Fixture boss') and not w:ResolvePublicDungeon('Molten Core','Fixture boss'))
fc.EncounterCoach={GetCombatContext=function()return {class='SHAMAN',tree=2}end}
fc.PublicReportCatalog=TestCatalog
ForeverCoachingDB.warcraftLogs={reviews={{comparison={specKey='SHAMAN:enhancement',rows={{you='DO NOT DISPLAY PERSONAL DATA'}}}}}}
w.GetComparisonModel=function()error('Personal comparisons must not be queried by normal pages')end
assert(w:LoadCompanionReviews()==0,'Automatic personal comparisons are paused')
local model=w:GetPublicReportModel()
assert(model.referenceOnly and model.ready and #model.specs==27 and #model.encounters==37)
assert(model.supportedDungeonCount==35 and model.coveredDungeonCount==2,'Supported scope is separate from supplied report coverage')
assert(model.selectedSpec=='SHAMAN:enhancement')
assert(model.nextFight==nil and model.rows[1].you==nil)
assert(model.rows[1].reference:find('2 uses / 2.0 casts/min',1,true))
local parent=CreateFrame('Frame');parent:SetSize(800,440);parent:Show()
fc.testPanel=fc:BuildWarcraftLogsPanel(parent,728)
fc:BuildEncounterLearningPage(parent,'Scenarios')
fc.RefreshCombatReview=function(self)self.testPanel.refresh();self:RefreshParserScenarios()end
local function visible(text)for _,f in ipairs(TestFrames)do if f:IsShown() and f.text==text then return true end end end
assert(visible('RECORDED SPELL') and visible('RECORDED USES'))
for _,label in ipairs({'YOU','NEXT FIGHT','DO NOT DISPLAY PERSONAL DATA','No matching fight','100-PARSE PLAYERS'})do assert(not visible(label),'Comparison UI must be paused: '..label)end
assert(fc.testPanel.status.text:find(w.publicNotice,1,true))
assert(visible(w.publicNotice),'Scenarios always displays the ongoing logging/testing/discretion notice')
assert(w:SetPublicEncounter('PublicReport0001:2:20'))
assert(w:GetPublicReportModel().status:find('Attempt ended without a kill',1,true))
assert(w:GetPublicReportModel().status:find('Partial event stream',1,true))
assert(w:GetPublicReportModel().rows[1].reference=='2 uses in recorded excerpt','Do not extrapolate partial cast rates')
assert(w:SetPublicSpec('MAGE:fire'))
assert(w:GetPublicReportModel().metrics:find('Fire',1,true) and fc.testPanel.model.selectedSpec=='MAGE:fire')
assert(w:SetPublicEncounter('dungeon:shapers-terrace'),'Missing-data dungeons remain selectable')
local pending=w:GetPublicReportModel()
assert(not pending.ready and pending.metrics:find("Shaper's Terrace",1,true) and pending.status:find('is supported',1,true))
assert(#pending.rows==0 and pending.scenario==nil,'A supported dungeon must not invent report examples')
assert(w:SetPublicSpec('SHAMAN:enhancement'))
assert(w:GetPublicReportModel().selectedEncounter=='dungeon:shapers-terrace','Preserve dungeon selection across spec changes')
assert(w:SetPublicEncounter('PublicReport0001:2:20'))
assert(not w:SetPublicEncounter('invented') and not w:SetPublicSpec('MAGE:invented'))
local sample=TestCatalog.examples[1];local original=sample.scenario.sourceURL
sample.scenario.sourceURL='https://example.com/fake';assert(not w:PreparePublicExample(sample));sample.scenario.sourceURL=original
sample.scenario.items[1].itemID=nil;assert(not w:PreparePublicExample(sample));sample.scenario.items[1].itemID=900
sample.scenario.casts[1].at=-1;assert(not w:PreparePublicExample(sample));sample.scenario.casts[1].at=1
sample.player='Fixture |cffff0000 markup';local clean=assert(w:PreparePublicExample(sample));assert(clean.player:find('||c',1,true))
fc.PublicReportCatalog={schema=1,source='Warcraft Logs',examples={}}
fc:RefreshCombatReview()
assert(not fc.testPanel.model.ready and #fc.testPanel.model.rows==0)
assert(fc.testPanel.status.text:find(w.publicNotice,1,true),'Disclaimer persists for empty data')
assert(not visible('RECORDED SPELL'),'Clear stale examples when catalog becomes empty')
`);
 lua.lua_close(L);
 const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'fc-public-test-'));
 try{const file=path.join(tmp,'catalog.lua');writePublicCatalog(catalog,file);const contents=fs.readFileSync(file,'utf8');assert(contents.includes('PublicReportCatalog')&&!contents.includes('CompanionReviews')&&!contents.includes('access_token'));assert.throws(()=>writePublicCatalog({examples:[]},file));assert.equal(fs.readFileSync(file,'utf8'),contents);}finally{fs.rmSync(tmp,{recursive:true,force:true});}
 console.log('PASS: public examples for all 27 specs/nine classes and every supplied dungeon, independent player/run selection, recorded spells/items/timing, partial-run labels, no personal comparisons, persistent testing/discretion notice, source validation and safe catalog output. Synthetic coverage fixtures; bundled example is separately sourced from a retrieved public report.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
