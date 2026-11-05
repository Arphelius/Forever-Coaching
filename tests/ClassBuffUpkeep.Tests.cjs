const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/ForeverSpellCatalog.lua','addons/ForeverCoaching/Core/LiveRotation.lua'])run(fs.readFileSync(file,'utf8'));
run(`local fc=ForeverCoaching;local live=fc.LiveRotation
local currentClass,tree,knownID,aura,expiration,hidden,unusable
local names={}
for _,catalog in pairs(fc.ForeverSpellCatalog.classes)do for name,spell in pairs(catalog.spells)do for _,id in ipairs(spell.ids or {})do names[id]=name end end end
UnitClass=function()return currentClass,currentClass end
UnitIsDeadOrGhost=function()return false end
UnitAffectingCombat=function()return true end
GetComboPoints=function()return 3 end
UnitCastingInfo=function()end;UnitChannelInfo=function()end
IsPlayerSpell=function(id)return id==knownID end
C_Spell={GetSpellInfo=function(id)if type(id)=='number' then return {spellID=id,name=names[id],iconID=id,castTime=0}end end,
 IsSpellUsable=function()return not unusable,unusable end,
 GetSpellCooldown=function()return {startTime=0,duration=0,isEnabled=true}end}
C_UnitAuras={GetAuraDataByIndex=function(_,i)if hidden then error('restricted')end;if i==1 and aura then return {name=aura,expirationTime=expiration,applications=1}end end}
C_UnitAuras.GetPlayerAuraBySpellID=function(id)
 if hidden then error('restricted')end
 if names[id]==aura and (expiration==0 or expiration>GetTime()) then return {name=aura}end
end
fc.EncounterCoach={GetBuildContext=function()return {class=currentClass}end}
fc.SpecScenarios={ForCurrent=function()return {available=true,class=currentClass,treeIndex=tree,role=tree==3 and 'healer' or 'damage'}end}
local examples={MAGE='Arcane Intellect',PRIEST='Inner Fire',WARLOCK='Demon Armor',DRUID='Mark of the Wild',HUNTER='Aspect of the Hawk',WARRIOR='Battle Shout',PALADIN='Blessing of Kings',ROGUE='Slice and Dice',SHAMAN='Lightning Shield'}
for class,name in pairs(examples)do
 currentClass=class;local ranks=fc.ForeverSpellCatalog.classes[class].spells[name].ids;knownID=ranks[#ranks]
 for spec=1,3 do
  tree=spec;aura=nil;expiration=nil
  local r=live:ShieldRecommendation();assert(r and r.spellID==knownID,class..spec..': missing buff must appear')
  aura=name;expiration=GetTime()+.1
  assert(not live:ShieldRecommendation(),class..spec..': even nearly expired buffs stay active')
  expiration=0;assert(not live:ShieldRecommendation(),class..spec..': permanent buff stays active')
  expiration=GetTime()-1;assert(live:ShieldRecommendation(),class..spec..': expired buff should appear')
  aura=nil;hidden=true;assert(not live:ShieldRecommendation(),class..spec..': hidden aura state cannot mean missing');hidden=false
  unusable=true;assert(not live:ShieldRecommendation(),class..spec..': unusable buff is excluded');unusable=false
 end
end
currentClass='MAGE';tree=1;knownID=fc.ForeverSpellCatalog.classes.MAGE.spells['Mage Armor'].ids[1];aura='Frost Armor';expiration=100
assert(not live:ShieldRecommendation(),'Do not replace an active alternative armor')
currentClass='SHAMAN';tree=3;knownID=fc.ForeverSpellCatalog.classes.SHAMAN.spells['Water Shield'].ids[1];aura=nil
assert(live:ShieldRecommendation().spellName=='Water Shield','Healer upkeep prefers the learned Water Shield')
currentClass='SHAMAN';tree=2;knownID=fc.ForeverSpellCatalog.classes.SHAMAN.spells['Lightning Shield'].ids[1]
C_UnitAuras.GetAuraDataByIndex=function()error('Enumeration restricted')end
C_UnitAuras.GetPlayerAuraBySpellID=function()return nil end
assert(live:ShieldRecommendation().spellID==knownID,'Targeted buff absence still works when enumeration is restricted and removed shield alternatives have no IDs')
local secret={};issecretvalue=function(value)return value==secret end
C_UnitAuras.GetPlayerAuraBySpellID=function(id)if id==knownID then return {name=secret,applications=secret,expirationTime=secret}end end
assert(not live:ShieldRecommendation(),'Buff presence does not require reading secret names, stacks or duration')
C_UnitAuras.GetPlayerAuraBySpellID=function()error('Restricted query')end
assert(not live:ShieldRecommendation(),'Fully restricted aura data cannot be treated as expired')
print('PASS: upkeep across all nine classes and three specs, expiry-only refresh, permanent buffs, hidden aura state, usability, alternatives and healer shield choice.')
`);
lua.lua_close(L);
