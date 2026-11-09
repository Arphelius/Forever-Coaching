const assert=require('assert/strict');
const {collectPublicReports,KNOWN_REPORTS}=require('../tools/Build-PublicReportCatalog.cjs');
assert(KNOWN_REPORTS.includes('ZT329XazM8GAphBf'),'Include the supplied boss-rotation example in seed report collection');
const {scanReports}=require('../tools/public-report-scan.cjs');
const codes=['RankReport000001','RankReport000002','RankReport000003'];
const actors=[{id:1,type:'Player',name:'Anonymous DPS',subType:'Shaman'},{id:2,type:'Player',name:'Anonymous Healer',subType:'Priest'},{id:3,type:'Player',name:'Anonymous Tank',subType:'Warrior'}];
const make=code=>({code,startTime:1793900000000,zone:{id:3000},masterData:{gameVersion:7,actors,abilities:[{gameID:101,name:'Fixture combat spell'},{gameID:102,name:'Fixture followup'}]},
 fights:[{id:1,name:'Ruins of Lordaeron',encounterID:12999,difficulty:10,gameZone:{id:2999,name:'Ruins of Lordaeron'},startTime:0,endTime:60000,kill:true,inProgress:false,friendlyPlayers:[1,2,3],friendlySpecs:['Enhancement','Holy','Protection'],dungeonPulls:[{id:1,name:'Trash',encounterID:0,startTime:0,endTime:25000,kill:true},{id:2,name:'Fixture boss',encounterID:999,startTime:26000,endTime:60000,kill:true}]}]});
async function main(){
 const eventCalls=[],scoreCalls=[],pageCalls=[];
 const client={report:async code=>make(code),instanceReports:async(zone,page,scope)=>{assert(zone===null||zone===2999);assert.deepEqual(scope,{zoneID:3000},'Scan historical instance reports without a seven-day cutoff');if(zone===null){assert.equal(page,1);return {codes:[codes[1]],hasMore:false};}pageCalls.push(page);return {codes:[codes[page===1?1:2]],hasMore:page===1};},
 observedPlayers:async(code,fight,metric)=>{scoreCalls.push(code+':'+metric);const index=codes.indexOf(code);return actors.map(a=>({id:a.id,role:a.id===2?'healer':a.id===3?'tank':'dps',total:(a.id===2?[3000,9000,6000]:[3000,6000,12000])[index]}));},
 events:async(code)=>{eventCalls.push(code);const index=codes.indexOf(code);return {complete:true,events:actors.flatMap(a=>Array.from({length:index===0?12:4},(_,i)=>{const timestamp=i<2?1000+i*1000:28000+i*1000;return [{timestamp,type:'cast',sourceID:a.id,abilityGameID:index===2?102:101},{timestamp:timestamp+1,type:'damage',sourceID:a.id,abilityGameID:index===2?102:101}];}).flat())};}};
 const progress=[];
 const result=await collectPublicReports({reports:[codes[0]],client,onProgress:message=>progress.push(message)});
 assert(progress.some(message=>message.startsWith('Preparing example 3/3:')&&message.includes('2 examples complete.')),'Show actual example progress during event downloads');
 assert.deepEqual(pageCalls,[1,2]);assert.equal(result.scan.reports,3);assert.equal(result.scan.incomplete,false);
 assert.equal(result.scan.discoveryPages,3,'Scan the zone-wide report listing as well as known dungeon scopes');
 assert.equal(result.examples.length,3);
 assert.equal(result.scan.rankedCandidates,9,'Count every scored class/spec run across the discovered reports');
 const dps=result.examples.find(e=>e.role==='dps'),healer=result.examples.find(e=>e.role==='healer'),tank=result.examples.find(e=>e.role==='tank');
 assert.equal(dps.code,codes[2]);assert.equal(tank.code,codes[2]);assert.equal(healer.code,codes[1],'Healing is ranked by HPS independently of DPS');
 assert.equal(dps.performance,200);assert.equal(healer.performance,150);
 assert.deepEqual(eventCalls.sort(),[codes[1],codes[2]].sort(),'Fetch each winning run once, never the busier but lower-output first report');
 assert.equal(scoreCalls.length,6,'Score every report and all matching classes before selecting winners');
 assert(dps.rotations.every(r=>r.steps.every(s=>s.name==='Fixture followup')),'Every encounter follows the same winning run, with no cross-player spell mixing');
 assert(result.examples.every(e=>e.gameVersion===7&&e.rankingScope==='dungeon'&&e.rotations.every(r=>r.fullSequence)));
 const incomplete=await scanReports(client,[codes[0]],{maxPages:1});assert(incomplete.scan.incomplete&&incomplete.scan.reports===2,'Page limits must never be advertised as all reports');
 const failures=await collectPublicReports({reports:[codes[0]],client:{...client,events:async code=>code===codes[2]?{complete:false,events:[]}:client.events(code)}});
 assert(failures.scan.incomplete&&failures.notes.some(n=>n.includes('incomplete')));
 assert(failures.examples.every(e=>e.code===codes[1]),'Fall back only when the higher-scored run cannot be fully retrieved, with explicit coverage warning');
 const limited=()=>{const e=new Error('Rate limited');e.code='WCL_RATE_LIMIT';throw e;};
 let limitedCalls=0;
 await assert.rejects(collectPublicReports({reports:codes,client:{...client,report:async()=>{limitedCalls++;limited();}}}),e=>e.code==='WCL_RATE_LIMIT');
 assert.equal(limitedCalls,1,'Stop immediately rather than requesting every report after throttling');
 await assert.rejects(collectPublicReports({reports:[codes[0]],discover:false,client:{...client,observedPlayers:async()=>limited()}}),e=>e.code==='WCL_RATE_LIMIT','Scoring rate limits must abort before catalog delivery');
 await assert.rejects(collectPublicReports({reports:[codes[0]],discover:false,client:{...client,events:async()=>limited()}}),e=>e.code==='WCL_RATE_LIMIT','Event rate limits must preserve the previous catalog');
 console.log('PASS: later-page instance discovery, all-report output scoring, DPS/HPS/tank separation, one coherent winning run, event-cache reuse, full sequences and incomplete-scan/fetch disclosure. Synthetic reports only.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
