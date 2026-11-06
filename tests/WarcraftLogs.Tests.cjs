const assert=require('assert/strict'),fs=require('fs'),os=require('os'),path=require('path');
const {reportCode,createClient,profile,compare,encodeReview}=require('../tools/warcraftlogs-client.cjs');
const {collect}=require('../tools/Review-WarcraftLogs.cjs');
const actor={id:1,name:'Tester',server:'Test Realm',subType:'Shaman',type:'Player'};
const fight={id:1,name:'Test Boss',encounterID:7,difficulty:3,startTime:0,endTime:60000,kill:true,friendlyPlayers:[1],friendlySpecs:['Enhancement']};
const report={code:'AbCdEfGh12345678',startTime:1793900000000,zone:{id:100},masterData:{gameVersion:16,actors:[actor],abilities:[{gameID:403,name:'Lightning Bolt'},{gameID:99,name:'Boss hit'}]},fights:[fight]};
const stream={complete:true,events:[{timestamp:1000,type:'cast',sourceID:1,abilityGameID:403},{timestamp:29000,type:'damage',targetID:1,sourceID:2,abilityGameID:99,amount:100},{timestamp:30000,type:'death',targetID:1,sourceID:2},{timestamp:32000,type:'death',targetID:2,sourceID:1}]};
const target=profile(report,fight,actor,stream);
const references=Array.from({length:3},(_,i)=>{const r=profile({...report,code:'RefCode00000000'+String(i).padStart(2,'0')},fight,actor,{complete:true,events:[1000,11000,21000,31000].map(timestamp=>({timestamp,type:'cast',sourceID:1,abilityGameID:403}))});r.percentile=100;return r;});
const analysis=compare(target,references),code=encodeReview(target,analysis);
assert.equal(reportCode('https://forever.warcraftlogs.com/reports/'+report.code+'#fight=1'),report.code);
assert.throws(()=>reportCode('https://evil.test/reports/'+report.code));
assert.match(analysis.improve,/Lightning Bolt: 1.0 casts\/min versus 4.0/);
assert.match(analysis.observations,/Death at 30.0s/);assert.doesNotMatch(analysis.observations,/32.0s/);
assert.match(analysis.coverage,/3 compatible verified/);
assert.doesNotMatch(compare({...target,complete:false},references).improve,/casts\/min/);
assert.doesNotMatch(compare({...target,fight:{...fight,kill:false}},references).improve,/casts\/min/);
assert.doesNotMatch(compare(target,references.map(r=>({...r,percentile:99.99}))).improve,/casts\/min/);
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
listener.scripts.OnEvent(listener,'PLAYER_REGEN_DISABLED');listener.scripts.OnEvent(listener,'PLAYER_REGEN_ENABLED')
for _,callback in ipairs(TestTimers)do callback()end
assert(ForeverCoaching.CombatReview:GetSource()=='local','New local fight must not display a stale external report')`);
run(fs.readFileSync('addons/ForeverCoaching/UI/WarcraftLogs.lua','utf8'));
run(`local parent=CreateFrame('Frame');local panel=ForeverCoaching:BuildWarcraftLogsPanel(parent,728)
assert(panel.frame.parent==parent and panel.height==340,'Warcraft Logs is embedded in review content')
assert(not ForeverCoachingWarcraftLogs and not ForeverCoaching.OpenWarcraftLogs,'No separate popup remains')
panel.input:SetText('invalid import');panel.importButton.scripts.OnClick(panel.importButton)
assert(panel.status:GetText():find('Paste a Forever Coaching',1,true),'Inline validation is visible')
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
 const ranked=await collect({report:report.code,player:'Tester',realm:'Test Realm',partition:1,output,client:{
  report:async code=>code===report.code?report:{...report,code},
  events:async code=>code===report.code?stream:{complete:true,events:[1000,11000,21000,31000].map(timestamp=>({timestamp,type:'cast',sourceID:1,abilityGameID:403}))},
  topRanks:async()=>references.map(r=>({name:'Tester',report:{code:r.report.code,fightID:1}})),
  percentile:async()=>100
 }});
 assert.match(ranked[0].analysis.coverage,/3 compatible verified/);
 assert.match(ranked[0].analysis.improve,/casts\/min/);
 }finally{fs.rmSync(output,{recursive:true,force:true});}
 console.log('PASS: WCL API pagination/errors, evidence-based outcomes, conservative 100-parse comparisons, all report attempts, safe character-bound import, logging controls, UI and fresh local review selection. Simulated fixtures only.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
