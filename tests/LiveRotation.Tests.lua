local FC=ForeverCoaching
local state={class='MAGE',tree=3,role='damage',mana=100,moving=0,range=true,auras={},combo=0,health=100,mode='single'}
local ids,names={},{};local nextID=100
local function id(name)if not ids[name] then nextID=nextID+1;ids[name]=nextID;names[nextID]=name end;return ids[name] end
FC.EncounterCoach={lessons={},GetBuildContext=function()return {}end,GetRecommendation=function()return state.urgent end}
FC.SpecScenarios={ForCurrent=function()return {available=not state.noSpec,class=state.class,treeIndex=state.tree,spec=state.class..state.tree,role=state.role}end}
UnitExists=function()return true end;UnitIsDeadOrGhost=function()return false end;UnitCanAttack=function()return true end
UnitAffectingCombat=function()return true end
UnitHealth=function(unit)return unit=='player' and state.health or 100 end;UnitHealthMax=function()return 100 end
UnitPower=function()return state.mana end;UnitPowerMax=function()return 100 end
GetUnitSpeed=function()return state.moving end;GetComboPoints=function()return state.combo end
IsPlayerSpell=function(value)return (names[value]~='Ice Barrier' or state.barrierKnown) and (not state.unlearned or state.unlearned~=value) end
IsSpellKnown=IsPlayerSpell
C_Spell={GetSpellInfo=function(value)
 local name=type(value)=='string' and value or names[value]
 return {spellID=id(name),name=name,iconID=id(name),castTime=state.instant and 0 or 2000}
end,IsSpellUsable=function()return not state.unusable,false end,
GetSpellCooldown=function(value)return {startTime=state.cooldown==value and 9 or 0,duration=state.cooldown==value and 20 or 0,isEnabled=true}end,
IsSpellInRange=function()return state.range end,
GetSpellPowerCost=function()if state.hiddenCosts then return nil end;return {{type=0,cost=30}}end}
C_UnitAuras={GetAuraDataByIndex=function(_,index)
 if state.hiddenAuras then error('restricted') end
 local name=state.auras[index];if name then return {name=name,expirationTime=100,applications=state.auraStacks or 1} end
end}
local live=FC.LiveRotation
local rec=live:GetRecommendation()
assert(rec.spellName=='Frostbolt' and #rec.queue==3,'Forecast must stop when the fourth cast would exceed remaining mana')
state.unlearned=id('Frostbolt');assert(not live:GetRecommendation().spellID,'Unlearned spells excluded');state.unlearned=nil
state.range=false;assert(not live:GetRecommendation().spellID,'Out of range excluded');state.range=true
state.moving=7;assert(not live:GetRecommendation().spellID,'Do not recommend a hard cast while moving');state.moving=0
state.cooldown=id('Frostbolt');assert(not live:GetRecommendation().spellID,'Cooldown excluded');state.cooldown=nil
state.hiddenCosts=true;assert(#live:GetRecommendation().queue==1,'Unknown cost cannot produce a fabricated follow-up');state.hiddenCosts=nil
state.barrierKnown=true;rec=live:GetRecommendation();assert(rec.spellName=='Ice Barrier','Frost uses its new damage and absorption buff when learned and absent');state.barrierKnown=false
state.tree=1;state.auras={'Missile Barrage'};rec=live:GetRecommendation();local missiles=0;for _,s in ipairs(rec.queue)do if s.name=='Arcane Missiles' then missiles=missiles+1 end end;assert(missiles==1,'Missile Barrage is consumed at the beginning of the channel');state.tree=3;state.auras={}
state.tree=2;state.auras={'Heating Up'};state.auraStacks=2;assert(live:GetRecommendation().spellName~='Pyroblast','One or two Heating Up stacks must not satisfy the three-stack priority');state.auraStacks=3;assert(live:GetRecommendation().spellName=='Pyroblast');state.auraStacks=nil;state.auras={};state.tree=3
state.class='WARLOCK';state.tree=3
rec=live:GetRecommendation();assert(rec.spellName=='Immolate');assert(rec.queue[2].name=='Conflagrate','Forecast respects applied setup')
state.auras={'Immolate'};assert(live:GetRecommendation().spellName=='Conflagrate','Current owned DoT is not reapplied')
state.hiddenAuras=true;rec=live:GetRecommendation();for _,a in ipairs(rec.queue)do assert(a.name~='Immolate' and a.name~='Conflagrate','Hidden aura state is not absence')end
state.hiddenAuras=nil;state.auras={}
state.class='ROGUE';state.tree=2;state.combo=0
rec=live:GetRecommendation();for _,a in ipairs(rec.queue)do assert(a.name~='Eviscerate','Do not assume builders generate combo points')end
state.combo=5;rec=live:GetRecommendation();assert(rec.spellName=='Slice and Dice','Maintain the attack-speed buff before damage finishers')
state.auras={'Slice and Dice'};rec=live:GetRecommendation();assert(rec.spellName=='Eviscerate');for i=2,#rec.queue do assert(rec.queue[i].name~='Eviscerate','Projected finisher spends combo points')end;state.auras={}
state.tree=1;state.mana=50;rec=live:GetRecommendation();assert(rec.spellName=='Shank','Shank restores Energy; passive Venom is never cast');for _,s in ipairs(rec.queue)do assert(s.name~='Venom')end
state.mana=100;state.tree=3;state.combo=5;assert(live:GetRecommendation().spellName=='Death Mark','Subtlety uses the current finisher');state.tree=2
state.class='MAGE';state.tree=3;state.combo=0
state.urgent={spellID=999,spellName='Kick',encounterPrompt=true};assert(live:GetRecommendation().spellID==999,'Interrupt overrides damage');state.urgent=nil
state.noSpec=true;assert(not live:GetRecommendation().spellID,'A browsed build never substitutes for unreadable spec');state.noSpec=nil
for _,class in ipairs({'MAGE','PRIEST','WARLOCK','HUNTER','ROGUE','WARRIOR','PALADIN','DRUID'})do
 for tree=1,3 do state.class=class;state.tree=tree;local value=live:GetRecommendation();assert(type(value)=='table' and #(value.queue or {})<=4,class..tree) end
end
state.class='MAGE';state.tree=3;state.role='healer';assert(not live:GetRecommendation().spellID,'No invented future healing assignment');state.role='damage'
C_Item={GetItemCount=function()return 1 end,IsUsableItem=function()return true end,GetItemSpell=function()return 'Potion',777 end,GetItemIconByID=function()return 888 end}
C_Container={GetItemCooldown=function()return 0,0,1 end}
SlashCmdList.FOREVERCOACHINGROTATION('item 123 health');state.health=20
assert(live:GetRecommendation().itemID==123,'Configured health item at low health')
state.class='WARRIOR';assert(not live:GetRecommendation().itemID,'An item assigned for one specialization is not used after changing spec');state.class='MAGE'
state.health=100;assert(not live:GetRecommendation().itemID,'Do not waste the health item at full health')
SlashCmdList.FOREVERCOACHINGROTATION('item 123 burst');assert(not live:GetRecommendation().itemID,'Hold burst consumable outside requested window')
SlashCmdList.FOREVERCOACHINGROTATION('burst on');assert(live:GetRecommendation().itemID==123)
state.urgent={spellID=999,spellName='Kick'};assert(live:GetRecommendation().spellID==999,'Urgency overrides burst item');state.urgent=nil
C_Container.GetItemCooldown=function()return 9,120,1 end;assert(not live:GetRecommendation().itemID,'Item shared cooldown respected')
SlashCmdList.FOREVERCOACHINGROTATION('item 123 off');assert(not ForeverCoachingDB.liveRotation.items[123])
state.class='MAGE';state.tree=3;state.role='damage';state.health=100;SlashCmdList.FOREVERCOACHINGROTATION('aoe');state.range=nil
assert(live:GetRecommendation().spellName=='Blizzard','A ground spell is offered in area mode though its range read is nil')
state.range=true;SlashCmdList.FOREVERCOACHINGROTATION('single');assert(live:GetRecommendation().spellName=='Frostbolt','Single target never offers Blizzard')
print('PASS: live priorities, movement/range/readiness, costs, DoTs, combo spending, urgent overrides, all class profiles and opt-in items.')
