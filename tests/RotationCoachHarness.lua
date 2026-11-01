-- Controllable low-level Shaman state. No website or client process required.
RotationState = {}
local spellData = {
    [403]={name='Lightning Bolt',castTime=1500,cost=15,damage=18},
    [8042]={name='Earth Shock',castTime=0,cost=20,damage=25},
    [408498]={name='Maelstrom Weapon',castTime=0,cost=0,damage=0},
    [6603]={name='Attack',castTime=0,cost=0,damage=0},
}
function ResetRotationState()
    RotationState={mana=100,maxMana=100,speed=0,known={[403]=true},inRange=true,combat=false,rank=0,stacks=0}
    ActionButton1=nil
    for _,frame in ipairs(TestFrames) do
        if frame.events.PLAYER_ENTERING_WORLD and frame.scripts.OnEvent then frame.scripts.OnEvent(frame,'PLAYER_ENTERING_WORLD') end
    end
end
ResetRotationState()
local secretMana={}
issecretvalue=function(value) return value==secretMana end
IsPlayerSpell=function(id) return RotationState.known[id] or (id==408498 and RotationState.rank>0) or false end
UnitExists=function(unit) return unit=='player' or unit=='target' end
UnitCanAttack=function() return true end
UnitIsDead=function() return false end
UnitHealth=function() return 1000 end
UnitPower=function() return RotationState.hiddenMana and secretMana or RotationState.mana end
UnitPowerMax=function() return RotationState.hiddenMana and secretMana or RotationState.maxMana end
UnitAffectingCombat=function() return RotationState.combat end
UnitCastingInfo=function() return nil end
UnitChannelInfo=function() return nil end
GetUnitSpeed=function() return RotationState.speed end
IsCurrentSpell=function() return RotationState.attacking end
IsAttackAction=function(slot) return slot==1 end
IsActionInRange=function() return RotationState.meleeRange end
GetActionInfo=function() return 'spell',6603 end
function InstallAttackButton()
    ActionButton1=CreateFrame('Button',nil,UIParent)
    ActionButton1.action=1
end
C_Spell={
    GetSpellInfo=function(id)
        local data=spellData[id]
        if data then return {name=data.name,iconID=id,castTime=data.castTime} end
    end,
    GetSpellDescription=function(id)
        return 'Deals '..(spellData[id].damage)..' Nature damage.'
    end,
    GetSpellPowerCost=function(id)
        local cost=RotationState.costs and RotationState.costs[id] or spellData[id].cost
        return {{type=0,cost=cost}}
    end,
    IsSpellUsable=function(id)
        local cost=RotationState.costs and RotationState.costs[id] or spellData[id].cost
        local enough=RotationState.mana>=cost
        return enough,not enough
    end,
    GetSpellCooldown=function() return {startTime=0,duration=0,isEnabled=true} end,
    IsSpellInRange=function() return RotationState.inRange end,
}
C_UnitAuras={
    GetUnitAuraBySpellID=function() return nil end,
    GetPlayerAuraBySpellID=function(id)
        if id==408505 and RotationState.stacks>0 then return {applications=RotationState.stacks} end
    end,
}
C_ClassTalents={GetActiveConfigID=function() return 1 end}
C_Traits={
    GetConfigInfo=function() return {treeIDs={1}} end,
    GetTreeNodes=function() return {1} end,
    GetNodeInfo=function() return {currentRank=RotationState.rank,activeEntry={entryID=1},maxRanks=5} end,
    GetEntryInfo=function() return {definitionID=1} end,
    GetDefinitionInfo=function() return {spellID=408498,overrideName='Maelstrom Weapon'} end,
}
