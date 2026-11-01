// Evaluate supplied, attributed encounter rules against the complete group log.
// A rule describes an assignment, not an inference from DPS or cast frequency.
const domains=new Set(['movement','interrupt','mana','cooldowns','rotation','range','targets','support','healing','speed']);
function validateContext(context,identity){
 if(context==null)return null;
 if(typeof context!=='object'||Array.isArray(context))throw Error('Encounter context must be an object.');
 for(const key of ['reportId','encounterId','actorId'])if(context[key]!==identity[key])throw Error('Encounter context belongs to a different '+key+'.');
 if(!context.build||typeof context.build.id!=='string'||!context.build.id||typeof context.build.capturedAt!=='string'||!Number.isFinite(Date.parse(context.build.capturedAt)))throw Error('Provide an identified fight-time build snapshot and capture timestamp.');
 if(!Array.isArray(context.rules)||context.rules.length>200)throw Error('Provide at most 200 encounter decision rules.');
 const ids=new Set();
 for(const r of context.rules){
  if(!r||typeof r.id!=='string'||!r.id||ids.has(r.id)||!domains.has(r.domain))throw Error('Decision rules need unique IDs and supported domains.');ids.add(r.id);
  if(!Number.isSafeInteger(r.startMs)||!Number.isSafeInteger(r.endMs)||r.startMs<0||r.endMs<=r.startMs)throw Error('Invalid decision window.');
  if(typeof r.title!=='string'||typeof r.why!=='string'||typeof r.next!=='string'||!Array.isArray(r.spellIds)||!r.spellIds.length||!r.spellIds.every(Number.isSafeInteger))throw Error('Rules need an explanation, next action and response spell IDs.');
  if(!Array.isArray(r.triggerEventIds)||!r.triggerEventIds.length||!r.triggerEventIds.every(x=>typeof x==='string'))throw Error('Rules must identify trigger events in this encounter.');
  if(!['cast','interrupt','dispel','heal','damage','absorb'].includes(r.responseType))throw Error('Unsupported decision response event.');
  if(!Number.isSafeInteger(r.targetId)||r.targetId<1)throw Error('Rules must identify the response target.');
  let url;try{url=new URL(r.sourceUrl);}catch{throw Error('Rules require an attributable mechanic or simulation source.');}
  if(url.protocol!=='https:'||url.username||url.password)throw Error('Use an HTTPS evidence source without credentials.');
 }
 return context;
}
function evaluateDecisions(context,events,identity,complete){
 context=validateContext(context,identity);if(!context)return {findings:[],coverage:[]};
 const eventMap=new Map(events.map(e=>[e.id,e]));const findings=[],coverage=[];
 const evidence=e=>({id:e.id,timeMs:e.timestamp_ms,time:Math.floor(e.timestamp_ms/60000)+':'+String(Math.floor(e.timestamp_ms/1000)%60).padStart(2,'0'),event:e.event_type,sourceId:e.source_id,targetId:e.target_id,spellId:e.spell_id??null,amount:e.amount??null});
 for(const rule of context.rules){
  const triggers=rule.triggerEventIds.map(id=>eventMap.get(id));
  const missing=triggers.some(e=>!e||e.timestamp_ms>rule.endMs);
  if(missing){coverage.push({domain:rule.domain,status:'Missing trigger evidence',ruleId:rule.id});continue;}
  const response=events.find(e=>e.source_id===identity.actorId&&e.target_id===rule.targetId&&e.event_type===rule.responseType&&rule.spellIds.includes(e.spell_id)&&e.timestamp_ms>=rule.startMs&&e.timestamp_ms<=rule.endMs);
  // Availability is a supplied assertion and is always labeled as such. It
  // must cover the entire window, including changes after the initial prompt.
  const a=rule.availability;
  const actionable=rule.assigned===true&&rule.safe===true&&a?.learned===true&&a?.ready===true&&a?.inRange===true&&a?.resources===true&&a?.freeToAct===true&&a?.throughMs>=rule.endMs;
  const kind=response?'good':complete&&actionable?'wrong':'investigate';
  const finding={kind,domain:rule.domain,title:rule.title,what:response?`Your ${rule.responseType} response was recorded within the assigned window.`:kind==='wrong'?'No matching response was recorded during the supplied assigned and actionable window.':'No matching response confirmed; opportunity availability or full event coverage is unresolved.',
   why:rule.why,next:rule.next,sourceUrl:rule.sourceUrl,confidence:'Log observation evaluated against supplied encounter context',
   contextOrigin:'User-supplied mechanic, assignment and availability; not independently verified',
   buildId:context.build.id,evidence:[...triggers,...(response?[response]:[])].map(evidence)};
  findings.push(finding);coverage.push({domain:rule.domain,status:kind==='investigate'?'Needs availability evidence':'Evaluated against supplied rule',ruleId:rule.id});
 }
 return {findings,coverage,build:{id:context.build.id,capturedAt:context.build.capturedAt,role:context.build.role}};
}
module.exports={validateContext,evaluateDecisions};
