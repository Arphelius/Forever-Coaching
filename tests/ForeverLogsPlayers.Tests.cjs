const assert=require('assert/strict');
const {createClient}=require('../tools/foreverlogs-review.cjs');
const {createPlayerService,rate}=require('../tools/foreverlogs-players.cjs');
async function main(){
 let rosters=0;
 const client=createClient('fixture-private-key',async(url,key)=>{
  assert.equal(key,'fixture-private-key');
  if(url.startsWith('/reports?')){const offset=Number(new URL('https://fixture'+url).searchParams.get('offset')||0);return {reports:offset===0?[{id:1,created_at:'2026-10-28T12:00:00Z'}]:[]};}
  if(url==='/reports/1')return {report:{id:1},encounters:Array.from({length:14},(_,i)=>({id:i+1,name:'Boss',duration_seconds:10}))};
  const encounterId=Number(url.match(/encounters\/(\d+)/)[1]);
  if(url.endsWith('/actors')){rosters++;return {encounter_id:encounterId,actors:[{id:1,name:'Player',is_player:true},{id:2,name:'Other',is_player:true},{id:3,name:'Player pet',is_pet:true}]};}
  return {report_id:1,encounter_id:encounterId,events:[{id:'a',timestamp_ms:100,event_type:'damage',source_id:1,target_id:9,spell_id:403,amount:'200'},{id:'b',timestamp_ms:200,event_type:'damage',source_id:2,target_id:9,spell_id:404,amount:'400'}],pagination:{has_more:false}};
 });
 const service=createPlayerService(client);
 const first=await service.search(' pLaYeR ');assert.equal(rosters,12,'Search must respect its roster budget');assert.equal(first.matches.length,12);assert(first.nextCursor);
 assert(!JSON.stringify(first).includes('reportId')&&!JSON.stringify(first).includes('actorId'));
 const second=await service.search('player',first.nextCursor);assert.equal(second.matches.length,2,'Continuation must not skip encounters in a report');assert(!second.nextCursor);
 await assert.rejects(service.search('other',first.nextCursor),/new player search/);
 const a=await service.review(first.matches[0].selectionId);assert.equal(a.damagePerSecond,'20.0');assert.equal(a.comparison.rank,2);assert.equal(a.parse.available,false);
 assert(!JSON.stringify(a).includes('reportId')&&!JSON.stringify(a).includes('spellId')&&!JSON.stringify(a).includes('event')&&!JSON.stringify(a).includes('fixture-private-key'));
 await service.review(first.matches[1].selectionId);const progress=service.progress(first.matches[0].selectionId);assert.equal(progress.fights.length,2);
 const stats=service.statistics(first.matches[0].selectionId);assert.equal(stats.players.length,2);assert.equal(stats.abilities[0].spellId,403);assert(!JSON.stringify(stats).includes('targetId'));
 assert.equal(rate('9007199254740993',1),'9007199254740993.0');
 const cachedRosters=rosters;await service.search('Player');assert.equal(rosters,cachedRosters,'Repeated search must reuse processed rosters');
 const spaced=await service.search('P lá y e r');assert.equal(spaced.matches.length,12,'Spaces and accents should not prevent a name match');
 let shouldLimit=true;
 const throttled={connected:()=>true,listReports:async()=>[{id:1}],report:async()=>({encounters:[{id:1,name:'Boss'},{id:2,name:'Boss'}]}),actors:async(_,id)=>{if(id===2&&shouldLimit){const e=Error('limited');e.statusCode=429;e.retryAfterSeconds=30;throw e;}return [{id:1,name:'Player',is_player:true}];}};
 const paused=createPlayerService(throttled),part=await paused.search('Player');assert(part.rateLimited&&part.nextCursor);assert.equal(part.inspected,1);assert.equal(part.matches.length,1);
 shouldLimit=false;const resumed=await paused.search('Player',part.nextCursor);assert.equal(resumed.inspected,1,'Rate limit continuation must resume at the failed roster');
 service.clear();assert.throws(()=>service.statistics(first.matches[0].selectionId),/Review/);
 console.log('PASS: name search, bounded API work, within-report pagination, pet exclusion, redacted summaries, comparisons and progress.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
