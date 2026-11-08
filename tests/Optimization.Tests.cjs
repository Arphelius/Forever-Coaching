const assert=require('assert/strict'),fs=require('fs'),os=require('os'),path=require('path');
const {profile,compare,encodeReview,createClient}=require('../tools/warcraftlogs-client.cjs');
const {compatible}=require('../tools/peer-coaching.cjs');
const {collectObserved,deliverObserved}=require('../tools/Optimize-WarcraftLogs.cjs');
const {toLua}=require('../tools/foreverlogs-review.cjs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
function sample({name='Learner',code='Target0000000001',className='Shaman',spec='Enhancement',role='dps',score=20,talent=1,level=22}={}){
 const actor={id:1,type:'Player',name,subType:className};
 const fight={id:1,name:'Ruins of Lordaeron',encounterID:12999,gameZone:{id:2999,name:'Ruins of Lordaeron'},difficulty:10,startTime:0,endTime:60000,kill:true,friendlyPlayers:[1],friendlySpecs:[spec]};
 const report={code,startTime:1793900000000,zone:{id:3000},masterData:{gameVersion:7,actors:[actor],abilities:[{gameID:101,name:'Fixture opener'},{gameID:102,name:'Fixture followup'},{gameID:103,name:'Fixture filler'}]},fights:[fight]};
 const ids=name==='Learner'?[101,103,103]:[101,102,103,102,102,102];
 const events=ids.map((abilityGameID,i)=>({timestamp:1000+i*8000,type:'cast',sourceID:1,abilityGameID}));
 events.push({timestamp:0,type:'combatantinfo',sourceID:1,level,talents:[{id:talent,rank:1}],gear:[{id:talent}]});
 return Object.assign(profile(report,fight,actor,{complete:true,events}),{role,metric:role==='healer'?'hps':'dps',performance:score});
}
const classes={Druid:['Feral','Restoration'],Hunter:['Marksmanship'],Mage:['Fire'],Paladin:['Protection','Holy'],Priest:['Shadow','Discipline'],Rogue:['Assassination'],Shaman:['Enhancement','Restoration'],Warlock:['Affliction'],Warrior:['Protection']};
for(const [className,specs]of Object.entries(classes))for(const spec of specs){
 const role=/^(Restoration|Holy|Discipline)$/.test(spec)?'healer':spec==='Protection'?'tank':'dps';
 const target=sample({className,spec,role});
 const peers=[sample({name:'Peer low',code:'PeerCode00000001',className,spec,role,score:30}),sample({name:'Peer top',code:'PeerCode00000002',className,spec,role,score:50,talent:99})];
 const result=compare(target,peers,{mode:'observed'});
 assert.equal(result.mentoring.ready,true,className+': observed comparison');
 assert.equal(result.comparison.context.referencePlayers[0].player,'Peer top','Highest matching output wins even with different talents');
 assert.equal(compare(target,[peers[0],{...peers[1],performance:NaN},peers[1]],{mode:'observed'}).comparison.context.referencePlayers[0].player,'Peer top','Invalid scores cannot disrupt highest-output selection');
 assert.equal(result.comparison.context.referencePlayers[0].percentile,undefined);
 assert.equal(result.comparison.context.metric,role==='healer'?'hps':'dps');
 assert.equal(result.comparison.scenario.casts[1].spellID,102);
 assert(result.comparison.findings.some(f=>f.comparison?.unit===target.metric));
 assert(result.coverage.includes('not compared, but still affect output'));
 if(role==='tank')assert(result.comparison.findings.some(f=>f.comparison?.action==='Tank DPS (threat unavailable)'));
 assert.equal(compare(target,peers).mentoring.ready,false,'Observed output must never pass as 100 percentile');
 for(const invalid of [{role:role==='tank'?'dps':'tank'},{level:60},{spec:'Other'},{complete:false},{performance:NaN}])assert(!compatible(target,{...peers[1],...invalid},100,'observed'));
 const deadPeer={...peers[1],deaths:[{timestamp:50000}]};
 const withDeath=compare(target,[deadPeer],{mode:'observed'});
 assert(withDeath.mentoring.ready,'Completed observed runs remain usable when a reference died');
 assert.equal(withDeath.comparison.context.referencePlayers[0].recordedDeaths,1);
 assert(!withDeath.mentoring.findings.some(f=>['ability-use','aura-coverage'].includes(f.topic)),'Reference death withholds sustained coaching');
 assert(withDeath.mentoring.findings.some(f=>f.topic==='opener'),'Pre-death opener remains an observed example');
 assert(!compare(target,[{...deadPeer,deaths:[{timestamp:1500}]}],{mode:'observed'}).mentoring.findings.some(f=>f.topic==='opener'),'Do not combine casts across a death into an opener');
 assert.equal(compare(target,[{...deadPeer,percentile:100}]).mentoring.ready,false,'Legacy percentile qualification stays strict');
 assert.equal(compare(target,[target],{mode:'observed'}).mentoring.ready,false,'Never compare to yourself');
}
async function main(){
 const target=sample(),peer=sample({name:'Peer',code:'PeerCode00000001',score:50,talent:99});
 const fake={
  report:async code=>code===target.report.code?target.report:peer.report,
  events:async code=>({complete:true,events:code===target.report.code?target.events:peer.events}),
  observedPlayers:async code=>[{id:1,role:'dps',total:code===target.report.code?1200:3000,level:22}],
  instanceReports:async zone=>{assert.equal(zone,2999);return {codes:[peer.report.code],hasMore:false};},
 };
 const results=await collectObserved({report:target.report.code,player:'Learner',sourceID:1,client:fake,output:null});
 assert.equal(results[0].analysis.comparison.context.referencePlayers[0].performance,50);
 const pageCalls=[];
 const paged=await collectObserved({report:target.report.code,player:'Learner',client:{...fake,
  instanceReports:async(zone,page,scope)=>{pageCalls.push(page);assert.equal(scope.zoneID,3000);assert(scope.startTime<target.report.startTime&&scope.endTime>target.report.startTime);return {codes:[page===1?target.report.code:peer.report.code],hasMore:page===1};},
 },output:null});
 assert.deepEqual(pageCalls,[1,2],'Follow discovery pagination to references beyond the first page');
 let repeatedInstanceCalls=0;
 const multiple=await collectObserved({report:target.report.code,player:'Learner',maxProfiles:1,client:{...fake,
  report:async code=>code===target.report.code?{...target.report,fights:[target.fight,{...target.fight,id:2}]}:peer.report,
  instanceReports:async()=>{repeatedInstanceCalls++;return {codes:[peer.report.code],hasMore:false};},
 },output:null});
 assert.equal(repeatedInstanceCalls,1,'Reuse discovery pages for the same instance');
 assert(multiple.length===2&&multiple.every(r=>r.analysis.mentoring.ready&&r.analysis.comparison.context.scan.profiles===1),'Profile budgets are per encounter, not exhausted by earlier attempts');
 assert.equal(paged[0].analysis.mentoring.ready,true);
 assert.equal(paged[0].analysis.comparison.context.scan.pages,2);
 const limited=await collectObserved({report:target.report.code,player:'Learner',maxPages:1,client:{...fake,
  instanceReports:async()=>({codes:[target.report.code],hasMore:true}),
 },output:null});
 assert.equal(limited[0].analysis.mentoring.ready,false);
 assert(limited[0].analysis.comparison.context.scan.notes.some(n=>n.includes('bounded sample')));
 assert.equal(limited[0].analysis.comparison.context.scan.rejected['same player'],1);
 const rejection=await collectObserved({report:target.report.code,player:'Learner',client:{...fake,
  report:async code=>code===target.report.code?target.report:{...peer.report,fights:[{...peer.fight,endTime:120000}]},
 },output:null});
 assert.equal(rejection[0].analysis.comparison.context.scan.profiles,0);
 assert.equal(rejection[0].analysis.comparison.context.scan.rejected['fight length outside 20%'],1,'Expose why no profiles reached event analysis');
 const repeated=[];
 const stalled=await collectObserved({report:target.report.code,player:'Learner',client:{...fake,instanceReports:async(zone,page)=>{repeated.push(page);return {codes:[target.report.code],hasMore:true};}},output:null});
 assert.deepEqual(repeated,[1,2]);
 assert(stalled[0].analysis.comparison.context.scan.notes.some(n=>n.includes('no new reports')),'Do not loop on repeated discovery pages');
 const partial=await collectObserved({report:target.report.code,player:'Learner',client:{...fake,instanceReports:async(zone,page)=>{if(page===2)throw Error('fixture page unavailable');return {codes:[peer.report.code],hasMore:true};}},output:null});
 assert(partial[0].analysis.mentoring.ready&&partial[0].analysis.comparison.context.scan.notes.some(n=>n.includes('earlier successful pages')),'Keep already-discovered references when a later page fails');
 const calls=[];
 const client=createClient({accessToken:'fixture',fetcher:async(url,options)=>{calls.push(JSON.parse(options.body));return {ok:true,text:async()=>JSON.stringify({data:{reportData:{report:{playerDetails:{data:{playerDetails:{tanks:[{id:1}],healers:[{id:2}],dps:[{id:3}]}}},table:{data:{entries:[{id:1,total:50},{id:2,total:60},{id:3,total:70}]}}}}}})};}});
 assert.deepEqual((await client.observedPlayers(target.report.code,target.fight,'hps')).map(p=>p.role),['dps','healer','tank']);
 assert(calls[0].query.includes('includeCombatantInfo:false')&&calls[0].query.includes('dataType:Healing'),'No gear or talents requested in role/output tables');
 const discoveryRequests=[];
 const discoveryClient=createClient({accessToken:'fixture',fetcher:async(url,options)=>{discoveryRequests.push(JSON.parse(options.body));return {ok:true,text:async()=>JSON.stringify({data:{reportData:{reports:{data:[{code:peer.report.code}],has_more_pages:true}}}})};}});
 assert((await discoveryClient.instanceReports(2999,2,{zoneID:3000,startTime:100,endTime:200})).hasMore);
 assert.deepEqual(discoveryRequests[0].variables,{zone:2999,page:2,rankingZone:3000,start:100,end:200});
 assert(discoveryRequests[0].query.includes('zoneID:$rankingZone')&&discoveryRequests[0].query.includes('startTime:$start'),'Send documented source zone and date filters to discovery');
 const fallback=await collectObserved({report:target.report.code,player:'Learner',referenceReports:[peer.report.code],client:{...fake,instanceReports:async()=>{throw Error('Discovery unavailable');}},output:null});
 assert(fallback[0].analysis.mentoring.ready&&fallback[0].analysis.coverage.includes('Only supplied reports were scanned'));
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 const run=s=>{if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));};
 run('unpack=unpack or table.unpack');
 for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/SpecScenarios.lua','addons/ForeverCoaching/UI/GuideSelectors.lua','addons/ForeverCoaching/Core/CombatReview.lua','addons/ForeverCoaching/Core/WarcraftLogs.lua','addons/ForeverCoaching/UI/ClassicTheme.lua','addons/ForeverCoaching/UI/WarcraftLogs.lua','addons/ForeverCoaching/UI/EncounterLearning.lua'])run(fs.readFileSync(file,'utf8'));
 run('Payload='+toLua(results[0].analysis.comparison)+';Code='+toLua(results[0].importCode));
 const deathAnalysis=compare(target,[{...peer,deaths:[{timestamp:50000}]}],{mode:'observed'});
 run('DeathPayload='+toLua(deathAnalysis.comparison)+';DeathCode='+toLua(encodeReview(target,deathAnalysis)));
 run(`
UnitName=function()return 'Learner'end;GetRealmName=function()return 'Forever'end;UnitClass=function()return 'Shaman','SHAMAN'end;UnitGUID=function()return 'Player-fixture'end
local fc=ForeverCoaching;local w=fc.WarcraftLogs
fc.EncounterCoach={GetCombatContext=function()return {class='SHAMAN',tree=2}end}
assert(w:Import(Code,Payload),'Single-realm observed import')
local model=w:GetComparisonModel()
assert(model.ready and model.referenceMode=='observed' and model.referenceHeading=='TOP OBSERVED DPS')
assert(model.rows[1].you=='20.0 DPS' and model.rows[1].reference=='50.0 DPS')
assert(model.status:find('Not a percentile or global ranking',1,true))
assert(model.nextFight:find('Fixture followup',1,true),'Action-linked next-fight goal')
local parent=CreateFrame('Frame');parent:SetSize(780,440);local panel=fc:BuildWarcraftLogsPanel(parent,728)
fc:BuildEncounterLearningPage(parent,'Scenarios')
assert(fc.parserScenarioView)
assert(w:Import(DeathCode,DeathPayload))
local deathModel=w:GetComparisonModel()
assert(deathModel.status:find('1 recorded deaths',1,true) and deathModel.status:find('Sustained-rotation coaching withheld',1,true),'Display reference death caveat')
for _,row in ipairs(deathModel.rows)do assert(not row.you:find('casts/min',1,true),'Do not render sustained-frequency grading from a dead reference')end
DeathPayload.context.referencePlayers[1].recordedDeaths=-1;assert(not w:Import(DeathCode,DeathPayload),'Reject invalid death metadata')
assert(w:Import(Code,Payload))
Payload.context.referencePlayers[1].role='healer';assert(not w:Import(Code,Payload),'Reject role mixing');Payload.context.referencePlayers[1].role='dps'
Payload.context.referencePlayers[1].percentile=100;assert(not w:Import(Code,Payload),'Observed is never relabeled a percentile');Payload.context.referencePlayers[1].percentile=nil
UnitName=function()return 'Other player'end;UnitGUID=function()return 'Player-other'end
assert(not w:Import(Code,Payload),'Other characters cannot claim player data')
fc.WarcraftLogsCatalog={schema=1,source='Warcraft Logs',entries={Payload}}
local catalog=w:GetComparisonModel();assert(catalog.ready and catalog.nextFight==nil)
for _,row in ipairs(catalog.rows)do assert(row.you=='No matching fight')end
assert(w:SetComparisonSpec('MAGE:fire'));assert(not w:GetComparisonModel().ready)
`);
 const game=fs.mkdtempSync(path.join(os.tmpdir(),'fc-opt-test-'));
 try{
  const addon=path.join(game,'Interface','AddOns','ForeverCoaching');fs.mkdirSync(path.join(addon,'Data'),{recursive:true});
  fs.writeFileSync(path.join(addon,'ForeverCoaching.toc'),'Data\\CompanionReviews.lua\n');
  assert.equal(deliverObserved(game,results).sent,1);
  const delivered=fs.readFileSync(path.join(addon,'Data','CompanionReviews.lua'),'utf8');
  assert(delivered.includes('WarcraftLogsCatalog')&&!delivered.includes('combatantinfo')&&!delivered.includes('access_token'));
  run(delivered);run("assert(ForeverCoaching.WarcraftLogsCatalog.entries[1].context.referenceMode=='observed')");
 }finally{fs.rmSync(game,{recursive:true,force:true});lua.lua_close(L);}
 console.log('PASS: observed optimization across nine classes, DPS/healer/tank roles, highest sampled output, talent/gear independence, logged role tables, bounded discovery, actual Lua import/UI/catalog and delivery. Synthetic data only.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
