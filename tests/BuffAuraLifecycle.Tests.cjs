const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/ForeverSpellCatalog.lua','addons/ForeverCoaching/Core/LiveRotation.lua'])run(fs.readFileSync(file,'utf8'));
run(`local fc=ForeverCoaching;local live=fc.LiveRotation
local class,known,restricted,aura,instance='SHAMAN',nil,false,nil,100
local names={}
for _,c in pairs(fc.ForeverSpellCatalog.classes)do for name,spell in pairs(c.spells)do for _,id in ipairs(spell.ids or {})do names[id]=name end end end
UnitClass=function()return class,class end;UnitIsDeadOrGhost=function()return false end
UnitAffectingCombat=function()return true end;GetComboPoints=function()return 3 end
IsPlayerSpell=function(id)return id==known end
C_Spell={GetSpellInfo=function(id)if type(id)=='number' then return {spellID=id,name=names[id],iconID=id,castTime=0}end end,
 IsSpellUsable=function()return true,false end,GetSpellCooldown=function()return {startTime=0,duration=0,isEnabled=true}end}
C_UnitAuras={GetPlayerAuraBySpellID=function(id)if restricted then return nil end;if aura and id==known then return {name=aura,spellId=id,auraInstanceID=instance}end end,
 GetAuraDataByIndex=function(_,index)if restricted then error('restricted enumeration')end;if index==1 and aura then return {name=aura,auraInstanceID=instance}end end}
local listener
for _,f in ipairs(TestFrames)do if f.events.UNIT_AURA then listener=f end end
local function event(unit,update)listener.scripts.OnEvent(listener,'UNIT_AURA',unit,update)end
local examples={MAGE='Arcane Intellect',PRIEST='Inner Fire',WARLOCK='Demon Armor',DRUID='Mark of the Wild',HUNTER='Aspect of the Hawk',WARRIOR='Battle Shout',PALADIN='Blessing of Kings',ROGUE='Slice and Dice',SHAMAN='Lightning Shield'}
for token,name in pairs(examples)do
 class=token;known=fc.ForeverSpellCatalog.classes[class].spells[name].ids[1]
 live.buffGroups={};live.buffInstances={};restricted=false;aura=name;instance=instance+1
 assert(not live:ShieldRecommendation(),class..': record the active aura instance')
 restricted=true
 assert(not live:ShieldRecommendation(),class..': active aura with restricted scan must not create a duplicate buff prompt')
 event('party1',{removedAuraInstanceIDs={instance}})
 assert(not live:ShieldRecommendation(),class..': another unit cannot remove our buff')
 event('player',{removedAuraInstanceIDs={instance+999}})
 assert(not live:ShieldRecommendation(),class..': unrelated aura removal must not count as buff expiration')
 event('player',{removedAuraInstanceIDs={instance}})
 local rec=live:ShieldRecommendation();assert(rec and rec.spellID==known,class..': explicit removal restores the prompt even when combat scans are restricted')
 for i=1,3 do assert(live:ShieldRecommendation().spellID==known,class..': reminder persists until buff application')end
 instance=instance+1;event('player',{addedAuras={{name=name,spellId=known,auraInstanceID=instance}}})
 assert(not live:ShieldRecommendation(),class..': reapplication clears the reminder while scans remain restricted')
 event('player',{removedAuraInstanceIDs={instance}})
 assert(live:ShieldRecommendation(),class..': repeat expiration works')
 -- Recover from a missed/opaque added event when reads become available again.
 restricted=false;instance=instance+1;aura=name
 assert(not live:ShieldRecommendation(),class..': a readable active aura overrides an old removal observation')
end
print('PASS: nine-class active -> restricted combat -> explicit removal -> persistent reminder -> reapplication -> repeated expiration, with unit/instance isolation and recovery.')
`);
lua.lua_close(L);
