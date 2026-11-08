const assert=require('assert/strict'),fs=require('fs'),path=require('path'),os=require('os');
const {createClient}=require('../tools/warcraftlogs-client.cjs');
const {responseCache}=require('../tools/wcl-response-cache.cjs');
const {collectPublicReports}=require('../tools/Build-PublicReportCatalog.cjs');
async function main(){
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'wcl-resume-'));
 try{
  const codeA='PublicReport0001',codeB='PublicReport0002';let requests=0,fail=false;
  const fetcher=async(url,options)=>{
   requests++;assert(!url.includes('oauth'),'Access-token fixtures do not call authentication');
   if(fail)return {ok:false,status:429};
   const {query,variables:v}=JSON.parse(options.body);
   const data=query.includes('events(')?{reportData:{report:{events:{data:[{timestamp:v.start,type:'cast'}],nextPageTimestamp:v.start===0?1000:null}}}}:
    {reportData:{report:{code:v.code,masterData:{actors:[]},fights:[]}}};
   return {ok:true,text:async()=>JSON.stringify({data})};
  };
  const options={accessToken:'PRIVATE_FIXTURE_TOKEN',clientId:'fixture-id',clientSecret:'PRIVATE_FIXTURE_SECRET',cacheDirectory:root,requestBudget:1,fetcher};
  let client=createClient(options);
  await client.report(codeA);
  await assert.rejects(client.report(codeB),e=>e.code==='WCL_REQUEST_BUDGET');assert.equal(requests,1);
  client=createClient(options);await client.report(codeA);await client.report(codeB);assert.equal(requests,2);assert.equal(client.requestStats.cached,1);
  const fight={id:1,startTime:0,endTime:2000};
  await assert.rejects(client.events(codeA,fight),e=>e.code==='WCL_REQUEST_BUDGET');
  client=createClient(options);
  await assert.rejects(client.events(codeA,fight),e=>e.code==='WCL_REQUEST_BUDGET');assert.equal(requests,3,'First event page persisted before pausing');
  client=createClient(options);const stream=await client.events(codeA,fight);assert(stream.complete&&stream.events.length===2);assert.equal(requests,4,'Resume reuses first event page, then fetches only the missing page');
  client=createClient(options);await client.events(codeA,fight);assert.equal(client.requestStats.network,0);assert.equal(client.requestStats.cached,2);
  fail=true;client=createClient(options);await assert.rejects(client.report('PublicReport0003'),e=>e.code==='WCL_RATE_LIMIT');
  fail=false;client=createClient(options);await client.report('PublicReport0003');assert.equal(client.requestStats.network,1,'Failed responses are never cached');
  const before=requests;await createClient({...options,clientId:'other-client'}).report(codeA);assert.equal(requests,before+1,'Different client identities do not share data');
  for(const file of fs.readdirSync(root)){const raw=fs.readFileSync(path.join(root,file),'utf8');assert(!raw.includes('PRIVATE_FIXTURE_TOKEN')&&!raw.includes('PRIVATE_FIXTURE_SECRET')&&!raw.includes('Authorization'),'No credentials or headers in cache');}
  let now=1000;const ttlCache=responseCache(path.join(root,'ttl'),'fixture',{now:()=>now,ttl:100});ttlCache.set('key',{ok:true});assert(ttlCache.get('key'));now=1100;assert.equal(ttlCache.get('key'),undefined,'Expired entries must be fetched again');
  const damaged=path.join(root,'ttl',fs.readdirSync(path.join(root,'ttl'))[0]);fs.writeFileSync(damaged,'broken');assert.equal(ttlCache.get('key'),undefined,'Interrupted or corrupt cache data is ignored');
  for(const stage of ['report','observedPlayers','events']){
   const stop=()=>{const error=new Error('Batch complete');error.code='WCL_REQUEST_BUDGET';throw error;};
   const report={code:codeA,startTime:0,masterData:{gameVersion:7,actors:[{id:1,type:'Player',name:'Fixture',subType:'Shaman'}]},fights:[{id:1,name:'Ruins of Lordaeron',encounterID:99,gameZone:{id:1,name:'Ruins of Lordaeron'},startTime:0,endTime:2000,kill:true,friendlyPlayers:[1],friendlySpecs:['Enhancement'],difficulty:1,dungeonPulls:[{id:1}]}]};
   const fake={report:async()=>report,observedPlayers:async()=>[{id:1,role:'dps',total:100}],events:async()=>({complete:true,events:[]}),[stage]:async()=>stop()};
   await assert.rejects(collectPublicReports({reports:[codeA],client:fake,discover:false}),e=>e.code==='WCL_REQUEST_BUDGET',`Budget pause propagates from ${stage} without writing a partial catalog`);
  }
  console.log('PASS: persistent request cache, cross-process resume, paginated events, batch pauses at every stage, rate-limit retry, client isolation, expiry/corruption and credential exclusion. Simulated API only.');
 }finally{fs.rmSync(root,{recursive:true,force:true});}
}
main().catch(e=>{console.error(e);process.exitCode=1;});
