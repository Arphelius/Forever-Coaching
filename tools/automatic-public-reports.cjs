// Scheduled, resumable public discovery. No secrets enter the state or catalog.
const fs=require('fs'),path=require('path');
const {reportCode}=require('./warcraftlogs-client.cjs');
const {KNOWN_REPORTS,collectPublicReports,writePublicCatalog}=require('./Build-PublicReportCatalog.cjs');
function save(file,state){
 fs.mkdirSync(path.dirname(file),{recursive:true});
 if(fs.existsSync(file)&&fs.lstatSync(file).isSymbolicLink())throw Error('Update state cannot be a symbolic link.');
 const tmp=file+'.'+require('crypto').randomBytes(8).toString('hex')+'.tmp';
 try{fs.writeFileSync(tmp,JSON.stringify(state),{flag:'wx'});fs.renameSync(tmp,file);}finally{if(fs.existsSync(tmp))fs.unlinkSync(tmp);}
}
async function refresh({client,stateFile,destinations,seeds=[],hours=4,now=Date.now,collect=collectPublicReports,write=writePublicCatalog,onProgress=()=>{}}){
 if(!Number.isInteger(hours)||hours<1||hours>24)throw Error('Update interval must be 1–24 hours.');
 let state={schema:1,codes:[]};
 if(fs.existsSync(stateFile)){
  if(fs.lstatSync(stateFile).isSymbolicLink())throw Error('Update state cannot be a symbolic link.');
  state=JSON.parse(fs.readFileSync(stateFile,'utf8'));
  if(state.schema!==1||!Array.isArray(state.codes))throw Error('Invalid automatic update state; existing catalog preserved.');
 }
 if(state.nextCheckAt>now()){onProgress('Next check: '+new Date(state.nextCheckAt).toISOString());return {status:'waiting'};}
 state.codes=[...new Set([...state.codes,...KNOWN_REPORTS,...seeds].map(reportCode))];
 const checkpoint=()=>save(stateFile,state);
 try{
  // Freeze the end time for pagination and resume. New cycles use a fresh
  // end time (and thus fresh cache keys). Search all start dates: a report
  // uploaded today may describe a dungeon played weeks ago.
  state.window=state.window||{end:now(),page:1,seen:[]};checkpoint();
  while(!state.window.complete){
   const w=state.window;
   if(w.page>1000)throw Error('Discovery exceeded 1000 pages; existing catalog preserved.');
   onProgress('Discovering All Dungeons page '+w.page);
   const batch=await client.instanceReports(null,w.page,{zoneID:3000,startTime:0,endTime:w.end});
   const codes=batch.codes.map(reportCode),seen=new Set(w.seen);
   if(batch.hasMore&&(!codes.length||codes.every(c=>seen.has(c))))throw Error('Discovery repeated an empty/previous page; existing catalog preserved.');
   state.codes=[...new Set([...state.codes,...codes])];
   if(state.codes.length>5000)throw Error('Discovery exceeds 5000 reports; existing catalog preserved.');
   w.seen=[...new Set([...w.seen,...codes])];w.page++;w.complete=!batch.hasMore;checkpoint();
  }
  const catalog=await collect({client,reports:state.codes,discover:false,maxReports:5000,strictFetch:true,onProgress});
  if(!catalog.examples.length||catalog.coverage.some(r=>r.unavailable)||catalog.scan.reportsAttempted!==state.codes.length||catalog.scan.reports!==state.codes.length)
   throw Error('Collection did not finish successfully; existing catalog preserved.');
  // Validate every delivery destination before touching any catalog.
  for(const file of destinations){fs.mkdirSync(path.dirname(file),{recursive:true});if(fs.existsSync(file)&&fs.lstatSync(file).isSymbolicLink())throw Error('Catalog cannot be a symbolic link.');}
  for(const file of destinations)write(catalog,file);
  state.lastSuccess=now();state.nextCheckAt=state.lastSuccess+hours*3600000;delete state.window;delete state.lastError;checkpoint();
  onProgress('Catalog saved. Reload WoW to load updated examples.');
  return {status:'saved',reports:catalog.scan.reports};
 }catch(error){
  state.lastError=String(error.message).slice(0,500);
  // One request batch per task invocation; later invocations resume its cache.
  state.nextCheckAt=now()+(error.code==='WCL_RATE_LIMIT'?3600000:15*60000);checkpoint();throw error;
 }
}
module.exports={refresh};
