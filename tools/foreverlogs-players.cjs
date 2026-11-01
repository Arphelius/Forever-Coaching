const {randomBytes}=require('crypto');
const token=()=>randomBytes(24).toString('hex');
function rate(total,seconds){
 if(!Number.isFinite(seconds)||seconds<=0||!Number.isSafeInteger(Math.round(seconds*1000)))return null;
 const value=BigInt(total)*10000n/BigInt(Math.max(1,Math.round(seconds*1000)));
 return (value/10n).toString()+'.'+(value%10n).toString();
}
function createPlayerService(client){
 const selections=new Map(),cursors=new Map(),reviewed=new Map();
 const bound=map=>{while(map.size>500)map.delete(map.keys().next().value);};
 const normalize=value=>String(value||'').normalize('NFKD').replace(/\p{M}/gu,'').toLocaleLowerCase().replace(/[^\p{L}\p{N}]/gu,'');
 function limited(error,position,query,matches=[],inspected=0){
  if(error.statusCode!==429)throw error;
  const nextCursor=token();cursors.set(nextCursor,{...position,query});bound(cursors);
  return {matches,nextCursor,inspected,rateLimited:true,retryAfterSeconds:error.retryAfterSeconds||60,coverage:'Forever Logs paused the search due to its rate limit. Results are incomplete; resume after the indicated wait.'};
 }
 function entry(value){const selected=selections.get(value);if(!selected)throw Error('Search for this player again to select a fight.');return selected;}
 function summary(raw,selected,selectionId){
  const brief=items=>(items||[]).slice(0,2).map(f=>({title:f.title,what:f.what,next:f.next||null}));
  const group=(raw.group||[]).map(p=>({player:p.player,selected:p.selected,damage:p.damage||'0',healing:p.healing||'0',deaths:p.deaths.length}));
  const ranked=[...group].sort((a,b)=>BigInt(a.damage)>BigInt(b.damage)?-1:BigInt(a.damage)<BigInt(b.damage)?1:0);
  const own=ranked.find(p=>p.selected);
  const rank=own?1+ranked.filter(p=>BigInt(p.damage)>BigInt(own.damage)).length:null;
  return {selectionId,player:raw.player,encounter:raw.encounter,date:selected.date,complete:raw.complete,
   damagePerSecond:rate(raw.totals.damage,raw.durationSeconds),healingPerSecond:rate(raw.totals.healing,raw.durationSeconds),deaths:raw.totals.deaths,
   good:brief(raw.good),improve:brief(raw.improve),setbacks:brief(raw.wrong),
   parse:{available:false,reason:'The source API does not supply player parse percentiles.'},
   comparison:{rank,players:group.length,label:'Damage position in this fight, across all roles. This is not a parse or a comparison of matching builds.'},
   coverage:raw.complete?'Processed fight reviewed.':'Partial fight: totals and comparisons may be incomplete.',
   identityNote:'Matched by player name. The API does not provide realm, class or build identity for these actors.'};
 }
 return {
  clear(){selections.clear();cursors.clear();reviewed.clear();},
  async search(value,cursor){
   const query=normalize(value);if(query.length<2||query.length>64)throw Error('Enter a player name between 2 and 64 characters.');
   if(!client.connected()){if(!client.configured())throw Error('Forever Logs has not been configured by the addon owner yet.');await client.connect();}
   let start={offset:0,encounterIndex:0};
   if(cursor){start=cursors.get(cursor);if(!start||start.query!==query)throw Error('Start a new player search.');}
   const matches=[];let reports;try{reports=await client.listReports(start.offset);}catch(error){return limited(error,start,query);}
   let inspected=0,processed=0,next=null;
   outer:for(let i=0;i<Math.min(4,reports.length);i++){
    const report=reports[i];let data;try{data=await client.report(report.id);}catch(error){return limited(error,{offset:start.offset+i,encounterIndex:i===0?start.encounterIndex:0},query,matches,inspected);}
    for(let j=i===0?start.encounterIndex:0;j<data.encounters.length;j++){
     if(inspected===12){next={offset:start.offset+i,encounterIndex:j};break outer;}
     const encounter=data.encounters[j];let actors;try{actors=await client.actors(report.id,encounter.id);}catch(error){return limited(error,{offset:start.offset+i,encounterIndex:j},query,matches,inspected);}inspected++;
     for(const actor of actors){if((actor.is_player===true||actor.character_type==='player')&&normalize(actor.name).includes(query)){
      const date=encounter.start_time||report.created_at||null;
      const selectionId=token();selections.set(selectionId,{reportId:report.id,encounterId:encounter.id,actorId:actor.id,player:actor.name,encounter:encounter.name||'Encounter',date});
      matches.push({selectionId,player:actor.name,encounter:encounter.name||'Encounter',date});
     }}
    }
    processed=i+1;
   }
   if(!next&&reports.length>processed)next={offset:start.offset+processed,encounterIndex:0};
   let nextCursor=null;if(next){nextCursor=token();cursors.set(nextCursor,{...next,query});bound(cursors);}bound(selections);
   return {matches,nextCursor,inspected,coverage:'Searches processed public fights in pages. Continue to older fights if your player is not found.'};
  },
  async review(selectionId){
   const selected=entry(selectionId);
   await client.report(selected.reportId);await client.actors(selected.reportId,selected.encounterId);
   const raw=await client.review(selected.reportId,selected.encounterId,selected.actorId);
   const result=summary(raw,selected,selectionId);reviewed.set(selectionId,{raw,summary:result,selected});bound(reviewed);return result;
  },
  statistics(selectionId){
   const record=reviewed.get(selectionId);if(!record)throw Error('Review this fight first.');
   const raw=record.raw;
   return {totals:raw.totals,abilities:(raw.abilities||[]).map(a=>({spellId:a.spellId,casts:a.casts,damage:a.damage,healing:a.healing})),
    players:(raw.group||[]).map(p=>({player:p.player,damage:p.damage,healing:p.healing,deaths:p.deaths.length})),
    comparisonNote:'Same-fight totals across all roles. Class, build, gear, assignments and pet ownership are not normalized.'};
  },
  progress(selectionId){
   const selected=entry(selectionId);
   const unique=new Map();for(const record of reviewed.values()){const s=record.summary;if(normalize(s.player)===normalize(selected.player)&&s.encounter===selected.encounter){const e=record.selected;unique.set(e.reportId+':'+e.encounterId+':'+e.actorId,s);}}
   return {fights:[...unique.values()].sort((a,b)=>String(a.date||'').localeCompare(String(b.date||''))),label:'Reviewed fights for this name and encounter during this helper session. Confirm character identity; results are not adjusted for build or gear.'};
  }
 };
}
module.exports={createPlayerService,rate};
