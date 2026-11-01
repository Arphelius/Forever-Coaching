const assert=require('assert/strict'),fs=require('fs'),path=require('path'),os=require('os'),{Readable}=require('stream');
const {analyze,createClient,toLua}=require('../tools/foreverlogs-review.cjs'),{createBridge}=require('../tools/foreverlogs-bridge.cjs');
const actors=[{id:1,name:'Player',is_player:true},{id:2,name:'Boss',character_type:'creature'}],encounter={id:7,name:'Test encounter',duration_seconds:40};
const e=(id,t,type,source=1,target=2,amount='0')=>({id,timestamp_ms:t,event_type:type,source_id:source,target_id:target,spell_id:403,amount});
const events=[e('9007199254740993',1000,'cast'),e('9007199254740994',2000,'damage',1,2,'9007199254740993'),e('3',2200,'heal',1,1,'100'),e('4',2400,'interrupt'),e('5',11000,'cast'),e('6',15000,'damage',2,1,'90'),e('7',17000,'death',2,1),e('8',21000,'immune')];
const review=analyze({reportId:42,encounter,actors,events:[...events,events[1]],actorId:1,complete:true});
assert.equal(review.totals.damage,'9007199254740993','Damage must keep 64-bit precision and deduplicate event IDs');
assert.equal(review.totals.casts,2);assert.equal(review.totals.deaths,1);
assert(review.good.some(f=>f.title.includes('interrupted')));
assert(review.wrong.some(f=>f.title==='Death during the encounter'));
assert(review.improve.some(f=>f.title.includes('gap')));
assert(review.wrong.every(f=>f.why&&f.evidence.length));
const partial=analyze({reportId:42,encounter,actors,events,actorId:1,complete:false});
assert(!partial.improve.some(f=>f.title.includes('gap')),'Partial streams cannot establish inactivity');
assert.equal(partial.complete,false);
const deadGap=analyze({reportId:42,encounter,actors,events:[e('a',1000,'cast'),e('b',4000,'death',2,1),e('c',20000,'cast')],actorId:1,complete:true});
assert(!deadGap.improve.some(f=>f.title.includes('gap')),'Do not blame cast gaps spanning death');
assert.throws(()=>analyze({reportId:42,encounter,actors,events,actorId:2,complete:true}),/player/);
async function main(){
 const calls=[];const client=createClient('',async(url,key)=>{assert.equal(key,'fixture-key');calls.push(url);
  if(url==='/reports?limit=20')return {reports:[{id:42,title:'Fixture'}]};
  if(url==='/reports/42')return {report:{id:42},encounters:[encounter]};
  if(url.endsWith('/actors'))return {encounter_id:7,actors};
  return {report_id:42,encounter_id:7,events:url.includes('cursor=')?events.slice(4):events.slice(0,4),pagination:{has_more:!url.includes('cursor='),next_cursor:url.includes('cursor=')?null:'opaque+cursor'}};
 });
 await assert.rejects(client.report(42),/Connect/);
 await client.connect('fixture-key');await client.report(42);await client.actors(42,7);
 await assert.rejects(client.review(42,7,2),/player/);
 const loaded=await client.review(42,7,1);assert(loaded.complete);assert(calls.some(c=>c.includes('cursor=opaque%2Bcursor')));
 const limited=await client.review(42,7,1,1);assert.equal(limited.complete,false);
 const dir=fs.mkdtempSync(path.join(os.tmpdir(),'fc-review-tests-'));fs.mkdirSync(path.join(dir,'addons/ForeverCoaching/Data'),{recursive:true});
 const bridge=createBridge(dir,client);
 let ownerToken=null;
 async function send(body,origin='http://127.0.0.1:4317'){
  const req=Readable.from([Buffer.from(JSON.stringify(body))]);req.method='POST';req.headers={host:'127.0.0.1:4317',origin,'content-type':'application/json',...(ownerToken?{'x-forever-owner-token':ownerToken}:{})};req.socket={remoteAddress:'127.0.0.1'};
  let status,result;await bridge(req,{writeHead(s){status=s;},end(s){result=JSON.parse(s);}});return {status,result};
 }
 assert.equal((await send({action:'import'})).status,403,'Raw tools require owner authentication');
 ownerToken=(await send({action:'connect',key:'fixture-key'})).result.ownerToken;assert(ownerToken);
 assert.equal((await send({action:'import'})).status,400,'Cannot import before analyzing');
 await send({action:'report',reportId:42});await send({action:'actors',reportId:42,encounterId:7});
 assert.equal((await send({action:'review',reportId:42,encounterId:7,actorId:1},'https://untrusted.example')).status,403);
 assert.equal((await send({action:'review',reportId:42,encounterId:7,actorId:1})).status,200);
 assert.equal((await send({action:'import'})).status,200);
 const imported=fs.readFileSync(path.join(dir,'addons/ForeverCoaching/Data/ForeverLogsReview.lua'),'utf8');assert(!imported.includes('fixture-key'));
 const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari'));
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 const source=fs.readFileSync('tests/CombatReviewHarness.lua','utf8')+'\n'+fs.readFileSync('addons/ForeverCoaching/Core/CombatReview.lua','utf8')+'\n'+imported+`
local r=ForeverCoaching.CombatReview
r:SetSource('foreverlogs')
local summary=r:GetLatestSummary()
assert(summary.metrics:find('Player',1,true) and summary.goodText:find('recorded',1,true))
assert(summary.wrongText:find('Evidence:',1,true))
r:SetSource('local')
local localSummary=r:GetLatestSummary()
assert(localSummary.goodText and localSummary.wrongText and localSummary.improveText)
`+'\nlocal escaped='+toLua('Quote " \\ newline\n control\x01')+'\nassert(type(escaped)=="string")';
 if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));lua.lua_close(L);
 // Remove only explicitly created fixture files and directories.
 fs.unlinkSync(path.join(dir,'addons/ForeverCoaching/Data/ForeverLogsReview.lua'));for(const suffix of ['addons/ForeverCoaching/Data','addons/ForeverCoaching','addons',''])fs.rmdirSync(path.join(dir,suffix));
 client.disconnect();assert(!client.connected());
 console.log('PASS: evidence analysis, exact amounts, actor isolation, partial streams, death gaps, pagination, local-only bridge, key-free Lua import, and addon source switching.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
