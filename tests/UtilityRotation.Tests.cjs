const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Core/LiveRotation.lua'])run(fs.readFileSync(file,'utf8'));
run(`local fc=ForeverCoaching;local live=fc.LiveRotation
local state={race='Gnome',class='MAGE',health=100,known={},cooldown={},range=true,combat=true,loc={},normal='normal',moving=0,combo=0}
local ids={['Escape Artist']=1,['Will of the Forsaken']=2,Stoneform=3,['Gift of the Naaru']=4,['Blood Fury']=5,Berserking=6,['Hammer of Justice']=7,['Kidney Shot']=8,Bash=9,['Scatter Shot']=10,['War Stomp']=11,Heal=12}
local names={};for name,id in pairs(ids)do names[id]=name end
UnitRace=function()return state.race,state.race end;UnitClass=function()return state.class,state.class end
UnitAffectingCombat=function()return state.combat end;UnitIsDeadOrGhost=function()return false end
UnitHealth=function()return state.health end;UnitHealthMax=function()return 100 end
GetUnitSpeed=function()return state.moving end;GetComboPoints=function()return state.combo end
UnitExists=function()return true end;UnitCanAttack=function()return true end
UnitClassification=function()return state.normal end
UnitCastingInfo=function(unit)if unit=='target' and state.cast then return 'Enemy spell',nil,nil,10000,15000,nil,nil,state.uninterruptible end end
UnitChannelInfo=function()end
IsPlayerSpell=function(id)return state.known[id]==true end
C_Spell={GetSpellInfo=function(value)local id=type(value)=='number' and value or ids[value];if id then return {spellID=id,name=names[id],iconID=id,castTime=state.castTime or 0}end end,
 IsSpellUsable=function()return not state.unusable,state.unusable end,
 GetSpellCooldown=function(id)return {startTime=state.cooldown[id] and 9 or 0,duration=state.cooldown[id] and 30 or 0,isEnabled=true}end,
 IsSpellInRange=function()return state.range end}
C_LossOfControl={GetActiveLossOfControlDataCount=function()return #state.loc end,GetActiveLossOfControlData=function(i)if state.hidden then error('restricted')end;return state.loc[i]end}
C_UnitAuras={GetAuraDataByIndex=function(_,i,filter)if filter=='HARMFUL' and i==1 and state.debuff then return {dispelName=state.debuff}end end}
fc.EncounterCoach={lessons={},GetRecommendation=function()return state.urgent end,GetBuildContext=function()return {class=state.class}end}
live.ProfileRecommendation=function()return {spellID=403,spellName='Lightning Bolt',targetHostile=true}end
state.known[1]=true;state.loc={{locType='ROOT',timeRemaining=3}}
assert(live:GetRecommendation().spellID==1,'Gnome escape triggers for an observed root')
state.cooldown[1]=true;assert(not live:UtilityRecommendation(),'Unavailable racial is excluded');state.cooldown={}
state.hidden=true;assert(not live:UtilityRecommendation(),'Hidden control state cannot trigger a racial');state.hidden=false
state.loc={{locType='ROOT',timeRemaining=0}};assert(not live:UtilityRecommendation(),'Expired control does not trigger a racial')
state.race='Scourge';state.known[2]=true;state.loc={{locType='FEAR',timeRemaining=4}}
assert(live:GetRecommendation().spellID==2,'Undead fear escape uses actual known racial')
state.loc={};state.race='Dwarf';state.known[3]=true;state.debuff='Poison'
assert(live:GetRecommendation().spellID==3,'Stoneform is prompted for an observed applicable debuff')
state.debuff=nil;state.race='Draenei';state.known[4]=true;state.health=20
assert(live:GetRecommendation().spellID==4 and live:GetRecommendation().unit=='player','Emergency racial heal targets the player')
state.race='Other';state.known[12]=true;fc.EncounterCoach.lessons={{spellID=12,name='Heal',kind='heal'}}
assert(live:GetRecommendation().spellID==12,'Known class heal offered at low health')
state.moving=7;state.castTime=2000;assert(not live:UtilityRecommendation(),'Do not suggest a hard self-heal while moving');state.moving=0;state.castTime=0
live.ItemRecommendation=function()return {spellID=999,itemID=1000,encounterPrompt=true}end
assert(live:GetRecommendation().itemID==1000,'Ready necessary profession item is integrated ahead of non-escape utility')
live.ItemRecommendation=function()return {spellID=999,itemID=1000,itemPriority=5}end
assert(live:GetRecommendation().spellID==12,'Offensive consumables cannot displace emergency healing')
live.ItemRecommendation=function()end
state.health=100;fc.EncounterCoach.lessons={};state.class='PALADIN';state.known[7]=true;state.cast=true;state.uninterruptible=false
assert(live:GetRecommendation().spellID==7,'Backup control for an observed ordinary-enemy cast')
state.urgent={spellID=123,spellName='Interrupt'};assert(live:GetRecommendation().spellID==123,'Existing ready interrupt takes priority over backup CC');state.urgent=nil
state.normal='worldboss';assert(not live:UtilityRecommendation(),'Never assume boss stun susceptibility');state.normal='normal'
state.uninterruptible=true;assert(not live:UtilityRecommendation(),'Do not invent a stop for an uninterruptible cast');state.uninterruptible=false
state.range=false;assert(not live:UtilityRecommendation(),'Out-of-range control is excluded');state.range=true
state.class='ROGUE';state.known[8]=true;assert(not live:UtilityRecommendation(),'Kidney Shot requires combo points');state.combo=2;assert(live:UtilityRecommendation().spellID==8)
state.class='SHAMAN';state.race='Tauren';state.known[11]=true
assert(not live:UtilityRecommendation(),'Area control requires area mode')
ForeverCoachingDB.liveRotation.mode='aoe';C_SwingTimer={IsTargetWithinSwingRange=function()return false end}
assert(not live:UtilityRecommendation(),'War Stomp requires confirmed close range')
C_SwingTimer.IsTargetWithinSwingRange=function()return true end
assert(live:UtilityRecommendation().spellID==11,'Known War Stomp is a backup stop only with area permission and melee range')
ForeverCoachingDB.liveRotation.mode='single';C_SwingTimer=nil
state.cast=false;state.race='Orc';state.known[5]=true
assert(not live:UtilityRecommendation(),'Do not spend offensive racials without a burst window')
ForeverCoachingDB.liveRotation.burst=true
assert(live:GetRecommendation().spellID==5,'Ready Orc racial is included during enabled burst')
state.race='Troll';state.known[6]=true;assert(live:GetRecommendation().spellID==6,'Ready Troll racial uses the same burst policy')
state.combat=false;assert(not live:UtilityRecommendation(),'No combat utility spam outside a fight')
print('PASS: necessary profession items, emergency healing, race/known/cooldown gates, observed control escapes, backup CC, boss/range/combo exclusions, burst racials and combat scope.')
`);
lua.lua_close(L);
