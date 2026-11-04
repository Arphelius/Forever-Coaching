const fs=require('fs');const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(`ForeverCoaching={};ForeverCoachingDB={};local state={class='ROGUE',tree=2,role='damage',health=1000,maxHealth=1000,power=100,maxPower=100,powerType=3,level=60,combat=true,owned={},disabled={},cooldowns={},skill=0}
ProfessionState=state;GetTime=function()return 100 end;CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
UnitClass=function()return state.class,state.class end;UnitLevel=function()return state.level end
UnitHealth=function()return state.health end;UnitHealthMax=function()return state.maxHealth end
UnitPowerType=function()return state.powerType end;UnitPower=function()return state.power end;UnitPowerMax=function()return state.maxPower end
UnitAffectingCombat=function()return state.combat end;UnitIsDeadOrGhost=function()return false end
UnitExists=function()return not state.noTarget end;UnitCanAttack=function()return not state.noTarget end
UnitCastingInfo=function()return state.casting and 'Cast' end;GetUnitSpeed=function()return state.moving and 7 or 0 end
GetProfessions=function()return 1 end;GetProfessionInfo=function()return 'Engineering',nil,state.skill,nil,nil,nil,202 end
ForeverCoaching.EncounterCoach={GetBuildContext=function()return {}end}
ForeverCoaching.SpecScenarios={ForCurrent=function()return {available=not state.noSpec,class=state.class,treeIndex=state.tree,role=state.role}end}
ForeverCoaching.GuideBrowser={class='PRIEST',buildID='holy'}
C_Item={GetItemCount=function(id,bank)assert(bank==false,'Bank-only items must never count');return state.owned[id] or 0 end,IsUsableItem=function(id)return not state.disabled[id]end,GetItemSpell=function(id)for _,item in ipairs(ForeverCoaching.ProfessionItems.items)do if item.id==id then return item.name,state.wrongSpell and 1 or item.spellID end end end,GetItemIconByID=function(id)return id end}
C_Container={GetItemCooldown=function(id)if state.hiddenCooldown then return nil end;if state.cooldowns[id]then return 90,120,1 end;return 0,0,1 end}
UseItemByName=function()error('Suggestions must never use items automatically')end`);
for(const file of ['Data/ProfessionItems.lua','Core/ProfessionItems.lua','Core/ProfessionGuide.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local s=ProfessionState;local e=fc.CraftedItems
local function item()e:Invalidate();return e:GetRecommendation()end
assert(not item(),'No owned items: no suggestions')
s.owned[13446]=1;s.health=200;assert(item().itemID==13446,'A Rogue can use a crafted healing potion regardless of Alchemy training')
s.hiddenCooldown=true;assert(not item());s.hiddenCooldown=false;s.cooldowns[13446]=true;assert(not item());s.cooldowns={}
s.disabled[13446]=true;assert(not item());s.disabled={};s.wrongSpell=true;assert(not item(),'Do not confuse a reused item ID from another game edition');s.wrongSpell=false
s.level=10;assert(not item(),'Level requirement');s.level=60;s.health=1000
s.owned={[13444]=1};s.power=5;assert(not item(),'Rogues must not be told to use Mana potions')
s.class='MAGE';s.tree=1;s.powerType=0;s.maxPower=2000;s.power=100;assert(item().itemID==13444)
s.class='ROGUE';s.powerType=3;s.maxPower=100;s.power=10;s.owned={[7676]=1};assert(item().itemID==7676);s.power=80;assert(not item(),'Do not waste Tea at high Energy')
s.class='DRUID';s.tree=2;s.power=10;assert(item().itemID==7676,'Cat can also use Tea');s.powerType=0;assert(not item(),'Caster Druid is not in an Energy form')
s.class='WARRIOR';s.tree=1;s.powerType=1;s.power=10;s.owned={[5631]=1};assert(item().itemID==5631);s.power=80;assert(not item())
s.powerType=0;s.power=1000;s.maxPower=1000;s.owned={[250937]=1,[250943]=1};ForeverCoachingDB.liveRotation.burst=true
for _,case in ipairs({{'WARRIOR',1,'damage',250943},{'ROGUE',2,'damage',250943},{'HUNTER',2,'damage',250943},{'MAGE',2,'damage',250937},{'PRIEST',3,'damage',250937},{'WARLOCK',1,'damage',250937},{'PALADIN',2,'tank',250937},{'PALADIN',3,'damage',250943},{'SHAMAN',1,'damage',250937},{'SHAMAN',2,'damage',250943},{'DRUID',1,'damage',250937},{'DRUID',2,'damage',250943}})do
 s.class,s.tree,s.role=case[1],case[2],case[3];assert(item().itemID==case[4],'Choose the actual class/spec effect, independent of browsed guides')
end
ForeverCoachingDB.liveRotation.burst=false;assert(not item(),'Hold damage potions outside requested burst')
s.class='PRIEST';s.role='healer';s.tree=2;ForeverCoachingDB.liveRotation.burst=true;s.owned={[250937]=1,[250949]=1};assert(item().itemID==250949,'Healers receive Mender healing power, not a damage potion')
e:SetEnabled(false);assert(not item());e:SetEnabled(true)
s.class='ROGUE';s.role='damage';s.tree=2;s.owned={[15993]=1};ForeverCoachingDB.liveRotation.burst=false;ForeverCoachingDB.liveRotation.mode='aoe';assert(not item(),'Owning a grenade is insufficient without Engineering')
s.skill=260;assert(item().itemID==15993);s.moving=true;assert(not item());s.moving=false;s.casting=true;assert(not item());s.casting=false;s.noTarget=true;assert(not item());s.noTarget=false
ForeverCoachingDB.liveRotation.mode='single';assert(not item(),'Grenades require permitted area damage')
s.combat=false;assert(not item());s.combat=true;s.health=100;s.owned={[13446]=1};s.noSpec=true;assert(item().itemID==13446,'Survival item does not require a guessed spec');s.noSpec=false
ForeverCoachingDB.liveRotation.excludedCraftedItems={[13446]=true};assert(not item(),'Explicitly removed items stay suppressed')
for _,class in ipairs({'WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','SHAMAN','MAGE','WARLOCK','DRUID'})do for _,goal in ipairs(fc.ProfessionGuide.goals)do local g=fc.ProfessionGuide:ForBuild(class,{role='damage'},goal.value);assert(g.available and g.pair and g.use and #g.sources>=3)end end
print('PASS: owned/usable/ready/level requirements, same shared cooldown, correct class/spec power, healer separation, Cat Tea, skill-gated grenades, burst/AoE opt-ins, actual identity, disable and nine-class guides.')`);
run(fs.readFileSync('addons/ForeverCoaching/Core/LiveRotation.lua','utf8'));
run(`local fc=ForeverCoaching;local s=ProfessionState
ForeverCoachingDB.liveRotation.excludedCraftedItems={};s.owned={[13446]=1};s.health=100;s.class='ROGUE';s.role='damage';s.tree=2
fc.CraftedItems:Invalidate()
fc.EncounterCoach.GetRecommendation=function()return nil end
assert(fc.LiveRotation:GetRecommendation().itemID==13446,'The actual live rotation must include the owned profession consumable')
s.owned[250937]=1;SlashCmdList.FOREVERCOACHINGROTATION('item 250937 burst');SlashCmdList.FOREVERCOACHINGROTATION('burst on')
assert(fc.LiveRotation:GetRecommendation().itemID==13446,'Automatic emergency recovery must precede a manually configured offensive potion')
fc.EncounterCoach.GetRecommendation=function()return {spellID=999,spellName='Kick'}end
assert(fc.LiveRotation:GetRecommendation().spellID==999,'Assigned urgent actions remain ahead of optional crafted items')
SlashCmdList.FOREVERCOACHINGROTATION('crafted off');assert(not fc.CraftedItems:IsEnabled())
SlashCmdList.FOREVERCOACHINGROTATION('crafted on');assert(fc.CraftedItems:IsEnabled())
print('PASS: live-engine integration, urgent override and saved crafted-item controls.')`);
