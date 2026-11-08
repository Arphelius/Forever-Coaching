// Public run output selection. No target character, personal comparison, or global-rank claim.
const fs=require('fs'),path=require('path');
const {createClient,reportCode,profile,recordedScenario,HOST}=require('./warcraftlogs-client.cjs');
const {toLua}=require('./foreverlogs-review.cjs');
const {addonDirectory}=require('./coaching-delivery.cjs');
const {resolveDungeon}=require('./forever-dungeons.cjs');
const {encounterRotations,isDungeonRun}=require('./combat-rotations.cjs');
const {scanReports}=require('./public-report-scan.cjs');
const KNOWN_REPORTS=['bcVxQRyHF6qjXhLk','gFd1CVbHJqkKwfMN','ZT329XazM8GAphBf'];
function spellsFromActions(actions){
 const counts=new Map();for(const e of actions){if(!e.spellID)continue;const row=counts.get(e.spellID)||{spellID:e.spellID,name:e.name,count:0};row.count++;counts.set(e.spellID,row);}
 return [...counts.values()].sort((a,b)=>b.count-a.count||a.spellID-b.spellID).slice(0,20);
}
async function collectPublicReports({reports=KNOWN_REPORTS,client=createClient(),discover=true,maxReports=500,maxPages=100}={}){
 const codes=[...new Set(reports.map(reportCode))];if(!codes.length||codes.length>100)throw Error('Supply one to one hundred public report codes.');
 const found=await scanReports(client,codes,{discover,maxReports,maxPages,zoneIDs:[3000]});
 const examples=[],notes=[...found.notes],coverage=[],candidates=new Map(),streams=new Map();
 for(const report of found.reports){
  const code=report.code;
  try{
   let recorded=0;
   for(const fight of report.fights.filter(f=>f.encounterID>=0&&!f.inProgress&&f.endTime>f.startTime&&f.kill&&isDungeonRun(f))){
    const dungeon=resolveDungeon(fight.gameZone?.name,fight.name);
    if(!dungeon){notes.push(`${code}, fight ${fight.id}: unsupported or ambiguous dungeon/wing; skipped. Raids are outside the current scope.`);continue;}
    const outputs=new Map();
    for(const metric of ['dps','hps']){try{for(const row of await client.observedPlayers(code,fight,metric)){
     if((row.role==='healer'&&metric==='hps')||(row.role!=='healer'&&metric==='dps'))outputs.set(row.id,{...row,metric});
    }}catch(error){found.scan.incomplete=true;notes.push(`${code}, fight ${fight.id}, ${metric}: ${error.message}`);}}
    for(const actor of report.masterData.actors.filter(a=>a.type==='Player'&&fight.friendlyPlayers?.includes(a.id))){
     const index=fight.friendlyPlayers.indexOf(actor.id),spec=fight.friendlySpecs?.[index],output=outputs.get(actor.id);
     if(typeof spec!=='string'||['unknown','none',''].includes(spec.toLowerCase())||!actor.subType||!output){found.scan.incomplete=true;notes.push(`${code}, fight ${fight.id}: a player lacks spec, role or output metadata and cannot be ranked.`);continue;}
     const performance=output.total/((fight.endTime-fight.startTime)/1000);
     const key=[dungeon.key,actor.subType.toUpperCase(),spec.toLowerCase(),output.role,fight.difficulty,report.masterData.gameVersion].join(':');
     if(!candidates.has(key))candidates.set(key,[]);
     candidates.get(key).push({report,fight,actor,spec,output,dungeon,performance});
     recorded++;
    }
   }
   if(!recorded)notes.push(`${code}: no rankable completed dungeon runs were found. Runs require a supported dungeon, completion status, spec, role and output metadata.`);
   coverage.push({code,rankedCandidates:recorded});
  }catch(error){notes.push(`${code}: ${error.message}`);coverage.push({code,examples:0,unavailable:true});}
 }
 for(const rows of candidates.values()){
  rows.sort((a,b)=>b.performance-a.performance||(b.report.startTime+b.fight.startTime)-(a.report.startTime+a.fight.startTime));
  for(const candidate of rows){
   const {report,fight,actor,spec,output,dungeon,performance}=candidate,code=report.code;
   try{
    const key=code+':'+fight.id;if(!streams.has(key))streams.set(key,await client.events(code,fight));
    const stream=streams.get(key);if(!stream.complete){found.scan.incomplete=true;notes.push(`${code}, fight ${fight.id}: top candidate events were incomplete; trying the next scored run.`);continue;}
    const p=profile(report,fight,actor,stream),rotations=encounterRotations(p);
    if(!rotations.length){found.scan.incomplete=true;notes.push(`${code}, fight ${fight.id}: no usable encounter sequences for a scored candidate; trying the next run.`);continue;}
    const url=`${HOST}/reports/${code}#fight=${fight.id}&source=${actor.id}`;
    examples.push({code,fightID:fight.id,actorID:actor.id,player:actor.name,class:actor.subType.toUpperCase(),spec,
     dungeonKey:dungeon.key,instanceId:fight.gameZone.id,instance:fight.gameZone.name,encounterId:fight.encounterID,encounter:fight.name,difficulty:fight.difficulty,gameVersion:report.masterData.gameVersion,rankingScope:'dungeon',
     started:report.startTime+fight.startTime,duration:p.duration,role:output.role,metric:output.metric,performance,recordedDeaths:p.deaths.length,complete:true,kill:true,
     scenario:recordedScenario(p,url),rotations,spells:[...p.counts.values()].filter(r=>r.id>0).sort((a,b)=>b.count-a.count||a.id-b.id).slice(0,20).map(r=>({spellID:r.id,name:r.name,count:r.count})),spellCountsComplete:true});
    break;
   }catch(error){found.scan.incomplete=true;notes.push(`${code}, fight ${fight.id}: candidate event retrieval failed: ${error.message}`);}
  }
 }
 found.scan.rankedCandidates=coverage.reduce((n,r)=>n+(r.rankedCandidates||0),0);
 found.scan.winnerRuns=examples.length;
 return {schema:1,source:'Warcraft Logs',examples,coverage,scan:found.scan,notes:[...new Set(notes)]};
}
// Seed only genuinely recorded actions already retrieved from a public report.
// These are excerpts: never extrapolate their spell counts to a full run.
function fromSavedComparisons(results){
 const examples=[];
 for(const r of results){const payload=r.analysis?.comparison,context=payload?.context,scenario=payload?.scenario;
  if(!r.analysis?.mentoring?.ready||!scenario)continue;
  const peer=context.referencePlayers?.find(p=>p.url===scenario.sourceURL);if(!peer)continue;
  const match=peer.url.match(/\/reports\/([A-Za-z0-9]{16})#fight=(\d+)&source=(\d+)$/);if(!match||!KNOWN_REPORTS.includes(match[1]))continue;
  examples.push({code:match[1],fightID:Number(match[2]),actorID:Number(match[3]),player:peer.player,class:peer.class,spec:peer.spec,
   instanceId:peer.instanceId,instance:context.instance,encounterId:peer.encounterId,encounter:context.encounter,difficulty:peer.difficulty,
   duration:scenario.duration,role:peer.role||'unknown',metric:peer.metric,performance:peer.performance,recordedDeaths:peer.recordedDeaths||0,
   complete:true,kill:true,scenario,spells:spellsFromActions(scenario.casts),spellCountsComplete:scenario.castCount===scenario.casts.length});
 }
 return {schema:1,source:'Warcraft Logs',examples,coverage:[],notes:['Cached public-report excerpts only. Refresh the known reports to include every recorded dungeon and spec.']};
}
function writePublicCatalog(catalog,destination){
 if(!catalog.examples.length)throw Error(['No public examples collected; existing catalog was preserved.',
  catalog.scan?`Examined ${catalog.scan.reports} reports; scored ${catalog.scan.rankedCandidates||0} candidates.`:'',
  ...(catalog.notes||[])].filter(Boolean).join('\n'));
 fs.mkdirSync(path.dirname(destination),{recursive:true});
 if(fs.existsSync(destination)&&fs.lstatSync(destination).isSymbolicLink())throw Error('The public catalog must not be redirected.');
 const tmp=destination+'.'+require('crypto').randomBytes(8).toString('hex')+'.tmp';
 try{fs.writeFileSync(tmp,'-- Public Warcraft Logs examples. No credentials or personal comparisons.\nForeverCoaching=ForeverCoaching or {}\nForeverCoaching.PublicReportCatalog='+toLua(catalog)+'\n',{flag:'wx'});fs.renameSync(tmp,destination);}finally{if(fs.existsSync(tmp))fs.unlinkSync(tmp);}
}
if(require.main===module){
 const args=process.argv.slice(2);let reports=KNOWN_REPORTS,gameRoot;const limits={};
 try{
  for(let i=0;i<args.length;i+=2){if(args[i]==='--reports'&&args[i+1])reports=args[i+1].split(',');else if(args[i]==='--game-root'&&args[i+1])gameRoot=args[i+1];else if(['--max-pages','--max-reports'].includes(args[i])&&args[i+1])limits[args[i]==='--max-pages'?'maxPages':'maxReports']=Number(args[i+1]);else throw Error('Use --reports CODE,CODE, optional --game-root PATH, --max-pages N and --max-reports N.');}
  collectPublicReports({reports,...limits}).then(catalog=>{
   const destination=path.resolve(__dirname,'../addons/ForeverCoaching/Data/PublicReportCatalog.lua');
   writePublicCatalog(catalog,destination);
   if(gameRoot){const addon=addonDirectory(gameRoot);const manifest=fs.readFileSync(path.join(addon,'ForeverCoaching.toc'),'utf8');if(!manifest.includes('Data\\PublicReportCatalog.lua'))throw Error('Install the public-report browser update first.');writePublicCatalog(catalog,path.join(addon,'Data','PublicReportCatalog.lua'));}
   console.log(`Selected ${catalog.examples.length} highest-output class/spec/role runs after examining ${catalog.scan.reports} available public reports and ${catalog.scan.discoveryPages} discovery pages. ${catalog.scan.incomplete?'Coverage is incomplete.':'Available discovery pages were exhausted.'} This is not a verified global ranking.`);
   for(const note of catalog.notes)console.log(note);
   console.log('Catalog saved. Reload WoW after updating; a first installation with a changed TOC requires restarting the game.');
  }).catch(e=>{console.error(e.message);process.exitCode=1;});
 }catch(e){console.error(e.message);process.exitCode=1;}
}
module.exports={KNOWN_REPORTS,collectPublicReports,fromSavedComparisons,writePublicCatalog};
