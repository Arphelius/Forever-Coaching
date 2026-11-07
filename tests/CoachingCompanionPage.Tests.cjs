const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
class Element{
 constructor(tag,text=''){this.tag=tag;this.textContent=text;this.children=[];this.value='';}
 append(...nodes){this.children.push(...nodes);}
 replaceChildren(...nodes){this.children=nodes;}
 add(node){this.append(node);}
}
const host=new Element('main'),requests=[],stored=[];
const analysis={good:'Observed contribution',observations:'Observed difference',improve:'Practice this',coverage:'Fixture coverage',mentoring:{ready:true,context:{peerCount:3,referencePlayers:[]},findings:[
 {kind:'good',title:'Opening order',what:'Your opener matched three peers.',why:'Same encounter.',next:'Keep this order.'},
 {kind:'change',title:'Ability use',what:'Fewer uses than matching peers.',why:'Check availability.',next:'Track the ability on your next pull.'},
]}};
async function fetch(url,opts){
 const body=opts?.body?JSON.parse(opts.body):null;requests.push({url,body,headers:opts?.headers});
 const data=url==='/status'?{configured:true,connected:true,user:{id:5,name:'Player'},csrf:'fixture-nonce',installs:['FixtureGame']}:
 body.action==='reports'?{reports:[{code:'Target0000000001',title:'Dungeon run',startTime:Date.now()}]}:
 body.action==='report'?{code:'Target0000000001',title:'Dungeon run',players:[{id:1,name:'Learner',realm:'Realm',class:'Shaman'}],fights:[{id:1,name:'Boss',kill:true,players:[1],specs:['Enhancement']}]}:
 {review:{encounter:'Boss',analysis},delivery:{sent:1,message:'Ready in WoW. Type /reload.'}};
 return {ok:true,json:async()=>data};
}
vm.runInNewContext(fs.readFileSync('tools/coaching-companion/companion.js','utf8'),{
 document:{getElementById:()=>host,createElement:tag=>new Element(tag),createTextNode:text=>new Element('text',text)},
 Option:class extends Element{constructor(text,value){super('option',text);this.value=value;}},
 fetch,location:{reload(){}},localStorage:{getItem:()=>null,setItem:(key,value)=>stored.push({key,value})},
});
const nodes=(n=host)=>[n,...n.children.flatMap(nodes)],flush=()=>new Promise(setImmediate);
(async()=>{
 await flush();
 const run=nodes().find(n=>n.tag==='select');run.value='Target0000000001';run.onchange();await flush();
 assert(nodes().some(n=>n.textContent==='Recorded spec: Enhancement'));
 const review=nodes().find(n=>n.tag==='button'&&n.textContent==='Review my run and send to WoW');assert(review);review.onclick();await flush();
 const sent=requests.find(r=>r.body?.action==='review');assert.deepEqual(JSON.parse(JSON.stringify(sent.body)),{action:'review',report:'Target0000000001',actor:1,fight:1,gameRoot:'FixtureGame',metric:'auto'});
 assert.equal(sent.headers['X-Coach-Token'],'fixture-nonce');
 assert(nodes().some(n=>n.textContent==='Track the ability on your next pull.'));
 assert(nodes().some(n=>n.textContent==='Ready in WoW. Type /reload.'));
 assert(!requests.some(r=>r.body?.partition||r.body?.clientSecret||r.body?.accessToken),'Players do not supply provider configuration or reference IDs');
 assert(!nodes().some(n=>n.tag==='input'&&n.type==='password'));
 assert.equal(stored[0].value,'Learner@Realm','Remember the chosen character without storing credentials');
 console.log('PASS: recent run selection, remembered character, automatic spec/encounter defaults, one-click analysis and delivery, clear reload result and no player API setup. Simulated browser only.');
})().catch(error=>{console.error(error);process.exitCode=1;});
