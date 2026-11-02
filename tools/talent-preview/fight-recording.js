window.FightRecordingPage=(()=>{
 let host,example,recording=null,real=false,page=0,filter='all',status='';
 const el=(tag,text,cls)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n;};
 function button(text,action){const b=el('button',text);b.type='button';b.onclick=action;return b;}
 function validate(text){
  if(text.length>5000000)throw Error('Recording exceeds the 5 MB preview limit.');
  const value=JSON.parse(text),fight=value.fight;
  if(value.format!=='ForeverCoachingFight-v1'||!fight||!Array.isArray(fight.events)||fight.events.length>12000)throw Error('Paste an exported Forever Coaching fight recording.');
  for(const event of fight.events)if(!event||typeof event.kind!=='string'||event.kind.length>100||!Number.isFinite(event.time))throw Error('A timeline event is invalid.');
  return fight;
 }
 const matches=e=>filter==='all'||filter==='player'&&e.unit==='player'||filter==='casts'&&e.kind.startsWith('cast_')||filter==='state'&&['health','resource','death','movement_start','movement_stop','ability_state'].includes(e.kind)||filter==='auras'&&e.kind.startsWith('aura_')||filter==='coaching'&&['opportunity','targeted_response','role_warning','client_error'].includes(e.kind);
 function describe(e){
  if(e.kind==='health')return `Health ${e.health}/${e.maxHealth??'?'}${e.change!=null?' ('+(e.change>0?'+':'')+e.change+')':''}`;
  if(e.kind==='resource')return `Resource ${e.powerType??'?'}: ${e.power}/${e.maxPower??'?'}`;
  if(e.kind==='ability_state')return `${e.spellName||'Spell #'+e.spellID} · usable: ${e.usable??'unknown'} · range: ${e.inRange??'unknown'} · cooldown duration: ${e.cooldownDuration??'unknown'}`;
  return e.message||e.spellName||e.kind.replaceAll('_',' ');
 }
 function draw(){if(!host)return;host.replaceChildren();const fight=real?recording:example?.recording;
  host.append(el('h2','Fight recording'),el('p','The addon records readable fight events automatically in game. Open “View fight timeline” during or after combat to inspect actions and what needs investigation.'));
  const importer=el('details');importer.append(el('summary','Open your exported fight'));const input=el('textarea');input.rows=5;input.placeholder='Paste JSON from the addon’s Export fight button';
  importer.append(input,button('Open recording',()=>{try{recording=validate(input.value);real=true;page=0;status='Recording opened in this browser only.';input.value='';draw();}catch(error){status=error.message;draw();}}),el('p','In WoW: Combat Review → View fight timeline → Export fight. The browser cannot read live game memory.'));host.append(importer);
  if(status)host.append(el('p',status,'review-status'));
  host.append(el('p',real?'YOUR EXPORTED RECORDING':'EXAMPLE RECORDING — simulated preview, not your live fight.','review-status'));
  if(!fight){host.append(el('p','No recording loaded. Import a fight after playing.'));return;}
  host.append(el('h3',(fight.player||'Player')+' · '+(fight.events?.length||0)+' observed events'));
  const tabs=el('div',undefined,'slide-nav');for(const [value,label] of [['all','All events'],['player','Player actions'],['casts','Casts'],['state','Health, resources & movement'],['auras','Auras'],['coaching','Coaching evidence']]){const b=button(label,()=>{filter=value;page=0;draw();});b.setAttribute('aria-pressed',String(filter===value));tabs.append(b);}host.append(tabs);
  const events=(fight.events||[]).filter(matches),pages=Math.max(1,Math.ceil(events.length/40));page=Math.min(page,pages-1);
  const timeline=el('section',undefined,'fight-timeline');for(const e of events.slice(page*40,page*40+40)){const row=el('div',undefined,'fight-event');row.append(el('span',e.time.toFixed(1)+'s','fight-time'),el('span',e.unitName||e.unit||'Coach'),el('strong',e.kind.replaceAll('_',' ')),el('p',describe(e)+(e.targetName?' → '+e.targetName:'')));timeline.append(row);}host.append(timeline);
  const nav=el('div',undefined,'slide-nav'),previous=button('Previous',()=>{page--;draw();}),next=button('Next',()=>{page++;draw();});previous.disabled=page===0;next.disabled=page>=pages-1;nav.append(previous,el('span',`${page+1} / ${pages}`),next);host.append(nav);
  const review=el('details');review.append(el('summary','Review this recording'));const player=(fight.events||[]).filter(e=>e.unit==='player'),casts=player.filter(e=>e.kind==='cast_succeeded'),failures=player.filter(e=>['cast_failed','cast_interrupted'].includes(e.kind)),deaths=player.filter(e=>e.kind==='death');review.append(el('p',`${casts.length} successful casts · ${failures.length} failed/interrupted casts · ${deaths.length} deaths.`),el('p',failures.length?'Inspect a failed/interrupted cast alongside movement and client errors. Cancelling a cast can be the correct response to a mechanic.':'No failed/interrupted player casts in the recorded stream; this does not establish flawless play.'));host.append(review);
  if(Array.isArray(fight.scenarios?.windows)){
   const scenarios=el('section');scenarios.append(el('h3','Scenario review'),el('p','Scenarios can overlap. A successful cast confirms execution; its effect and whether it was the best choice are not established.'));
   for(const w of fight.scenarios.windows.slice(0,600)){
    const row=el('details');row.append(el('summary',`${w.title||w.id}: ${Number(w.started||0).toFixed(1)}–${Number(w.ended||w.started||0).toFixed(1)}s`),el('p',String(w.evidence||'')),el('p',`${Number(w.casts||0)} successful casts / ${Number(w.responses||0)} matching targeted responses / ${Number(w.failures||0)} failed or interrupted casts.`));
    for(const a of (Array.isArray(w.actions)?w.actions:[]).slice(0,80))row.append(el('p',`${Number(a.at||0).toFixed(1)}s / ${a.spell||''} / ${a.message||a.kind||''}`));
    if(w.partial)row.append(el('p','Action detail storage limit reached.'));
    scenarios.append(row);
   }
   scenarios.append(el('p',String(fight.scenarios.coverage||'')));host.append(scenarios);
  }
  const coverage=el('details');coverage.append(el('summary','Recording coverage'),el('p',fight.coverage||'Coverage not supplied.'),el('p',fight.truncated?'Storage limit reached: this is a partial timeline.':'The recorder stores a bounded timeline of readable events.'),el('p','Missing/restricted categories: '+(Object.keys(fight.missing||{}).join(', ')||'none flagged')));host.append(coverage);
 }
 return {render(panel,replay){host=panel;example=replay;draw();},validate};
})();
