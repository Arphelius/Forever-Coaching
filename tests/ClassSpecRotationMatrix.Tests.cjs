const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/ForeverSpellCatalog.lua','addons/ForeverCoaching/Data/SpecScenarios.lua','addons/ForeverCoaching/Core/RotationCoach.lua','addons/ForeverCoaching/Core/LiveRotation.lua'])run(fs.readFileSync(file,'utf8'));
run(`local fc=ForeverCoaching;local live=fc.LiveRotation
local state={class='MAGE',tree=1,target=true,combat=true,moving=0}
local byName,byID={},{}
for class,c in pairs(fc.ForeverSpellCatalog.classes)do
 byName[class]={};byID[class]={}
 for name,spell in pairs(c.spells)do
  for _,id in ipairs(spell.ids or {})do local s={spellID=id,name=name,iconID=id,castTime=0,description=spell.description};byName[class][name]=s;byID[class][id]=s end
 end
end
UnitClass=function()return state.class,state.class end;UnitLevel=function()return 60 end
UnitGUID=function(unit)return unit=='player' and 'self' or state.target and 'enemy' end
UnitExists=function(unit)return unit=='player' or state.target end
UnitCanAttack=function()return state.target end;UnitCanAssist=function(_,unit)return unit=='player'end
UnitIsDead=function()return false end;UnitIsDeadOrGhost=UnitIsDead
UnitHealth=function()return 100 end;UnitHealthMax=function()return 100 end
UnitPower=function()return 2000 end;UnitPowerMax=function()return 2000 end;UnitPowerType=function()return 0 end
UnitAffectingCombat=function()return state.combat end
UnitCastingInfo=function()end;UnitChannelInfo=function()end
GetUnitSpeed=function()return state.moving end;GetComboPoints=function()return 5 end
IsPlayerSpell=function(id)return byID[state.class][id]~=nil end
C_Spell={GetSpellInfo=function(value)return type(value)=='number' and byID[state.class][value] or byName[state.class][value]end,
 GetSpellDescription=function(id)return byID[state.class][id] and byID[state.class][id].description or ''end,
 IsSpellUsable=function()return true,false end,
 GetSpellCooldown=function()return {startTime=0,duration=0,isEnabled=true}end,
 GetSpellPowerCost=function()return {{type=0,cost=0}}end,
 IsSpellInRange=function()return state.target end}
C_UnitAuras={GetAuraDataByIndex=function()end,GetPlayerAuraBySpellID=function()return {}end}
C_SwingTimer={IsTargetWithinSwingRange=function()return true end}
IsCurrentSpell=function(id)return id==6603 end
fc.EncounterCoach={lessons={},GetBuildContext=function()return {class=state.class,activeTalents={}}end,GetRecommendation=function()end}
fc.SpecScenarios={ForCurrent=function()
 local p=fc.SpecScenarioProfiles[state.class][state.tree]
 return {available=not state.unknown,class=state.class,treeIndex=state.tree,spec=p.name,role=state.bear and 'tank' or p.role}
end}
local total=0
for class,profiles in pairs(fc.SpecScenarioProfiles)do
 state.class=class
 for tree,profile in ipairs(profiles)do
  state.tree=tree;state.target=true;state.combat=true;state.unknown=false
  local rec=live:GetRecommendation();assert(type(rec)=='table',class..tree)
  assert(#(rec.queue or {})<=4,class..tree..': oversized strip')
  if profile.role=='healer' then assert(not rec.spellID,class..tree..': do not invent future healing targets')
  else assert(rec.spellID,class..tree..': no usable attack with a learned spellbook and readable state') end
  for _,entry in ipairs(rec.queue or {})do assert(entry.id==6603 or byID[class][entry.id],class..tree..': unlearned/other-class action')end
  state.target=false;rec=live:GetRecommendation();assert(not rec.spellID,class..tree..': no enemy means no offensive recommendation')
  local idle=live:GetIdleRecommendation();assert(idle.preview and #idle.queue>0 and #idle.queue<=4,class..tree..': persistent idle strip')
  state.target=true;state.unknown=true
  if class~='SHAMAN' then assert(not live:GetRecommendation().spellID,class..tree..': never borrow a browsed spec')end
  state.unknown=false;total=total+1
 end
end
state.class='DRUID';state.tree=2;state.bear=true;state.target=true
local bear=live:GetRecommendation();assert(bear.spellID and byID.DRUID[bear.spellID],'Bear has its own learned tank profile')
assert(total==27)
print('PASS: actual bundled spell IDs across 27 specs plus Bear, healer separation, no-target safety, persistent idle strips, four-icon budget and unavailable-spec handling.')
`);
lua.lua_close(L);
