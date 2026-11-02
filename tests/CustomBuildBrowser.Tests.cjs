const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const ids=new Map(),storage={};
class Element{
 constructor(tag){this.tag=tag;this.children=[];this.value='';this.dataset={};}
 set id(value){this._id=value;ids.set(value,this);}get id(){return this._id;}
 append(...nodes){this.children.push(...nodes);}prepend(...nodes){this.children.unshift(...nodes);}replaceChildren(){this.children=[];}
 add(option){this.children.push(option);}
}
const $=id=>{if(!ids.has(id))ids.set(id,new Element(id));return ids.get(id);};$('class').value='MAGE';
const article=new Element('article'),context={window:{},document:{createElement:tag=>new Element(tag),querySelector:()=>article},Option:class extends Element{constructor(name,value){super('option');this.textContent=name;this.value=value;}},localStorage:{getItem:key=>storage[key],setItem:(key,value)=>storage[key]=value},Date};
vm.runInNewContext(fs.readFileSync('tools/talent-preview/custom-builds.js','utf8'),context);const api=context.window.CustomTalentBuilds;let state;
async function refresh(){
 const request=api.request();if(!request)return;const draft=JSON.parse(JSON.stringify(request.draft));let error;
 if(request.change){const c=request.change,key=c.treeIndex+':'+c.talentIndex,rank=draft.ranks[key]||0;if(rank+c.delta<0||rank+c.delta>2)error='Invalid rank';else{draft.ranks[key]=rank+c.delta;if(c.delta>0)draft.order.push({treeIndex:c.treeIndex,talentIndex:c.talentIndex});else draft.order.pop();}}
 state={custom:{draft,points:draft.order.length,valid:draft.order.length>0,error,roles:['damage']}};api.render(state);
}
api.init({$,refresh,getState:()=>state});
const all=node=>[node,...node.children.flatMap(all)];
const find=label=>all(article).concat(all($('builds'))).find(n=>n.tag==='button'&&n.textContent===label);
async function main(){
 await find('Custom Builds').onclick();assert(api.isActive());await api.change(1,1,1);assert.equal(api.request().draft.ranks['1:1'],1);
 let input=all(article).find(n=>n.tag==='input');input.value='Arcane experiment';input.oninput();
 await find('Save custom build').onclick();let saved=JSON.parse(storage['fc-custom-builds-v1']);assert.equal(saved.length,1);assert.equal(saved[0].draft.name,'Arcane experiment');assert.equal(saved[0].draft.order.length,1);
 assert.equal(find('New build').disabled,false,'Controls must re-enable after an asynchronous edit');
 await find('New build').onclick();assert.equal(api.request().draft.order.length,0);await find('Arcane experiment').onclick();assert.equal(api.request().draft.order.length,1,'Saved build must reopen');
 await find('Delete build').onclick();assert.equal(JSON.parse(storage['fc-custom-builds-v1']).length,1);await find('Delete build').onclick();assert.equal(JSON.parse(storage['fc-custom-builds-v1']).length,0);
 await find('Published builds').onclick();assert(!api.isActive());assert.equal(api.request(),null);
 console.log('PASS: browser calculator edits, storage, reopen, confirmed delete, tab switching and async control recovery.');
}
main().catch(error=>{console.error(error);process.exitCode=1;});
