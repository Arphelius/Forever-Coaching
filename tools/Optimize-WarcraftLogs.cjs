// Developer-side collection. No credentials or synthetic references enter Lua.
const fs=require('fs'),path=require('path');
const {createClient,reportCode,specFor,profile,compare,encodeReview}=require('./warcraftlogs-client.cjs');
const {compatible}=require('./peer-coaching.cjs');
const {toLua}=require('./foreverlogs-review.cjs');
const {addonDirectory}=require('./coaching-delivery.cjs');
async function collectObserved({report:input,player,sourceID,referenceReports=[],output='.local/optimization',client=createClient(),maxReports=10,maxProfiles=30,discover=true}){
 if(typeof player!=='string'||!player.trim())throw Error('Specify --player.');
 if(sourceID!==undefined&&(!Number.isSafeInteger(sourceID)||sourceID<=0))throw Error('Invalid source ID.');
 if(!Number.isSafeInteger(maxReports)||maxReports<1||maxReports>50||!Number.isSafeInteger(maxProfiles)||maxProfiles<1||maxProfiles>100)throw Error('Invalid scan limits.');
 const targetReport=await client.report(reportCode(input));
 const normalize=s=>String(s||'').toLowerCase().replace(/[\s'-]/g,'');
 const actors=targetReport.masterData.actors.filter(a=>a.type==='Player'&&normalize(a.name)===normalize(player)&&(sourceID===undefined||a.id===sourceID));
 if(actors.length!==1)throw Error('Choose one report player with --player and --source.');
 const actor=actors[0],results=[],cache=new Map(),tables=new Map(),streams=new Map();let examined=0;
 async function table(report,fight,metric){const key=report.code+':'+fight.id+':'+metric;if(!tables.has(key))tables.set(key,await client.observedPlayers(report.code,fight,metric));return tables.get(key);}
 async function load(report,fight,who,metric,row){
  const key=report.code+':'+fight.id+':'+who.id+':'+metric;
  if(!cache.has(key)){
   const streamKey=report.code+':'+fight.id;
   if(!streams.has(streamKey))streams.set(streamKey,await client.events(report.code,fight));
   const p=profile(report,fight,who,streams.get(streamKey));
   p.role=row.role;p.metric=metric;p.performance=row.total/p.duration;if(p.level==null)p.level=row.level;
   cache.set(key,p);
  }
  return cache.get(key);
 }
 for(const fight of targetReport.fights.filter(f=>f.encounterID>0&&!f.inProgress&&f.endTime>f.startTime&&f.friendlyPlayers?.includes(actor.id))){
  const notes=[],damage=await table(targetReport,fight,'dps');
  let own=damage.find(p=>p.id===actor.id);
  // A healer with no damage can be absent from the damage table.
  if(!own)own=(await table(targetReport,fight,'hps')).find(p=>p.id===actor.id);
  if(!own){notes.push('The report did not expose this player\'s role and output.');results.push({fightID:fight.id,encounter:fight.name,unavailable:notes});continue;}
  const metric=own.role==='healer'?'hps':'dps';
  if(metric==='hps')own=(await table(targetReport,fight,metric)).find(p=>p.id===actor.id);
  if(!own){results.push({fightID:fight.id,encounter:fight.name,unavailable:['Healing output was not exposed for this player.']});continue;}
  const target=await load(targetReport,fight,actor,metric,own),peers=[];
  const codes=new Set([targetReport.code,...referenceReports.map(reportCode)]);
  if(discover){try{const page=await client.instanceReports(fight.gameZone.id);for(const code of page.codes)codes.add(code);if(page.hasMore)notes.push('Only the first discovery page was scanned.');}catch(error){notes.push(error.message+' Only supplied reports were scanned.');}}
  const selected=[...codes].slice(0,maxReports);if(codes.size>selected.length)notes.push('Report scan limit reached.');
  for(const code of selected){
   try{
    const report=code===targetReport.code?targetReport:await client.report(code);
    for(const other of report.fights.filter(f=>f.encounterID===fight.encounterID&&f.difficulty===fight.difficulty&&f.kill&&!f.inProgress&&f.gameZone?.id===fight.gameZone?.id&&
     f.endTime>f.startTime&&Math.abs((f.endTime-f.startTime)/1000-target.duration)/target.duration<=.2&&
     report.masterData.gameVersion===targetReport.masterData.gameVersion&&report.zone?.id===targetReport.zone?.id&&
     Math.abs((report.startTime+f.startTime)-(targetReport.startTime+fight.startTime))<=7*86400000)){
     const rows=await table(report,other,metric);
     for(const who of report.masterData.actors.filter(a=>a.type==='Player'&&a.subType===actor.subType&&other.friendlyPlayers?.includes(a.id)&&specFor(report,other,a)===target.spec)){
      if(normalize(who.name)===normalize(actor.name)&&normalize(who.server)===normalize(actor.server))continue;
      const row=rows.find(p=>p.id===who.id&&p.role===target.role);if(!row)continue;
      if(examined>=maxProfiles){notes.push('Player-event scan limit reached.');break;}examined++;
      const ref=await load(report,other,who,metric,row);
      if(compatible(target,ref,100,'observed'))peers.push(ref);
     }
    }
   }catch(error){notes.push('A candidate report was unavailable: '+error.message);}
  }
  const analysis=compare(target,peers,{mode:'observed'});
  analysis.comparison.context.scan={reports:selected.length,profiles:examined,notes:[...new Set(notes)]};
  analysis.coverage+=' '+[...new Set(notes)].join(' ');
  results.push({fightID:fight.id,encounter:fight.name,analysis,importCode:encodeReview(target,analysis)});
 }
 if(!results.length)throw Error('No completed encounter or dungeon segments for this character.');
 if(output!==null){fs.mkdirSync(output,{recursive:true});fs.writeFileSync(path.join(output,'reviews.json'),JSON.stringify(results,null,2));}
 return results;
}
function deliverObserved(gameRoot,results){
 const ready=results.filter(r=>r.analysis?.mentoring?.ready&&r.analysis.comparison.context.referenceMode==='observed');
 if(!ready.length)return {sent:0,message:'No matching observed references; no data delivered.'};
 const addon=addonDirectory(gameRoot),destination=path.join(addon,'Data','CompanionReviews.lua');
 if(fs.existsSync(destination)&&fs.lstatSync(destination).isSymbolicLink())throw Error('The data file must not be redirected.');
 if(ready.length>30)throw Error('Too many optimization entries.');
 const entries=ready.map(r=>({id:require('crypto').createHash('sha256').update(JSON.stringify(r.analysis.comparison)).digest('hex'),code:r.importCode,comparison:r.analysis.comparison}));
 const text='-- Personal optimization data. No credentials.\nForeverCoaching=ForeverCoaching or {}\nForeverCoaching.CompanionReviews='+toLua(entries)+'\nForeverCoaching.WarcraftLogsCatalog='+toLua({schema:1,source:'Warcraft Logs',entries:entries.map(r=>r.comparison)})+'\n';
 const tmp=destination+'.'+require('crypto').randomBytes(8).toString('hex')+'.tmp';
 try{fs.writeFileSync(tmp,text,{flag:'wx'});fs.renameSync(tmp,destination);}finally{if(fs.existsSync(tmp))fs.unlinkSync(tmp);}
 return {sent:ready.length,message:'Optimization data delivered. Use /reload in WoW. Personal columns appear only for the matching character.'};
}
if(require.main===module){
 const args=process.argv.slice(2),options={};let gameRoot;
 try{
  if(args.includes('--help')){console.log('Developer utility: node tools/Optimize-WarcraftLogs.cjs --report CODE --player NAME [--source ID] [--reference-reports CODE,CODE] [--game-root PATH]\nUses logged roles and output tables; no percentile required. Scans a bounded instance report sample. Never claims global best or inferred tank threat. Credentials use WCL_CLIENT_ID/WCL_CLIENT_SECRET.');}
  else{
   for(let i=0;i<args.length;i+=2){const key=args[i],value=args[i+1];if(value===undefined)throw Error('Missing option value.');
    if(key==='--game-root')gameRoot=value;
    else if(key==='--source')options.sourceID=Number(value);
    else if(key==='--reference-reports')options.referenceReports=value.split(',');
    else if(['--report','--player','--output'].includes(key))options[key.slice(2)]=value;
    else throw Error('Unknown option. Use --help.');
   }
   collectObserved(options).then(results=>{
    for(const r of results){
     const context=r.analysis?.mentoring?.context,peer=context?.referencePlayers?.[0];
     console.log(`${r.encounter} / fight ${r.fightID}: ${r.analysis?.mentoring?.ready?`${context.role} reference ready / ${peer.player} / ${peer.performance.toFixed(1)} ${context.metric.toUpperCase()}`:'no compatible reference'}`);
     for(const note of context?.scan?.notes||r.unavailable||[])console.log('  '+note);
    }
    console.log('Results saved to '+(options.output||'.local/optimization')+'/reviews.json. Highest observed means this scanned sample, not a global ranking.');
    if(gameRoot)console.log(deliverObserved(gameRoot,results).message);
   }).catch(e=>{console.error(e.message);process.exitCode=1;});
  }
 }catch(e){console.error(e.message);process.exitCode=1;}
}
module.exports={collectObserved,deliverObserved};
