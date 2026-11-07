const assert=require('assert/strict'),fs=require('fs'),os=require('os'),path=require('path');
const {reportCode,createClient,profile,compare,encodeReview}=require('../tools/warcraftlogs-client.cjs');
const {collect}=require('../tools/Review-WarcraftLogs.cjs');
const actor={id:1,name:'Tester',server:'Test Realm',subType:'Shaman',type:'Player'};
const fight={id:1,name:'Test Boss',encounterID:7,difficulty:3,gameZone:{id:33,name:'Test Dungeon'},startTime:0,endTime:60000,kill:true,friendlyPlayers:[1],friendlySpecs:['Enhancement']};
const report={code:'AbCdEfGh12345678',startTime:1793900000000,zone:{id:100},masterData:{gameVersion:16,actors:[actor],abilities:[{gameID:403,name:'Lightning Bolt'},{gameID:99,name:'Boss hit'}]},fights:[fight]};
const stream={complete:true,events:[{timestamp:1000,type:'cast',sourceID:1,abilityGameID:403},{timestamp:29000,type:'damage',targetID:1,sourceID:2,abilityGameID:99,amount:100},{timestamp:30000,type:'death',targetID:1,sourceID:2},{timestamp:32000,type:'death',targetID:2,sourceID:1}]};
const target=profile(report,fight,actor,stream);
const references=Array.from({length:3},(_,i)=>{const peer={...actor,name:'Peer'+i};const r=profile({...report,code:'RefCode0000000'+String(i).padStart(2,'0'),masterData:{...report.masterData,actors:[peer]}},fight,peer,{complete:true,events:[1000,11000,21000,31000].map(timestamp=>({timestamp,type:'cast',sourceID:1,abilityGameID:403}))});r.percentile=100;return r;});
const aliveStream={complete:true,events:stream.events.filter(e=>e.type!=='death')};
const alive=profile(report,fight,actor,aliveStream);
const analysis=compare(alive,references),code=encodeReview(alive,analysis);
assert.equal(reportCode('https://forever.warcraftlogs.com/reports/'+report.code+'#fight=1'),report.code);
assert.throws(()=>reportCode('https://evil.test/reports/'+report.code));
assert.match(analysis.improve,/Lightning Bolt: 1.0 casts\/min versus 4.0/);
assert.match(compare(target,references).observations,/Death at 30.0s/);assert.doesNotMatch(compare(target,references).observations,/32.0s/);
assert.doesNotMatch(compare(target,references).improve,/casts\/min/,'Do not grade a death-shortened rotation as low cast frequency');
assert.match(analysis.coverage,/3 compatible verified/);
assert.doesNotMatch(compare({...target,complete:false},references).improve,/casts\/min/);
assert.doesNotMatch(compare({...target,fight:{...fight,kill:false}},references).improve,/casts\/min/);
assert.doesNotMatch(compare(alive,references.map(r=>({...r,percentile:94.99}))).improve,/casts\/min/);
assert.doesNotMatch(compare(alive,references.map(r=>({...r,percentile:99.99}))).improve,/casts\/min/,'Do not round a non-100 parse into the reference set');
assert.throws(()=>compare(alive,references,{minPercentile:95}),/100-percentile/);
assert.doesNotMatch(compare(target,references.map(r=>({...r,spec:'Elemental'}))).improve,/casts\/min/);
assert.doesNotMatch(compare(target,references.slice(0,2)).improve,/casts\/min/);
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code){if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));
run(fs.readFileSync('addons/ForeverCoaching/Core/CombatReview.lua','utf8'));
run(fs.readFileSync('addons/ForeverCoaching/Core/WarcraftLogs.lua','utf8'));
run(`UnitName=function()return 'Tester' end;GetRealmName=function()return 'Test Realm' end
UnitClass=function()return 'Shaman','SHAMAN' end;UnitGUID=function()return 'Player-test' end
UnitAffectingCombat=function()return false end
local w=ForeverCoaching.WarcraftLogs
assert(not w:SetLogging(true),'Missing logging API is handled')
local logging=false;LoggingCombat=function(value)if value~=nil then logging=value end;return logging end
assert(w:SetLogging(true) and w:GetLogging());assert(w:SetLogging(false) and not w:GetLogging())
assert(w:Import(${JSON.stringify(code)}))
assert(ForeverCoaching.CombatReview:GetSource()=='warcraftlogs')
local summary=ForeverCoaching.CombatReview:GetLatestSummary()
assert(summary.metrics:find('Test Boss',1,true) and summary.improveText:find('casts/min',1,true))
assert(#w:GetReviews()==1);assert(w:Import(${JSON.stringify(code)}));assert(#w:GetReviews()==1,'Duplicate import replaces')
assert(not w:Import('https://forever.warcraftlogs.com'))
assert(not w:Import('return function() end'))
assert(not w:Import(string.rep('a',60001)))
assert(not w:Import(${JSON.stringify(code.replace('Tester','Other'))}))
assert(not w:Import(${JSON.stringify(code.replace('Test%20Realm','OtherRealm'))}))
assert(not w:Import(${JSON.stringify(code.replace('|60000|','|bad|'))}))
assert(not w:Import(${JSON.stringify(code.replace('Tester','%ZZ'))}))
UnitAffectingCombat=function()return true end;assert(not w:Import(${JSON.stringify(code)}))
UnitAffectingCombat=function()return false end
UnitGUID=function()return 'Player-other' end;assert(#w:GetReviews()==0,'Other characters do not see the import')
UnitGUID=function()return 'Player-test' end
local listener;for _,frame in ipairs(TestFrames)do if frame.events.PLAYER_REGEN_DISABLED then listener=frame end end
ForeverCoachingDB.combatAnalysisReady=false
listener.scripts.OnEvent(listener,'PLAYER_REGEN_DISABLED');listener.scripts.OnEvent(listener,'PLAYER_REGEN_ENABLED')
for _,callback in ipairs(TestTimers)do callback()end
assert(ForeverCoaching.CombatReview:GetSource()=='warcraftlogs','Local recording must not replace the Warcraft Logs access page')
assert(not ForeverCoachingDB.combatAnalysisReady,'A local recording must not announce new Warcraft Logs analysis')`);
for(const file of ['addons/ForeverCoaching/UI/ClassicTheme.lua','addons/ForeverCoaching/UI/GuideSelectors.lua','addons/ForeverCoaching/Data/SpecScenarios.lua','addons/ForeverCoaching/UI/WarcraftLogs.lua'])run(fs.readFileSync(file,'utf8'));
run(`local parent=CreateFrame('Frame');local panel=ForeverCoaching:BuildWarcraftLogsPanel(parent,728)
assert(panel.frame.parent==parent and panel.height==120,'Missing comparisons show one compact state')
assert(panel.specPicker and panel.encounterPicker,'Only spec and encounter selection are needed')
assert(not panel.url and not panel.saveButton and not panel.input and not panel.importButton,'The player page must not require links, scripts or imports')
assert(not ForeverCoachingWarcraftLogs and not ForeverCoaching.OpenWarcraftLogs,'No separate popup remains')
assert(not ForeverCoaching.WarcraftLogs:SaveReportURL('https://unrelated.test/reports/AbCdEfGh12345678'),'Legacy link storage remains provider-bound')
local reportURL='https://forever.warcraftlogs.com/reports/AbCdEfGh12345678#fight=1'
assert(ForeverCoaching.WarcraftLogs:SaveReportURL(reportURL))
assert(ForeverCoaching.WarcraftLogs:GetReportURL()==reportURL,'Save report access per character')
UnitGUID=function()return 'Player-another'end
assert(ForeverCoaching.WarcraftLogs:GetReportURL()==ForeverCoaching.WarcraftLogs.url,'Do not show another character report link')
UnitGUID=function()return 'Player-test'end
assert(ForeverCoaching.WarcraftLogs:GetReferenceURL(),'Expose a supplied 100-parse reference link')
local entry=ForeverCoachingDB.warcraftLogs.reviews[1];local references=entry.references
entry.references=references:gsub('100 percentile','99.99 percentile')
assert(not ForeverCoaching.WarcraftLogs:GetReferenceURL(),'Lower-percentile references must not be labeled 100 parses')
assert(ForeverCoaching.WarcraftLogs:GetSummary().wrongText:find('withheld',1,true),'Do not render old 95/99 comparisons as 100-parse findings')
entry.references=references
assert(ForeverCoaching.WarcraftLogs:SaveReportURL('https://forever.warcraftlogs.com/reports/NewReport0000001#fight=2'))
assert(ForeverCoaching.WarcraftLogs:GetSummary().metrics=='Warcraft Logs / Report access','A new bookmark must not display another report comparison')
assert(not ForeverCoaching.WarcraftLogs:GetReferenceURL(),'A new report must not inherit old reference links')
assert(ForeverCoaching.WarcraftLogs:SaveReportURL('https://forever.warcraftlogs.com/reports/AbCdEfGh12345678#fight=last'))
assert(ForeverCoaching.WarcraftLogs:GetSummary().metrics=='Warcraft Logs / Report access','Do not guess which fight a dynamic website link currently resolves to')
assert(ForeverCoaching.WarcraftLogs:SaveReportURL(reportURL))
assert(parent:IsShown(),'Importing must leave the review page visible')`);
lua.lua_close(L);
async function main(){
 let calls=[];
 const client=createClient({accessToken:'fixture-only',fetcher:async(url,options)=>{
  const body=JSON.parse(options.body);calls.push({url,body});
  let data;if(body.query.includes('masterData'))data={reportData:{report}};
  else data={reportData:{report:{events:{data:stream.events,nextPageTimestamp:null}}}};
  return {ok:true,text:async()=>JSON.stringify({data})};
 }});
 assert.equal((await client.report(report.code)).code,report.code);
 assert.equal((await client.events(report.code,fight)).complete,true);
 assert(calls.every(c=>c.url==='https://forever.warcraftlogs.com/api/v2/client'));
 assert.equal(calls[1].body.variables.fight,1);
 const bad=createClient({accessToken:'fixture',fetcher:async()=>({ok:true,text:async()=>JSON.stringify({data:{reportData:{report:{events:{data:[],nextPageTimestamp:0}}}}})})});
 await assert.rejects(()=>bad.events(report.code,fight),/pagination/);
 await assert.rejects(()=>createClient({accessToken:'fixture',fetcher:async()=>({ok:false,status:429})}).report(report.code),/rate limit/);
 const partial=createClient({accessToken:'fixture',fetcher:async()=>({ok:true,text:async()=>JSON.stringify({data:{reportData:{report:{events:{data:[],nextPageTimestamp:10}}}}})})});
 assert.equal((await partial.events(report.code,fight,1)).complete,false);
 const output=fs.mkdtempSync(path.join(os.tmpdir(),'fc-wcl-tests-'));
 try{const rows=await collect({report:report.code,player:'Tester',realm:'Test Realm',output,client:{report:async()=>({...report,fights:[fight,{...fight,id:2,kill:false},{...fight,id:3,inProgress:true}]}),events:async()=>stream}});
 assert.equal(rows.length,2);assert(fs.existsSync(path.join(output,report.code+'-2.fcwcl.txt')));
 assert(!fs.readFileSync(path.join(output,'reviews.json'),'utf8').includes('fixture-only'));
 const singleRealmClient={report:async()=>({...report,masterData:{...report.masterData,actors:report.masterData.actors.map(a=>({...a,server:undefined}))}}),events:async()=>stream};
 assert.equal((await collect({report:report.code,player:'Tester',sourceID:1,output:null,client:singleRealmClient})).length,1,'Forever characters need no realm input or exposed realm metadata');
 await assert.rejects(()=>collect({report:report.code,player:'Tester',sourceID:2,output:null,client:singleRealmClient}),/exactly one/,'Never silently choose another source');
 const ambiguousClient={...singleRealmClient,report:async()=>({...report,masterData:{...report.masterData,actors:[...report.masterData.actors,{...report.masterData.actors.find(a=>a.type==='Player'),id:99}]}})};
 await assert.rejects(()=>collect({report:report.code,player:'Tester',output:null,client:ambiguousClient}),/exactly one/,'Duplicate names require a report source');
 const ranked=await collect({report:report.code,player:'Tester',realm:'Test Realm',partition:1,output,client:{
  report:async code=>code===report.code?report:references.find(r=>r.report.code===code).report,
  events:async code=>code===report.code?aliveStream:{complete:true,events:[1000,11000,21000,31000].map(timestamp=>({timestamp,type:'cast',sourceID:1,abilityGameID:403}))},
  topRanks:async()=>references.map(r=>({name:r.actor.name,report:{code:r.report.code,fightID:1}})),
  percentile:async()=>100
 }});
 assert.match(ranked[0].analysis.coverage,/3 compatible verified/);
 assert.match(ranked[0].analysis.improve,/casts\/min/);
 assert.match(ranked[0].analysis.references,/100 percentile/,'Only verified exact 100 parses qualify');
 }finally{fs.rmSync(output,{recursive:true,force:true});}
 console.log('PASS: WCL API pagination/errors, independent high-percentile peer coaching, death opportunity limits, all report attempts, safe character-bound import, logging controls, UI and fresh local review selection. Simulated fixtures only.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
