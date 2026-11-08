const assert=require('assert/strict');
const {profile}=require('../tools/warcraftlogs-client.cjs');
const {encounterRotations,nonCombat,isDungeonRun}=require('../tools/combat-rotations.cjs');
assert(isDungeonRun({name:'Library',gameZone:{name:'Scarlet Monastery'}}),'Recognize explicitly named dungeon wings as full runs');
assert(!isDungeonRun({name:'Fixture boss',gameZone:{name:'Scarlet Monastery: Library'}}),'Do not rank a standalone boss as the entire wing');
for(const name of ['Summon Warhorse','Summon Dreadsteed','Ancestral Spirit','Conjure Mana Ruby','Create Healthstone'])assert(nonCombat(name));
for(const name of ['Life Tap','Rebirth','Blood Fury','Stormstrike','Blink'])assert(!nonCombat(name));
const actor={id:1,type:'Player',name:'Must never be displayed',subType:'Shaman'};
const fight={id:1,name:'Ruins of Lordaeron',encounterID:12999,gameZone:{id:2999,name:'Ruins of Lordaeron'},startTime:0,endTime:60000,friendlyPlayers:[1],friendlySpecs:['Enhancement'],dungeonPulls:[
 {id:1,encounterID:0,name:'NPC pack',startTime:0,endTime:10000},
 {id:2,encounterID:99,name:'Named boss',startTime:20000,endTime:40000,kill:true},
]};
const abilities=[{gameID:403,name:'Lightning Bolt'},{gameID:17364,name:'Stormstrike'},{gameID:324,name:'Lightning Shield'},
 {gameID:6603,name:'Melee'},{gameID:900,name:'Hearthstone'},{gameID:901,name:'Conjure Food'},{gameID:902,name:'Fixture Mount'},{gameID:903,name:'Teleport: Fixture'},{gameID:904,name:'Blood Fury'}];
const report={code:'PublicReport0001',startTime:1793900000000,masterData:{actors:[actor],abilities}};
const cast=(timestamp,id)=>({timestamp,type:'cast',sourceID:1,abilityGameID:id});
const events=[cast(1000,403),cast(2000,324),cast(3000,6603),cast(4000,900),cast(5000,901),cast(6000,902),cast(7000,903),
 cast(21000,17364),cast(22000,403),cast(23000,17364),cast(24000,403),
 {timestamp:21001,type:'damage',sourceID:1,abilityGameID:17364},cast(45000,403)];
const p=profile(report,fight,actor,{complete:true,events});
const rows=encounterRotations(p);
assert.equal(rows.length,2);assert.equal(rows[0].name,'Trash mobs');assert.equal(rows[1].name,'Named boss');
assert.deepEqual(rows[0].opener.map(e=>e.name),['Lightning Bolt','Lightning Shield'],'Only active combat abilities; buffs are supported by reviewed class metadata');
assert.deepEqual(rows[1].opener.map(e=>e.name),['Stormstrike','Lightning Bolt','Stormstrike','Lightning Bolt']);
assert.deepEqual(rows[1].repeated.map(e=>e.name),['Stormstrike','Lightning Bolt']);assert.equal(rows[1].repeats,2);
assert(rows.every(r=>!JSON.stringify(r).includes(actor.name)));
assert(rows.every(r=>r.fullSequence&&r.steps.reduce((n,s)=>n+s.count,0)===r.combatCasts),'Full sequences account for every filtered combat cast');
const long=profile(report,fight,actor,{complete:true,events:Array.from({length:30},(_,i)=>cast(21000+i*100,i%2?403:17364))});
assert.equal(encounterRotations(long).find(r=>r.kind==='boss').steps.length,30,'Do not truncate the rotation to six opener actions');
const repeatedCasts=profile(report,fight,actor,{complete:true,events:Array.from({length:50},(_,i)=>cast(21000+i*100,403))});
const repeatedSteps=encounterRotations(repeatedCasts).find(r=>r.kind==='boss').steps;
assert.equal(repeatedSteps.length,1);assert.equal(repeatedSteps[0].count,50);assert.equal(repeatedSteps[0].at,1);assert.equal(repeatedSteps[0].end,5.9,'Compression preserves repetitions and timing');
assert.equal(encounterRotations({...p,fight:{...fight,dungeonPulls:[]}}).length,0,'Never invent boss/trash splits for an entire dungeon');
assert.equal(encounterRotations({...p,fight:{...fight,name:'Deadmines',gameZone:{name:'The Deadmines'},dungeonPulls:[]}}).length,0,'Dungeon aliases must not become fake bosses');
const earlyDeath=encounterRotations({...p,deaths:[{timestamp:21500}]});assert.deepEqual(earlyDeath[1].opener.map(e=>e.name),['Stormstrike'],'Do not build an opener across a death');
assert.equal(earlyDeath[1].repeats,0,'Do not construct a repeated rotation across death downtime');
const noEvidence=profile(report,fight,actor,{complete:true,events:[cast(1000,902)]});assert(encounterRotations(noEvidence).every(r=>r.combatCasts===0),'Keep known encounter boundaries, with no invented ability casts');
const racial=profile(report,fight,actor,{complete:true,events:[cast(1000,904),{timestamp:1001,type:'applybuff',sourceID:1,targetID:1,abilityGameID:904}]});
assert.equal(encounterRotations(racial)[0].opener[0].name,'Blood Fury','Observed self-applied racial combat cooldowns remain available');
assert(encounterRotations(profile(report,fight,actor,{complete:true,events:[cast(1000,904)]})).every(r=>r.combatCasts===0),'An unclassified racial name alone is not effect evidence');
console.log('PASS: dungeon pull boundaries, real boss/trash labels, compact opener/repeated sequence, class combat buffs, non-combat/automatic exclusions, out-of-pull casts and death/gap limits. Synthetic event fixtures only.');
