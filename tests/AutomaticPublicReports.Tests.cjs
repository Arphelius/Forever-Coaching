const assert=require('assert/strict'),fs=require('fs'),os=require('os'),path=require('path');
const {refresh}=require('../tools/automatic-public-reports.cjs');
async function main(){
 const root=fs.mkdtempSync(path.join(os.tmpdir(),'fc-automatic-'));
 try{
  const stateFile=path.join(root,'state.json'),destinations=[path.join(root,'source.lua'),path.join(root,'installed.lua')];
  destinations.forEach(f=>fs.writeFileSync(f,'ORIGINAL'));
  let now=1000000000,fail=false,pages=[],writes=0,collects=0;
  const a='PublicReport0001',b='PublicReport0002';
  const client={instanceReports:async(zone,page,options)=>{assert.equal(zone,null);assert.equal(options.zoneID,3000);assert.equal(options.startTime,0);pages.push({page,end:options.endTime});if(page===1)return {codes:[a],hasMore:true};if(fail)throw Object.assign(Error('Budget'),{code:'WCL_REQUEST_BUDGET'});return {codes:[b],hasMore:false};}};
  const collect=async options=>{collects++;assert.equal(options.discover,false);assert.equal(options.strictFetch,true);assert(options.reports.includes(a)&&options.reports.includes(b));return {examples:[{}],coverage:[],scan:{reports:options.reports.length,reportsAttempted:options.reports.length}};};
  const write=(_,file)=>{writes++;fs.writeFileSync(file,'UPDATED');};
  const opts={client,stateFile,destinations,now:()=>now,collect,write};
  fail=true;await assert.rejects(refresh(opts),e=>e.code==='WCL_REQUEST_BUDGET');
  assert.equal(writes,0);destinations.forEach(f=>assert.equal(fs.readFileSync(f,'utf8'),'ORIGINAL'));
  let state=JSON.parse(fs.readFileSync(stateFile));assert.equal(state.window.page,2);assert(state.codes.includes(a));
  assert.equal((await refresh(opts)).status,'waiting');
  now+=15*60000;fail=false;await refresh(opts);assert.equal(writes,2);assert.equal(collects,1);
  assert.deepEqual(pages.map(p=>p.page),[1,2,2]);assert.equal(pages[0].end,pages[2].end,'Resume must keep stable discovery/cache window');
  state=JSON.parse(fs.readFileSync(stateFile));assert(!state.window);assert(state.codes.includes(a)&&state.codes.includes(b));
  assert.equal((await refresh(opts)).status,'waiting');
  now+=4*3600000;await refresh(opts);assert.notEqual(pages[3].end,pages[0].end,'Next cycle must use fresh discovery cache keys');
  now+=4*3600000;
  await assert.rejects(refresh({...opts,collect:async()=>{throw Error('API failed');}}),/API failed/);assert.equal(writes,4);
  now+=15*60000;
  await assert.rejects(refresh({...opts,collect:async options=>({examples:[{}],coverage:[],scan:{reports:0,reportsAttempted:options.reports.length}})}),/did not finish/);assert.equal(writes,4);
  // Repeated pages are a failure, not a successfully exhausted listing.
  const repeatedFile=path.join(root,'repeated.json');
  await assert.rejects(refresh({...opts,stateFile:repeatedFile,client:{instanceReports:async()=>({codes:[a],hasMore:true})}}),/repeated/);
  // HTTP rate limits delay retries rather than hammering the API.
  const rateFile=path.join(root,'rate.json');
  await assert.rejects(refresh({...opts,stateFile:rateFile,client:{instanceReports:async()=>{throw Object.assign(Error('Rate limited'),{code:'WCL_RATE_LIMIT'});}}}));
  assert.equal(JSON.parse(fs.readFileSync(rateFile)).nextCheckAt,now+3600000);
  assert(!fs.readFileSync(stateFile,'utf8').includes('clientSecret'));
  console.log('PASS: live All Dungeons pagination, deduplication, frozen-window resume, fresh discovery per cycle, scheduled intervals, budget/rate backoff and preserving catalogs on failed/incomplete collection. Simulated API only.');
 }finally{fs.rmSync(root,{recursive:true,force:true});}
}
main().catch(e=>{console.error(e);process.exitCode=1;});
