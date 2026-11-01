-- Tank live priorities (Protection Paladin, Protection Warrior, Bear) from MythicSim's tank APLs.
-- Spells resolve only when known, so a level 20 character gets a shorter list than a level 60 one.
local FC=ForeverCoaching
local state
local function reset(class,tree,role,known)
    local set={};for _,n in ipairs(known) do set[n]=true end
    state={class=class,tree=tree,role=role,known=set,buffs={},debuffs={},stance=nil,rage=0,mana=100,health=100,targetHealth=100,cd={},mode='single'}
    ForeverCoachingDB=nil
end
local ids,names={},{};local nextID=500
local function id(name)if not ids[name] then nextID=nextID+1;ids[name]=nextID;names[nextID]=name end;return ids[name] end
FC.EncounterCoach={lessons={},GetBuildContext=function()return {}end,GetRecommendation=function()end}
FC.SpecScenarios={ForCurrent=function()return {available=true,class=state.class,treeIndex=state.tree,spec=state.class..state.tree,role=state.role}end}
FC.RoleWarnings=nil
UnitExists=function()return true end;UnitIsDeadOrGhost=function()return false end;UnitCanAttack=function()return true end
UnitAffectingCombat=function()return true end;UnitCastingInfo=function()end;UnitChannelInfo=function()end
UnitHealth=function(unit)if unit=='player' then return state.health end;return state.targetHealth end
UnitHealthMax=function()return 100 end
UnitPower=function(_,kind)if kind==1 then return state.rage end;return state.mana end
GetUnitSpeed=function()return 0 end;GetComboPoints=function()return 0 end
IsPlayerSpell=function(value)return state.known[names[value]]==true end
IsSpellKnown=IsPlayerSpell
GetSpellInfo=function(value)local n=type(value)=='number' and names[value] or value;return n,nil,id(n) end
C_Spell={GetSpellInfo=function(value)
    local name=type(value)=='string' and value or names[value]
    return {spellID=id(name),name=name,iconID=id(name),castTime=0}
end,IsSpellUsable=function()return true,false end,
GetSpellCooldown=function(value)local on=state.cd[names[value]];return {startTime=on and 9 or 0,duration=on and 20 or 0,isEnabled=true}end,
IsSpellInRange=function()return true end,
GetSpellPowerCost=function()return {}end}
C_UnitAuras={GetAuraDataByIndex=function(unit,index)
    if state.hiddenAuras then error('restricted') end
    local list=unit=='player' and state.buffs or state.debuffs
    local a=list[index];if a then return {name=a[1],expirationTime=a[2] or 100,applications=a[3]} end
end}
GetNumShapeshiftForms=function()return 3 end
GetShapeshiftFormInfo=function(i)
    local forms={'Battle Stance','Defensive Stance','Berserker Stance'}
    return id(forms[i]),state.stance==forms[i],true,id(forms[i])
end
local live=FC.LiveRotation
local function first()return live:GetRecommendation().spellName end
local function queue()local out={};for _,s in ipairs(live:GetRecommendation().queue or {})do out[#out+1]=s.name end;return table.concat(out,', ')end

-- Protection Paladin.
local pal60={'Righteous Fury','Judgement','Seal of Righteousness','Holy Shield','Holy Strike','Hammer of Wrath','Lay on Hands','Consecration','Hammer of the Righteous'}
reset('PALADIN',2,'tank',pal60)
assert(first()=='Righteous Fury','Righteous Fury first when missing: '..queue())
assert(queue()=='Righteous Fury, Seal of Righteousness, Judgement, Holy Shield','Lv60 Paladin opener: the seal, then Judgement on it: '..queue())
state.buffs={{'Righteous Fury'},{'Seal of Righteousness'},{'Holy Shield'}}
assert(first()=='Judgement','Judgement while the seal is up: '..queue())
state.buffs={{'Righteous Fury'},{'Seal of Righteousness',10.5},{'Holy Shield'}}
assert(queue():find('Seal of Righteousness',1,true),'Seal refreshed when 1 s or less remains: '..queue())
state.buffs={{'Righteous Fury'},{'Seal of Righteousness'},{'Holy Shield'}};state.cd={Judgement=true}
assert(first()=='Holy Strike','Holy Strike when Judgement is on cooldown: '..queue())
state.targetHealth=15;assert(first()=='Hammer of Wrath','Hammer of Wrath below 20%');state.targetHealth=100
state.health=5;assert(first()=='Lay on Hands','Lay on Hands below 10% health');state.health=100
assert(not queue():find('Consecration',1,true),'Consecration waits for area mode')
ForeverCoachingDB.liveRotation.mode='aoe'
assert(first()=='Hammer of the Righteous' and queue():find('Consecration',1,true),'Area mode adds Hammer of the Righteous and Consecration: '..queue())
-- Level 20: no Holy Shield or Hammer of the Righteous yet; the list shrinks, nothing invented.
reset('PALADIN',2,'tank',{'Righteous Fury','Judgement','Seal of Righteousness','Holy Strike','Consecration'})
state.buffs={{'Righteous Fury'},{'Seal of Righteousness'}}
assert(queue()=='Judgement, Holy Strike','Lv20 Paladin: '..queue())
state.hiddenAuras=true
assert(not queue():find('Righteous Fury',1,true) and not queue():find('Judgement',1,true),'Hidden buffs never trigger buff or seal advice: '..queue())

-- Protection Warrior.
local war60={'Defensive Stance','Shield Slam','Revenge','Battle Shout','Sunder Armor','Heroic Strike','Thunder Clap','Cleave'}
reset('WARRIOR',3,'tank',war60);state.stance='Battle Stance';state.rage=60
assert(first()=='Defensive Stance','Defensive Stance first outside it: '..queue())
state.stance='Defensive Stance';state.buffs={{'Battle Shout'}}
assert(queue()=='Shield Slam, Revenge, Sunder Armor, Sunder Armor','Lv60 Warrior: Sunder ahead of Heroic Strike under 5 stacks: '..queue())
state.debuffs={{'Sunder Armor',100,5}}
assert(queue()=='Shield Slam, Revenge, Heroic Strike, Sunder Armor','Five Sunders: Heroic Strike at 45+ rage: '..queue())
state.rage=20
assert(queue()=='Shield Slam, Revenge, Sunder Armor, Sunder Armor','Heroic Strike only at 45 rage: '..queue())
state.stance=nil;GetNumShapeshiftForms=function()return nil end
assert(first()~='Defensive Stance','Unreadable stance never triggers stance advice')
GetNumShapeshiftForms=function()return 3 end
reset('WARRIOR',3,'tank',{'Defensive Stance','Revenge','Sunder Armor','Heroic Strike','Battle Shout','Thunder Clap'});state.stance='Defensive Stance';state.buffs={{'Battle Shout'}}
assert(first()=='Revenge','Lv20 Warrior without Shield Slam: '..queue())

-- Bear (Primal Bite replaces Mangle in Forever).
local bear60={'Faerie Fire (Feral)','Demoralizing Roar','Primal Bite','Lacerate','Maul','Swipe'}
reset('DRUID',2,'tank',bear60);state.rage=30
assert(queue()=='Faerie Fire (Feral), Demoralizing Roar, Primal Bite, Lacerate','Lv60 Bear: '..queue())
state.debuffs={{'Faerie Fire (Feral)'},{'Demoralizing Roar'},{'Lacerate',100,5}};state.cd={['Primal Bite']=true}
assert(first()=='Maul','Five fresh Lacerates: Maul at 25 rage: '..queue())
state.debuffs={{'Faerie Fire (Feral)'},{'Demoralizing Roar'},{'Lacerate',13,5}}
assert(first()=='Lacerate','Lacerate refreshed at 4.5 s or less: '..queue())
state.debuffs={{'Faerie Fire (Feral)'},{'Demoralizing Roar'},{'Lacerate',100,2}}
assert(first()=='Lacerate','Lacerate stacked to five')
reset('DRUID',2,'tank',{'Faerie Fire (Feral)','Demoralizing Roar','Maul','Swipe'});state.rage=30
state.debuffs={{'Faerie Fire (Feral)'},{'Demoralizing Roar'}}
assert(first()=='Maul','Lv20 Bear: Maul without Primal Bite or Lacerate: '..queue())
for _,n in ipairs({'Mangle (Bear)','Swipe (Bear)','Shield of Righteousness','Devastate'}) do assert(not ids[n],n..' is not a Forever spell and must not be asked for') end
print('PASS: tank priorities (Paladin, Warrior, Bear) by level, buff/seal/stance upkeep, stacks, rage, hidden state.')
