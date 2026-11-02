const $=id=>document.getElementById(id);
const classes=['DRUID','HUNTER','MAGE','PALADIN','PRIEST','ROGUE','SHAMAN','WARLOCK','WARRIOR'];
const colors=['#ff7d0a','#abd473','#69ccf0','#f58cba','#eeeeee','#fff569','#398bea','#9482c9','#c79c6e'];
for(const cls of classes){const option=new Option(cls[0]+cls.slice(1).toLowerCase(),cls);$('class').add(option);} $('class').value='SHAMAN';
const initialPage=new URLSearchParams(location.search).get('page');
let selected=0,learned={},state,request=0,page=['review','scenarios','learn','gear','resources'].includes(initialPage)?initialPage:'talents',reviewCase='failed',coachingCase='responded';
let vfxEnabled=true;
let reviewSource=new URLSearchParams(location.search).get('source')==='logs'?'logs':'replay',reviewSlide='timeline';
try{vfxEnabled=localStorage.getItem('fc-talent-vfx')!=='off';}catch{}
function syncVFXButton(){const b=$('toggle-vfx');b.textContent=vfxEnabled?'VFX: On':'VFX: Off';b.setAttribute('aria-pressed',String(vfxEnabled));}
syncVFXButton();
const element=(tag,text,cls)=>{const e=document.createElement(tag);if(text!==undefined)e.textContent=text;if(cls)e.className=cls;return e;};
async function refresh(){
 const ticket=++request;
 const params=new URLSearchParams({class:$('class').value,activity:$('activity').value,level:$('level').value,legacy:$('legacy').value,build:selected,learned:JSON.stringify(learned),reviewCase,coachingCase});
 const custom=window.CustomTalentBuilds?.request();if(custom){params.set('custom',JSON.stringify(custom.draft));if(custom.change)params.set('customChange',JSON.stringify(custom.change));}
 try{const response=await fetch('/state?'+params);const result=await response.json();if(ticket!==request)return;if(!response.ok)throw Error(result.error);state=result;render();$('error').textContent='';}
 catch(error){if(ticket===request)$('error').textContent=error.message;}
}
function render(){
 const isCustom=window.CustomTalentBuilds?.isActive();
 window.AddonI18n?.setProtectedNames([state.build?.title,...(state.abilityLessons||[]).map(l=>l.name),...(state.layout||[]).flatMap(t=>[t.name,...t.nodes.map(n=>n.name)]),...(state.choices||[]).flatMap(c=>[c.title,c.spec])]);
 document.documentElement.style.setProperty('--accent',colors[classes.indexOf($('class').value)]);
 $('builds').replaceChildren();
 for(const choice of state.choices||[]){const b=element('button',undefined,choice.index===selected?'active':'');b.append(element('strong',choice.spec),element('span',choice.title));if(choice.recommended)b.append(element('small','Recommended · '+choice.role));b.onclick=()=>{selected=choice.index;refresh();};$('builds').append(b);}
 const choice=(state.choices||[]).find(c=>c.index===selected);
 $('title').textContent=state.build?.title||'Select a build';$('summary').textContent=state.build?`${state.build.role||''} · ${state.build.distribution||''}`:'Choose a build.';
 $('source').hidden=!choice?.source;if(choice?.source)$('source').href=choice.source;
 $('stats').textContent=`Level ${state.level} · ${state.available} unspent · ${state.spent}/${state.budget} learned`;
 const next=state.nextPoint;
 const previewEffects=$('preview-effects').checked;
 const designOnly=!next&&!(state.order||[]).length&&state.designPreviewPoint;
 const effectStep=next||(Array.isArray(state.order)?state.order[0]:null)||state.designPreviewPoint;
 const focus=!!(!isCustom&&next&&state.available>0&&!state.locked&&!state.overBudget);
 $('trees').classList.toggle('focus',focus);
 $('next').textContent=state.overBudget?'Too many learned points for these settings. Reset points or raise the level.':next?`${state.available?'Next point':'Upcoming talent'}: ${next.name} ${next.rank}/${next.maxRank}${state.locked?' — tree row is locked':''}`:state.build?((state.order||[]).length?'This allocation is complete.':`Point order unavailable: ${state.orderType||'No recorded progression.'} See the build allocation below.`):'Choose a build first.';
 $('learn').disabled=!next||!state.available||state.locked||state.overBudget;
 $('trees').replaceChildren();
 for(const [ti,tree] of (state.layout||[]).entries()){
  const section=element('section',undefined,'tree');section.append(element('h2',tree.name));const nodes=element('div',undefined,'nodes');
  section.style.setProperty('--tree-art',`url('/classic-theme/${$('class').value}-${ti+1}.jpg')`);
  for(const [ni,node] of tree.nodes.entries()){
   const key=`${ti+1}:${ni+1}`,rank=(isCustom?state.custom?.draft.ranks[key]:state.ranks[key])||0;
   const highlighted=next&&next.treeIndex===ti+1&&next.talentIndex===ni+1&&state.available>0&&!state.locked&&!state.overBudget;
   const allocation=state.build?.talents?.find(t=>t.treeIndex===ti+1&&t.talentIndex===ni+1);
   const allocated=!!allocation;
   const effectTarget=(vfxEnabled||window.TalentBorderStyles[state.effect?.kind])&&effectStep&&effectStep.treeIndex===ti+1&&effectStep.talentIndex===ni+1&&(isCustom||highlighted||previewEffects||designOnly);
   const b=element('button',undefined,'node'+(rank?' learned':'')+(allocated?' allocated':'')+(highlighted?' next':'')+(effectTarget?' effect-target':''));b.style.left=`${node.col*25}%`;b.style.top=`${node.row*47}px`;
   b.append(element('div',node.name.split(' ').map(x=>x[0]).join('').slice(0,3)),element('span',`${allocation?.rank||0}/${node.maxRank}`));b.title=`Build target: ${allocation?.rank||0}/${node.maxRank}; learned: ${rank}/${node.maxRank}. `+node.name+' — '+rank+'/'+node.maxRank+' (click to simulate learning)';
   b.onclick=()=>{const points=Object.entries(learned).filter(([k])=>k.startsWith(`${ti+1}:`)).reduce((n,[,v])=>n+v,0);if(state.available>0&&rank<node.maxRank&&points>=node.row*5&&!state.overBudget){learned[key]=rank+1;refresh();}};
   if(isCustom){b.onclick=()=>window.CustomTalentBuilds.change(ti+1,ni+1,1);b.oncontextmenu=event=>{event.preventDefault();window.CustomTalentBuilds.change(ti+1,ni+1,-1);};b.title=`${node.name} — ${rank}/${node.maxRank}. Left-click: add. Right-click: remove.`;}
   nodes.append(b);
   if(effectTarget){if(vfxEnabled)window.TalentEffects.attach(b,state.effect);else window.TalentEffects.attachBorder(b,state.effect);}
  }section.append(nodes);$('trees').append(section);
 }
 $('route').replaceChildren();$('route-note').textContent=state.orderType==='published'?'Published guide order; level labels account for Talented.':'Suggested order from the actual Lua planner; level labels account for Talented.';
 $('route-note').textContent='Talent badges show build target ranks. '+((state.order||[]).length?$('route-note').textContent:state.build?'Point order unavailable: '+(state.orderType||'No recorded progression.'):'Select a build to see its allocation.');
 if(state.build){
  const allocation=element('details');allocation.open=!(state.order||[]).length;allocation.append(element('summary','Build allocation — points to put in each talent'));
  for(const talent of state.build.talents||[]){const row=element('div',undefined,'progress');row.append(element('span',talent.tree||state.layout?.[talent.treeIndex-1]?.name||''),element('strong',talent.name+': '+talent.rank+'/'+talent.maxRank));allocation.append(row);}
  $('route').append(allocation);
 }
 for(const step of Array.isArray(state.order)?state.order:[]){const current=next&&step.treeIndex===next.treeIndex&&step.talentIndex===next.talentIndex&&step.rank===next.rank;const row=element('div',undefined,'progress'+(current?' current':''));row.append(element('span',`Level ${step.level-state.legacy}`),element('strong',`${step.name} ${step.rank}/${step.maxRank}`));$('route').append(row);}
 if(isCustom)window.CustomTalentBuilds.render(state);
 renderFeature();
}
function renderFeature(){
 const compact=page==='talents';$('addon-window').classList.toggle('combat-review',page==='review');$('addon-window').classList.toggle('compact-talents',compact);
 $('addon-window').classList.toggle('coaching-page',!compact);
 const rankings=page==='review'&&reviewSource==='logs';
 $('addon-window').classList.toggle('rankings-dashboard',rankings);
 document.body?.classList.toggle('rankings-view',rankings);
 document.querySelector('.controls').hidden=page==='review';
 $('level-up').hidden=true;
 for(const id of ['reset','toggle-vfx'])$(id).hidden=!compact;
 const legacyLabel=$('legacy').closest?.('label');if(legacyLabel)legacyLabel.hidden=!compact;
 const pageTitle={review:'Combat Review',scenarios:'Combat Scenarios',learn:'Learn Your Class',talents:'Talent Studio'}[page]||page;
 document.querySelector('header h1').textContent=pageTitle;
 document.querySelector('header p').textContent={talents:'Preview talent guidance, class designs, and static borders.',scenarios:'Practice one encounter situation at a time.',learn:'Learn one ability at a time: when, how and why to use it.',review:reviewSource==='logs'?'Browse recorded class/spec rankings and aggregate statistics.':'Inspect automatically recorded combat events and investigate decisions.',gear:'Choose stats for your build and compare upgrades with SimGearForever.',resources:'References and companion tools.'}[page];
 document.querySelector('.window-title span:last-child').textContent=pageTitle;
 document.querySelector('main>aside').hidden=!compact;document.querySelector('main>article').hidden=!compact;
 const panel=$('feature-page');panel.hidden=compact;panel.replaceChildren();
 for(const b of document.querySelectorAll('[data-page]'))b.classList.toggle('active',b.dataset.page===page);
 if(compact)return;
 const buildPicker=element('select');buildPicker.add(new Option('Choose a build (optional for replay)','0'));
 for(const choice of state.choices||[])buildPicker.add(new Option(choice.title,choice.index));
 buildPicker.value=String(selected);buildPicker.onchange=()=>{selected=Number(buildPicker.value);refresh();};
 const buildLabel=element('label','Specialization ');buildLabel.append(buildPicker);
 {
  const classLabel=element('label','Class '),classPicker=element('select');
  for(const token of classes)classPicker.add(new Option(token[0]+token.slice(1).toLowerCase(),token));
  classPicker.value=$('class').value;classPicker.onchange=()=>{$('class').value=classPicker.value;selected=0;learned={};refresh();};
  classLabel.append(classPicker);panel.append(classLabel,buildLabel);
 }
 if(page==='scenarios'||page==='learn'){
  const content=element('div');panel.append(content);window.EncounterCoaching.render(content,state,page,element);return;
 }
 if(page==='resources'){
  panel.append(element('h2','Resources & sources'),element('p','Explore the original websites, our references and the tools that inspired the addon. Build-specific sources are also linked with each build.'));
  for(const [title,description,url] of [
   ['ForeverChanges','Current Forever class spells and changes used for toolkit guidance.','https://foreverchanges.pro/changes'],
   ['Warcraft Logs','Check your parses, reports and rankings for supported games. Inspiration for log analysis; Forever integration is deferred.','https://www.warcraftlogs.com/'],
   ['Forever Logs','Our source for recorded class/spec aggregate statistics. Explore the original data and website.','https://foreverlogs.gg/'],
   ['MythicSim','Build references and simulation research. Check each build’s source and simulation assumptions.','https://mythicsim.com/'],
   ['SimGearForever','Companion addon for gear and stat optimization. Gear integration is planned separately.','https://www.curseforge.com/wow/addons/simgearforever']
  ]){const card=element('section',undefined,'review-card');const link=element('a','Visit '+title);link.href=url;link.target='_blank';link.rel='noopener noreferrer';card.append(element('h3',title),element('p',description),link);panel.append(card);}return;
 }
 if(page==='gear'){
  const guide=state.gearGuide;
  panel.append(element('h2',guide?.title||'Choose a build'));
  if(guide?.available){for(const stat of guide.stats){const card=element('section',undefined,'review-card');card.append(element('h3',stat.name),element('p',stat.why));panel.append(card);}}
  else if(guide)panel.append(element('p',guide.notice));
  if(guide){const companion=element('section',undefined,'review-card');companion.append(element('h3','Compare upgrades with SimGearForever'),element('p',guide.companion));for(const [i,step] of (guide.steps||[]).entries())companion.append(element('p',`${i+1}. ${step}`));const link=element('a','Get SimGearForever on CurseForge');link.href=guide.url;link.target='_blank';link.rel='noopener noreferrer';companion.append(link);panel.append(companion);}return;
 }
 const sources=element('div',undefined,'slide-nav');
 for(const [value,label] of [['replay','Recorded fight'],['logs','Forever Logs']]){const b=element('button',label);b.setAttribute('aria-pressed',String(reviewSource===value));b.onclick=()=>{reviewSource=value;renderFeature();};sources.append(b);}panel.append(sources);
 if(reviewSource==='logs'){const logsPanel=element('div',undefined,'rankings-dashboard-content');panel.append(logsPanel);window.CombatReviewPage.render(logsPanel,state.coachingReplay||state.review||{},{logsOnly:true});return;}
 const recordingPanel=element("div");panel.append(recordingPanel);window.FightRecordingPage.render(recordingPanel,state.coachingReplay,{class:$('class').value,tree:state.specScenarios?.treeIndex,role:state.specScenarios?.role});

}
for(const button of document.querySelectorAll('[data-page]'))button.onclick=()=>{page=button.dataset.page;if(state)renderFeature();};
$('learn').onclick=()=>{const n=state.nextPoint;if(!n||$('learn').disabled)return;learned[`${n.treeIndex}:${n.talentIndex}`]=n.rank;refresh();};
$('level-up').onclick=()=>{$('level').value=Math.min(60,Number($('level').value)+1);refresh();};
$('reset').onclick=()=>{learned={};refresh();};
$('preview-effects').onchange=()=>{if(state)render();};
$('toggle-vfx').onclick=()=>{vfxEnabled=!vfxEnabled;if(!vfxEnabled)window.TalentEffects.refreshBorders?.();try{localStorage.setItem('fc-talent-vfx',vfxEnabled?'on':'off');}catch{}syncVFXButton();if(state)render();};
for(const id of ['class','activity','level','legacy'])$(id).onchange=()=>{if(id==='class'){selected=0;learned={};}if(id==='activity')selected=0;refresh();};
window.CustomTalentBuilds?.init({$,refresh,getState:()=>state});
refresh();
