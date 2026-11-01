const assert=require('assert/strict'),fs=require('fs'),vm=require('vm');
class Element{
 constructor(tag){this.tag=tag;this.children=[];this.value='';this.textContent='';this.style={setProperty(){}};this.classList={toggle(){}};}
 append(...nodes){this.children.push(...nodes);}
 replaceChildren(...nodes){this.children=nodes;}
 add(option){this.children.push(option);}
 setAttribute(){}
}
const ids=new Map(),get=id=>{if(!ids.has(id))ids.set(id,new Element(id));return ids.get(id);};
get('level').value='30';get('activity').value='leveling';get('legacy').value='0';
const nav=['review','talents','scenarios','learn','gear','resources'].map(page=>{const el=new Element('button');el.dataset={page};return el;});
const selectors=new Map();
const document={getElementById:get,createElement:tag=>new Element(tag),documentElement:new Element('root'),querySelector:selector=>{if(!selectors.has(selector))selectors.set(selector,new Element(selector));return selectors.get(selector);},querySelectorAll:()=>nav};
const Option=class extends Element{constructor(text,value){super('option');this.textContent=text;this.value=String(value);}};
const all=node=>[node,...node.children.flatMap(all)];
const flush=()=>new Promise(resolve=>setImmediate(resolve));
async function main(){
 const base='http://127.0.0.1:4317';
 const read=async suffix=>{const response=await fetch(base+suffix);const data=await response.json();assert(response.ok,JSON.stringify(data));return data;};
 const data=await read('/state?class=SHAMAN&level=30&build=1&coachingCase=responded');
 assert(data.coachingReplay?.simulated);
 assert(data.coachingReplay.timeline.some(o=>o.kind==='interrupt'&&o.status==='responded'));
 assert(data.abilityLessons.some(l=>l.name==='Earth Shock'));
 for(const mode of ['missed','wrong-target','hidden']){
  const s=await read('/state?class=SHAMAN&level=30&build=0&coachingCase='+mode);
  assert(!s.coachingReplay.timeline.some(o=>o.status==='responded'),mode);
  if(mode==='hidden')assert(!s.coachingReplay.timeline.some(o=>o.spellID),'Hidden readiness cannot produce actionable prompts');
 }
 for(const cls of ['DRUID','HUNTER','MAGE','PALADIN','PRIEST','ROGUE','WARLOCK','WARRIOR']){
  const s=await read('/state?class='+cls+'&level=30');assert(s.coachingReplay&&s.abilityLessons.length,cls);
 }
 for(const cls of ['DRUID','HUNTER','MAGE','PALADIN','PRIEST','ROGUE','SHAMAN','WARLOCK','WARRIOR']){
  for(const activity of ['leveling','dungeons','raids','pvp']){
   const s=await read('/state?class='+cls+'&level=60&activity='+activity);
   const keys=s.choices.map(c=>c.title.toLowerCase()+':'+c.role);
   assert.equal(new Set(keys).size,keys.length,cls+' '+activity+' must not show duplicate named builds');
   if(cls==='SHAMAN'&&activity==='leveling')assert.equal(s.choices.filter(c=>c.title==='Enhancement').length,1,'Show exactly one Enhancement build');
  }
 }
 const window={TalentBorderStyles:{},TalentEffects:{attach(){},attachBorder(){}}};
 const sandbox={window,document,Option,URLSearchParams,location:{search:'?page=scenarios'},localStorage:{getItem(){return null;}},fetch:async()=>({ok:true,json:async()=>data})};
 vm.runInNewContext(fs.readFileSync('tools/talent-preview/encounter-coaching.js','utf8'),sandbox);
 vm.runInNewContext(fs.readFileSync('tools/talent-preview/fight-recording.js','utf8'),sandbox);
 vm.runInNewContext(fs.readFileSync('tools/talent-preview/app.js','utf8'),sandbox);
 await flush();await flush();
 assert.equal(get('error').textContent,'');
 let nodes=all(get('feature-page'));
 assert(!nodes.some(n=>n.textContent==='Try the encounter observer'),'Scenarios must not contain combat replay');
 assert.equal(nodes.filter(n=>n.className==='review-card').length,1,'One scenario per slide');
 assert(nodes.some(n=>n.textContent==='Single target (ST)'));
 assert(nodes.some(n=>n.textContent==='Action order'));
 assert(nodes.some(n=>n.className==='scenario-action'),'Scenarios must render discrete action steps');
 assert(nodes.some(n=>n.textContent.startsWith('1. Cast ')),'The first step must name the action');
 nodes.find(n=>n.tag==='button'&&n.textContent==='Next').onclick();nodes=all(get('feature-page'));
 assert(nodes.some(n=>n.tag==='h3'&&n.textContent==='Cleave (two targets)'),'Next advances the scenario');
 nav.find(n=>n.dataset.page==='review').onclick();nodes=all(get('feature-page'));
 assert(nodes.some(n=>n.textContent==='Fight recording'),'Timeline belongs to Combat Review');
 assert(nodes.some(n=>n.className==='fight-event'),'Actual Lua recorder events are rendered');
 assert(!nodes.some(n=>n.textContent==='Respond to the observed targets'),'Synthetic response selector is removed');
 nav.find(n=>n.dataset.page==='learn').onclick();nodes=all(get('feature-page'));
 assert(nodes.some(n=>n.textContent==='Class ability lessons'),'Learn renders without selecting a build');
 assert(nodes.some(n=>n.textContent.startsWith('When: An assigned dangerous cast')),'When/how/why lessons render');
 assert.equal(nodes.filter(n=>n.className==='review-card').length,1,'One ability per slide');
 assert(!nodes.some(n=>n.textContent.startsWith('Prepare:')||n.textContent==='Try the encounter observer'),'Learn excludes scenario and combat-review content');
 nodes.find(n=>n.tag==='button'&&n.textContent==='Next').onclick();nodes=all(get('feature-page'));
 assert(nodes.some(n=>n.tag==='h3'&&n.textContent==='Healing Wave'),'Next advances the ability');
 nav.find(n=>n.dataset.page==='gear').onclick();nodes=all(get('feature-page'));
 assert(nodes.some(n=>n.tag==='a'&&n.href==='https://www.curseforge.com/wow/addons/simgearforever'),'Gear links directly to the companion addon');
 assert(!nodes.some(n=>n.textContent==='Try the encounter observer'||n.textContent==='Class ability lessons'||n.textContent.startsWith('Prepare:')),'Gear excludes other sections');
 const html=await (await fetch(base+'/')).text();assert(html.includes('/encounter-coaching.js'));
 const talentState=await read('/state?class=SHAMAN&level=60&build=1');
 assert(talentState.gearGuide.available&&talentState.gearGuide.stats.length,'Selected build exposes gear stat guidance');
 const recording=window.FightRecordingPage.validate(JSON.stringify({format:'ForeverCoachingFight-v1',fight:talentState.coachingReplay.recording}));
 assert(recording.events.length,'An exported recording can be opened by the viewer');
 assert.throws(()=>window.FightRecordingPage.validate(JSON.stringify({format:'ForeverCoachingFight-v1',fight:{events:[{kind:'cast',time:'invalid'}]}})),'Malformed event times are rejected');
 assert(talentState.talentLessons?.length,'The running server must expose the new talent lessons');
 const lessonHost=new Element('section');
 const el=(tag,text,cls)=>{const n=new Element(tag);if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n;};
 window.EncounterCoaching.render(lessonHost,talentState,'learn',el);
 all(lessonHost).find(n=>n.tag==='button'&&n.textContent==='Talents in this build').onclick();
 let lessonNodes=all(lessonHost);
 for(const heading of ['What it does','Why it matters in this build','How to use it well'])assert(lessonNodes.some(n=>n.textContent===heading),heading);
 assert(lessonNodes.some(n=>n.textContent===talentState.talentLessons[0].effect));
 lessonNodes.find(n=>n.tag==='button'&&n.textContent==='Next').onclick();lessonNodes=all(lessonHost);
 assert(lessonNodes.some(n=>n.tag==='h3'&&n.textContent===talentState.build.talents[1].name),'Talent slides advance');
 console.log('PASS: running replay, all class catalogs, separate sections, single-slide scenarios/lessons and next-slide navigation.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
