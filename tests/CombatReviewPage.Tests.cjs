const assert=require('assert/strict'),fs=require('fs'),vm=require('vm');
class Element{
 constructor(tag,text=''){this.tag=tag;this.textContent=text;this.children=[];this.hidden=false;this.value='';}
 append(...nodes){this.children.push(...nodes);}
 replaceChildren(...nodes){this.children=nodes;}
 setAttribute(){}
 add(option){this.children.push(option);}
}
const requests=[],window={},host=new Element('section');
const review={metrics:'Fixture player / Fixture fight',complete:true,totals:{damage:'200',casts:2},coverage:'Full retrieved stream',
 good:[{title:'Damage delivered',what:'200 damage',why:'Recorded hits confirm damage.',evidence:[{time:'0:01',event:'damage',spellId:403,amount:'200'}]}],
 wrong:[{title:'No established mistake',what:'None established',why:'Missing context is not proof of a mistake.'}],
 improve:[{title:'One decision',what:'Review one cast',why:'Choose a specific moment.',next:'Check the target.'}]};
const fetch=async(url,options)=>{
 const body=options?JSON.parse(options.body):null;requests.push(body||{action:'status'});
 const response=body?.action==='connect'?{connected:true,ownerToken:'fixture-owner-session',reports:[{id:42,title:'Fixture report'}]}:body?.action==='report'?{report:{id:42},encounters:[{id:7,name:'Fixture fight'}]}:body?.action==='actors'?{actors:[{id:1,name:'Fixture player',is_player:true}]}:body?.action==='review'?{review}:body?.action==='import'?{message:'Imported fixture review.'}:{connected:false};
 return {ok:true,json:async()=>response};
};
vm.runInNewContext(fs.readFileSync('tools/talent-preview/combat-review.js','utf8'),{window,document:{createElement:tag=>new Element(tag)},Option:class extends Element{constructor(text,value){super('option',text);this.value=value;}},URLSearchParams,location:{search:''},fetch});
const all=(node=host)=>[node,...node.children.flatMap(n=>all(n))],button=text=>all().find(n=>n.tag==='button'&&n.textContent===text),flush=()=>new Promise(setImmediate);
(async()=>{
 window.ForeverLogsOwnerPage.render(host,{});await flush();
 const password=all().find(n=>n.tag==='input'&&n.type==='password');assert(password);
 password.value='fixture-key';button('Connect').onclick();assert.equal(password.value,'','Clear password before request completes');await flush();
 let selects=all().filter(n=>n.tag==='select');selects[0].value='42';selects[0].onchange();await flush();
 selects=all().filter(n=>n.tag==='select');selects[1].value='7';selects[1].onchange();await flush();
 selects=all().filter(n=>n.tag==='select');selects[2].value='1';selects[2].onchange();button('Analyze this fight').onclick();await flush();
 for(const title of ['WHAT YOU DID WELL','WHAT WENT WRONG','WHAT TO IMPROVE'])assert(all().some(n=>n.textContent===title),title);
 assert(all().some(n=>n.textContent==='View event evidence'));
 button('Import this review into the addon').onclick();await flush();assert(all().some(n=>n.textContent==='Imported fixture review.'));
 assert(requests.filter(r=>r.key).length===1,'Only connection request may contain the key');
 button('Local demo').onclick();assert(all().some(n=>n.textContent.includes('DEMO — simulated')));
 window.ForeverLogsOwnerPage.render(host,{}, {logsOnly:true});
 assert(!button('Local demo'),'Forever Logs source must not contain a second demo source');
 console.log('PASS: review-page connection, cleared password, report/encounter/player selection, findings, evidence, import, and demo labeling.');
})().catch(e=>{console.error(e);process.exitCode=1;});
