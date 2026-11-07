const assert=require('assert/strict');
const {profile,compare,encodeReview}=require('../tools/warcraftlogs-client.cjs');
const {mentor}=require('../tools/peer-coaching.cjs');
const classes={Druid:['Balance','Moonfire','Wrath','Starfire'],Hunter:['Marksmanship','Serpent Sting','Aimed Shot','Arcane Shot'],Mage:['Fire','Scorch','Fireball','Fire Blast'],Paladin:['Retribution','Judgement','Crusader Strike','Consecration'],Priest:['Shadow','Shadow Word: Pain','Mind Blast','Mind Flay'],Rogue:['Assassination','Garrote','Sinister Strike','Eviscerate'],Shaman:['Enhancement','Stormstrike','Earth Shock','Lightning Bolt'],Warlock:['Affliction','Corruption','Immolate','Shadow Bolt'],Warrior:['Fury','Bloodthirst','Whirlwind','Heroic Strike']};
function sample({className='Shaman',peer=0,target=false,matching=false}={}){
 const [spec,...names]=classes[className];
 const actor={id:1,type:'Player',name:target?'Learner':'Peer'+peer,server:'FixtureRealm',subType:className};
 const fight={id:1,name:'Dungeon Boss',encounterID:77,difficulty:3,gameZone:{id:33,name:'Fixture Dungeon'},startTime:1000,endTime:61000,kill:true,friendlyPlayers:[1],friendlySpecs:[spec]};
 const report={code:target?'Target0000000001':'PeerCode0000000'+peer,startTime:1793900000000,zone:{id:50},masterData:{gameVersion:16,actors:[actor,{id:2,name:'Dungeon Boss',type:'NPC'}],abilities:names.map((name,i)=>({gameID:101+i,name}))},fights:[fight]};
 const sequence=target&&!matching?[103,103,101]:[101,102,103,102,102,102,102];
 const events=sequence.map((abilityGameID,i)=>({timestamp:2000+i*7000,type:'cast',sourceID:1,targetID:2,abilityGameID}));
 events.push({timestamp:1000,type:'combatantinfo',sourceID:1,talents:[{id:9,rank:1}]},
  {timestamp:2000,type:'applydebuff',sourceID:1,targetID:2,abilityGameID:101},
  {timestamp:target&&!matching?15000:60000,type:'removedebuff',sourceID:1,targetID:2,abilityGameID:101});
 const result=profile(report,fight,actor,{complete:true,events});result.percentile=100;result.partition=2;result.metric='dps';return result;
}
for(const className of Object.keys(classes)){
 const target=sample({className,target:true}),refs=[1,2,3].map(peer=>sample({className,peer}));
 const result=mentor(target,refs);
 assert.equal(result.ready,true,className);
 assert.equal(result.context.peerCount,3);assert.equal(result.context.talentMatches,3);
 for(const topic of ['ability-use','opener','aura-coverage'])assert(result.findings.some(f=>f.kind==='change'&&f.topic===topic),className+': '+topic);
 assert(result.findings.every(f=>f.references.length===3));
 assert(result.findings.find(f=>f.topic==='opener').evidence.some(e=>e.startsWith('1.0s')));
 assert(result.findings.filter(f=>f.kind==='change').every(f=>f.next.includes('pull')||f.next.includes('Track')));
 const matched=mentor(sample({className,target:true,matching:true}),refs);
 for(const topic of ['ability-use','opener','aura-coverage'])assert(matched.findings.some(f=>f.kind==='good'&&f.topic===topic),className+': positive '+topic);
 const analysis=compare(target,refs);
 assert.deepEqual(analysis.comparison.scenario.casts.map(e=>e.spellID),refs[0].casts.map(e=>e.abilityGameID),className+': replay the actual reference order');
 assert.equal(analysis.comparison.scenario.sourceURL,analysis.comparison.context.referencePlayers[0].url);
 assert.equal(analysis.comparison.scenario.casts[0].at,1);
 assert.equal(analysis.comparison.context.class,className.toUpperCase());
 assert(analysis.comparison.findings.filter(f=>f.kind==='change').every(f=>f.comparison&&f.comparison.you!==undefined&&f.comparison.reference!==undefined),className+': preserve side-by-side metrics for the addon');
 assert(analysis.observations.includes('Your first casts:'));
 assert(analysis.improve.includes('Next pull:'));
 assert(analysis.references.includes('100 percentile'));
 assert(encodeReview(target,analysis).length<60000);
}
const target=sample({target:true}),refs=[1,2,3].map(peer=>sample({peer}));
const itemPeers=[1,2,3].map(peer=>sample({peer}));
itemPeers[0].events.push(
 {timestamp:4000,type:'useitem',sourceID:1,itemID:900,itemName:'Fixture Potion'},
 {timestamp:5000,type:'useitem',sourceID:8,itemID:901,itemName:'Other player potion'},
 {timestamp:6000,type:'applybuff',sourceID:1,targetID:1,abilityGameID:101},
 {timestamp:7000,type:'applybuff',sourceID:8,targetID:1,abilityGameID:102});
itemPeers[0].events.find(e=>e.type==='combatantinfo').gear=[{id:902,name:'Equipped trinket'}];
const replay=compare(target,itemPeers).comparison.scenario;
assert.deepEqual(replay.items,[{at:3,spellID:undefined,name:'Fixture Potion',itemID:900}],'Explicit item use only, never teammates or equipment');
assert.equal(replay.buffs.length,1,'Only self-applied buffs belong to this reference');
assert.equal(replay.buffs[0].at,5);
assert.equal(compare(target,refs).comparison.scenario.items.length,0,'Do not guess item uses from spell names');
assert.equal(compare(target,refs.slice(0,2)).comparison.scenario,undefined,'No unqualified reference replay');
for(const mutate of [
 r=>{r.spec='Restoration';},r=>{r.actor.subType='Mage';},r=>{r.fight.encounterID=78;},r=>{r.fight.difficulty=4;},
 r=>{r.report.zone.id=51;},r=>{r.report.masterData.gameVersion=17;},r=>{r.complete=false;},r=>{r.percentile=94;},r=>{r.percentile=99.99;},
 r=>{r.report.startTime+=8*86400000;},r=>{r.duration=120;},r=>{r.partition=3;},r=>{r.metric='hps';},
 r=>{r.deaths=[{timestamp:20000}];},r=>{r.events=r.events.map(e=>e.type==='combatantinfo'?{...e,talents:[{id:99,rank:1}]}:e);},
 r=>{r.fight.gameZone.id=34;},r=>{r.fight.gameZone=null;},r=>{r.fight.keystoneLevel=15;},r=>{r.fight.keystoneAffixes=[1];},r=>{r.fight.hardModeLevel=1;},
]){
 const invalid=[1,2,3].map(peer=>sample({peer}));invalid.forEach(mutate);
 assert.equal(mentor(target,invalid).ready,false,'Incompatible peer context must not generate coaching');
}
assert.equal(mentor(target,[refs[0],refs[0],refs[0]]).ready,false,'One player is not three peers');
assert.equal(mentor(target,[target,...refs.slice(0,2)]).ready,false,'Never benchmark the player against themself');
assert.equal(mentor({...target,complete:false},refs).ready,false);
assert.equal(mentor({...target,fight:{...target.fight,kill:false}},refs).ready,false);
assert.equal(mentor({...target,spec:null},refs).ready,false);
assert.equal(mentor({...target,level:18},refs.map(r=>({...r,level:60}))).ready,false,'Known level differences are not comparable');
assert.throws(()=>mentor(target,refs,{minPercentile:1}));
assert.throws(()=>mentor(target,refs,{minPeers:1}));
const dead=mentor({...target,deaths:[{timestamp:20000}]},refs);
assert(!dead.findings.some(f=>['ability-use','aura-coverage'].includes(f.topic)));
assert(dead.findings.some(f=>f.topic==='opportunity'));
const missing=sample({target:true});missing.events=missing.events.filter(e=>e.type!=='removedebuff');
missing.events.push({timestamp:15000,type:'removedebuff',targetID:2,abilityGameID:101});
assert(!mentor(missing,refs).findings.some(f=>f.topic==='aura-coverage'),'Ambiguous aura removal cannot establish uptime');
const instanceMissing=sample({target:true});
instanceMissing.events=instanceMissing.events.map(e=>e.type==='applydebuff'?{...e,targetInstance:2}:e);
assert(!mentor(instanceMissing,refs).findings.some(f=>f.topic==='aura-coverage'),'Missing target-instance identity cannot establish uptime');
function asSelfBuff(p){return {...p,events:p.events.map(e=>e.type.endsWith('debuff')?{...e,type:e.type.replace('debuff','buff'),targetID:p.actor.id}:e)};}
assert(mentor(asSelfBuff(target),refs.map(asSelfBuff)).findings.some(f=>f.topic==='aura-coverage'&&f.what.includes('on yourself')),'Self-buff coverage needs the same attribution checks');
const diedTarget=sample({target:true});diedTarget.events=diedTarget.events.filter(e=>e.type!=='removedebuff');
diedTarget.events.push({timestamp:15000,type:'death',targetID:2});
assert(mentor(diedTarget,refs).findings.some(f=>f.topic==='aura-coverage'&&f.evidence.some(e=>e.includes('-14.0s'))),'A target death must close its aura interval');
const foreign=sample({target:true});foreign.events=foreign.events.filter(e=>!e.type.includes('debuff'));
foreign.events.push({timestamp:2000,type:'applydebuff',sourceID:9,targetID:2,abilityGameID:101},{timestamp:15000,type:'removedebuff',sourceID:9,targetID:2,abilityGameID:101});
assert(!mentor(foreign,refs).findings.some(f=>f.topic==='aura-coverage'),'Teammate aura coverage must not be attributed to the learner');
const rank=sample({target:true,matching:true});rank.report.masterData.abilities.push({gameID:999,name:classes.Shaman[1]});rank.abilities.set(999,classes.Shaman[1]);rank.casts[0]={...rank.casts[0],abilityGameID:999};
assert(mentor(rank,refs).findings.some(f=>f.kind==='good'&&f.topic==='opener'),'Spell ranks with the same recorded name should share a rotation identity');
console.log('PASS: all nine classes: positive habits, opener differences, ability frequency, aura coverage, evidence, practice goals, independent peers and context/death/attribution limits. Synthetic rotations are fixtures, not real player benchmarks.');
