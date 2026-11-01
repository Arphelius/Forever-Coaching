const assert=require('assert/strict'),fs=require('fs'),vm=require('vm');
class Element{constructor(tag,text=''){this.tag=tag;this.textContent=text;this.children=[];this.value='';}append(...nodes){this.children.push(...nodes);}replaceChildren(...nodes){this.children=nodes;}setAttribute(){}add(node){this.children.push(node);}}
const host=new Element('section'),window={},requests=[];
let searchMode='normal',searchCalls=0;
const review={selectionId:'opaque-fight',player:'Player',encounter:'Boss',complete:true,damagePerSecond:'200.0',healingPerSecond:'0.0',deaths:0,good:[{what:'A useful interrupt was recorded.'}],improve:[{what:'Plan the next assigned cast.',next:'Reserve the interrupt.'}],setbacks:[],comparison:{rank:2,players:5},coverage:'Processed fight reviewed.',identityNote:'Name match only.'};
const fetch=async(url,options)=>{const body=options?JSON.parse(options.body):null;if(body)requests.push(body);if(body?.action==='searchPlayers'){searchCalls++;if(searchMode==='continue'&&searchCalls<4)return {ok:true,json:async()=>({matches:[],nextCursor:'older-page',inspected:12})};if(searchMode==='limited')return {ok:true,json:async()=>({matches:[],nextCursor:'saved-position',inspected:2,rateLimited:true,retryAfterSeconds:30})};}const data=!body?{connected:true,configured:true}:body.action==='searchPlayers'?{matches:[{selectionId:'opaque-fight',player:'Player',encounter:'Boss',date:'2026-10-29T00:00:00Z'}],nextCursor:null}:body.action==='playerReview'?{review}:body.action==='playerProgress'?{fights:[review],label:'Reviewed fights in this session.'}:body.action==='playerStatistics'?{statistics:{totals:{damage:'2000'},players:[{player:'Player',damage:'2000',healing:'0',deaths:0}],abilities:[{spellId:403,casts:2,damage:'2000',healing:'0'}],comparisonNote:'Same fight, all roles.'}}:{};return {ok:true,json:async()=>data};};
const sandbox={window,document:{createElement:tag=>new Element(tag)},Option:class extends Element{constructor(text,value){super('option',text);this.value=value;}},URLSearchParams,location:{search:''},fetch,Date};
vm.runInNewContext(fs.readFileSync('tools/talent-preview/combat-review.js','utf8'),sandbox);
vm.runInNewContext(fs.readFileSync('tools/talent-preview/player-logs.js','utf8'),sandbox);
const all=(node=host)=>[node,...node.children.flatMap(all)],button=text=>all().find(n=>n.tag==='button'&&n.textContent===text),flush=()=>new Promise(setImmediate);
(async()=>{
 window.CombatReviewPage.render(host,{});
 assert(!all().some(n=>n.type==='password'||n.textContent==='Public report'));
 const input=all().find(n=>n.type==='search');input.value='Player';input.oninput();button('Search player').onclick();await flush();await flush();
 all().find(n=>n.tag==='button'&&n.textContent.startsWith('Player · Boss')).onclick();await flush();await flush();
 assert(all().some(n=>n.textContent==='Your progress'));assert(!all().some(n=>n.textContent.includes('Spell #403')));
 assert(!requests.some(r=>['report','actors','reports','review'].includes(r.action)),'Normal flow must not request raw owner endpoints');
 button('More advanced statistics').onclick();await flush();assert(all().some(n=>n.textContent.startsWith('Spell #403')));
 button('Hide advanced statistics').onclick();assert(!all().some(n=>n.textContent.startsWith('Spell #403')));
 assert(!button('Owner tools'),'The player view must not expose owner tools');
 assert(!all().some(n=>n.type==='password'||n.textContent==='Public report'),'Player view excludes credential forms and raw reports');
 searchMode='continue';searchCalls=0;button('Search player').onclick();await flush();await flush();assert.equal(searchCalls,4,'Search should automatically continue beyond the first page');
 searchMode='limited';searchCalls=0;button('Search player').onclick();await flush();await flush();assert.equal(searchCalls,1);assert(all().some(n=>n.textContent.includes('Search paused by Forever Logs')));assert(button('Search older fights'),'Rate-limited searches retain their continuation');
 console.log('PASS: player-first search, concise review, opt-in statistics and no owner tools or credential form.');
})().catch(e=>{console.error(e);process.exitCode=1;});
