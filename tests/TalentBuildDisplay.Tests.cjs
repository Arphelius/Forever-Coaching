const fs=require('fs'),vm=require('vm'),assert=require('assert');
function node(){return {children:[],style:{setProperty(){}},classList:{toggle(){}},append(...items){this.children.push(...items)},replaceChildren(){this.children=[]}};}
const ids={};const $=id=>ids[id]||(ids[id]=node());$('class').value='PRIEST';
const talent={name:'Holy Fire',tree:'Holy',treeIndex:1,talentIndex:1,rank:3,maxRank:5};
const state={choices:[],build:{talents:[talent]},layout:[{name:'Holy',nodes:[{name:'Holy Fire',maxRank:5,row:0,col:0}]}],ranks:{'1:1':0},order:null,orderType:'Recorded requirements conflict',available:1};
const context={$,state,selected:0,classes:['PRIEST'],colors:['white'],vfxEnabled:false,window:{TalentBorderStyles:{}},document:{documentElement:node()},renderFeature(){},element(tag,text){return Object.assign(node(),{tag,textContent:text})}};
const source=fs.readFileSync('tools/talent-preview/app.js','utf8');vm.runInNewContext(source.slice(source.indexOf('function render(){'),source.indexOf('function renderFeature(){'))+'\nrender();',context);
const button=$('trees').children[0].children[1].children[0];
assert.equal(button.children[1].textContent,'3/5');assert.match(button.title,/learned: 0\/5/);
assert.match($('next').textContent,/Point order unavailable/);assert(!$('next').textContent.includes('complete'));
const allocation=$('route').children[0];assert.equal(allocation.open,true);assert.equal(allocation.children[1].children[1].textContent,'Holy Fire: 3/5');
console.log('Talent display: target ranks, learned ranks, allocation list, and unavailable progression passed.');
