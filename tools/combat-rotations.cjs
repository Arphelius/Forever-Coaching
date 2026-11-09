const fs=require('fs'),path=require('path');
const {resolveDungeon}=require('./forever-dungeons.cjs');
const AUTOMATIC=new Set([1,75,5019,6603]);
const RACIAL_BUFFS=new Set(['blood fury','berserking','stoneform','will of the forsaken','escape artist']);
const optionalAbility=name=>RACIAL_BUFFS.has(name.toLowerCase())||/war stomp|cannibalize|shadowmeld|perception|devouring plague|starshards|feedback|hex of weakness|shadowguard|touch of weakness|desperate prayer|elune|grenade|dynamite|sapper|bomb|dragonling|battle chicken|potion/i.test(name);
const nonCombat=name=>/^(melee|attack|auto attack|auto shot|shoot|shoot wand|resurrection|ancestral spirit|redemption|revive)$/i.test(name)||/^(teleport|portal|track|find|sense)\b|astral recall|hearthstone|fishing|eagle eye|far sight|beast lore|feed pet|revive pet|dismiss pet|conjure (food|water|mana)|create (healthstone|soulstone|firestone|spellstone)|ritual of|summon (warhorse|charger|felsteed|dreadsteed)/i.test(name);
let classSpells;
function knownSpells(){
 if(classSpells)return classSpells;
 const f=require('./preview-runtime/node_modules/fengari');const L=f.lauxlib.luaL_newstate();f.lualib.luaL_openlibs(L);
 const source=fs.readFileSync(path.join(__dirname,'../addons/ForeverCoaching/Data/ForeverSpellCatalog.lua'),'utf8');
 if(f.lauxlib.luaL_dostring(L,f.to_luastring(source))!==f.lua.LUA_OK)throw Error('Reviewed spell catalog could not load.');
 classSpells=new Map();
 const collect=`for class,book in pairs(ForeverCoaching.ForeverSpellCatalog.classes)do for name,spell in pairs(book.spells)do if not spell.passive then for _,id in ipairs(spell.ids)do Record(class,id,name)end end end end`;
 f.lua.lua_pushcfunction(L,state=>{const className=f.to_jsstring(f.lua.lua_tostring(state,1)),id=f.lua.lua_tointeger(state,2),name=f.to_jsstring(f.lua.lua_tostring(state,3));if(!nonCombat(name)){if(!classSpells.has(className))classSpells.set(className,new Set());classSpells.get(className).add(id);}return 0;});
 f.lua.lua_setglobal(L,f.to_luastring('Record'));
 try{if(f.lauxlib.luaL_dostring(L,f.to_luastring(collect))!==f.lua.LUA_OK)throw Error('Reviewed active spells could not load.');}finally{f.lua.lua_close(L);}
 return classSpells;
}
function combatCasts(p,start,end){
 const own=p.events.filter(e=>e.sourceID===p.actor.id&&e.timestamp>=start&&e.timestamp<=end);
 const evidence=new Set(own.filter(e=>['damage','heal','interrupt','dispel','applydebuff'].includes(e.type)).map(e=>e.abilityGameID));
 for(const event of own)if(event.type==='applybuff'&&event.targetID===p.actor.id&&RACIAL_BUFFS.has((p.abilities.get(event.abilityGameID)||'').toLowerCase()))evidence.add(event.abilityGameID);
 const learned=knownSpells().get(p.actor.subType.toUpperCase())||new Set();
 return p.casts.filter(e=>e.timestamp>=start&&e.timestamp<=end&&!AUTOMATIC.has(e.abilityGameID)&&
  Number.isSafeInteger(e.abilityGameID)&&e.abilityGameID>0&&!nonCombat(p.abilities.get(e.abilityGameID)||'')&&!optionalAbility(p.abilities.get(e.abilityGameID)||'')&&
  (evidence.has(e.abilityGameID)||learned.has(e.abilityGameID))).sort((a,b)=>a.timestamp-b.timestamp);
}
function summarize(p,segment){
 const casts=combatCasts(p,segment.startTime,segment.endTime);
 const damage=new Map();
 for(const e of p.events)if(e.type==='damage'&&e.sourceID===p.actor.id&&e.timestamp>=segment.startTime&&e.timestamp<segment.endTime&&Number.isFinite(e.amount)&&e.amount>0){
  const id=e.abilityGameID;if(!Number.isSafeInteger(id)||id<=0)continue;
  const row=damage.get(id)||{spellID:id,name:p.abilities.get(id)||'Spell #'+id,amount:0};row.amount+=e.amount;damage.set(id,row);
 }
 const action=e=>({spellID:e.abilityGameID,name:p.abilities.get(e.abilityGameID)||'Spell #'+e.abilityGameID});
 const compact=[];let previousCast,chain=0;
 for(const event of casts){
  if(previousCast&&(event.timestamp-previousCast.timestamp>15000||p.deaths.some(d=>d.timestamp>=previousCast.timestamp&&d.timestamp<=event.timestamp)))chain++;
  const previous=compact.at(-1);if(!previous||previous.abilityGameID!==event.abilityGameID||previous.chain!==chain)compact.push({...event,chain});
  previousCast=event;
 }
 const patterns=new Map();
 for(let size=2;size<=4;size++)for(let i=0;i<=compact.length-size;i++){
  const slice=compact.slice(i,i+size);if(slice.some(e=>e.chain!==slice[0].chain))continue;
  const key=slice.map(e=>e.abilityGameID).join(':');const row=patterns.get(key)||{events:slice,count:0,last:-size};
  if(i>=row.last+size){row.count++;row.last=i;}patterns.set(key,row);
 }
 const repeated=[...patterns.values()].filter(p=>p.count>=2).sort((a,b)=>b.count*b.events.length-a.count*a.events.length||b.count-a.count)[0];
 const steps=[];let previous;
 for(const event of casts){
  const at=(event.timestamp-segment.startTime)/1000;
  const row=steps.at(-1);
  const separated=previous&&(event.timestamp-previous.timestamp>15000||p.deaths.some(d=>d.timestamp>=previous.timestamp&&d.timestamp<=event.timestamp));
  if(row&&row.spellID===event.abilityGameID&&!separated){row.count++;row.end=at;}
  else steps.push({...action(event),at,end:at,count:1});
  previous=event;
 }
 return {combatOnly:true,kind:segment.encounterID===0?'trash':'boss',name:segment.encounterID===0?'Trash mobs':segment.name,
  start:(segment.startTime-p.fight.startTime)/1000,end:(segment.endTime-p.fight.startTime)/1000,
  opener:compact.filter(e=>e.chain===compact[0]?.chain).slice(0,6).map(action),repeated:repeated?repeated.events.map(action):[],repeats:repeated?.count||0,
  damage:[...damage.values()],healing:healingBySegment(p,segment),steps,fullSequence:true,combatCasts:casts.length,complete:p.complete,kill:segment.kill===true};
}
function healingBySegment(p,segment){
 if(!p.friendlyTargets){p.friendlyTargets=new Set([p.actor.id,...(p.fight.friendlyPlayers||[])]);for(const e of p.events)if(e.type==='summon'&&p.friendlyTargets.has(e.sourceID))p.friendlyTargets.add(e.targetID);}
 if(!p.healingEvents)p.healingEvents=p.events.filter(e=>e.sourceID===p.actor.id&&(e.type==='heal'||e.type==='absorbed'));
 const spells=new Map();
 for(const e of p.healingEvents)if(e.timestamp>=segment.startTime&&e.timestamp<segment.endTime&&e.targetIsFriendly!==false&&(p.friendlyTargets.has(e.targetID)||e.targetIsFriendly===true)&&Number.isFinite(e.amount)&&e.amount>=0&&Number.isSafeInteger(e.abilityGameID)&&e.abilityGameID>0){
  // WCL heal.amount already excludes overheal. Heal absorbs and consumed shields
  // contribute to effective healing; never subtract overheal a second time.
  const amount=e.amount+(e.type==='heal'&&Number.isFinite(e.absorbed)?Math.max(0,e.absorbed):0);
  if(amount>0){const row=spells.get(e.abilityGameID)||{spellID:e.abilityGameID,name:p.abilities.get(e.abilityGameID)||'Spell #'+e.abilityGameID,amount:0};row.amount+=amount;spells.set(e.abilityGameID,row);}
 }
 return [...spells.values()];
}
function isDungeonRun(fight){
 const dungeon=resolveDungeon(fight.gameZone?.name,fight.name),normal=s=>String(s).toLowerCase().replace(/[^a-z0-9]/g,'');
 return !!(fight.dungeonPulls?.length||dungeon&&[dungeon.name,...dungeon.aliases].some(n=>normal(n)===normal(fight.name)||normal(n)===normal(fight.gameZone?.name+': '+fight.name)));
}
function encounterSegments(p){
 const wholeDungeon=isDungeonRun(p.fight);
 const segments=Array.isArray(p.fight.dungeonPulls)&&p.fight.dungeonPulls.length?p.fight.dungeonPulls:
  p.fight.encounterID===0||!wholeDungeon&&p.fight.name!==p.fight.gameZone?.name?[p.fight]:[];
 return segments.filter(s=>Number.isFinite(s.startTime)&&Number.isFinite(s.endTime)&&s.endTime>s.startTime&&s.startTime>=p.fight.startTime&&s.endTime<=p.fight.endTime&&Number.isSafeInteger(s.encounterID)&&s.encounterID>=0&&typeof s.name==='string');
}
function encounterRotations(p){return encounterSegments(p).map(s=>summarize(p,s));}
function encounterDamageSummaries(p){
 const own={...p,events:p.events.filter(e=>e.sourceID===p.actor.id)};
 return encounterSegments(p).map(s=>{
  const damage=new Map();for(const e of own.events)if(e.type==='damage'&&e.timestamp>=s.startTime&&e.timestamp<s.endTime&&Number.isFinite(e.amount)&&e.amount>0&&Number.isSafeInteger(e.abilityGameID)&&e.abilityGameID>0){const row=damage.get(e.abilityGameID)||{spellID:e.abilityGameID,name:p.abilities.get(e.abilityGameID)||'Spell #'+e.abilityGameID,amount:0};row.amount+=e.amount;damage.set(e.abilityGameID,row);}
  return {combatOnly:true,summaryOnly:true,kind:s.encounterID===0?'trash':'boss',name:s.encounterID===0?'Trash mobs':s.name,start:(s.startTime-p.fight.startTime)/1000,end:(s.endTime-p.fight.startTime)/1000,opener:[],repeated:[],repeats:0,combatCasts:combatCasts(own,s.startTime,s.endTime).length,complete:p.complete,kill:s.kill===true,damage:[...damage.values()],healing:healingBySegment(p,s)};
 });
}
module.exports={encounterRotations,encounterDamageSummaries,combatCasts,nonCombat,isDungeonRun};
