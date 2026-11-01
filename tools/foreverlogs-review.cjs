// Event-based observations, never parse rankings or unsupported rotation grades.
const https=require('https');
const BASE='https://foreverlogs.gg/api/public/v1';
const {topics}=require('./talent-preview/encounter-coaching.js');
const {evaluateDecisions}=require('./encounter-decisions.cjs');
let rateLimitedUntil=0;
function id(value){const n=Number(value);if(!Number.isSafeInteger(n)||n<1)throw Error('Choose a valid report, encounter, and player.');return n;}
function request(endpoint,key){return new Promise((resolve,reject)=>{
 if(Date.now()<rateLimitedUntil){const error=Error('Forever Logs rate limit reached. Wait before retrying.');error.statusCode=429;error.retryAfterSeconds=Math.ceil((rateLimitedUntil-Date.now())/1000);reject(error);return;}
 const req=https.get(BASE+endpoint,{headers:{Authorization:'Bearer '+key,Accept:'application/json'}},res=>{
  const errors={401:'The API key was rejected.',403:'This key needs events:read access.',404:'This public report or encounter is unavailable.',429:'Forever Logs rate limit reached. Wait before retrying.'};
  if(res.statusCode!==200){const error=Error(errors[res.statusCode]||'Forever Logs is unavailable. Try again later.');error.statusCode=res.statusCode;error.retryAfterSeconds=res.statusCode===429?Math.min(3600,Math.max(1,Number(res.headers['retry-after'])||60)):null;if(res.statusCode===429)rateLimitedUntil=Date.now()+error.retryAfterSeconds*1000;res.resume();reject(error);return;}
  let size=0;const chunks=[];res.on('data',b=>{size+=b.length;if(size>40*1024*1024){req.destroy();reject(Error('Event response is too large.'));return;}chunks.push(b);});
  res.on('end',()=>{try{const value=JSON.parse(Buffer.concat(chunks).toString());if(value.success!==true)throw Error();resolve(value);}catch{reject(Error('Forever Logs returned an invalid response.'));}});res.on('error',()=>reject(Error('Forever Logs connection was interrupted.')));
 });req.setTimeout(20000,()=>req.destroy());req.on('error',()=>reject(Error('Cannot reach Forever Logs. Check your connection and try again.')));
});}
function amount(e){return typeof e.amount==='string'&&/^\d+$/.test(e.amount)?BigInt(e.amount):0n;}
function stamp(ms){return Math.floor(ms/60000)+':'+String(Math.floor(ms/1000)%60).padStart(2,'0');}
function analyze({reportId,encounter,actors,events,actorId,complete,context}){
 const actor=actors.find(a=>a.id===id(actorId)&&(a.is_player===true||a.character_type==='player'));
 if(!actor)throw Error('Select a player from this encounter.');
 const seen=new Set(),sorted=[];
 for(const event of events){if(!Number.isSafeInteger(event.timestamp_ms)||event.timestamp_ms<0)continue;if(event.id!==undefined){if(typeof event.id!=='string')throw Error('Event IDs must remain opaque strings.');if(seen.has(event.id))continue;seen.add(event.id);}sorted.push(event);}
 sorted.sort((a,b)=>a.timestamp_ms-b.timestamp_ms);
 const outgoing=sorted.filter(e=>e.source_id===actor.id),incoming=sorted.filter(e=>e.target_id===actor.id);
 const cast=outgoing.filter(e=>e.event_type==='cast'),deaths=incoming.filter(e=>e.event_type==='death');
 const outgoingType=type=>outgoing.filter(e=>e.event_type===type),sum=list=>list.reduce((n,e)=>n+amount(e),0n);
 const damage=sum(outgoingType('damage')),healing=sum(outgoingType('heal')),absorbs=sum(outgoingType('absorb'));
 const evidence=e=>({id:e.id??null,timeMs:e.timestamp_ms,time:stamp(e.timestamp_ms),event:e.event_type,sourceId:e.source_id??null,targetId:e.target_id??null,spellId:e.spell_id??null,amount:e.amount??null});
 const good=[],wrong=[],improve=[];
 const finding=(title,what,why,next,list=[])=>({title,what,why,next,evidence:list.slice(0,4).map(evidence)});
 for(const [type,value,label] of [['damage',damage,'Damage delivered'],['heal',healing,'Healing delivered'],['absorb',absorbs,'Damage absorbed']]){
  if(value>0n)good.push(finding(label,`${value.toLocaleString('en-US')} recorded ${type==='heal'?'healing':type==='absorb'?'absorption':'damage'}.`,
   type==='heal'?'Your healing contributed to recovering damage. The total alone cannot establish whether each heal was necessary.':type==='absorb'?'These absorbs reduced damage that reached the protected target. This is a confirmed defensive contribution.':'These landed attacks contributed to defeating the target. Target priority and spell efficiency still need encounter context.',null,outgoingType(type)));
 }
 for(const [type,label,why] of [['interrupt','Enemy casts interrupted','Stopping an enemy cast can prevent its effect; these are recorded interrupt events.'],['dispel','Effects dispelled','These recorded dispels confirm that you removed effects. Whether each dispel was necessary needs encounter context.']]){
  const list=outgoingType(type);if(list.length)good.unshift(finding(label,`${list.length} recorded ${type}${list.length===1?'':'s'}.`,why,null,list));
 }
 if(cast.length)good.push(finding('Abilities used',`${cast.length} cast events recorded.`,`This confirms ability use, not a rotation score. The API does not expose your resources, talents, or cooldown availability.`,null,cast));
 if(deaths.length){wrong.push(finding('Death during the encounter',`${deaths.length} recorded death${deaths.length===1?'':'s'}; first at ${stamp(deaths[0].timestamp_ms)}.`,
  'Death stops your contribution until you return. A death is an outcome, not proof that you caused it.',
  'Review the incoming hits immediately before the death, then decide whether positioning, a defensive, or external help was available.',deaths));
  const before=incoming.filter(e=>e.event_type==='damage'&&e.timestamp_ms<=deaths[0].timestamp_ms&&e.timestamp_ms>=deaths[0].timestamp_ms-10000);
  if(before.length)improve.push(finding('Review the final 10 seconds',`${sum(before).toLocaleString('en-US')} incoming damage recorded before the first death.`,
   'This is a useful window to investigate, but it does not identify which damage was avoidable.',
   'Check these timestamps against the encounter before deciding on a defensive or movement change.',before.slice(-4)));
 }
 const immune=outgoing.filter(e=>['immune','evade'].includes(e.event_type));
 if(immune.length)wrong.push(finding('Attacks did not affect the target',`${immune.length} immune or evade outcomes recorded.`,
  'These attempts did not land. The log does not establish whether target choice, encounter mechanics, or another condition caused them.',
  'Check the target and encounter phase at these times before repeating the same attack.',immune));
 if(complete){let longest=null;for(let i=1;i<cast.length;i++){const a=cast[i-1],b=cast[i],gap=b.timestamp_ms-a.timestamp_ms;
   if(gap>=6000&&!deaths.some(d=>d.timestamp_ms>=a.timestamp_ms&&d.timestamp_ms<=b.timestamp_ms)&&(!longest||gap>longest.gap))longest={a,b,gap};}
  if(longest)improve.push(finding('Check a gap between ability casts',`${(longest.gap/1000).toFixed(1)} seconds between casts at ${stamp(longest.a.timestamp_ms)}–${stamp(longest.b.timestamp_ms)}.`,
   'A cast gap can come from movement, crowd control, resource limits, auto-attacking, or required mechanics. It is not automatically wasted time.',
   'If this was a safe damage window, plan an available action for it; otherwise keep the necessary mechanic first.',[longest.a,longest.b]));
 }
 if(!good.length)good.push(finding('No positive action can be confirmed yet','No supported contribution events were found for this player.','A missing event is not evidence of poor play.',null));
 if(!wrong.length)wrong.push(finding('No specific mistake established',complete?'No supported negative outcome was identified by these checks.':'Only part of this encounter was retrieved.',
  'That does not mean the fight was flawless. We will not invent mistakes from totals or missing context.',null));
 if(!improve.length)improve.push(finding('Choose one decision to review',cast.length?'Use the recorded casts and outcomes to pick one moment.':'Confirm this is the correct player and encounter.',
  'The API does not include enough resource, gear, talent, or cooldown context to grade your entire rotation.',
  'Compare one recorded moment with the encounter mechanic and the options you actually had.'));
 // Keep every player's contributions separate: teammates provide context, not
 // a ranking or proof that the selected player should have copied their casts.
 const group=actors.filter(a=>a.is_player===true||a.character_type==='player').map(a=>{
  const own=sorted.filter(e=>e.source_id===a.id);
  return {actorId:a.id,player:a.name,selected:a.id===actor.id,casts:own.filter(e=>e.event_type==='cast').length,
   damage:sum(own.filter(e=>e.event_type==='damage')).toString(),healing:sum(own.filter(e=>e.event_type==='heal')).toString(),
   interrupts:own.filter(e=>e.event_type==='interrupt').map(evidence),dispels:own.filter(e=>e.event_type==='dispel').map(evidence),
   deaths:sorted.filter(e=>e.target_id===a.id&&e.event_type==='death').map(evidence)};
 });
 const abilityMap=new Map();
 for(const event of outgoing){if(event.spell_id==null)continue;let row=abilityMap.get(event.spell_id);
  if(!row){row={spellId:event.spell_id,casts:0,damage:0n,healing:0n,targets:new Set()};abilityMap.set(event.spell_id,row);}
  if(event.event_type==='cast')row.casts++;
  if(event.event_type==='damage')row.damage+=amount(event);
  if(event.event_type==='heal')row.healing+=amount(event);
  if(event.target_id!=null)row.targets.add(event.target_id);
 }
 const abilities=Array.from(abilityMap.values(),r=>({...r,damage:r.damage.toString(),healing:r.healing.toString(),targets:[...r.targets]}));
 const deathWindows=deaths.map(death=>({time:stamp(death.timestamp_ms),events:sorted.filter(e=>e.timestamp_ms>=death.timestamp_ms-10000&&e.timestamp_ms<=death.timestamp_ms&&(e.source_id===actor.id||e.target_id===actor.id)).map(evidence)}));
 const decisionCoverage=topics.map(topic=>({...topic,status:'Needs encounter context',
  explanation:'Events are observations. '+topic.requires+' are required before judging this decision.'}));
 const duration=Number(encounter.duration_seconds)||null;
 const decisions=evaluateDecisions(context,sorted,{reportId:id(reportId),encounterId:id(encounter.id),actorId:actor.id},complete);
 for(const finding of decisions.findings){
  (finding.kind==='good'?good:finding.kind==='wrong'?wrong:improve).unshift(finding);
 }
 for(const coverage of decisions.coverage){const topic=decisionCoverage.find(t=>t.id===coverage.domain);if(topic){topic.status=coverage.status;topic.explanation='See the attributed decision rule and its event evidence. Context is supplied, not inferred from the log.';}}
 return {source:'Forever Logs',sourceUrl:'https://foreverlogs.gg/',reportId:id(reportId),encounterId:id(encounter.id),player:actor.name,actorId:actor.id,encounter:encounter.name||'Encounter',durationSeconds:duration,complete:complete===true,
  metrics:`${actor.name} / ${encounter.name||'Encounter'} / ${duration?duration+' sec / ':''}${complete?'Full event stream':'Partial event stream'}`,
  good,wrong,improve,group,abilities,deathWindows,decisionCoverage,buildContext:decisions.build?{status:'Supplied fight-time snapshot',...decisions.build,explanation:'Build snapshot supplied with encounter context; identity matched, talents not independently verified.'}:{status:'Unknown at encounter time',explanation:'The selected preview build is not proof of this logged player’s talents. Build-specific grading requires a matching fight-time snapshot.'},observation:good.map(f=>f.what+' '+f.why).join('\n'),takeaway:wrong.map(f=>f.what+' '+f.why).join('\n'),nextStep:improve.map(f=>f.what+' '+f.next).join('\n'),
  totals:{damage:damage.toString(),healing:healing.toString(),absorbs:absorbs.toString(),casts:cast.length,deaths:deaths.length},
  coverage:complete?'Full retrieved event stream. Findings remain limited to information recorded by the API.':'Page limit reached. Absence-based checks are disabled; retrieve the rest before judging the full fight.',
  analyzedAt:new Date().toISOString()};
}
function createClient(initialKey='',read=request){let key=initialKey,verified=false;let reports=new Map(),actorCache=new Map(),reportPages=new Map(),aggregates=new Map();
 async function aggregate(endpoint){if(!key)throw Error('Forever Logs has not been configured by the addon owner yet.');const cached=aggregates.get(endpoint);if(cached&&Date.now()-cached.at<1800000)return cached.data;const data=await read(endpoint,key);aggregates.set(endpoint,{at:Date.now(),data});if(aggregates.size>100)aggregates.delete(aggregates.keys().next().value);return data;}
 return {
  connected:()=>verified,
  configured:()=>!!key,
  matchesKey:value=>typeof value==='string'&&value.trim()===key,
  async aggregateCatalog(){const [phases,bosses]=await Promise.all([aggregate('/phases'),aggregate('/bosses')]);if(!Array.isArray(phases.phases)||!Array.isArray(bosses.bosses))throw Error('Invalid aggregate catalog response.');return {phases:phases.phases,bosses:bosses.bosses};},
  async aggregateStatistics(filters={}){
   const phase=id(filters.phase),metric=filters.metric||'avg_dps',difficulty=filters.difficulty||'all';
   if(!['avg_dps','avg_hps','avg_dtps'].includes(metric)||!['normal','heroic','mythic','ascended','all'].includes(difficulty))throw Error('Choose a valid statistic and difficulty.');
   const params=new URLSearchParams({phase:String(phase),metric,difficulty});if(filters.bossId)params.set('bossId',String(id(filters.bossId)));
   if(filters.damageMode){if(!['standard','boss-only','trash'].includes(filters.damageMode))throw Error('Invalid damage scenario.');params.set('damageMode',filters.damageMode);}
   if(filters.role){if(!['tank','dps','tanks-and-dps','support'].includes(filters.role))throw Error('Invalid role.');params.set('role',filters.role);}
   const data=await aggregate('/statistics?'+params);if(!data.statistics||typeof data.statistics!=='object'||Array.isArray(data.statistics))throw Error('Invalid aggregate statistics response.');
   return {...data,sourceUrl:'https://foreverlogs.gg/',cacheMinutes:30};
  },
  async rankingBoards(){
   const phases=await aggregate('/phases');const phase=phases.phases?.find(p=>p.is_active)||phases.phases?.[0];
   if(!phase)return {boards:[],sourceUrl:'https://foreverlogs.gg/',notice:'No rankings are available yet.'};
   const scenarios=[
    {id:'overall',title:'Overall damage',unit:'DPS',metric:'avg_dps',role:'dps',damageMode:'standard'},
    {id:'boss',title:'Boss damage',unit:'DPS',metric:'avg_dps',role:'dps',damageMode:'boss-only'},
    {id:'trash',title:'Trash damage',unit:'DPS',metric:'avg_dps',role:'dps',damageMode:'trash'},
    {id:'healing',title:'Healing',unit:'HPS',metric:'avg_hps'},
    {id:'tank',title:'Tank damage',unit:'DPS',metric:'avg_dps',role:'tank',damageMode:'standard'}
   ];
   const boards=[];
   for(const scenario of scenarios){
    try{
     const data=await this.aggregateStatistics({phase:phase.phase_number,difficulty:'all',...scenario});
     const mismatched=(data.metric&&data.metric!==scenario.metric)||(data.damage_mode&&scenario.damageMode&&data.damage_mode!==scenario.damageMode);
     const rows=[];if(!mismatched)for(const [className,group] of Object.entries(data.statistics))for(const [specName,values] of Object.entries(group.specs||{})){
      if(typeof values.median==='number'&&Number.isFinite(values.median)&&values.total_parses>0)rows.push({className,specName,value:values.median,samples:values.total_parses});
     }
     rows.sort((a,b)=>b.value-a.value||a.className.localeCompare(b.className)||a.specName.localeCompare(b.specName));
     boards.push({id:scenario.id,title:scenario.title,unit:scenario.unit,rows:rows.map(row=>({...row,rank:1+rows.filter(other=>other.value>row.value).length})),note:mismatched?'This breakdown is not available from the source.':null});
    }catch(error){boards.push({id:scenario.id,title:scenario.title,unit:scenario.unit,rows:[],note:error.message});if(error.statusCode===429)break;}
   }
   return {boards,sourceUrl:'https://foreverlogs.gg/',basis:'Median recorded performance per specialization, using the current available content and all difficulties. Not individual player parses.',cacheMinutes:30};
  },
  disconnect(){key='';verified=false;reports.clear();actorCache.clear();reportPages.clear();},
  async connect(value){const candidate=value||key;if(typeof candidate!=='string'||!candidate.trim()||/[\r\n]/.test(candidate))throw Error('Enter your full API key in the local connection form.');
   const data=await read('/reports?limit=20',candidate.trim());if(!Array.isArray(data.reports))throw Error('Invalid report response.');key=candidate.trim();verified=true;reports.clear();actorCache.clear();reportPages.clear();reportPages.set(0,{at:Date.now(),reports:data.reports});return data.reports;},
  async listReports(offset=0){if(!verified)throw Error('Connect Forever Logs first.');if(!Number.isSafeInteger(offset)||offset<0)throw Error('Invalid report page.');const cached=reportPages.get(offset);if(cached&&Date.now()-cached.at<60000)return cached.reports;const data=await read('/reports?limit=20&offset='+offset,key);if(!Array.isArray(data.reports))throw Error('Invalid report response.');reportPages.set(offset,{at:Date.now(),reports:data.reports});if(reportPages.size>100)reportPages.delete(reportPages.keys().next().value);return data.reports;},
  async report(value){if(!key)throw Error('Connect Forever Logs first.');const reportId=id(value);if(reports.has(reportId))return reports.get(reportId);const data=await read('/reports/'+reportId,key);if(data.report?.id!==reportId||!Array.isArray(data.encounters))throw Error('Report response did not match.');reports.set(reportId,data);return data;},
  async actors(reportValue,encounterValue){const reportId=id(reportValue),encounterId=id(encounterValue);if(!reports.get(reportId)?.encounters.some(e=>e.id===encounterId))throw Error('Load this report and choose one of its encounters first.');
   if(actorCache.has(reportId+':'+encounterId))return actorCache.get(reportId+':'+encounterId);
   const data=await read(`/reports/${reportId}/encounters/${encounterId}/actors`,key);if(data.encounter_id!==encounterId||!Array.isArray(data.actors))throw Error('Actor response did not match.');actorCache.set(reportId+':'+encounterId,data.actors);return data.actors;},
  async review(reportValue,encounterValue,actorValue,maxPages=5,context=null){const reportId=id(reportValue),encounterId=id(encounterValue),actorId=id(actorValue),encounter=reports.get(reportId)?.encounters.find(e=>e.id===encounterId),actors=actorCache.get(reportId+':'+encounterId);
   if(!encounter||!actors?.some(a=>a.id===actorId&&(a.is_player===true||a.character_type==='player')))throw Error('Load the encounter and choose its player first.');
   const events=[],cursors=new Set();let cursor=null,complete=false;
   for(let page=0;page<Math.min(5,maxPages);page++){const data=await read(`/reports/${reportId}/encounters/${encounterId}/events?limit=50000`+(cursor?'&cursor='+encodeURIComponent(cursor):''),key);
    if(data.report_id!==reportId||data.encounter_id!==encounterId||!Array.isArray(data.events)||typeof data.pagination?.has_more!=='boolean')throw Error('Event page did not match the requested encounter.');events.push(...data.events);
    if(data.pagination.has_more===false){complete=true;break;}cursor=data.pagination.next_cursor;if(typeof cursor!=='string'||!cursor||cursors.has(cursor))throw Error('Invalid or repeated event cursor.');cursors.add(cursor);
   }return analyze({reportId,encounter,actors,events,actorId,complete,context});
  }
 };
}
function luaQuote(value){return '"'+String(value).replace(/[\x00-\x1f\\"]/g,c=>c==='\\'?'\\\\':c==='"'?'\\"':'\\'+String(c.charCodeAt(0)).padStart(3,'0'))+'"';}
function toLua(value){if(value===null||value===undefined)return 'nil';if(typeof value==='string')return luaQuote(value);if(typeof value==='number'||typeof value==='boolean')return String(value);if(Array.isArray(value))return '{'+value.map(toLua).join(',')+'}';return '{'+Object.entries(value).map(([k,v])=>'['+luaQuote(k)+']='+toLua(v)).join(',')+'}';}
module.exports={analyze,createClient,toLua,id};
