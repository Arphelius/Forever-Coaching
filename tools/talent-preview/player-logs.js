window.CombatReviewPage=(()=>{
 let host,searchName='',matches=[],cursor=null,review=null,statistics=null,progress=null,busy=false,status='Search for a player to find their processed fights.';
 let watching=false,timer=null;
 let retryAt=0;
 function stop(){watching=false;if(timer!==null){clearTimeout(timer);timer=null;}}
 function schedule(){if(timer!==null)clearTimeout(timer);if(watching)timer=setTimeout(()=>{timer=null;if(host?.isConnected===false){stop();return;}search(false,true).then(schedule);},60000);}
 const el=(tag,text,cls)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n;};
 const button=(text,action)=>{const b=el('button',text);b.type='button';b.disabled=busy;b.onclick=action;return b;};
 async function request(action,data={}){const response=await fetch('/foreverlogs',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action,...data})});const result=await response.json();if(!response.ok)throw Error(result.error||'Unable to load player data.');return result;}
 async function run(action){if(busy)return;busy=true;draw();try{await action();}catch(error){status=error.message;stop();}finally{busy=false;draw();}}
 function search(older=false,retain=false){
  if(Date.now()<retryAt){status=`Forever Logs rate limit: wait ${Math.ceil((retryAt-Date.now())/1000)} seconds before resuming. Your search position is saved.`;draw();return Promise.resolve();}
  return run(async()=>{
   if(!older&&!retain){review=null;statistics=null;progress=null;}if(!older)matches=[];
   let next=older?cursor:null,checked=0,limited=false;
   for(let page=0;page<4;page++){
    status=`Searching processed fights for ${searchName}… ${checked} fights checked.`;draw();
    const result=await request('searchPlayers',{name:searchName,...(next?{cursor:next}:{})});
    matches=[...matches,...result.matches];checked+=result.inspected||0;next=result.nextCursor;cursor=next;
    if(result.rateLimited){limited=true;retryAt=Date.now()+(result.retryAfterSeconds||60)*1000;stop();status=`Search paused by Forever Logs' rate limit. ${checked} fights checked. Wait ${result.retryAfterSeconds||60} seconds, then resume; this does not mean the player was not found.`;break;}
    if(matches.length||!next)break;
   }
   if(!limited)status=matches.length?'Choose a fight to review.':cursor?`${checked} processed fights checked so far. No match yet; continue searching older fights.`:'No matching player in the available processed fights. Check the spelling or whether their logs have been uploaded.';
  });
 }
 function choose(selectionId){return run(async()=>{statistics=null;progress=null;review=null;const result=await request('playerReview',{selectionId});review=result.review;progress=await request('playerProgress',{selectionId});status=review.coverage;});}
 function draw(){if(!host)return;host.replaceChildren();
  host.append(el('h2','Find a player'),el('p','Find fights, review your performance, and track your progress.'));
  const form=el('section',undefined,'review-connection'),name=el('input');name.type='search';name.placeholder='Player name';name.value=searchName;name.autocomplete='off';name.disabled=busy;
  name.oninput=()=>{searchName=name.value;};name.onkeydown=e=>{if(e.key==='Enter')search();};
  const label=el('label','Player name');label.append(name);form.append(label,button('Search player',()=>search()));host.append(form);
  const message=el('p',status,'review-status');message.setAttribute('role','status');host.append(message);
  if(matches.length){const choices=el('section',undefined,'player-fights');choices.append(el('h3','Matching fights'));for(const fight of matches){const date=fight.date?new Date(fight.date).toLocaleString():'Date unavailable';choices.append(button(`${fight.player} · ${fight.encounter} · ${date}`,()=>choose(fight.selectionId)));}host.append(choices);}
  if(cursor)host.append(button('Search older fights',()=>search(true)));
  if(matches.length)host.append(button(watching?'Stop checking for new fights':'Check for new fights every minute',()=>{if(watching)stop();else{watching=true;schedule();}draw();}));
  if(review){
   host.append(el('h3',review.player+' · '+review.encounter));
   const metrics=el('div',undefined,'review-totals');for(const [name,value] of [['Damage/sec',review.damagePerSecond],['Healing/sec',review.healingPerSecond],['Deaths',review.deaths]])metrics.append(el('span',name+': '+(value??'Unavailable')));host.append(metrics);
   if(review.complete&&review.comparison?.rank)host.append(el('p',`Damage position in this fight: ${review.comparison.rank} of ${review.comparison.players} players, across all roles. This is not a parse percentile.`));
   const good=review.good?.[0],next=review.improve?.[0],setback=review.setbacks?.[0];
   for(const [title,finding] of [['What went well',good],['What to improve',next]]){const card=el('section',undefined,'review-card');card.append(el('h3',title),el('p',finding?.what||'Not enough evidence to assess this yet.'));if(finding?.next)card.append(el('p',finding.next));host.append(card);}
   if(review.deaths&&setback)host.append(el('p',setback.what));
   host.append(el('p','Parse percentile: unavailable from the source API.'));
   if(progress){const trend=el('section');trend.append(el('h3','Your progress'));if(progress.fights.length<2)trend.append(el('p','Review another fight against this encounter to start comparing your progress.'));else for(const fight of progress.fights.slice(-5))trend.append(el('p',`${fight.date?new Date(fight.date).toLocaleDateString():'Undated'} · ${fight.damagePerSecond??'?'} damage/sec · ${fight.healingPerSecond??'?'} healing/sec · ${fight.deaths} deaths${fight.complete?'':' · partial'}`));trend.append(el('p',progress.label));host.append(trend);}
   host.append(button(statistics?'Hide advanced statistics':'More advanced statistics',()=>{if(statistics){statistics=null;draw();}else run(async()=>{statistics=(await request('playerStatistics',{selectionId:review.selectionId})).statistics;});}));
   if(statistics){const advanced=el('section',undefined,'review-card');advanced.append(el('h3','Detailed performance'),el('p',statistics.comparisonNote));for(const [label,value] of Object.entries(statistics.totals))advanced.append(el('p',label+': '+value));for(const player of statistics.players)advanced.append(el('p',`${player.player}: ${player.damage} damage · ${player.healing} healing · ${player.deaths} deaths`));for(const ability of statistics.abilities)advanced.append(el('p',`Spell #${ability.spellId}: ${ability.casts} casts · ${ability.damage} damage · ${ability.healing} healing`));advanced.append(el('p',review.identityNote));host.append(advanced);}
  }
  host.append(el('p','Updates when fights have been uploaded and processed. Live in-game prompts use local combat observations.'));
  const source=el('a','Combat data: Forever Logs');source.href='https://foreverlogs.gg/';source.target='_blank';source.rel='noreferrer';host.append(source);
 }
 return {render(panel){host=panel;draw();}};
})();
