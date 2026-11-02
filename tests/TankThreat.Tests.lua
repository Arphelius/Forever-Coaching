-- Tank threat states and advice: secure, warning, another tank, lost close (no taunt), lost far (taunt),
-- and hidden threat (no advice).
local FC=ForeverCoaching
local state
local function reset()
    state={combat=true,class='WARRIOR',known={Taunt=true},roles={player='TANK',party1='DAMAGER',party2='TANK'},
        threat={player={true,3,100},party1={false,1,40},party2={false,0,20}},targettarget='party1'}
end
local names={player='Tank',party1='Mage',party2='Offtank',target='Ogre'}
UnitGroupRolesAssigned=function(unit)if unit=='targettarget' then unit=state.targettarget end;return state.roles[unit] or 'NONE' end
UnitAffectingCombat=function()return state.combat end
UnitHealth=function()return 100 end;UnitHealthMax=function()return 100 end
UnitPower=function()return 100 end;UnitPowerMax=function()return 100 end
UnitGUID=function(unit)if unit=='player' or unit=='party1' or unit=='party2' then return 'guid-'..unit end end
UnitCanAttack=function(_,unit)return unit=='target' end
UnitCanAssist=function(_,unit)return unit=='targettarget' end
UnitName=function(unit)if unit=='targettarget' then unit=state.targettarget end;return names[unit] end
UnitClass=function()return state.class,state.class end
UnitIsDeadOrGhost=function()return false end
UnitDetailedThreatSituation=function(unit)
    if state.hidden then error('restricted') end
    local t=state.threat[unit];if t then return t[1],t[2],t[3] end
end
GetInstanceInfo=function()return 'Test','party',1,'Normal',5,0,false,1 end
local ids={}
C_Spell={GetSpellInfo=function(name)ids[name]=ids[name] or (#ids+900);return {spellID=ids[name],name=name}end}
IsPlayerSpell=function(id)for n,v in pairs(ids)do if v==id then return state.known[n]==true end end;return false end
IsSpellKnown=IsPlayerSpell
C_UnitAuras={GetAuraDataByIndex=function()end}
FC.EncounterCoach={currentOffers={}}
FC.FightRecorder={Record=function()end}
FC.LiveRotation={ProfileRecommendation=function()return {spellName='Shield Slam'}end}
local W=FC.RoleWarnings
local function threat()W:Sample();for _,a in ipairs(W.alerts)do if a.kind=='threat' then return a.message end end end

reset()
assert(threat()==nil and W.threat.state=='secure','Holding the mob with a clear lead: no advice')
state.threat.party1={false,2,85}
local m=threat();assert(W.threat.state=='warning' and m=='Threat slipping — Shield Slam' and W.threatAction.color=='yellow' and W.threatAction.spell=='Shield Slam','Warning: calm line and a yellow border on the quick threat spell: '..tostring(m))
reset();state.threat.player={false,1,40};state.threat.party2={true,3,100};state.targettarget='party2'
assert(threat()==nil and W.threat.state=='other-tank','Another tank holding it is information only (the bar shows it)')
reset();state.threat.player={false,1,85};state.threat.party1={true,3,100}
m=threat();assert(W.threat.state=='lost-close' and m:find('Lost aggro on',1,true) and W.threatAction.spell=='Shield Slam' and W.threatAction.color=='red','Close loss: red border on the threat spell, no taunt: '..tostring(m))
state.threat.player={false,1,30}
m=threat();assert(W.threat.state=='lost-far' and m:find('— Taunt',1,true) and W.threatAction.spell=='Taunt' and W.threatAction.color=='red' and not m:find('%u%u%u'),'Far loss: red border on the taunt, no capitals: '..tostring(m))
state.class='PALADIN';state.known={}
m=threat();assert(m:find('Shield Slam',1,true) and not m:find('Taunt',1,true) and not m:find('Hand of Reckoning',1,true),'No known taunt: never name one: '..tostring(m))
reset()
local back;W:Sample();for _,a in ipairs(W.alerts)do if a.message=='Aggro back' then back=true end end
assert(back and W.threatAction==nil,'Taking the mob back after a loss says so once, and clears the border')
reset();state.hidden=true
assert(threat()==nil and W.threat.state=='unknown','Hidden threat: no advice')
reset();state.combat=false
assert(threat()==nil and W.threat==nil,'Out of combat: nothing')
reset();state.roles.player='DAMAGER';state.threat.player={false,3,110}
assert(threat():find('High threat',1,true),'Damage dealers keep the high-threat warning, without capitals')
print('PASS: tank threat states (secure, warning, other tank, close and far loss, hidden) and taunt only when far.')
