const http=require('http'),fs=require('fs'),path=require('path');
const {randomBytes}=require('crypto');
const {createLogin}=require('./coaching-oauth.cjs');
const {reportCode,specFor}=require('./warcraftlogs-client.cjs');
const {collect}=require('./Review-WarcraftLogs.cjs');
const delivery=require('./coaching-delivery.cjs');
function publicClientId(){
 if(process.env.WCL_CLIENT_ID)return process.env.WCL_CLIENT_ID;
 try{const config=JSON.parse(fs.readFileSync(path.join(__dirname,'coaching-companion/config.json'),'utf8'));return typeof config.clientId==='string'?config.clientId:'';}catch{return '';}
}
function createCompanion({port=4318,clientId=publicClientId(),loginFactory=createLogin,collector=collect,discover=delivery.discover,send=delivery.deliver,validateInstall=delivery.addonDirectory,fetcher=fetch}={}){
 const origin='http://127.0.0.1:'+port,sessions=new Map();
 const reply=(res,status,data)=>{res.writeHead(status,{'Content-Type':'application/json; charset=utf-8'});res.end(JSON.stringify(data));};
 function session(req,res){
  const cookie=String(req.headers.cookie||'').split(';').map(s=>s.trim()).find(s=>s.startsWith('fc_coach='))?.slice(9);
  if(cookie&&sessions.has(cookie))return sessions.get(cookie);
  if(sessions.size>=20)throw Error('Close unused companion windows and restart the helper.');
  const id=randomBytes(32).toString('hex'),value={csrf:randomBytes(32).toString('hex'),login:loginFactory({clientId,redirectURI:origin+'/callback',fetcher}),user:null,report:null,busy:false,install:null};
  sessions.set(id,value);res.setHeader('Set-Cookie','fc_coach='+id+'; HttpOnly; SameSite=Lax; Path=/');return value;
 }
 const server=http.createServer(async(req,res)=>{
  res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('Referrer-Policy','no-referrer');
  res.setHeader('Content-Security-Policy',"default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'");
  if(req.headers.host!=='127.0.0.1:'+port||!['127.0.0.1','::ffff:127.0.0.1'].includes(req.socket.remoteAddress)||(req.headers.origin&&req.headers.origin!==origin)){reply(res,403,{error:'Open the companion from its local launcher.'});return;}
  let s;
  try{
   const url=new URL(req.url,origin);
   if(req.method==='GET'&&url.pathname==='/health'){reply(res,200,{service:'ForeverCoachingCompanion',pid:process.pid,startedAt:server.startedAt});return;}
   s=session(req,res);
   if(req.method==='GET'&&url.pathname==='/login'){res.writeHead(302,{Location:s.login.begin()});res.end();return;}
   if(req.method==='GET'&&url.pathname==='/callback'){
    const previousUser=s.user;
    try{s.user=await s.login.finish(Object.fromEntries(url.searchParams));s.report=null;s.notice=null;}catch(error){s.user=s.login.connected()?previousUser:null;s.notice=error.message;}
    // Drop the authorization code from the address bar before rendering assets.
    res.writeHead(303,{Location:'/'});res.end();return;
   }
   if(req.method==='GET'&&url.pathname==='/status'){
    reply(res,200,{configured:s.login.configured(),connected:s.login.connected(),user:s.user,csrf:s.csrf,installs:discover(),notice:s.notice});s.notice=null;return;
   }
   const assets={'/':'index.html','/companion.js':'companion.js','/companion.css':'companion.css'};
   if(req.method==='GET'&&assets[url.pathname]){
    const file=assets[url.pathname];res.writeHead(200,{'Content-Type':file.endsWith('.js')?'text/javascript':file.endsWith('.css')?'text/css':'text/html; charset=utf-8'});
    res.end(fs.readFileSync(path.join(__dirname,'coaching-companion',file)));return;
   }
   if(req.method!=='POST'||url.pathname!=='/action'){reply(res,404,{error:'Not found.'});return;}
   if(req.headers['x-coach-token']!==s.csrf||!String(req.headers['content-type']||'').startsWith('application/json')){reply(res,403,{error:'Reload the companion page and try again.'});return;}
   if(s.busy){reply(res,409,{error:'Your run is already being reviewed.'});return;}
   let size=0,chunks=[];for await(const chunk of req){size+=chunk.length;if(size>8192)throw Error('Request too large.');chunks.push(chunk);}
   const body=JSON.parse(Buffer.concat(chunks).toString());
   if(s.busy){reply(res,409,{error:'Your run is already being reviewed.'});return;}
   s.busy=true;
   try{
    if(body.action==='disconnect'){s.login.disconnect();s.user=null;s.report=null;s.install=null;reply(res,200,{message:'Disconnected. Sign-in tokens removed from memory.'});return;}
    if(!s.login.connected())throw Error('Sign in to Warcraft Logs first.');
    const client=s.login.client();
    if(body.action==='reports'){reply(res,200,{reports:await client.recentReports(s.user.id)});return;}
    if(body.action==='report'){
     s.report=null;const report=await client.report(reportCode(body.report));
     const fights=report.fights.filter(f=>f.encounterID>0&&!f.inProgress&&f.endTime>f.startTime);
     const players=report.masterData.actors.filter(a=>a.type==='Player'&&fights.some(f=>f.friendlyPlayers?.includes(a.id))).map(a=>({id:a.id,name:a.name,realm:a.server,class:a.subType}));
     s.report=report;reply(res,200,{code:report.code,title:report.title,players,fights:fights.map(f=>({id:f.id,name:f.name,kill:f.kill,players:f.friendlyPlayers,specs:f.friendlySpecs}))});return;
    }
    if(body.action==='review'){
     const report=s.report,actor=report?.masterData.actors.find(a=>a.type==='Player'&&a.id===body.actor),fight=report?.fights.find(f=>f.id===body.fight&&f.friendlyPlayers?.includes(body.actor));
     if(!actor||!fight||report.code!==body.report)throw Error('Choose a run, your character and an encounter first.');
     if(!['auto','dps','hps'].includes(body.metric||'auto'))throw Error('Choose damage or healing coaching.');
     const metric=body.metric&&body.metric!=='auto'?body.metric:/^(holy|restoration|discipline)$/i.test(specFor(report,fight,actor)||'')?'hps':'dps';
     const gameRoot=body.gameRoot;if(gameRoot)validateInstall(gameRoot);
     const results=await collector({report:report.code,player:actor.name,realm:actor.server,metric,partition:'auto',fightID:fight.id,output:null,client});
     const result=results[0];
     const exported=gameRoot?send(gameRoot,results):{sent:0,message:'Review ready here. Select your game folder and review again to send it to WoW.'};
     reply(res,200,{review:{encounter:result.encounter,url:result.url,analysis:result.analysis},delivery:exported});return;
    }
    throw Error('Unknown companion action.');
   }finally{s.busy=false;}
  }catch(error){reply(res,400,{error:error instanceof SyntaxError?'The request could not be read. Please try again.':error.message});}
 });
 server.startedAt=new Date().toISOString();
 server.on('close',()=>{for(const s of sessions.values())s.login.disconnect();sessions.clear();});
 return server;
}
if(require.main===module){const port=4318;createCompanion({port}).listen(port,'127.0.0.1',()=>process.stdout.write('Forever Coaching companion: http://127.0.0.1:'+port+'\n'));}
module.exports={createCompanion};
