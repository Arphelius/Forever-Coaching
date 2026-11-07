// Developer-side collection. No credentials or synthetic references enter Lua.
const fs=require('fs'),path=require('path');
const {createClient,reportCode,specFor,profile,compare,encodeReview}=require('./warcraftlogs-client.cjs');
const {compatible}=require('./peer-coaching.cjs');
const {toLua}=require('./foreverlogs-review.cjs');
const {addonDirectory}=require('./coaching-delivery.cjs');
async function collectObserved({report:input,player,sourceID,referenceReports=[],output='.local/optimization',client=createClient(),maxReports=50,maxProfiles=30,maxPages=5,discover=true}){
 if(typeof player!=='string'||!player.trim())throw Error('Specify --player.');
 if(sourceID!==undefined&&(!Number.isSafeInteger(sourceID)||sourceID<=0))throw Error('Invalid source ID.');
 if(!Number.isSafeInteger(maxReports)||maxReports<1||maxReports>100||!Number.isSafeInteger(maxProfiles)||maxProfiles<1||maxProfiles>100||!Number.isSafeInteger(maxPages)||maxPages<1||maxPages>10)throw Error('Invalid scan limits.');
 const targetReport=await client.report(reportCode(input));
 const normalize=s=>String(s||'').toLowerCase().replace(/[\s'-]/g,'');
 const actors=targetReport.masterData.actors.filter(a=>a.type==='Player'&&normalize(a.name)===normalize(player)&&(sourceID===undefined||a.id===sourceID));
 if(actors.length!==1)throw Error('Choose one report player with --player and --source.');
 const actor=actors[0],results=[],cache=new Map(),tables=new Map(),streams=new Map(),discovery=new Map();
 const scope={zoneID:targetReport.zone?.id,startTime:Math.max(0,targetReport.startTime-7*86400000),
  endTime:targetReport.startTime+Math.max(...targetReport.fights.map(f=>Number.isFinite(f.endTime)?f.endTime:0))+7*86400000};
 async function discoverReports(instance){
  if(discovery.has(instance))return discovery.get(instance);
  const codes=new Set(),notes=[];let pages=0,more=false;
  try{
   for(let page=1;page<=maxPages;page++){
    const batch=await client.instanceReports(instance,page,scope);pages++;
    let added=0;for(const code of batch.codes){if(!codes.has(code)){codes.add(code);added++;}}
    more=batch.hasMore;
    if(!more)break;
    if(added===0){notes.push('Discovery stopped because pagination returned no new reports.');break;}
    if(codes.size>=maxReports)break;
   }
   if(more)notes.push('Public report discovery has more pages; the bounded sample is incomplete.');
  }catch(error){notes.push(error.message+(pages?' Discovery stopped after earlier successful pages.':' Only supplied reports were scanned.'));}
  const result={codes:[...codes],pages,notes};discovery.set(instance,result);return result;
 }
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
  let examined=0,pages=0;const rejected={};const reject=reason=>{rejected[reason]=(rejected[reason]||0)+1;};
  const codes=new Set([targetReport.code,...referenceReports.map(reportCode)]);
  if(discover){const found=await discoverReports(fight.gameZone.id);for(const code of found.codes)codes.add(code);notes.push(...found.notes);pages=found.pages;}
  const selected=[...codes].slice(0,maxReports);if(codes.size>selected.length)notes.push('Report scan limit reached.');
  for(const code of selected){
   try{
    const report=code===targetReport.code?targetReport:await client.report(code);
    for(const other of report.fights){
     // Count the first failed condition at each stage. Never silently relax
     // encounter/level/role boundaries just to manufacture a reference.
     const reason=other.encounterID!==fight.encounterID?'different encounter':
      other.difficulty!==fight.difficulty?'different difficulty':
      !other.kill||other.inProgress?'unfinished or unsuccessful segment':
      other.gameZone?.id!==fight.gameZone?.id?'different instance':
      !(other.endTime>other.startTime)||Math.abs((other.endTime-other.startTime)/1000-target.duration)/target.duration>.2?'fight length outside 20%':
      report.masterData.gameVersion!==targetReport.masterData.gameVersion?'different game version':
      report.zone?.id!==targetReport.zone?.id?'different ranking zone':
      !Number.isFinite(report.startTime)||Math.abs((report.startTime+other.startTime)-(targetReport.startTime+fight.startTime))>7*86400000?'date outside seven days':null;
     if(reason){reject(reason);continue;}
     const players=report.masterData.actors.filter(a=>a.type==='Player'&&a.subType===actor.subType&&other.friendlyPlayers?.includes(a.id)&&specFor(report,other,a)===target.spec);
     if(!players.length){reject('no matching class/spec');continue;}
     const rows=await table(report,other,metric);
     for(const who of players){
      if(normalize(who.name)===normalize(actor.name)&&normalize(who.server)===normalize(actor.server)){reject('same player');continue;}
      const row=rows.find(p=>p.id===who.id&&p.role===target.role);if(!row){reject('different role or missing output');continue;}
      if(examined>=maxProfiles){notes.push('Player-event scan limit reached for this encounter.');reject('player scan limit');break;}examined++;
      const ref=await load(report,other,who,metric,row);
      if(compatible(target,ref,100,'observed'))peers.push(ref);
      else reject(ref.level!=null&&target.level!=null&&ref.level!==target.level?'different player level':!ref.complete?'partial events':ref.deaths.length?'reference player died':'other incompatible context');
     }
    }
   }catch(error){reject('candidate fetch failed');notes.push('A candidate report was unavailable: '+error.message);}
  }
  const analysis=compare(target,peers,{mode:'observed'});
  analysis.comparison.context.scan={reports:selected.length,pages,profiles:examined,rejected,notes:[...new Set(notes)]};
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
  if(args.includes('--help')){console.log('Developer utility: node tools/Optimize-WarcraftLogs.cjs --report CODE --player NAME [--source ID] [--reference-reports CODE,CODE] [--game-root PATH] [--max-pages 5] [--max-reports 50] [--max-profiles 30]\nUses logged roles and output tables; no percentile required. Scans a bounded instance report sample. Never claims global best or inferred tank threat. Credentials use WCL_CLIENT_ID/WCL_CLIENT_SECRET.');}
  else{
   for(let i=0;i<args.length;i+=2){const key=args[i],value=args[i+1];if(value===undefined)throw Error('Missing option value.');
    if(key==='--game-root')gameRoot=value;
    else if(key==='--source')options.sourceID=Number(value);
    else if(key==='--reference-reports')options.referenceReports=value.split(',');
    else if(['--max-pages','--max-reports','--max-profiles'].includes(key))options[{'--max-pages':'maxPages','--max-reports':'maxReports','--max-profiles':'maxProfiles'}[key]]=Number(value);
    else if(['--report','--player','--output'].includes(key))options[key.slice(2)]=value;
    else throw Error('Unknown option. Use --help.');
   }
   collectObserved(options).then(results=>{
    for(const r of results){
     const context=r.analysis?.mentoring?.context,peer=context?.referencePlayers?.[0];
     console.log(`${r.encounter} / fight ${r.fightID}: ${r.analysis?.mentoring?.ready?`${context.role} reference ready / ${peer.player} / ${peer.performance.toFixed(1)} ${context.metric.toUpperCase()}`:'no compatible reference'}`);
     if(context?.scan){console.log(`  Checked ${context.scan.reports} reports from ${context.scan.pages} discovery pages; examined ${context.scan.profiles} candidate player profiles.`);for(const [reason,count]of Object.entries(context.scan.rejected))console.log(`  Excluded ${count}: ${reason}.`);}
     for(const note of context?.scan?.notes||r.unavailable||[])console.log('  '+note);
    }
    console.log('Results saved to '+(options.output||'.local/optimization')+'/reviews.json. Highest observed means this scanned sample, not a global ranking.');
    if(gameRoot)console.log(deliverObserved(gameRoot,results).message);
   }).catch(e=>{console.error(e.message);process.exitCode=1;});
  }
 }catch(e){console.error(e.message);process.exitCode=1;}
}
module.exports={collectObserved,deliverObserved};
