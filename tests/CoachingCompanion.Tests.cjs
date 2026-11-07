const assert=require('assert/strict'),fs=require('fs'),path=require('path'),os=require('os'),net=require('net');
const {createHash}=require('crypto');
const {createLogin}=require('../tools/coaching-oauth.cjs');
const {createCompanion}=require('../tools/coaching-companion.cjs');
const {deliver,addonDirectory}=require('../tools/coaching-delivery.cjs');
const {createClient}=require('../tools/warcraftlogs-client.cjs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const targetCode='Target0000000001',peerCodes=[1,2,3].map(i=>'PeerCode0000000'+i);
const actor={id:1,type:'Player',name:'Learner',server:'FixtureRealm',subType:'Shaman'};
const fight={id:1,name:'Fixture Boss',encounterID:77,difficulty:3,gameZone:{id:33,name:'Fixture Dungeon'},startTime:0,endTime:60000,kill:true,friendlyPlayers:[1],friendlySpecs:['Enhancement']};
function metadata(code){const person=code===targetCode?actor:{...actor,name:'Peer'+(peerCodes.indexOf(code)+1)};return {code,title:'Fixture Run',startTime:Date.now(),zone:{id:50},masterData:{gameVersion:16,actors:[person],abilities:[{gameID:101,name:'Stormstrike'},{gameID:102,name:'Earth Shock'},{gameID:103,name:'Lightning Bolt'}]},fights:[fight]};}
let requests=[];
async function upstream(url,options){
 requests.push({url,options});
 if(url.endsWith('/oauth/token'))return {ok:true,json:async()=>({access_token:'fixture-access',refresh_token:'fixture-refresh',expires_in:3600})};
 assert(url.endsWith('/api/v2/user'),'Signed-in API calls must use the user endpoint');
 assert.equal(options.headers.Authorization,'Bearer fixture-access');
 const {query,variables:v}=JSON.parse(options.body);let data;
 if(query.includes('currentUser'))data={userData:{currentUser:{id:5,name:'FixtureUser'}}};
 else if(query.includes('reports(userID'))data={reportData:{reports:{data:[{code:targetCode,title:'Fixture Run',startTime:Date.now(),endTime:Date.now()}]}}};
 else if(query.includes('masterData'))data={reportData:{report:metadata(v.code)}};
 else if(query.includes('characterRankings'))data={worldData:{encounter:{characterRankings:{rankings:peerCodes.map((code,i)=>({name:'Peer'+(i+1),report:{code,fightID:1}}))}}}};
 else if(query.includes('rankings('))data={reportData:{report:{rankings:{data:[{fightID:1,partition:2,roles:{dps:{characters:[{id:1,rankPercent:100}]}}}]}}}};
 else if(query.includes('events('))data={reportData:{report:{events:{nextPageTimestamp:null,data:(v.code===targetCode?[101,103,103]:[101,102,103,102,102,102]).map((abilityGameID,i)=>({timestamp:1000+i*8000,type:'cast',sourceID:1,abilityGameID}))}}}};
 else throw Error('Unexpected fixture query');
 return {ok:true,text:async()=>JSON.stringify({data})};
}
async function freePort(){const s=net.createServer();await new Promise(r=>s.listen(0,'127.0.0.1',r));const p=s.address().port;await new Promise(r=>s.close(r));return p;}
function checkImported(luaText){
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 function run(code){if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
 for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/SpecScenarios.lua','addons/ForeverCoaching/Core/CombatReview.lua','addons/ForeverCoaching/Core/WarcraftLogs.lua'])run(fs.readFileSync(file,'utf8'));
 run(`GetRealmName=function()return 'FixtureRealm'end;UnitName=function()return 'WrongCharacter'end;UnitGUID=function()return 'Player-fixture'end;UnitAffectingCombat=function()return false end`);
 run(luaText);
 run(`local w=ForeverCoaching.WarcraftLogs
 assert(w:LoadCompanionReviews()==0 and #w:GetReviews()==0,'Do not import another character review')
 UnitName=function()return 'Learner'end
 UnitAffectingCombat=function()return true end
 assert(not w:LoadCompanionReviews(),'Delay delivery in combat')
 UnitAffectingCombat=function()return false end
 assert(w:LoadCompanionReviews()==1,'Companion file should import without copy/paste')
 assert(w:GetSummary().improveText:find('reference median',1,true),'Peer coaching must reach the in-game review')
 ForeverCoaching.EncounterCoach={GetCombatContext=function()return {class='SHAMAN',tree=2}end}
 local comparison=w:GetComparisonModel()
 assert(comparison.ready and #comparison.rows>0 and comparison.selectedSpec=='SHAMAN:enhancement','Structured data must reach the comparison table')
 assert(comparison.rows[1].you~='No matching fight' and comparison.rows[1].reference,'Keep player and 100-parse values separate')
 assert(ForeverCoaching.CombatReview:GetSource()=='warcraftlogs')
 assert(w:LoadCompanionReviews()==0 and #w:GetReviews()==1,'A reload must not duplicate deliveries')
 local selected=ForeverCoachingDB.warcraftLogs.selected;w:LoadCompanionReviews()
 assert(ForeverCoachingDB.warcraftLogs.selected==selected and #w:GetReviews()==1,'An old consumed delivery must not duplicate or reselect a review')`);
 lua.lua_close(L);
}
async function main(){
 let time=1000,exchanges=0;
 const login=createLogin({clientId:'public-id',redirectURI:'http://127.0.0.1:4318/callback',now:()=>time,
  fetcher:async(url,opts)=>{exchanges++;const body=new URLSearchParams(opts.body);assert(!body.has('client_secret'));if(body.get('grant_type')==='authorization_code')assert.equal(createHash('sha256').update(body.get('code_verifier')).digest('base64url'),authorization.searchParams.get('code_challenge'));return {ok:true,json:async()=>({access_token:'private-token',refresh_token:'private-refresh',expires_in:60})};},
  clientFactory:options=>({currentUser:async()=>{await options.getAccessToken();return {id:5,name:'FixtureUser'};},token:options.getAccessToken})});
 let authorization=new URL(login.begin());assert.equal(authorization.searchParams.get('code_challenge_method'),'S256');
 await assert.rejects(()=>login.finish({state:'wrong',code:'x'}));assert.equal(exchanges,0);
 authorization=new URL(login.begin());await login.finish({state:authorization.searchParams.get('state'),code:'fixture-code'});
 await assert.rejects(()=>login.finish({state:authorization.searchParams.get('state'),code:'fixture-code'}),'Callback is single use');
 time+=40000;assert.equal(await login.client().token(),'private-token');assert.equal(exchanges,2,'Expired access must refresh without asking for keys');
 login.disconnect();assert.equal(login.connected(),false);assert.throws(()=>login.client());
 const folder=fs.mkdtempSync(path.join(os.tmpdir(),'fc-companion-')),addon=path.join(folder,'Interface','AddOns','ForeverCoaching');
 fs.mkdirSync(path.join(addon,'Data'),{recursive:true});fs.writeFileSync(path.join(addon,'ForeverCoaching.toc'),'Data\\CompanionReviews.lua\n');
 fs.writeFileSync(path.join(addon,'Data','CompanionReviews.lua'),'ForeverCoaching.CompanionReviews={}');
 const port=await freePort(),server=createCompanion({port,clientId:'public-id',fetcher:upstream,discover:()=>[folder]});
 await new Promise(r=>server.listen(port,'127.0.0.1',r));const base='http://127.0.0.1:'+port;
 try{
  const statusResponse=await fetch(base+'/status'),cookie=statusResponse.headers.get('set-cookie').split(';')[0],status=await statusResponse.json();
  assert(status.configured&&!status.connected);assert.equal(status.installs[0],folder);
  const headers={'Cookie':cookie,'Content-Type':'application/json','X-Coach-Token':status.csrf};
  async function action(body){const res=await fetch(base+'/action',{method:'POST',headers,body:JSON.stringify(body)});const value=await res.json();assert(res.ok,value.error);return value;}
  assert.equal((await fetch(base+'/status',{headers:{Origin:'https://unrelated.test'}})).status,403);
  assert.equal((await fetch(base+'/action',{method:'POST',headers:{Cookie:cookie,'Content-Type':'application/json'},body:'{"action":"reports"}'})).status,403);
  assert.equal((await fetch(base+'/action',{method:'POST',headers,body:'{"action":"reports"}'})).status,400,'Reports require sign-in');
  const start=await fetch(base+'/login',{headers:{Cookie:cookie},redirect:'manual'}),auth=new URL(start.headers.get('location'));
  const callback=await fetch(base+'/callback?'+new URLSearchParams({state:auth.searchParams.get('state'),code:'fixture-code'}),{headers:{Cookie:cookie},redirect:'manual'});
  assert.equal(callback.status,303);assert.equal(callback.headers.get('location'),'/');
  const reports=await action({action:'reports'});assert.equal(reports.reports[0].code,targetCode);
  const loaded=await action({action:'report',report:targetCode});assert.equal(loaded.players[0].name,'Learner');
  const result=await action({action:'review',report:targetCode,actor:1,fight:1,metric:'auto',gameRoot:folder});
  assert.equal(result.review.analysis.mentoring.ready,true);assert.equal(result.delivery.sent,1);assert(result.delivery.message.includes('/reload'));
  const exported=fs.readFileSync(path.join(addon,'Data','CompanionReviews.lua'),'utf8');
  assert(!/fixture-access|fixture-refresh|private-token|code_verifier|client_secret/.test(exported),'Only review data may enter the game');
  checkImported(exported);
  const repeated=deliver(folder,[{analysis:{mentoring:{ready:true}},importCode:exported.match(/code="([^"]+)"/)[1]}]);
  assert.equal(repeated.sent,1);assert.notEqual(fs.readFileSync(path.join(addon,'Data','CompanionReviews.lua'),'utf8'),exported,'An explicit resend has a fresh receipt');
  assert.equal(deliver(folder,[{analysis:{mentoring:{ready:false}}}]).sent,0,'Do not send a fabricated peer review when references are missing');
  fs.writeFileSync(path.join(addon,'ForeverCoaching.toc'),'Core\\WarcraftLogs.lua');assert.throws(()=>addonDirectory(folder),/Update Forever Coaching/);
  await action({action:'disconnect'});
  assert.equal((await fetch(base+'/status',{headers:{Cookie:cookie}}).then(r=>r.json())).connected,false);
 }finally{server.closeAllConnections();await new Promise(r=>server.close(r));fs.rmSync(folder,{recursive:true,force:true});}
 // Old reports with no identifiable historical period cannot fall back to the
 // current default, while recent runs can use the sole exposed default.
 const client=createClient({accessToken:'fixture',fetcher:async(url,opts)=>{const {query}=JSON.parse(opts.body);return {ok:true,text:async()=>JSON.stringify({data:query.includes('partitions')?{worldData:{zone:{partitions:[{id:7,name:'Current rules',default:true}]}}}:{reportData:{report:{rankings:{data:[]}}}}})};}});
 assert.equal(await client.partitionFor({...metadata(targetCode),startTime:Date.now()-60000},fight),7);
 await assert.rejects(()=>client.partitionFor({...metadata(targetCode),startTime:Date.now()-30*86400000},fight),/could not be identified/);
 const ambiguous=createClient({accessToken:'fixture',fetcher:async(url,opts)=>{const {query}=JSON.parse(opts.body);return {ok:true,text:async()=>JSON.stringify({data:query.includes('partitions')?{worldData:{zone:{partitions:[{id:6,default:false},{id:7,default:true}]}}}:{reportData:{report:{rankings:{data:[]}}}}})};}});
 await assert.rejects(()=>ambiguous.partitionFor({...metadata(targetCode),startTime:Date.now()-60000},fight),/could not be identified/,'Recency does not prove the run used the current rules after a balance change');
 console.log('PASS: PKCE/state/replay/refresh, browser sign-in and recent runs, automatic peer selection, direct game delivery and Lua import, character/combat/duplicate protections, local request boundaries and historical-period handling. Simulated provider only.');
}
main().catch(error=>{console.error(error);process.exitCode=1;});
