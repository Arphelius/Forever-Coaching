// Public-report API access. Credentials stay outside the addon and exported reviews.
const HOST='https://forever.warcraftlogs.com';
const {mentor,renderFinding}=require('./peer-coaching.cjs');
function reportCode(value){
 if(/^[A-Za-z0-9]{16}$/.test(value||''))return value;
 let url;try{url=new URL(value);}catch{throw Error('Use a Forever Warcraft Logs report URL.');}
 const match=url.pathname.match(/^\/reports\/([A-Za-z0-9]{16})\/?$/);
 if(url.origin!==HOST||!match)throw Error('Use a report from '+HOST+'.');
 return match[1];
}
async function jsonRequest(url,options,fetcher=fetch){
 const response=await fetcher(url,{...options,redirect:'error',signal:AbortSignal.timeout(30000)});
 if(!response.ok)throw Error(response.status===429?'Warcraft Logs rate limit reached; retry later.':`Warcraft Logs request failed (${response.status}). Check report permissions and API access.`);
 const raw=await response.text();if(raw.length>32*1024*1024)throw Error('Warcraft Logs response too large.');
 try{return JSON.parse(raw);}catch{throw Error('Warcraft Logs returned invalid JSON.');}
}
function createClient({clientId=process.env.WCL_CLIENT_ID,clientSecret=process.env.WCL_CLIENT_SECRET,accessToken=process.env.WCL_ACCESS_TOKEN,getAccessToken,api='client',fetcher=fetch}={}){
 if(!['client','user'].includes(api))throw Error('Unsupported Warcraft Logs connection.');
 let token=accessToken,expires=accessToken?Infinity:0;
 async function query(query,variables={}){
  if(getAccessToken)token=await getAccessToken();
  if(!getAccessToken&&(!token||Date.now()>=expires)){
   if(!clientId||!clientSecret)throw Error('Set WCL_CLIENT_ID and WCL_CLIENT_SECRET, or WCL_ACCESS_TOKEN, outside the addon.');
   const auth=await jsonRequest('https://www.warcraftlogs.com/oauth/token',{method:'POST',headers:{Authorization:'Basic '+Buffer.from(clientId+':'+clientSecret).toString('base64'),'Content-Type':'application/x-www-form-urlencoded'},body:'grant_type=client_credentials'},fetcher);
   if(typeof auth.access_token!=='string')throw Error('Warcraft Logs token was not returned.');
   token=auth.access_token;expires=Date.now()+Math.max(1,Number(auth.expires_in||3600)-60)*1000;
  }
  if(typeof token!=='string'||!token)throw Error('Sign in to Warcraft Logs again.');
  const result=await jsonRequest(HOST+'/api/v2/'+api,{method:'POST',headers:{Authorization:'Bearer '+token,'Content-Type':'application/json'},body:JSON.stringify({query,variables})},fetcher);
  if(result.errors?.length||!result.data)throw Error('Warcraft Logs API rejected this query. Verify the Forever schema and report permissions.');
  return result.data;
 }
 const reports=new Map();
 async function report(value){const code=reportCode(value);if(reports.has(code))return reports.get(code);
  const data=await query(`query($code:String!){reportData{report(code:$code){code title startTime zone{id} masterData{gameVersion actors{id name server type subType} abilities{gameID name}} fights{id name encounterID difficulty gameZone{id name} hardModeLevel keystoneLevel keystoneAffixes startTime endTime kill inProgress friendlyPlayers friendlySpecs}}}}`,{code});
  const result=data.reportData?.report;
  if(!result||result.code!==code||!Array.isArray(result.fights)||!Array.isArray(result.masterData?.actors))throw Error('Report metadata unavailable.');
  reports.set(code,result);return result;
 }
 async function events(code,fight,maxPages=100){
  let cursor=fight.startTime;const result=[];
  for(let page=0;page<maxPages;page++){
   const data=await query(`query($code:String!,$fight:Int!,$start:Float!,$end:Float!){reportData{report(code:$code){events(fightIDs:[$fight],startTime:$start,endTime:$end,dataType:All,includeResources:true,limit:10000,useAbilityIDs:true){data nextPageTimestamp}}}}`,{code:reportCode(code),fight:fight.id,start:cursor,end:fight.endTime});
   const batch=data.reportData?.report?.events;
   if(!Array.isArray(batch?.data))throw Error('Event page unavailable.');
   result.push(...batch.data);const next=batch.nextPageTimestamp;
   if(next==null)return {events:result,complete:true};
   if(!Number.isFinite(next)||next<=cursor)throw Error('Event pagination did not advance.');
   cursor=next;
  }
  return {events:result,complete:false};
 }
 async function topRanks(fight,actor,spec,metric,partition){
  const data=await query(`query($encounter:Int!,$difficulty:Int!,$class:String!,$spec:String!,$partition:Int,$metric:CharacterRankingMetricType!){worldData{encounter(id:$encounter){characterRankings(difficulty:$difficulty,className:$class,specName:$spec,partition:$partition,metric:$metric,page:1)}}}`,{encounter:fight.encounterID,difficulty:fight.difficulty,class:actor.subType,spec,partition,metric});
  const ranks=data.worldData?.encounter?.characterRankings;
  if(!Array.isArray(ranks?.rankings))throw Error('Leaderboard unavailable; no reference parses were assumed.');
  return ranks.rankings;
 }
 async function percentile(code,fight,actor,metric){
  const data=await query(`query($code:String!,$fight:Int!,$metric:ReportRankingMetricType!){reportData{report(code:$code){rankings(fightIDs:[$fight],playerMetric:$metric,compare:Parses,timeframe:Historical)}}}`,{code,fight:fight.id,metric});
  const ranks=data.reportData?.report?.rankings;
  const entry=ranks?.data?.find(row=>row.fightID===fight.id);
  const rows=Object.values(entry?.roles||{}).flatMap(role=>role.characters||[]);
  const player=rows.find(row=>row.id===actor.id);
  return typeof player?.rankPercent==='number'?player.rankPercent:null;
 }
 async function currentUser(){
  const data=await query('query{userData{currentUser{id name}}}');const user=data.userData?.currentUser;
  if(!Number.isSafeInteger(user?.id)||typeof user.name!=='string')throw Error('Warcraft Logs did not return your profile. Sign in with profile access.');
  return {id:user.id,name:user.name};
 }
 async function recentReports(userID,page=1){
  const data=await query('query($user:Int!,$page:Int!){reportData{reports(userID:$user,page:$page,limit:20){data{code title startTime endTime}}}}',{user:userID,page});
  const rows=data.reportData?.reports?.data;if(!Array.isArray(rows))throw Error('Your recent runs could not be loaded.');
  return rows.map(r=>({code:reportCode(r.code),title:String(r.title||'Uploaded run'),startTime:r.startTime,endTime:r.endTime}));
 }
 async function partitionFor(meta,fight,metric='dps'){
  const data=await query('query($code:String!,$fight:Int!,$metric:ReportRankingMetricType!){reportData{report(code:$code){rankings(fightIDs:[$fight],playerMetric:$metric,compare:Parses,timeframe:Historical)}}}',{code:meta.code,fight:fight.id,metric});
  const ranks=data.reportData?.report?.rankings,entry=ranks?.data?.find(r=>r.fightID===fight.id);
  const partition=entry?.partition??ranks?.partition;
  if(Number.isSafeInteger(partition)&&partition>0)return partition;
  // A current default is appropriate only for a recent report. Never apply
  // today's tuning period silently to an old run.
  const at=meta.startTime+fight.startTime,age=Date.now()-at;
  if(Number.isFinite(at)&&age>=0&&age<=7*86400000&&Number.isSafeInteger(meta.zone?.id)){
   const zones=await query('query($zone:Int!){worldData{zone(id:$zone){partitions{id name default}}}}',{zone:meta.zone.id});
   const partitions=zones.worldData?.zone?.partitions||[];
   const defaults=partitions.filter(p=>p.default===true&&Number.isSafeInteger(p.id)&&p.id>0);
   if(partitions.length===1&&defaults.length===1)return defaults[0].id;
  }
  throw Error('The matching rules period could not be identified for this run. Try a recent uploaded run.');
 }
 return {report,events,topRanks,percentile,currentUser,recentReports,partitionFor};
}
function specFor(report,fight,actor){const index=fight.friendlyPlayers?.indexOf(actor.id);return index>=0?fight.friendlySpecs?.[index]:null;}
function profile(report,fight,actor,stream){
 const abilities=new Map((report.masterData.abilities||[]).map(a=>[a.gameID,a.name]));
 const events=stream.events.filter(e=>Number.isFinite(e.timestamp)&&e.timestamp>=fight.startTime&&e.timestamp<=fight.endTime);
 const own=events.filter(e=>e.sourceID===actor.id);const casts=own.filter(e=>e.type==='cast');
 const counts=new Map();for(const e of casts){const id=e.abilityGameID;if(!Number.isSafeInteger(id))continue;const row=counts.get(id)||{id,name:abilities.get(id)||'Spell #'+id,count:0,first:(e.timestamp-fight.startTime)/1000};row.count++;counts.set(id,row);}
 const deaths=events.filter(e=>e.type==='death'&&e.targetID===actor.id);
 const timeline=events.filter(e=>(e.sourceID===actor.id||e.targetID===actor.id)&&['cast','death','interrupt','dispel','applybuff','removebuff','applydebuff','removedebuff','resurrect'].includes(e.type));
 const combatant=events.find(e=>e.type==='combatantinfo'&&e.sourceID===actor.id);
 const level=Number.isSafeInteger(combatant?.level)?combatant.level:Number.isSafeInteger(actor.level)?actor.level:null;
 return {report,fight,actor,spec:specFor(report,fight,actor),level,complete:stream.complete,duration:(fight.endTime-fight.startTime)/1000,casts,counts,deaths,timeline,events,abilities};
}
function compare(target,references,options={}){
 const good=[],observations=[],improve=[];
 const stamp=e=>((e.timestamp-target.fight.startTime)/1000).toFixed(1)+'s';
 good.push(`${target.casts.length} successful cast events; ${target.deaths.length} recorded deaths. ${target.fight.kill?'Boss defeated.':'Attempt ended without a kill.'}`);
 for(const type of ['interrupt','dispel']){const list=target.events.filter(e=>e.sourceID===target.actor.id&&e.type===type);if(list.length)good.push(`${list.length} recorded ${type} events.`);}
 for(const death of target.deaths.slice(0,3)){
  const hits=target.events.filter(e=>e.type==='damage'&&e.targetID===target.actor.id&&e.timestamp<=death.timestamp&&e.timestamp>=death.timestamp-10000).slice(-5);
  observations.push(`Death at ${stamp(death)}. Final recorded hits: ${hits.map(e=>`${target.abilities.get(e.abilityGameID)||'Spell #'+e.abilityGameID} at ${stamp(e)} (${Number(e.amount)||0})`).join('; ')||'unavailable'}. This does not establish blame.`);
  improve.push(`Review the 10 seconds before ${stamp(death)} for encounter damage, positioning and available help. The log alone does not prove a defensive was ready.`);
 }
 const coaching=mentor(target,references,options),compatible=coaching.peers;
 const comparison={schema:1,source:'Warcraft Logs',ready:coaching.ready,context:coaching.context,
  report:{code:target.report.code,fightID:target.fight.id,player:target.actor.name,realm:target.actor.server,started:target.report.startTime+target.fight.startTime},
  findings:coaching.findings};
 // Keep multiple decision areas visible rather than filling all cards with
 // frequency checks for the first few abilities in a spell list.
 function selected(kinds){const topics=new Map();return coaching.findings.filter(f=>kinds.includes(f.kind)).filter(f=>{const count=topics.get(f.topic)||0;topics.set(f.topic,count+1);return count<2;}).slice(0,6);}
 good.unshift(...selected(['good']).map(renderFinding));
 observations.unshift(...selected(['change','context','unavailable']).map(renderFinding));
 const practice=selected(['change','context','unavailable']);
 if(!practice.length)practice.push(...selected(['good']));
 improve.unshift(...practice.map(f=>`${f.title}\n${f.what}\nNext pull: ${f.next}`));
 if(coaching.ready)good.unshift(`Peer group: ${compatible.length} independent ${target.spec} players on ${target.fight.name}, same instance, difficulty and game version; verified ${coaching.context.minPercentile}th percentile or higher.`);
 if(!observations.length)observations.push('No specific mistake established by these checks. Absence of findings does not establish flawless play.');
 if(!improve.length)improve.push('No specific rotation practice goal was established from the matching peer sample.');
 const timeline=target.timeline.slice(0,150).map(e=>`${stamp(e)} / ${e.type} / ${target.abilities.get(e.abilityGameID)|| (e.abilityGameID?'Spell #'+e.abilityGameID:target.actor.name)}`);
 return {good:good.join('\n'),observations:observations.join('\n\n'),improve:improve.slice(0,12).join('\n\n'),timeline:timeline.join('\n'),references:compatible.map(r=>`${HOST}/reports/${r.report.code}#fight=${r.fight.id}&source=${r.actor.id} / ${r.actor.name} / ${r.spec} / ${r.percentile} percentile`).join('\n'),mentoring:{ready:coaching.ready,context:coaching.context,findings:coaching.findings},comparison,coverage:`${target.complete?'Complete retrieved':'Partial'} event stream. ${compatible.length} compatible verified reference players at ${coaching.context.minPercentile}th percentile or higher. Same encounter, difficulty, class, spec, game version and zone; duration within 20%, dates within seven days. Known level differences excluded; level is not always exposed. Talent snapshots: ${coaching.context.talentSamples} reference players; ${coaching.context.talentMatches} match the exposed target IDs/ranks (${coaching.context.targetTalentsKnown?'target talents recorded':'target talents unavailable'}). Complete talent effects, gear, tuning/hotfix and assignment equivalence are not verified. Peer patterns are practice goals, not automatic error verdicts or a universal rotation. This sample does not establish which specs are most popular or best across all dungeons. Timeline shows ${Math.min(150,target.timeline.length)}/${target.timeline.length} selected events.`};
}
function encodeReview(target,analysis){
 const fields=['FCWCL1',target.report.code,target.fight.id,target.actor.name,target.actor.server||'',target.actor.subType?.toUpperCase(),target.spec||'Unknown',target.fight.encounterID,target.fight.name,Math.round(target.report.startTime+target.fight.startTime),Math.round(target.duration*1000),analysis.good,analysis.observations,analysis.improve,analysis.timeline,analysis.references,analysis.coverage];
 const result=fields.map(v=>encodeURIComponent(String(v??''))).join('|');if(result.length>60000)throw Error('Review too large for import.');return result;
}
module.exports={HOST,reportCode,createClient,specFor,profile,compare,encodeReview};
