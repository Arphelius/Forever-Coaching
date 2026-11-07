// Compare recorded decisions with independent, contemporaneous peers. Patterns
// are examples to rehearse, not proof that a spell was available or optimal.
const HOST='https://forever.warcraftlogs.com';
const normal=value=>String(value??'').trim().toLowerCase();
const median=values=>{const sorted=[...values].sort((a,b)=>a-b),middle=Math.floor(sorted.length/2);return sorted.length%2?sorted[middle]:(sorted[middle-1]+sorted[middle])/2;};
const playerKey=p=>normal(p.actor.name).replace(/[\s'-]/g,'')+'@'+normal(p.actor.server).replace(/[\s'-]/g,'');
const link=p=>`${HOST}/reports/${p.report.code}#fight=${p.fight.id}&source=${p.actor.id}`;
const stamp=(p,event)=>((event.timestamp-p.fight.startTime)/1000).toFixed(1)+'s';
function compatible(target,ref,minPercentile){
 const targetTalents=talentKey(target),referenceTalents=talentKey(ref);
 return ref.complete&&!ref.deaths.length&&Number.isFinite(ref.percentile)&&ref.percentile>=minPercentile&&ref.percentile<=100&&ref.fight.kill&&
  typeof target.spec==='string'&&!['unknown','none',''].includes(normal(target.spec))&&ref.spec===target.spec&&
  typeof target.actor.subType==='string'&&ref.actor.subType===target.actor.subType&&
  ref.fight.encounterID===target.fight.encounterID&&target.fight.difficulty!=null&&ref.fight.difficulty===target.fight.difficulty&&
  target.fight.gameZone?.id!=null&&ref.fight.gameZone?.id===target.fight.gameZone.id&&
  (ref.fight.hardModeLevel||0)===(target.fight.hardModeLevel||0)&&
  (ref.fight.keystoneLevel||0)===(target.fight.keystoneLevel||0)&&
  JSON.stringify([...(ref.fight.keystoneAffixes||[])].sort((a,b)=>a-b))===JSON.stringify([...(target.fight.keystoneAffixes||[])].sort((a,b)=>a-b))&&
  target.report.zone?.id!=null&&ref.report.zone?.id===target.report.zone.id&&
  Number.isFinite(target.report.masterData.gameVersion)&&ref.report.masterData.gameVersion===target.report.masterData.gameVersion&&
  target.duration>0&&Math.abs(ref.duration-target.duration)/target.duration<=.2&&
  Number.isFinite(target.report.startTime)&&Number.isFinite(ref.report.startTime)&&
  Math.abs((ref.report.startTime+ref.fight.startTime)-(target.report.startTime+target.fight.startTime))<=7*86400000&&
  (!target.partition||!ref.partition||target.partition===ref.partition)&&
  (target.level==null||ref.level==null||target.level===ref.level)&&
  (!targetTalents||!referenceTalents||targetTalents===referenceTalents)&&
  (!target.metric||!ref.metric||target.metric===ref.metric);
}
function spell(p,id){return p.abilities.get(id)||p.counts.get(id)?.name||'Spell #'+id;}
function castRows(p){
 const rows=new Map();
 for(const event of [...p.casts].sort((a,b)=>a.timestamp-b.timestamp)){
  if(!Number.isSafeInteger(event.abilityGameID))continue;
  const name=spell(p,event.abilityGameID),key=normal(name);
  const row=rows.get(key)||{name,events:[]};row.events.push(event);rows.set(key,row);
 }
 return rows;
}
function opening(p){return [...p.casts].sort((a,b)=>a.timestamp-b.timestamp).slice(0,3).map(e=>({name:spell(p,e.abilityGameID),time:stamp(p,e)}));}
function talentKey(p){
 const info=p.events.find(e=>e.type==='combatantinfo'&&e.sourceID===p.actor.id);
 if(!Array.isArray(info?.talents)||!info.talents.length)return null;
 const values=info.talents.map(t=>Number.isSafeInteger(t.id)?`${t.id}:${t.rank??'unknown'}`:null);
 return values.every(Boolean)?values.sort().join(','):null;
}
// Only count intervals whose start is observed. Pre-pull auras without an
// application event are unknown. Match hostile target names, never report IDs.
function auraRows(p){
 const actors=new Map(p.report.masterData.actors.map(a=>[a.id,a]));
 const active=new Map(),rows=new Map();
 function finish(key,end){const open=active.get(key);if(!open)return;const row=rows.get(open.key);row.intervals.push([open.start,end]);active.delete(key);}
 for(const e of [...p.events].sort((a,b)=>a.timestamp-b.timestamp)){
  if(e.type==='death'){
   for(const [instance,open] of active){
    if(open.targetID===e.targetID&&(e.targetInstance==null||open.targetInstance===e.targetInstance)){
     if(e.targetInstance==null&&open.targetInstance!==0)rows.get(open.key).ambiguous=true;
     finish(instance,e.timestamp);
    }
   }
  }
  if((e.sourceID==null||e.targetInstance==null)&&['removebuff','removedebuff'].includes(e.type)){
   for(const [instance,open] of active){const row=rows.get(open.key);
    if(open.targetID===e.targetID&&(e.targetInstance==null||open.targetInstance===e.targetInstance)&&
     normal(spell(p,e.abilityGameID))===normal(row.name)&&
     (e.sourceID==null||(e.sourceID===p.actor.id&&e.targetInstance==null&&open.targetInstance!==0)))row.ambiguous=true;
   }
  }
  if(e.sourceID!==p.actor.id||!Number.isSafeInteger(e.abilityGameID))continue;
  const buff=['applybuff','refreshbuff','removebuff'].includes(e.type)&&e.targetID===p.actor.id;
  const debuff=['applydebuff','refreshdebuff','removedebuff'].includes(e.type)&&actors.get(e.targetID)?.type==='NPC';
  if(!buff&&!debuff)continue;
  const target=buff?'self':normal(actors.get(e.targetID).name),name=spell(p,e.abilityGameID);
  const key=(buff?'buff:':'debuff:')+normal(name)+':'+target;
  const instance=key+':'+e.targetID+':'+(e.targetInstance??0);
  if(e.type==='removebuff'||e.type==='removedebuff'){finish(instance,e.timestamp);continue;}
  if(!rows.has(key))rows.set(key,{name,target:buff?'yourself':actors.get(e.targetID).name,intervals:[],first:e.timestamp});
  if(!active.has(instance))active.set(instance,{key,start:e.timestamp,targetID:e.targetID,targetInstance:e.targetInstance??0});
 }
 for(const key of [...active.keys()])finish(key,p.fight.endTime);
 for(const row of rows.values()){
  let total=0,start,end;
  for(const interval of row.intervals.sort((a,b)=>a[0]-b[0])){
   if(start===undefined){[start,end]=interval;continue;}
   if(interval[0]<=end)end=Math.max(end,interval[1]);else{total+=end-start;[start,end]=interval;}
  }
  if(start!==undefined)total+=end-start;
  row.uptime=total/(p.duration*1000)*100;
 }
 return rows;
}
function mentor(target,references,{minPercentile=95,minPeers=3}={}){
 if(!Number.isFinite(minPercentile)||minPercentile<90||minPercentile>100)throw Error('Reference percentile must be between 90 and 100.');
 if(!Number.isSafeInteger(minPeers)||minPeers<3)throw Error('At least three independent reference players are required.');
 const seen=new Set([playerKey(target)]),peers=[];
 for(const ref of references){if(!compatible(target,ref,minPercentile)||seen.has(playerKey(ref)))continue;seen.add(playerKey(ref));peers.push(ref);}
 const links=peers.map(link),findings=[];
 const add=(kind,topic,title,what,why,next,evidence=[])=>findings.push({kind,topic,title,what,why,next,evidence,references:links});
 const targetTalents=talentKey(target),known=peers.filter(p=>talentKey(p)),sameBuild=targetTalents?known.filter(p=>talentKey(p)===targetTalents).length:0;
 const context={spec:target.spec,instanceId:target.fight.gameZone?.id,instance:target.fight.gameZone?.name,rankingZone:target.report.zone?.id,encounter:target.fight.name,difficulty:target.fight.difficulty,
  gameVersion:target.report.masterData.gameVersion,minPercentile,peerCount:peers.length,
  talentMatches:sameBuild,talentSamples:known.length,targetTalentsKnown:!!targetTalents,
  referencePlayers:peers.map(p=>({player:p.actor.name,realm:p.actor.server,spec:p.spec,percentile:p.percentile,url:link(p)}))};
 const eligible=target.complete&&target.fight.kill&&!!target.spec&&peers.length>=minPeers;
 if(!eligible){
  add('unavailable','coverage','Peer coaching not ready',`${peers.length}/${minPeers} independent compatible reference players available for ${target.spec||'an unknown spec'} on ${target.fight.name}.`,
   'Rotation coaching needs a complete player kill and comparable reference fights; a local cast count is not a rotation assessment.',
   'Analyze a completed uploaded fight with its recorded spec and matching leaderboard partition to retrieve reference players.');
  return {ready:false,context,findings,peers};
 }
 const opportunity='Same spec and encounter do not guarantee the same talents, gear, assignment or target access. Confirm these before copying the pattern.';
 const ownRows=castRows(target),peerRows=peers.map(castRows);
 // Deaths change opportunity. Do not interpret lost time as poor rotation.
 if(!target.deaths.length){
  const keys=new Set(peerRows.flatMap(rows=>[...rows.keys()]));
  for(const key of keys){
   const users=peerRows.filter(rows=>rows.has(key));if(users.length<minPeers||users.length/peers.length<.6)continue;
   const name=users[0].get(key).name,rates=peerRows.map((rows,i)=>(rows.get(key)?.events.length||0)*60/peers[i].duration);
   const expected=median(rates),row=ownRows.get(key),actual=(row?.events.length||0)*60/target.duration;
   if(expected<=0)continue;
   const evidence=(row?.events||[]).slice(0,4).map(e=>`${stamp(target,e)} ${name}`);
   if(actual<expected*.65){
    add('change','ability-use',`${name}: fewer uses`,`${name}: ${actual.toFixed(1)} casts/min versus ${expected.toFixed(1)} reference median (${users.length}/${peers.length} peers used it).`,
     `You used it ${row?.events.length||0} times; peers used it ${median(peerRows.map(rows=>rows.get(key)?.events.length||0)).toFixed(0)} times over comparable fights. This is a rotation difference, not proof it was ready. ${opportunity}`,
     `For the next ${target.fight.name} pull, track ${name}. If learned, ready and appropriate for your assignment, practice fitting it into safe action windows; compare its use rate again after the pull.`,evidence);
   }else if(actual>=expected*.8&&actual<=expected*1.2){
    add('good','ability-use',`${name}: peer-aligned usage`,`${name}: ${actual.toFixed(1)} casts/min, close to the ${expected.toFixed(1)} reference median.`,
     'Your recorded use frequency is consistent with these peers; this does not grade each cast or prove equal damage.',
     `Keep this ${name} usage habit while checking the target and encounter assignment.`,evidence);
   }
  }
 }
 const patterns=new Map();
 for(const peer of peers){const sequence=opening(peer);if(sequence.length!==3||new Set(sequence.map(s=>s.name)).size<2)continue;
  const key=JSON.stringify(sequence.map(s=>normal(s.name))),group=patterns.get(key)||{sequence,count:0};group.count++;patterns.set(key,group);}
 const pattern=[...patterns.values()].sort((a,b)=>b.count-a.count)[0];
 if(pattern&&pattern.count>=minPeers&&pattern.count/peers.length>=.6){
  const own=opening(target),expected=pattern.sequence.map(s=>s.name).join(' -> '),actual=own.map(s=>s.name).join(' -> ')||'no cast events';
  const matches=JSON.stringify(own.map(s=>normal(s.name)))===JSON.stringify(pattern.sequence.map(s=>normal(s.name)));
  add(matches?'good':'change','opener',matches?'Opening sequence matched peers':'A reference opener to practice',
   `Your first casts: ${actual}. ${pattern.count}/${peers.length} peers opened with ${expected}.`,
   `Opening order can affect setup and follow-up actions. This is an observed reference pattern, not a universal priority list. ${opportunity}`,
   matches?'Keep the opening order on equivalent pulls, adapting it when mechanics require.':
    `Before the next comparable pull, rehearse ${expected} if it fits your learned toolkit and assignment. Then compare the opening casts again.`,own.map(s=>`${s.time} ${s.name}`));
 }
 if(!target.deaths.length){
  const ownAuras=auraRows(target),peerAuras=peers.map(auraRows);
  for(const [key,row] of ownAuras){
   // Starting late can be a deliberate phase or target assignment. Restrict
   // upkeep comparisons to auras observed near the pull in every sample used.
  if(row.ambiguous||row.first-target.fight.startTime>5000)continue;
   const samples=peerAuras.map((rows,i)=>({row:rows.get(key),peer:peers[i]})).filter(s=>s.row&&!s.row.ambiguous&&s.row.first-s.peer.fight.startTime<=5000);
   if(samples.length<minPeers)continue;
   const expected=median(samples.map(s=>s.row.uptime)),actual=row.uptime;
   if(expected>=60&&actual<expected-20){
    add('change','aura-coverage',`${row.name}: lower observed coverage`,
     `${row.name} on ${row.target}: ${actual.toFixed(0)}% observed fight coverage versus ${expected.toFixed(0)}% reference median (${samples.length} peers).`,
     `Only intervals beginning with a recorded application are counted. Target downtime, dispels and assignments can explain this difference. ${opportunity}`,
     `Track ${row.name} expiration on ${row.target}. On safe, eligible windows, practice maintaining the effect; check the missing intervals against mechanics before changing refresh timing.`,
     row.intervals.slice(0,3).map(([start,end])=>`${((start-target.fight.startTime)/1000).toFixed(1)}s-${((end-target.fight.startTime)/1000).toFixed(1)}s ${row.name}`));
   }else if(expected>=60&&actual>=expected-10){
    add('good','aura-coverage',`${row.name}: sustained coverage`,
     `${row.name} on ${row.target}: ${actual.toFixed(0)}% observed coverage versus ${expected.toFixed(0)}% reference median.`,
     'You maintained coverage comparable to the retrieved peers. Coverage does not establish snapshot quality or ideal refresh timing.',
     `Keep tracking ${row.name} on your assigned target while respecting encounter downtime.`);
   }
  }
 }
 if(target.deaths.length)add('context','opportunity','Death changed your action windows',
  'Ability-frequency and aura-coverage coaching were withheld because this fight includes your death.',
  'Time spent dead is not equivalent to choosing the wrong rotation.',
  'Review the death first, then compare a surviving pull to assess your sustained rotation.');
 if(!findings.length)add('context','coverage','No stable rotation pattern established',
  'Compatible peers were found, but these checks did not establish a consistent opener, usage or coverage pattern.',
  'The absence of a difference is not a complete rotation grade.',
  'Collect more matching pulls and confirm the talent build before choosing a rotation habit to practice.');
 return {ready:true,context,findings,peers};
}
function renderFinding(finding){return `${finding.title}\n${finding.what}\nWhy: ${finding.why}${finding.next?'\nNext pull: '+finding.next:''}${finding.evidence.length?'\nYour evidence: '+finding.evidence.join('; '):''}`;}
module.exports={mentor,renderFinding,compatible};
