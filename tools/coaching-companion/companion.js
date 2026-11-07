(()=>{
 const host=document.getElementById('app');
 let state=null,reports=[],report=null,result=null,actor='',fight='',gameRoot='',busy=false,message='Loading your connection…',metric='auto';
 const el=(tag,text,cls)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n;};
 function button(text,fn,secondary=false){const b=el('button',text,secondary?'secondary':undefined);b.type='button';b.disabled=busy;b.onclick=fn;return b;}
 function input(labelText,value,change){const label=el('label',labelText),i=el('input');i.value=value;i.disabled=busy;i.onchange=()=>change(i.value);label.append(i);return label;}
 function select(labelText,rows,value,change){const label=el('label',labelText),s=el('select');s.add(new Option('Choose…',''));for(const row of rows)s.add(new Option(row.label,String(row.value)));s.value=value;s.disabled=busy;s.onchange=()=>change(s.value);label.append(s);return label;}
 async function call(action,data={}){
  const response=await fetch('/action',{method:'POST',headers:{'Content-Type':'application/json','X-Coach-Token':state.csrf},body:JSON.stringify({action,...data})});
  const body=await response.json();if(!response.ok)throw Error(body.error||'Please try again.');return body;
 }
 async function work(text,fn){if(busy)return;busy=true;message=text;render();try{await fn();}catch(error){message=error.message;}finally{busy=false;render();}}
 async function loadReports(){const data=await call('reports');reports=data.reports;message=reports.length?'Choose your uploaded run.':'No personal reports found. Upload a run first, or use a report shared by your group.';}
 async function loadReport(code){await work('Loading your run…',async()=>{
  report=null;result=null;actor='';fight='';const data=await call('report',{report:code});report=data;
  let remembered;try{remembered=localStorage.getItem('fc-character-'+state.user.id);}catch{}
  const saved=data.players.find(p=>p.name+'@'+p.realm===remembered);
  if(saved)actor=String(saved.id);else if(data.players.length===1)actor=String(data.players[0].id);
  chooseFight();message='Choose your character and encounter, then review your run.';
 });}
 function chooseFight(){const choices=(report?.fights||[]).filter(f=>f.players.includes(Number(actor)));fight=choices.length?String(choices[choices.length-1].id):'';}
 function render(){
  host.replaceChildren();
  if(!state){host.append(el('p',message,'notice'));return;}
  const connection=el('section');connection.append(el('h2',state.connected?'Connected to Warcraft Logs':'1. Connect your account'));
  if(!state.configured){connection.append(el('p','Sign-in is not enabled in this build yet. The addon publisher needs to finish the connection setup. You do not need to create API keys.','notice'));}
  else if(!state.connected){const link=el('a','Sign in with Warcraft Logs','button');link.href='/login';connection.append(link,el('p','Sign in on Warcraft Logs. Your password is never entered here.','muted'));}
  else{connection.append(el('p','Signed in as '+state.user.name),button('Refresh my runs',()=>work('Looking for your recent runs…',loadReports),true),document.createTextNode(' '),button('Disconnect',()=>work('Disconnecting…',async()=>{await call('disconnect');location.reload();}),true));}
  host.append(connection);
  if(state.connected){
   const run=el('section');run.append(el('h2','2. Choose your run'));
   run.append(select('Uploaded run',reports.map(r=>({value:r.code,label:r.title+' — '+new Date(r.startTime).toLocaleDateString()})),report?.code||'',code=>{if(code)loadReport(code);}));
   const shared=el('details');shared.append(el('summary','A group member uploaded the run?'));
   let url='';shared.append(input('Shared Warcraft Logs report link','',v=>{url=v;}),button('Open shared run',()=>{if(url.trim())loadReport(url.trim());}));run.append(shared);
   if(report){
    run.append(select('Your character',report.players.map(p=>({value:p.id,label:p.name+' — '+p.realm+' / '+p.class})),actor,value=>{actor=value;result=null;chooseFight();render();}));
    if(actor)run.append(select('Encounter',report.fights.filter(f=>f.players.includes(Number(actor))).map(f=>({value:f.id,label:f.name+' — '+(f.kill?'completed':'attempt')})),fight,value=>{fight=value;result=null;render();}));
    if(actor&&fight){
     const chosen=report.fights.find(f=>f.id===Number(fight)),index=chosen.players.indexOf(Number(actor));run.append(el('p','Recorded spec: '+(chosen.specs?.[index]||'Unavailable'),'muted'));
     const options=el('details');options.append(el('summary','Coaching preference'),select('Focus',[{value:'auto',label:'Choose from my recorded spec'},{value:'dps',label:'Damage'},{value:'hps',label:'Healing'}],metric,v=>{metric=v;}));run.append(options);
     if(state.installs.length)run.append(select('Send to WoW',state.installs.map(p=>({value:p,label:p})),gameRoot,v=>{gameRoot=v;}));
     else run.append(input('Forever game folder (optional — review here without it)',gameRoot,v=>{gameRoot=v;}));
     const review=button(gameRoot?'Review my run and send to WoW':'Review my run',()=>work('Finding matching players and comparing your decisions. This can take a few minutes…',async()=>{
      const data=await call('review',{report:report.code,actor:Number(actor),fight:Number(fight),gameRoot:gameRoot||null,metric});result=data.review;message=data.delivery.message;
      const p=report.players.find(p=>p.id===Number(actor));try{localStorage.setItem('fc-character-'+state.user.id,p.name+'@'+p.realm);}catch{}
     }));run.append(review);
    }
   }
   host.append(run);
  }
  host.append(el('p',message,'notice'));
  if(result){
   const analysis=result.analysis,summary=el('section');summary.append(el('h2',result.encounter),el('p',analysis.mentoring.ready?'Peer coaching ready — '+analysis.mentoring.context.peerCount+' matching reference players.':'Matching reference fights are still needed.',analysis.mentoring.ready?'ready':'muted'));host.append(summary);
   const columns=el('div',undefined,'columns');
   for(const [title,kind,text] of [['Keep doing this','good',analysis.good],['Change to practice','change',analysis.observations],['Next pull','practice',analysis.improve]]){
    const card=el('section');card.append(el('h2',title));
    const findings=analysis.mentoring.findings.filter(f=>kind==='good'?f.kind==='good':kind==='change'?['change','context','unavailable'].includes(f.kind):f.kind==='change');
    if(findings.length){for(const f of findings.slice(0,6)){const item=el('div',undefined,'finding');item.append(el('h3',f.title),el('p',kind==='practice'?f.next:f.what),el('p',kind==='practice'?'':f.why,'muted'));card.append(item);}}
    else card.append(el('p',text));columns.append(card);
   }
   host.append(columns);
   const evidence=el('details');evidence.append(el('summary','Reference players and evidence'),el('p',analysis.coverage));
   for(const peer of analysis.mentoring.context.referencePlayers){const p=el('p'),a=el('a',peer.player+' / '+peer.spec+' / '+peer.percentile+' percentile');a.href=peer.url;a.target='_blank';a.rel='noopener noreferrer';p.append(a);evidence.append(p);}
   host.append(evidence);
  }
 }
 async function start(){try{const response=await fetch('/status');if(!response.ok)throw Error('Open this page from Review-My-Run.cmd.');state=await response.json();gameRoot=state.installs[0]||'';message=state.notice||(state.connected?'Loading your uploaded runs…':'Connect once, then choose an uploaded run.');if(state.connected)await work(message,loadReports);else render();}catch(error){message=error.message;render();}}
 render();start();
})();
