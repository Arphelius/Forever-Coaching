const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Core/LiveRotation.lua'])run(fs.readFileSync(file,'utf8'));
run(`local fc=ForeverCoaching;local live=fc.LiveRotation
local aura,hidden,dead,casting,cooldown,unusable,combat=false,false,false,false,false,false,false
local known={[324]=true,[325]=true}
fc.ForeverSpellCatalog={classes={SHAMAN={spells={['Lightning Shield']={ids={324,325}}}}}}
UnitClass=function()return 'Shaman','SHAMAN'end
UnitIsDeadOrGhost=function()return dead end
UnitAffectingCombat=function()return combat end
UnitCastingInfo=function()return casting and 'Lightning Bolt' or nil end
UnitChannelInfo=function()end
IsPlayerSpell=function(id)return known[id]==true end
C_Spell={GetSpellInfo=function(id)if id==324 or id==325 then return {spellID=id,name='Lightning Shield',iconID=id,castTime=0}end end,
 IsSpellUsable=function()return not unusable,unusable end,
 GetSpellCooldown=function()return {startTime=cooldown and 9 or 0,duration=cooldown and 10 or 0,isEnabled=true}end}
C_UnitAuras={GetAuraDataByIndex=function(unit,index)
 assert(unit=='player');if hidden then error('restricted')end
 if aura and index==1 then return {name=aura,expirationTime=100,applications=3}end
end}
live.ProfileRecommendation=function()return {spellID=403,spellName='Lightning Bolt',icon=403,targetHostile=true}end
local rec=live:GetRecommendation();assert(rec.spellID==325 and rec.selfBuff and rec.reviewEligible==false,'Missing shield uses the highest learned rank even without an enemy')
aura='Lightning Shield';assert(live:GetRecommendation().spellID==403,'Active Lightning Shield returns to the opener')
aura='Water Shield';assert(live:GetRecommendation().spellID==403,'Preserve the chosen Water Shield')
aura='Earth Shield';assert(live:GetRecommendation().spellID==403,'Preserve the chosen Earth Shield')
aura=false;hidden=true;assert(live:GetRecommendation().spellID==403,'Unreadable aura state is not a missing buff');hidden=false
unusable=true;assert(live:GetRecommendation().spellID==403,'Do not suggest an unaffordable shield');unusable=false
cooldown=true;assert(live:GetRecommendation().spellID==403,'Shield cooldown is respected');cooldown=false
known={};assert(live:GetRecommendation().spellID==403,'Never suggest an unlearned shield');known[324]=true
assert(live:GetRecommendation().spellID==324,'Lower learned rank remains supported')
dead=true;assert(live:GetRecommendation().spellID==403,'No shield upkeep while dead');dead=false
casting=true;assert(live:GetRecommendation().spellID==403,'Do not interrupt the current cast for shield upkeep');casting=false
fc.EncounterCoach={GetRecommendation=function()return {spellID=8042,spellName='Earth Shock',situation='interrupt'}end}
assert(live:GetRecommendation().spellID==8042,'Urgent interrupts take priority over shield upkeep');fc.EncounterCoach=nil
`);
run(fs.readFileSync('addons/ForeverCoaching/UI/CombatHUD.lua','utf8'));
run(`ForeverCoachingCombatHUD.scripts.OnUpdate(ForeverCoachingCombatHUD,1)
assert(not ForeverCoaching.combatHUDLastError,ForeverCoaching.combatHUDLastError)
assert(ForeverCoachingRotationStrip:IsShown() and ForeverCoachingRotationSlot1.icon:GetTexture()==324,'HUD displays self-buff upkeep without a hostile target')
print('PASS: missing/active/alternative/hidden shields, highest learned rank, usability, cooldown, death/casting gates, interrupt priority and no-target HUD rendering.')`);
lua.lua_close(L);
