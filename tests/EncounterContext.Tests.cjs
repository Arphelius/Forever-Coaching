const assert=require('assert/strict');
const {analyze}=require('../tools/foreverlogs-review.cjs');
const {topics,render}=require('../tools/talent-preview/encounter-coaching.js');
const events=[
 {id:'1',timestamp_ms:100,event_type:'interrupt',source_id:2,target_id:9,spell_id:5},
 {id:'2',timestamp_ms:200,event_type:'heal',source_id:2,target_id:1,spell_id:6,amount:'50'},
 {id:'3',timestamp_ms:300,event_type:'damage',source_id:1,target_id:9,spell_id:7,amount:'20'},
 {id:'4',timestamp_ms:400,event_type:'death',source_id:9,target_id:1}
];
const review=analyze({reportId:1,encounter:{id:1},actors:[{id:1,name:'Self',is_player:true},{id:2,name:'Ally',is_player:true}],events,actorId:1,complete:true});
assert.equal(review.group.length,2);
assert.equal(review.group[0].interrupts.length,0);
assert.equal(review.group[1].interrupts.length,1);
assert.equal(review.totals.healing,'0');
assert.equal(review.abilities[0].damage,'20');
assert.deepEqual(review.abilities[0].targets,[9]);
assert(review.deathWindows[0].events.some(e=>e.sourceId===2&&e.event==='heal'));
assert.equal(review.decisionCoverage.length,10);
assert(review.decisionCoverage.every(t=>t.status==='Needs encounter context'));
assert.equal(review.buildContext.status,'Unknown at encounter time');
assert(topics.some(t=>t.id==='support'&&t.requires.includes('dispel')));
const node=(tag,text)=>({text,append(...children){this.children=(this.children||[]).concat(children);}});
const panel=node('section');render(panel,{build:{title:'Healer',role:'healer',talents:[{name:'Test',rank:1}]},level:30},'learn',node);
const descendants=node=>[node,...(node.children||[]).flatMap(descendants)];
assert(descendants(panel).some(n=>n.text==='Talents in this build'));
console.log('PASS: group attribution, healing context, ability targets, coverage gaps and build curriculum.');
