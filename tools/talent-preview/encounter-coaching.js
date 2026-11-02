// Shared review curriculum. These are practice prompts, never inferred mistakes.
(function(root){
 const topics=[
 ['movement','Mechanics and movement','Identify the mechanic and its safe position before committing to a cast.','Move out of danger first; use a suitable instant ability or movement tool while relocating.','Mechanic timeline, position, movement and cast availability'],
 ['interrupt','Interrupts','Agree which enemy casts you are assigned to stop and keep a backup.','Interrupt the assigned dangerous cast while it is interruptible; avoid duplicating a teammate.','Enemy cast window, assignment, range, interrupt readiness and group interrupts'],
 ['mana','Mana and recovery','Budget resources for the expected fight length and the next pull.','Use efficient actions during low pressure; drink between pulls when safe and restore health with food if needed.','Resource history, costs, regeneration, pressure and consumable events'],
 ['cooldowns','Burst and cooldown planning','Identify priority damage or healing windows and the next larger pull.','Commit cooldowns when their benefit is needed; hold only when the upcoming window justifies losing a use.','Cooldown availability, fight duration, pull schedule and burst windows'],
 ['rotation','Ability choices','Check the selected build, learned abilities, procs and target count.','Choose an action that fits the current proc, resource budget and mechanic instead of following a fixed sequence.','Build at fight time, spell ranks, procs, cooldowns and simulation assumptions'],
 ['range','Range and positioning','Plan a position that reaches assigned targets while respecting the mechanic.','Reposition when safe; a range failure alone does not prove the movement was wrong.','Position or range samples, target, mechanic and action timing'],
 ['targets','Priority targets and crowd control','Agree kill order and crowd control assignments before the pull.','Focus the required target; control dangerous enemies and avoid breaking assigned control.','Target identities, priority windows, control effects and assignments'],
 ['support','Buffs, dispels and cures','Know which buffs and magic, curse, poison or disease effects your build can handle.','Apply missing required buffs and remove assigned harmful effects when safe; check whether dispelling triggers another mechanic.','Aura identity, dispel type, removal outcome, assignment and mechanic rules'],
 ['healing','Healing and defensives','Plan healing, personal defensives and external help for incoming damage.','Stabilize endangered players and use an appropriate defensive before predictable damage.','Health, incoming damage, healing, absorbs, cooldowns and damage forecast'],
 ['speed','Movement speed and preparation','Identify travel, escape and group movement windows.','Use an available movement tool when it helps meet the mechanic; prepare buffs, food and mana before the next pull.','Movement requirement, speed effects, readiness and preparation events']
 ].map(([id,title,prepare,react,requires])=>({id,title,prepare,react,requires}));
 const positions={};
 let learnMode='abilities';
 const api={topics,render(panel,state,page,el){
  panel.replaceChildren?.();
  panel.append(el('h2',page==='learn'?'Learn your chosen build':'Your specialization in each scenario'));
  const build=state.build||{title:'Class toolkit preview',role:'unspecified',talents:[]};
  panel.append(el('p',`${build.title} · ${build.role||'unspecified'} · Level ${state.level}`));
  const again=()=>api.render(panel,state,page,el);
  if(page==='scenarios'){
   if(!state.specScenarios?.available){panel.append(el('p',state.specScenarios?.notice||'Select a build to preview its specialization-specific scenarios.'));return;}
  }
  if(page==='learn'){
   const tabs=el('div',undefined,'slide-nav');
   for(const [value,title] of [['abilities','Class ability lessons'],['talents','Talents in this build']]){const b=el('button',title);b.setAttribute?.('aria-pressed',String(learnMode===value));b.onclick=()=>{learnMode=value;again();};tabs.append(b);}panel.append(tabs);
  }
  const mode=page==='scenarios'?'scenarios':learnMode;
  const items=mode==='scenarios'?state.specScenarios.scenarios:mode==='abilities'?(state.abilityLessons||[]):(build.talents||[]);
  const key=`${mode}:${build.id||state.abilityLessons?.[0]?.name||'toolkit'}`;
  const index=Math.min(positions[key]||0,Math.max(0,items.length-1));
  if(!items.length){panel.append(el('p',mode==='talents'?'Choose a build above to inspect its talents.':'No ability lessons available.'));return;}
  const controls=el('div',undefined,'slide-nav');
  const previous=el('button','Previous');previous.disabled=index===0;previous.onclick=()=>{positions[key]=index-1;again();};
  const next=el('button','Next');next.disabled=index===items.length-1;next.onclick=()=>{positions[key]=index+1;again();};
  const picker=el('select');picker.setAttribute?.('aria-label',mode==='scenarios'?'Choose a scenario':'Choose a lesson');
  items.forEach((item,i)=>{const option=el('option',item.title||item.name);option.value=String(i);picker.append(option);});picker.value=String(index);picker.onchange=()=>{positions[key]=Number(picker.value);again();};
  controls.append(previous,el('span',`${index+1} / ${items.length}`),next,picker);panel.append(controls);
  const item=items[index],card=el('section',undefined,'review-card');card.append(el('h3',item.title||item.name));
  if(mode==='scenarios'){
   card.append(el('h4','When'),el('p',item.trigger),el('h4','Before'),el('p',item.prepare));
   for(const [index,step] of (item.steps||[]).entries()){
    const action=el('section',undefined,'scenario-action');action.append(el('h4',`${index+1}. ${step.action}`),el('p','When: '+step.when),el('p','Why: '+step.why));card.append(action);
   }
   if(!item.steps?.length)card.append(el('p',item.react));
   card.append(el('h4','Avoid','scenario-avoid'),el('p',item.avoid));
   if(item.unavailable?.length){const omitted=el('details');omitted.append(el('summary','Abilities not included in this checklist'),el('p',item.unavailable.join(', ')));card.append(omitted);}
   const evidence=el('details');evidence.append(el('summary','Talents in this allocation and guidance basis'),el('p',state.specScenarios.confidence));
   if(item.brings)evidence.append(el('p','Group tools: '+item.brings));
   for(const talent of state.specScenarios.talentEffects||[])evidence.append(el('p',`${talent.name} ${talent.rank}: ${talent.effect}`));card.append(evidence);
  }else if(mode==='abilities'){
   card.append(el('h4','What it does'),el('p',item.description||'Effect unavailable for this ability.'),el('h4','Why it is used'),el('p',item.why),el('h4','When to use it'),el('p',item.when));
  }
  else {
   const lesson=(state.talentLessons||[]).find(lesson=>lesson.name===item.name);
   card.append(el('p',`Rank ${item.rank}`));
   if(lesson){
    card.append(el('h4','What it does'),el('p',lesson.effect),el('h4','Why it is used'),el('p',lesson.why),el('h4','Good for this build'),el('p',lesson.buildBenefit||lesson.why));
    const evidence=el('details');evidence.append(el('summary','Talent evidence and confidence'),el('p',lesson.provenance),el('p',lesson.guidanceBasis));
    for(const [url,label] of [[lesson.sourceUrl,'Pinned talent effect source'],[lesson.auditUrl,'Source audit corrections'],[lesson.confirmationUrl,'Beta rank confirmation']]){if(url){const a=el('a',label);a.href=url;a.target='_blank';a.rel='noreferrer';evidence.append(a);}}card.append(evidence);
   }else card.append(el('p','Talent effect data is unavailable for this selection. Check the current client tooltip.'));
  }
  panel.append(card);
  const sourceUrl=mode==='scenarios'?state.specScenarios.sourceUrl:mode==='abilities'?item.sourceUrl:null;
  if(sourceUrl){const sources=el('details');sources.append(el('summary','Source'));const source=el('a','ForeverChanges');source.href=sourceUrl;source.target='_blank';source.rel='noopener noreferrer';sources.append(source);panel.append(sources);}
  const reference=el('details');reference.append(el('summary','Build reference and preview limits'),el('p','The browser uses the selected plan and class catalog; the game filters lessons against actual learned abilities.'));
  if(build.note)reference.append(el('p',build.note));
  const guideUrl=state.buildEvidenceUrl||(/^https:\/\/(www\.)?mobalytics\.gg\//.test(build.source?.url||'')?build.source.url:'https://mobalytics.gg/wow-forever');
  const guide=el('a','Mobalytics');guide.href=guideUrl;guide.target='_blank';guide.rel='noreferrer';reference.append(guide);panel.append(reference);
 }};
 if(typeof module!=='undefined'&&module.exports)module.exports=api;
 else root.EncounterCoaching=api;
})(typeof window==='undefined'?globalThis:window);
