const fs=require('fs'),readline=require('readline');
const {resolveDungeon}=require('./forever-dungeons.cjs');
function csv(text){
 const fields=[];let value='',quoted=false,depth=0;
 for(let i=0;i<text.length;i++){const c=text[i];
  if(c==='"'){if(quoted&&text[i+1]==='"'){value+='"';i++;}else quoted=!quoted;}
  else if(c===','&&!quoted&&depth===0){fields.push(value);value='';}
  else{if(!quoted&&'(['.includes(c))depth++;if(!quoted&&')]'.includes(c))depth--;value+=c;}
 }fields.push(value);return fields;
}
function timestamp(text){const m=text.match(/^(\d+)\/(\d+)\/(\d{4}) (\d+):(\d+):(\d+)(?:\.(\d+))?$/);if(!m)return;return Date.UTC(+m[3],+m[1]-1,+m[2],+m[4],+m[5],+m[6],Math.floor(Number('0.'+(m[7]||0))*1000));}
function logParser(){
 const identities=new Map(),fights=[];let version,advanced=false,zone,zoneDifficulty=0,boss,trash,last=0,serial=0,malformed=0,zoneSerial=0;
 function segment(kind,start,name,difficulty=zoneDifficulty){return {kind,start,end:start,name,difficulty,dungeonKey:zone.key,zoneSerial,actors:new Map()};}
 function actor(s,guid){if(!s.actors.has(guid))s.actors.set(guid,{damage:new Map(),healing:0,casts:new Map(),deaths:0});return s.actors.get(guid);}
 function close(s,end,kill){if(!s)return;s.end=Math.max(s.start+1000,end);s.kill=kill;fights.push(s);}
 function closeTrash(){if(trash){close(trash,trash.end,true);trash=null;}}
 function closeZone(){closeTrash();if(boss){close(boss,last,false);boss=null;}zone=null;}
 function consume(line){
  const split=line.indexOf('  ');if(split<0)return;const at=timestamp(line.slice(0,split));if(!Number.isFinite(at))return;last=at;
  const p=csv(line.slice(split+2)),type=p[0];
  if(type==='COMBAT_LOG_VERSION'){closeZone();version=Number(p[1]);advanced=p[3]==='1';if(version!==22)throw Error(`Combat log version ${version} is not supported; no private data was delivered.`);return;}
  if(type==='ZONE_CHANGE'){closeZone();zone=resolveDungeon(p[2]);zoneDifficulty=Number(p[3])||0;zoneSerial++;return;}
  if(!zone)return;
  if(type==='ENCOUNTER_START'){closeTrash();if(boss)close(boss,at,false);boss=segment('boss',at,p[2],Number(p[3]));return;}
  if(type==='ENCOUNTER_END'){if(boss&&boss.name===p[2]){close(boss,at,p[5]==='1');boss=null;}return;}
  if(p[1]?.startsWith('Player-')&&/^0x/i.test(p[3]||'')&&(Number(p[3])&1))identities.set(p[1],p[2]);
  if(p[5]?.startsWith('Player-')&&/^0x/i.test(p[7]||'')&&(Number(p[7])&1))identities.set(p[5],p[6]);
  if(trash&&at-trash.end>15000)closeTrash();
  const damage=['SWING_DAMAGE','SPELL_DAMAGE','SPELL_PERIODIC_DAMAGE','RANGE_DAMAGE','SPELL_BUILDING_DAMAGE'].includes(type);
  const hostile=!!((Number(p[3])|Number(p[7]))&0x40);
  if(!boss&&hostile&&(damage||type==='SPELL_CAST_SUCCESS'||type==='SPELL_ABSORBED')){if(!trash)trash=segment('trash',at,'Trash mobs');trash.end=at;}
  const current=boss||trash;if(!current)return;
  if(type==='UNIT_DIED'&&identities.has(p[5]))actor(current,p[5]).deaths++;
  if(type==='SPELL_ABSORBED'){
   const caster=p[9]?.startsWith('Player-')?9:12;
   if(p[caster]?.startsWith('Player-')&&/^0x/i.test(p[caster+2]||'')&&(Number(p[caster+2])&1)&&(Number(p[7])&0x10)){
    identities.set(p[caster],p[caster+1]);const absorbed=Number(p[caster+7]);
    if(Number.isFinite(absorbed)&&absorbed>=0)actor(current,p[caster]).healing+=absorbed;
   }return;
  }
  if(!identities.has(p[1]))return;
  if(type==='SPELL_CAST_SUCCESS'){
   const id=Number(p[9]);if(!Number.isSafeInteger(id)||id<=0)return;
   const casts=actor(current,p[1]).casts,spell=casts.get(id)||{spellID:id,name:p[10],count:0,first:(at-current.start)/1000,last:0};spell.count++;spell.last=(at-current.start)/1000;casts.set(id,spell);
  }
  if(type==='SPELL_HEAL'||type==='SPELL_PERIODIC_HEAL'){
   const index=12+(advanced?19:0),amount=Number(p[index]),overheal=Number(p[index+2]);
   if((Number(p[7])&0x10)&&Number.isFinite(amount)&&amount>=0&&Number.isFinite(overheal))actor(current,p[1]).healing+=Math.max(0,amount-Math.max(0,overheal));
  }
  if(damage){
   const swing=type==='SWING_DAMAGE',base=swing?9:12,index=base+(advanced?19:0);
   const amount=Number(p[index]),overkill=Number(p[index+2]);
   if(!Number.isFinite(amount)||amount<0||!Number.isFinite(overkill)){malformed++;return;}
   const id=swing?6603:Number(p[9]);if(!Number.isSafeInteger(id)||id<=0){malformed++;return;}
   const spells=actor(current,p[1]).damage,spell=spells.get(id)||{spellID:id,name:swing?'Melee':p[10],amount:0};spell.amount+=Math.max(0,amount-Math.max(0,overkill));spells.set(id,spell);
  }
 }
 function finish(){
  closeZone();const output=[],trashGroups=new Map();
  for(const s of fights){
   for(const [guid,stats]of s.actors){
    const duration=(s.end-s.start)/1000,key=s.zoneSerial+':'+guid,trashGroup=trashGroups.get(key);
    if(s.kind==='trash'&&trashGroup){
     trashGroup.duration+=duration;trashGroup.deaths+=stats.deaths;trashGroup.healing+=stats.healing;
     for(const item of stats.damage.values()){const old=trashGroup.damage.find(v=>v.spellID===item.spellID);if(old)old.amount+=item.amount;else trashGroup.damage.push({...item});}
     for(const item of stats.casts.values()){const old=trashGroup.casts.find(v=>v.spellID===item.spellID);if(old)old.count+=item.count;else trashGroup.casts.push({...item});}
    }else{
     const fight={id:String(++serial),guid,character:identities.get(guid),dungeonKey:s.dungeonKey,kind:s.kind,name:s.name,difficulty:s.difficulty,started:s.start,duration,kill:s.kill,deaths:stats.deaths,healing:stats.healing,damage:[...stats.damage.values()],casts:[...stats.casts.values()]};output.push(fight);if(s.kind==='trash')trashGroups.set(key,fight);
    }
   }
  }
  return {schema:1,source:'Local combat log',malformedDamageEvents:malformed,fights:output.slice(-200)};
 }
 return {consume,finish};
}
async function parseLog(file){const parser=logParser();for await(const line of readline.createInterface({input:fs.createReadStream(file,{encoding:'utf8'}),crlfDelay:Infinity}))parser.consume(line);return parser.finish();}
module.exports={csv,timestamp,logParser,parseLog};
