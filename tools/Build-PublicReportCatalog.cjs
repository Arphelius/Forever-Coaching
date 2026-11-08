// Public examples only. No target character, personal comparison, or ranking.
const fs=require('fs'),path=require('path');
const {createClient,reportCode,profile,recordedScenario,HOST}=require('./warcraftlogs-client.cjs');
const {toLua}=require('./foreverlogs-review.cjs');
const {addonDirectory}=require('./coaching-delivery.cjs');
const KNOWN_REPORTS=['bcVxQRyHF6qjXhLk','gFd1CVbHJqkKwfMN'];
function spellsFromActions(actions){
 const counts=new Map();for(const e of actions){if(!e.spellID)continue;const row=counts.get(e.spellID)||{spellID:e.spellID,name:e.name,count:0};row.count++;counts.set(e.spellID,row);}
 return [...counts.values()].sort((a,b)=>b.count-a.count||a.spellID-b.spellID).slice(0,20);
}
async function collectPublicReports({reports=KNOWN_REPORTS,client=createClient()}={}){
 const codes=[...new Set(reports.map(reportCode))];if(!codes.length||codes.length>100)throw Error('Supply one to one hundred public report codes.');
 const examples=[],notes=[],coverage=[];
 for(const code of codes){
  try{
   const report=await client.report(code);let recorded=0;
   for(const fight of report.fights.filter(f=>f.encounterID>0&&!f.inProgress&&f.endTime>f.startTime)){
    const stream=await client.events(code,fight);const outputs=new Map();
    for(const metric of ['dps','hps']){try{for(const row of await client.observedPlayers(code,fight,metric)){
     if((row.role==='healer'&&metric==='hps')||(row.role!=='healer'&&metric==='dps'))outputs.set(row.id,{...row,metric});
    }}catch(error){notes.push(`${code}, fight ${fight.id}, ${metric}: ${error.message}`);}}
    for(const actor of report.masterData.actors.filter(a=>a.type==='Player'&&fight.friendlyPlayers?.includes(a.id))){
     const p=profile(report,fight,actor,stream);if(typeof p.spec!=='string'||['unknown','none',''].includes(p.spec.toLowerCase())||!actor.subType||!fight.gameZone?.id){notes.push(`${code}, fight ${fight.id}: a player lacks spec/class/instance metadata.`);continue;}
     const url=`${HOST}/reports/${code}#fight=${fight.id}&source=${actor.id}`,scenario=recordedScenario(p,url),output=outputs.get(actor.id);
     examples.push({code,fightID:fight.id,actorID:actor.id,player:actor.name,class:actor.subType.toUpperCase(),spec:p.spec,
      instanceId:fight.gameZone.id,instance:fight.gameZone.name,encounterId:fight.encounterID,encounter:fight.name,difficulty:fight.difficulty,
      started:report.startTime+fight.startTime,duration:p.duration,role:output?.role||'unknown',metric:output?.metric,
      performance:output?output.total/p.duration:undefined,recordedDeaths:p.deaths.length,complete:p.complete,kill:fight.kill===true,
      scenario,spells:[...p.counts.values()].filter(r=>r.id>0).sort((a,b)=>b.count-a.count||a.id-b.id).slice(0,20).map(r=>({spellID:r.id,name:r.name,count:r.count})),spellCountsComplete:p.complete});
     recorded++;
    }
   }
   coverage.push({code,examples:recorded});
  }catch(error){notes.push(`${code}: ${error.message}`);coverage.push({code,examples:0,unavailable:true});}
 }
 return {schema:1,source:'Warcraft Logs',examples,coverage,notes:[...new Set(notes)]};
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
 if(!catalog.examples.length)throw Error('No public examples collected; existing catalog was preserved.');
 fs.mkdirSync(path.dirname(destination),{recursive:true});
 if(fs.existsSync(destination)&&fs.lstatSync(destination).isSymbolicLink())throw Error('The public catalog must not be redirected.');
 const tmp=destination+'.'+require('crypto').randomBytes(8).toString('hex')+'.tmp';
 try{fs.writeFileSync(tmp,'-- Public Warcraft Logs examples. No credentials or personal comparisons.\nForeverCoaching=ForeverCoaching or {}\nForeverCoaching.PublicReportCatalog='+toLua(catalog)+'\n',{flag:'wx'});fs.renameSync(tmp,destination);}finally{if(fs.existsSync(tmp))fs.unlinkSync(tmp);}
}
if(require.main===module){
 const args=process.argv.slice(2);let reports=KNOWN_REPORTS,gameRoot;
 try{
  for(let i=0;i<args.length;i+=2){if(args[i]==='--reports'&&args[i+1])reports=args[i+1].split(',');else if(args[i]==='--game-root'&&args[i+1])gameRoot=args[i+1];else throw Error('Use --reports CODE,CODE and optional --game-root PATH.');}
  collectPublicReports({reports}).then(catalog=>{
   const destination=path.resolve(__dirname,'../addons/ForeverCoaching/Data/PublicReportCatalog.lua');
   writePublicCatalog(catalog,destination);
   if(gameRoot){const addon=addonDirectory(gameRoot);const manifest=fs.readFileSync(path.join(addon,'ForeverCoaching.toc'),'utf8');if(!manifest.includes('Data\\PublicReportCatalog.lua'))throw Error('Install the public-report browser update first.');writePublicCatalog(catalog,path.join(addon,'Data','PublicReportCatalog.lua'));}
   console.log(`Collected ${catalog.examples.length} public player/run examples from ${catalog.coverage.filter(r=>!r.unavailable).length}/${reports.length} reports. No player comparisons or global rankings.`);
   for(const note of catalog.notes)console.log(note);
   console.log('Catalog saved. Reload WoW after updating; a first installation with a changed TOC requires restarting the game.');
  }).catch(e=>{console.error(e.message);process.exitCode=1;});
 }catch(e){console.error(e.message);process.exitCode=1;}
}
module.exports={KNOWN_REPORTS,collectPublicReports,fromSavedComparisons,writePublicCatalog};
