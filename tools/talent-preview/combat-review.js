window.ForeverLogsOwnerPage=(()=>{
 let host,localReview,mode=new URLSearchParams(location.search).get('demo')==='1'?'demo':'logs',connected=false,busy=false,status='Connect your events:read key to choose a fight.',checked=false;
 let reports=[],encounters=[],actors=[],reportId='',encounterId='',actorId='',review=null;
 let contextText='';
 let configured=false,logsOnly=false,offset=0,watching=false,watchTimer=null;
 let ownerToken=null;
 let requestDone=Promise.resolve();
 function stopWatching(){watching=false;if(watchTimer!==null){clearTimeout(watchTimer);watchTimer=null;}}
 function watch(){if(watchTimer!==null)clearTimeout(watchTimer);if(!watching)return;watchTimer=setTimeout(()=>{watchTimer=null;if(!connected||host?.isConnected===false||host?.hidden){stopWatching();return;}call('reports',{offset:0},r=>{offset=0;reports=r.reports;status='Latest processed public reports refreshed. Choose a report to review.';}).then(watch);},60000);}
 const el=(tag,text,cls)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n;};
 const button=(text,action)=>{const b=el('button',text);b.type='button';b.disabled=busy;b.onclick=action;return b;};
 const field=(title,node)=>{const label=el('label',title);label.append(node);return label;};
 function redraw(){if(host&&!host.hidden)render(host,localReview);}
 async function call(action,data={},apply=()=>{}){
  if(busy)return;busy=true;status=action==='review'?'Reading the encounter events and building your review…':'Connecting to Forever Logs…';redraw();
  let finish;requestDone=new Promise(resolve=>{finish=resolve;});
  try{const response=await fetch('/foreverlogs',{method:'POST',headers:{'Content-Type':'application/json',...(ownerToken?{'X-Forever-Owner-Token':ownerToken}:{})},body:JSON.stringify({action,...data})});const result=await response.json();if(!response.ok)throw Error(result.error||'Request failed.');apply(result);}
  catch(error){status=error.message;stopWatching();}finally{busy=false;redraw();finish();}
 }
 function select(options,current,change,placeholder){const s=el('select');s.add(new Option(placeholder,''));for(const [id,text] of options)s.add(new Option(text,id));s.value=current;s.disabled=busy;s.onchange=()=>change(s.value);return s;}
 function findingCard(title,items,kind){const card=el('section',undefined,'review-card review-'+kind);card.append(el('h3',title));
  for(const item of items||[]){const entry=el('div',undefined,'review-finding');entry.append(el('h4',item.title),el('p',item.what),el('p',item.why,'review-explanation'));
   if(item.next)entry.append(el('p',item.next,'review-action'));
   if(item.contextOrigin)entry.append(el('p',item.contextOrigin,'review-coverage'));
   if(item.sourceUrl){const source=el('a','Decision evidence source');source.href=item.sourceUrl;source.target='_blank';source.rel='noreferrer';entry.append(source);}
   if(item.evidence?.length){const details=el('details');details.append(el('summary','View event evidence'));for(const e of item.evidence)details.append(el('p',`${e.time} · ${e.event}${e.spellId!==null?' · spell #'+e.spellId:''}${e.amount!==null?' · '+e.amount:''}`,'review-evidence'));entry.append(details);}card.append(entry);
  }return card;
 }
 function render(panel,demo,options){host=panel;localReview=demo;if(options)logsOnly=options.logsOnly===true;if(logsOnly)mode='logs';panel.replaceChildren();
  const header=el('div',undefined,'review-header');header.append(el('span','OWNER ACCESS','review-eyebrow'),el('h2','Owner report tools'),el('p','Report browsing, event evidence and imports are restricted to the configured key owner.'));panel.append(header);
  if(!logsOnly){const tabs=el('div',undefined,'review-source-tabs');tabs.append(button('Forever Logs',()=>{mode='logs';redraw();}),button('Local demo',()=>{mode='demo';redraw();}));panel.append(tabs);}
  if(mode==='demo'){
   panel.append(el('p','DEMO — simulated encounter replay. This is not your Forever Logs data.','review-status'));
   const columns=el('div',undefined,'review-columns');columns.append(findingCard('WHAT YOU DID WELL',[{title:'Recorded actions',what:demo.goodText||demo.observation}],'good'),findingCard('WHAT WENT WRONG',[{title:'Recorded setbacks',what:demo.wrongText||demo.takeaway}],'wrong'),findingCard('WHAT TO IMPROVE',[{title:'Next fight',what:demo.improveText||demo.nextStep}],'improve'));panel.append(columns);return;
  }
  const connection=el('section',undefined,'review-connection');connection.append(el('h3',connected?'Forever Logs connected':'Connect Forever Logs'));
  connection.append(el('p','Reads public, fully processed reports authorized by your events:read key. This API does not provide a live combat stream or unrestricted database access.'));
  if(!connected){const key=el('input');key.type='password';key.autocomplete='off';key.placeholder='Full key with events:read';key.spellcheck=false;
   const connect=()=>{const value=key.value;key.value='';call('connect',{key:value},r=>{ownerToken=r.ownerToken;connected=true;reports=r.reports;status='Owner verified. Report tools unlocked for this session.';});};
   key.onkeydown=e=>{if(e.key==='Enter')connect();};connection.append(field('API key',key),button('Connect',connect),el('p','Your key stays in the local helper’s memory until you disconnect or close it. It is not saved in the addon.'));
  }else{
   connection.append(button('Load recent reports',()=>call('reports',{offset:0},r=>{offset=0;reports=r.reports;status='Reports loaded.';})),button('Disconnect',()=>{stopWatching();call('disconnect',{},()=>{connected=false;configured=false;review=null;reports=[];encounters=[];actors=[];reportId=encounterId=actorId='';status='Disconnected. Key removed from the helper.';});}));
   const previous=button('Previous reports',()=>call('reports',{offset:Math.max(0,offset-20)},r=>{offset=Math.max(0,offset-20);reports=r.reports;status='Report page loaded.';}));previous.disabled=busy||offset===0;
   const next=button('Next reports',()=>call('reports',{offset:offset+20},r=>{offset+=20;reports=r.reports;status='Report page loaded.';}));next.disabled=busy||reports.length<20;
   connection.append(previous,el('span','Reports '+(offset+1)+'–'+(offset+reports.length)),next,button(watching?'Stop watching reports':'Watch for processed reports',()=>{if(watching)stopWatching();else{watching=true;watch();}redraw();}),el('p','Watching refreshes the report list every 60 seconds while this page is open. It does not stream in-progress fights or change your selected review.'));
   const loadReport=value=>{reportId=value;encounterId=actorId='';encounters=[];actors=[];review=null;if(value)call('report',{reportId:value},r=>{encounters=r.encounters;status='Choose an encounter.';});};
   connection.append(field('Public report',select(reports.map(r=>[r.id,`${r.title||'Report'} (#${r.id})`]),reportId,loadReport,'Choose a report')));
   const number=el('input');number.type='number';number.min='1';number.placeholder='Report ID';connection.append(field('Or enter a report ID',number),button('Load report',()=>loadReport(number.value)));
   if(encounters.length)connection.append(field('Encounter',select(encounters.map(e=>[e.id,`${e.name||'Encounter'} (#${e.id})`]),encounterId,value=>{encounterId=value;actorId='';actors=[];review=null;if(value)call('actors',{reportId,encounterId:value},r=>{actors=r.actors.filter(a=>a.is_player===true||a.character_type==='player');status='Choose the player to review.';});},'Choose an encounter')));
   if(actors.length)connection.append(field('Player',select(actors.map(a=>[a.id,a.name]),actorId,value=>{actorId=value;review=null;redraw();},'Choose a player')));
   if(actorId){
    const details=el('details');details.append(el('summary','Encounter rules and fight-time build (JSON)'));
    const context=el('textarea');context.rows=8;context.value=contextText;context.placeholder='Optional attributed encounter context. See docs/encounter-context.example.json';context.oninput=()=>{contextText=context.value;};details.append(context,el('p','Rules must match this report, encounter and player. Supplied assignments and availability are labeled separately from log observations.'));connection.append(details);
    connection.append(button('Analyze this fight',()=>{let context=null;try{if(contextText.trim())context=JSON.parse(contextText);}catch{status='Encounter context is not valid JSON.';redraw();return;}call('review',{reportId,encounterId,actorId,context},r=>{review=r.review;status=review.complete?'Review ready. Full event stream retrieved.':'Partial review ready. Some event pages were not retrieved.';});}));
   }
  }
  panel.append(connection);const message=el('p',status,'review-status');message.setAttribute('role','status');panel.append(message);
  if(review){
   panel.append(el('p','Build at fight time: '+review.buildContext?.status+'. '+(review.buildContext?.explanation||'')));
   panel.append(el('h3',review.metrics,'review-fight-title'));const facts=el('div',undefined,'review-totals');for(const [label,value] of Object.entries(review.totals))facts.append(el('span',`${label}: ${value}`));panel.append(facts);
   const columns=el('div',undefined,'review-columns');columns.append(findingCard('WHAT YOU DID WELL',review.good,'good'),findingCard('WHAT WENT WRONG',review.wrong,'wrong'),findingCard('WHAT TO IMPROVE',review.improve,'improve'));panel.append(columns);
   const group=el('details');group.append(el('summary','Every player: encounter context'));
   for(const player of review.group||[])group.append(el('p',`${player.player}${player.selected?' (you)':''}: ${player.casts} casts, ${player.interrupts.length} interrupts, ${player.dispels.length} dispels, ${player.deaths.length} deaths.`));panel.append(group);
   const abilities=el('details');abilities.append(el('summary','Your abilities and targets'));
   for(const a of review.abilities||[])abilities.append(el('p',`Spell #${a.spellId}: ${a.casts} casts, ${a.damage} damage, ${a.healing} healing; target IDs: ${a.targets.join(', ')}.`));panel.append(abilities);
   for(const death of review.deathWindows||[]){const detail=el('details');detail.append(el('summary','Your final 10 seconds before death at '+death.time));for(const e of death.events)detail.append(el('p',`${e.time} · ${e.event} · ${e.sourceId} → ${e.targetId} · spell #${e.spellId} · ${e.amount??''}`));panel.append(detail);}
   panel.append(el('h3','Encounter decisions to investigate'));
   for(const topic of review.decisionCoverage||[]){const detail=el('details');detail.append(el('summary',topic.title+' — '+topic.status),el('p',topic.explanation),el('p','Before the next pull: '+topic.prepare),el('p','Response to practice: '+topic.react));panel.append(detail);}
   panel.append(el('p',review.coverage,'review-coverage'),button('Import this review into the addon',()=>call('import',{},r=>{status=r.message;})));
  }else panel.append(el('div','Your review will appear here after you select a fight. Each finding includes what happened, why it matters, and the supporting timestamps.','review-empty'));
  const source=el('a','Combat events provided by Forever Logs');source.href='https://foreverlogs.gg/';source.target='_blank';source.rel='noreferrer';panel.append(source);
  if(!checked){checked=true;fetch('/foreverlogs').then(r=>r.json()).then(r=>{connected=!!ownerToken&&r.connected;configured=r.configured;redraw();}).catch(()=>{status='Local helper unavailable. Restart Preview-Addon.cmd.';redraw();});}
 }
 return {render,lock:async()=>{stopWatching();await requestDone;if(ownerToken)await call('lockOwner');ownerToken=null;connected=false;reports=[];encounters=[];actors=[];review=null;}};
})();
