const assert=require('assert/strict'),fs=require('fs'),os=require('os'),path=require('path');
const {collectPublicReports,writePublicCatalog}=require('../tools/Build-PublicReportCatalog.cjs');
const {extractReportCodes,readReportPages}=require('../tools/saved-report-pages.cjs');
assert.deepEqual(extractReportCodes(`<a href='/reports/PublicReport0001?fight=1'>one</a><a href="https://forever.warcraftlogs.com/reports/PublicReport0001">duplicate</a><a href="https://example.com/reports/PublicReport0002">foreign</a><script>/reports/PublicReport0003</script>`),['PublicReport0001'],'Only valid Forever report hyperlinks, deduplicated; never execute saved scripts');
const pageTemp=fs.mkdtempSync(path.join(os.tmpdir(),'saved-report-pages-'));try{fs.writeFileSync(path.join(pageTemp,'dungeon.html'),`<a href='/reports/PublicReport0001'>run</a>`);assert.deepEqual(readReportPages(pageTemp),{codes:['PublicReport0001'],pages:1});fs.writeFileSync(path.join(pageTemp,'next.html'),`<a href='/reports/PublicReport0002'>run</a>`);assert.equal(readReportPages(pageTemp).codes.length,2);}finally{fs.rmSync(pageTemp,{recursive:true,force:true});}
assert.throws(()=>writePublicCatalog({examples:[],scan:{reports:0,rankedCandidates:0},notes:['Fixture authentication failure']},'unused'),/Examined 0 reports; scored 0 candidates\.[\s\S]*Fixture authentication failure/,'Empty scans must explain the actual failure before preserving the catalog');
const {toLua}=require('../tools/foreverlogs-review.cjs');
const {dungeons,resolveDungeon}=require('../tools/forever-dungeons.cjs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const specs={Druid:['Balance','Feral','Restoration'],Hunter:['Beast Mastery','Marksmanship','Survival'],Mage:['Arcane','Fire','Frost'],Paladin:['Holy','Protection','Retribution'],Priest:['Discipline','Holy','Shadow'],Rogue:['Assassination','Combat','Subtlety'],Shaman:['Elemental','Enhancement','Restoration'],Warlock:['Affliction','Demonology','Destruction'],Warrior:['Arms','Fury','Protection']};
const actors=[];for(const [subType,values]of Object.entries(specs))for(const spec of values)actors.push({id:actors.length+1,name:'Fixture '+subType+' '+spec,type:'Player',subType,spec});
function report(code){return {code,startTime:1793900000000,zone:{id:3000},masterData:{gameVersion:7,actors,abilities:[{gameID:101,name:'Fixture spell'},{gameID:102,name:'Fixture buff'}]},
 fights:[1,2].map(id=>({id,name:id===1?'Ruins of Lordaeron':'Shadowfang Keep',encounterID:100+id,gameZone:{id:200+id,name:id===1?'Ruins of Lordaeron':'Shadowfang Keep'},difficulty:10,startTime:0,endTime:60000,kill:true,inProgress:false,friendlyPlayers:actors.map(a=>a.id),friendlySpecs:actors.map(a=>a.spec),dungeonPulls:[{id:1,encounterID:0,name:'Trash',startTime:0,endTime:20000,kill:true},{id:2,encounterID:900+id,name:'Fixture Boss '+id,startTime:21000,endTime:60000,kill:true}]}))};}
async function main(){
 assert.equal(dungeons.length,35);assert.equal(new Set(dungeons.map(d=>d.key)).size,35);
 for(const dungeon of dungeons)for(const name of [dungeon.name,...dungeon.aliases])assert.equal(resolveDungeon(name,'Fixture boss')?.key,dungeon.key);
 assert.equal(resolveDungeon('Scarlet Monastery','Library')?.key,'scarlet-monastery-library');
 assert.equal(resolveDungeon('Dire Maul','West')?.key,'dire-maul-west');
 assert.equal(resolveDungeon('Stratholme','Undead')?.key,'stratholme-undead');
 assert.equal(resolveDungeon('Scarlet Monastery','Fixture boss'),null,'Never guess a wing from an ambiguous parent name');
 assert.equal(resolveDungeon('Molten Core','Fixture boss'),null,'Raids are outside the current supported scope');
 let streams=0;
 const client={report:async code=>report(code),events:async(code,fight)=>{streams++;return {complete:true,events:actors.flatMap(a=>[
  ...[1000,2000,3000,4000,22000,23000,24000,25000].flatMap((timestamp,i)=>[{timestamp,type:'cast',sourceID:a.id,abilityGameID:i%2?102:101},{timestamp:timestamp+10,type:'damage',sourceID:a.id,abilityGameID:i%2?102:101}]),
  {timestamp:4000,type:'applybuff',sourceID:a.id,targetID:a.id,abilityGameID:102},
  {timestamp:5000,type:'useitem',sourceID:a.id,itemID:900,itemName:'Fixture item'},
 ])};},observedPlayers:async(code,fight,metric)=>actors.map(a=>({id:a.id,role:['Holy','Restoration','Discipline'].includes(a.spec)?'healer':a.spec==='Protection'?'tank':'dps',total:(metric==='hps'?600:1200)*(code==='PublicReport0002'?2:1)}))};
 const catalog=await collectPublicReports({reports:['PublicReport0001','PublicReport0002'],client});
 assert.equal(catalog.examples.length,54,'Highest-output class/spec/role run in each supplied dungeon');
 assert.equal(streams,2,'Download winner streams once per segment, not every losing candidate');
 assert(catalog.examples.every(e=>e.code==='PublicReport0002'),'Rank by actual output, not report order or cast count');
 assert.equal(new Set(catalog.examples.map(e=>e.class+e.spec)).size,27);
 assert(catalog.examples.some(e=>e.role==='healer'&&e.metric==='hps')&&catalog.examples.some(e=>e.role==='tank'&&e.metric==='dps'));
 assert(catalog.examples.every(e=>e.scenario.items[0].itemID===900&&e.rotations.length===2));
 assert(catalog.examples.every(e=>e.kill&&e.complete&&e.spellCountsComplete&&e.rankingScope==='dungeon'));
 assert(catalog.examples.every(e=>['ruins-of-lordaeron','shadowfang-keep'].includes(e.dungeonKey)));
 let unsupportedEvents=0;
 const raids=await collectPublicReports({reports:['PublicReport0001'],client:{...client,
  report:async code=>{const r=report(code);return {...r,fights:r.fights.map(f=>({...f,name:'Fixture raid boss',gameZone:{id:999,name:'Molten Core'}}))};},
  events:async()=>{unsupportedEvents++;throw Error('Must not retrieve raid events');},
 }});
 assert.equal(raids.examples.length,0);assert.equal(unsupportedEvents,0);assert(raids.notes.some(n=>n.includes('outside the current scope')));
 const missingRoles=await collectPublicReports({reports:['PublicReport0001'],client:{...client,observedPlayers:async()=>{throw Error('fixture output unavailable');}}});
 assert.equal(missingRoles.examples.length,0,'Unknown output cannot be labeled a top performer');
 assert(missingRoles.notes.some(n=>n.includes('output')));
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
 run('unpack=unpack or table.unpack');
 for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/SpecScenarios.lua','addons/ForeverCoaching/Data/SupportedDungeons.lua','addons/ForeverCoaching/Data/PublicReportCatalog.lua','addons/ForeverCoaching/Core/WarcraftLogs.lua','addons/ForeverCoaching/UI/GuideSelectors.lua','addons/ForeverCoaching/UI/ClassicTheme.lua','addons/ForeverCoaching/UI/WarcraftLogs.lua','addons/ForeverCoaching/UI/EncounterLearning.lua'])run(fs.readFileSync(file,'utf8'));
 run(`assert(#ForeverCoaching.WarcraftLogs:PublicExamples()>0,'Bundled real public excerpt must validate')`);
 run('TestCatalog='+toLua(catalog)+';ExpectedDungeons='+toLua(dungeons));
 const winner=structuredClone(catalog.examples.find(e=>e.class==='SHAMAN'&&e.spec==='Enhancement'&&e.dungeonKey==='ruins-of-lordaeron'));
 const lower=structuredClone(winner);winner.actorID=999;winner.scenario.sourceURL=winner.scenario.sourceURL.replace(/source=\d+$/,'source=999');winner.performance=200;winner.scenario.castCount=44;
 winner.rotations[0].steps=Array.from({length:40},(_,i)=>({spellID:i%2?102:101,name:i===39?'Tail combat action':'Full combat action '+i,at:i*.3,end:i*.3,count:1}));winner.rotations[0].combatCasts=40;winner.rotations[1].name='Winner boss';
 winner.rotations[0].damage=[{spellID:101,name:'Trash damage ability',amount:300}];
 winner.rotations[1].damage=[{spellID:101,name:'Boss damage ability',amount:15000},{spellID:6603,name:'Melee',amount:5000},...Array.from({length:7},(_,i)=>({spellID:200+i,name:i===0?'Blood Fury':i===1?'Solid Dynamite':'Fixture effect '+i,amount:0}))];
 winner.rotations[1].steps[0].name='Blood Fury';
 winner.rotations.push({...structuredClone(winner.rotations[0]),start:1,end:19,damage:[{spellID:101,name:'Trash damage ability',amount:200}]});
 run('LongCatalog='+toLua({schema:1,source:'Warcraft Logs',examples:[lower,winner]}));
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
assert(model.referenceOnly and model.ready and #model.specs==27 and #model.encounters==35)
assert(model.supportedDungeonCount==35 and model.coveredDungeonCount==2,'Supported scope is separate from supplied report coverage')
assert(model.status=='This is not a verified ranking across every log on Warcraft Logs.','Ready view shows only the ranking disclaimer, without scan statistics or technical status')
assert(model.selectedSpec=='SHAMAN:enhancement')
assert(model.nextFight==nil and model.rows[1].you==nil)
assert(model.rows[1].action=='Damage by ability','One compact damage section replaces technical run descriptions')
local foundBoss=false;for _,row in ipairs(model.rows)do if row.action:find('Fixture Boss',1,true)then foundBoss=true end end;assert(foundBoss)
for _,option in ipairs(model.encounters)do assert(not option.label:find('Fixture ',1,true),'Dropdown contains dungeons, never players')end
local parent=CreateFrame('Frame');parent:SetSize(800,440);parent:Show()
fc.testPanel=fc:BuildWarcraftLogsPanel(parent,728)
fc.RefreshCombatReview=function(self)self.testPanel.refresh()end
local function visible(text)for _,f in ipairs(TestFrames)do if f:IsShown() and f.text==text then return true end end end
assert(visible('ENCOUNTER') and visible('OBSERVED ROTATION'))
for _,label in ipairs({'YOU','NEXT FIGHT','DO NOT DISPLAY PERSONAL DATA','No matching fight','100-PARSE PLAYERS'})do assert(not visible(label),'Comparison UI must be paused: '..label)end
assert(fc.testPanel.status.text:find(w.publicNotice,1,true))
assert(w:SetPublicEncounter('dungeon:shadowfang-keep'))
assert(w:GetPublicReportModel().rows[1].action=='Damage by ability')
assert(not w:GetPublicReportModel().status:find('Fixture Shaman',1,true),'Player names are not displayed')
assert(w:SetPublicSpec('MAGE:fire'))
assert(fc.testPanel.model.selectedSpec=='MAGE:fire')
assert(w:SetPublicEncounter('dungeon:shapers-terrace'),'Missing-data dungeons remain selectable')
local pending=w:GetPublicReportModel()
assert(not pending.ready and pending.metrics:find("Shaper's Terrace",1,true) and pending.status:find('is supported',1,true))
assert(#pending.rows==0 and pending.scenario==nil,'A supported dungeon must not invent report examples')
assert(w:SetPublicSpec('SHAMAN:enhancement'))
assert(w:GetPublicReportModel().selectedEncounter=='dungeon:shapers-terrace','Preserve dungeon selection across spec changes')
assert(w:SetPublicEncounter('dungeon:shadowfang-keep'))
assert(not w:SetPublicEncounter('invented') and not w:SetPublicSpec('MAGE:invented'))
local sample=TestCatalog.examples[1];local original=sample.scenario.sourceURL
sample.scenario.sourceURL='https://example.com/fake';assert(not w:PreparePublicExample(sample));sample.scenario.sourceURL=original
sample.scenario.items[1].itemID=nil;assert(not w:PreparePublicExample(sample));sample.scenario.items[1].itemID=900
sample.scenario.casts[1].at=-1;assert(not w:PreparePublicExample(sample));sample.scenario.casts[1].at=1
local savedSpell=sample.rotations[1].opener[1].spellID
sample.rotations[1].opener[1].spellID=6603;assert(not w:PreparePublicExample(sample),'Reject automatic attacks in supplied rotation summaries');sample.rotations[1].opener[1].spellID=savedSpell
local savedEnd=sample.rotations[1]['end'];sample.rotations[1]['end']=sample.duration+1;assert(not w:PreparePublicExample(sample),'Reject summaries outside the recorded run');sample.rotations[1]['end']=savedEnd
sample.player='Fixture |cffff0000 markup';local clean=assert(w:PreparePublicExample(sample));assert(clean.player:find('||c',1,true))
local partial={schema=1,source='Warcraft Logs',examples={}}
for _,e in ipairs(TestCatalog.examples)do if not (e.class=='SHAMAN' and e.spec=='Enhancement' and e.dungeonKey=='shadowfang-keep')then partial.examples[#partial.examples+1]=e end end
fc.PublicReportCatalog=partial;assert(w:SetPublicSpec('SHAMAN:enhancement'));assert(w:SetPublicEncounter('dungeon:shadowfang-keep'))
assert(w:GetPublicReportModel().status:find('other specs',1,true),'Distinguish other-spec reports from missing dungeon data')
local otherLabel=false;for _,option in ipairs(w:GetPublicReportModel().encounters)do if option.value=='dungeon:shadowfang-keep'then otherLabel=option.label:find('other specs available',1,true)end end;assert(otherLabel)
fc.PublicReportCatalog=LongCatalog;assert(w:SetPublicSpec('SHAMAN:enhancement'));assert(w:SetPublicEncounter('dungeon:ruins-of-lordaeron'))
local full=w:GetPublicReportModel();assert(full.rows[1].meter[1].amount==500,'Choose highest output, not first stored example')
local page=fc:BuildOptimizationPage(parent)
fc.RefreshCombatReview=function(self)self.testPanel.refresh();if self.optimizationView and self.optimizationView.parent:IsShown()then self.optimizationView.refresh()end end
assert(page.document and page.specPicker and page.dungeonPicker and page.sectionPicker,'Use the shared Learn/Scenarios document layout with three direct selectors')
assert(#page.model.sections==2 and page.model.selectedSection=='trash','Trash and each named boss are separate selectable sections')
for _,row in ipairs(page.model.rows)do assert(not row.action:find('Winner boss',1,true),'Trash view must not dump boss casts')end
assert(w:SetPublicSection('boss:winner boss'))
assert(page.model.sectionLabel=='Winner boss')
local bossAbility,meterCount=false,0;for _,row in ipairs(page.model.rows)do if row.meter then meterCount=meterCount+1;bossAbility=row.meter[1].amount==15000 and row.meter[1].share==75 and row.meter[1].value:find('15.0k dmg - 385 DPS',1,true);assert(#row.meter==9,'A ninth ability remains in the same meter');assert(row.reference:find('Blood Fury [Racial]',1,true) and row.reference:find('Solid Dynamite [Profession / item]',1,true),'Optional contributions have bracket labels')else assert(not row.reference:find('Blood Fury',1,true),'Racial casts are hidden from existing catalog timelines')end;assert(not row.reference:find('Trash damage ability',1,true),'Boss damage excludes trash')end;assert(bossAbility and meterCount==1,'One boss meter shows abbreviated damage, encounter DPS and percentages')
for _,row in ipairs(page.model.rows)do assert(not row.action:find('Trash mobs',1,true),'Boss view must not dump trash casts')end
assert(not w:SetPublicSection('boss:invented'),'Reject missing encounters')
assert(w:SetPublicSection('trash'))
assert(#page.model.rows==1 and page.model.rows[1].meter[1].amount==500 and page.model.rows[1].meter[1].dps==25,'One meter aggregates trash damage with DPS over the union of pull durations')
assert(page.document.groups[1].heading.text=='Overall damage and DPS' and page.document.groups[1].body.text=='500 dmg - 25 DPS','Show encounter totals above the ability meter')
assert(page.document.groups[2].meterRows[1]:IsShown(),'Render damage as compact meter bars')
assert(w:SetPublicEncounter('dungeon:shapers-terrace'))
assert(#page.model.rows==0 and page.model.selectedSection==nil,'Dungeon changes clear stale encounter content')
assert(w:SetPublicSpec('SHAMAN:enhancement') and w:SetPublicEncounter('dungeon:ruins-of-lordaeron'))
local tail,boss=false,false
for _,row in ipairs(full.rows)do if row.reference:find('Tail combat action',1,true)then tail=true end;if row.action=='Winner boss'then boss=true end;assert(not row.action:find('Fixture Boss',1,true),'Do not fill another encounter using the lower-ranked player')end
assert(not tail and boss and #full.rows==3,'Keep bosses separate and summarize trash once')
local count=LongCatalog.examples[2].rotations[1].steps[1].count;LongCatalog.examples[2].rotations[1].steps[1].count=2;assert(not w:PreparePublicExample(LongCatalog.examples[2]),'Reject truncated/mismatched full sequence accounting');LongCatalog.examples[2].rotations[1].steps[1].count=count
fc.PublicReportCatalog={schema=1,source='Warcraft Logs',examples={}}
fc:RefreshCombatReview()
assert(not fc.testPanel.model.ready and #fc.testPanel.model.rows==0)
assert(fc.testPanel.status.text:find(w.publicNotice,1,true),'Disclaimer persists for empty data')
assert(not visible('ENCOUNTER'),'Clear stale rotations when catalog becomes empty')
`);
 lua.lua_close(L);
 const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'fc-public-test-'));
 try{const file=path.join(tmp,'catalog.lua');writePublicCatalog(catalog,file);const contents=fs.readFileSync(file,'utf8');assert(contents.includes('PublicReportCatalog')&&!contents.includes('CompanionReviews')&&!contents.includes('access_token'));assert.throws(()=>writePublicCatalog({examples:[]},file));assert.equal(fs.readFileSync(file,'utf8'),contents);}finally{fs.rmSync(tmp,{recursive:true,force:true});}
 console.log('PASS: public examples for all 27 specs/nine classes and every supplied dungeon, independent player/run selection, recorded spells/items/timing, partial-run labels, no personal comparisons, persistent testing/discretion notice, source validation and safe catalog output. Synthetic coverage fixtures; bundled example is separately sourced from a retrieved public report.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
