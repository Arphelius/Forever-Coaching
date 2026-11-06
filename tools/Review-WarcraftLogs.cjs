const fs=require('fs'),path=require('path');
const {HOST,reportCode,createClient,specFor,profile,compare,encodeReview}=require('./warcraftlogs-client.cjs');
async function collect({report:input,player,realm,metric='dps',partition,output='.local/warcraftlogs',client=createClient()}){
 if(!player||!realm)throw Error('Specify --player and --realm to identify the character.');
 if(!['dps','hps'].includes(metric))throw Error('Metric must be dps or hps.');
 if(partition!==undefined&&(!Number.isSafeInteger(partition)||partition<1))throw Error('Partition must be a positive integer from the matching leaderboard.');
 const report=await client.report(reportCode(input));
 const norm=s=>String(s).toLowerCase().replace(/[\s'-]/g,'');
 const actors=report.masterData.actors.filter(a=>a.type==='Player'&&norm(a.name)===norm(player)&&norm(a.server)===norm(realm));
 if(actors.length!==1)throw Error('Player/realm did not identify exactly one report actor.');
 const actor=actors[0],results=[],referenceCache=new Map();
 for(const fight of report.fights.filter(f=>f.encounterID>0&&!f.inProgress&&f.endTime>f.startTime&&f.friendlyPlayers?.includes(actor.id))){
  const target=profile(report,fight,actor,await client.events(report.code,fight));
  const references=[],notes=[];
  if(partition&&target.spec&&fight.kill){
   try{
    const ranks=await client.topRanks(fight,actor,target.spec,metric,partition);
    for(const rank of ranks.slice(0,20)){
     if(references.length>=5)break;
     const code=rank.report?.code,fightId=rank.report?.fightID;
     if(!code||!Number.isSafeInteger(fightId)||(code===report.code&&fightId===fight.id))continue;
     const key=code+':'+fightId+':'+rank.name;
     try{
      let ref=referenceCache.get(key);
      if(!ref){
       const meta=await client.report(code),f=meta.fights.find(f=>f.id===fightId&&!f.inProgress);
       if(!f||Math.abs((meta.startTime+f.startTime)-(report.startTime+fight.startTime))>7*86400000)continue;
       const candidates=meta.masterData.actors.filter(a=>a.type==='Player'&&a.name===rank.name&&a.subType===actor.subType&&f.friendlyPlayers?.includes(a.id)&&specFor(meta,f,a)===target.spec);
       if(candidates.length!==1)continue;
       const percent=await client.percentile(code,f,candidates[0],metric);
       if(percent!==100)continue;
       ref=profile(meta,f,candidates[0],await client.events(code,f));ref.percentile=percent;
       referenceCache.set(key,ref);
      }
      if(!references.some(r=>r.report.code===ref.report.code&&r.fight.id===ref.fight.id&&r.actor.id===ref.actor.id))references.push(ref);
     }catch{notes.push('A leaderboard reference could not be retrieved or verified.');}
    }
   }catch(error){notes.push(error.message);}
  }else notes.push('Reference comparison requires a kill, an exposed spec and an explicit matching --partition.');
  const analysis=compare(target,references);
  analysis.coverage+=` Metric: ${metric}; requested partition: ${partition??'not supplied'}. References restricted to +/-7 days. `+[...new Set(notes)].join(' ');
  results.push({fightID:fight.id,encounter:fight.name,url:`${HOST}/reports/${report.code}#fight=${fight.id}&source=${actor.id}`,analysis,importCode:encodeReview(target,analysis)});
 }
 if(!results.length)throw Error('No completed boss attempts for this character were found in the report.');
 fs.mkdirSync(output,{recursive:true});
 for(const result of results)fs.writeFileSync(path.join(output,`${report.code}-${result.fightID}.fcwcl.txt`),result.importCode);
 fs.writeFileSync(path.join(output,'reviews.json'),JSON.stringify(results,null,2));
 return results;
}
if(require.main===module){
 const args=process.argv.slice(2),options={};
 if(args.includes('--help')){console.log('node tools/Review-WarcraftLogs.cjs --report FOREVER_REPORT_URL --player NAME --realm REALM [--metric dps|hps] [--partition ID] [--output .local/warcraftlogs]\nSet WCL_CLIENT_ID/WCL_CLIENT_SECRET or WCL_ACCESS_TOKEN in the environment. No credentials are exported. All completed boss attempts in this report are reviewed.');}
 else{try{for(let i=0;i<args.length;i+=2){const name=args[i].replace(/^--/,'');if(!['report','player','realm','metric','partition','output'].includes(name)||args[i+1]===undefined)throw Error('Unknown option or missing value. Use --help.');options[name]=name==='partition'?Number(args[i+1]):args[i+1];}
 collect(options).then(rows=>console.log(`Prepared ${rows.length} fight reviews. Paste a .fcwcl.txt file into Combat Review > Warcraft Logs > Import.`)).catch(e=>{console.error(e.message);process.exitCode=1;});}catch(e){console.error(e.message);process.exitCode=1;}}
}
module.exports={collect};
