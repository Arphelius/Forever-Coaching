local FC=ForeverCoaching
local state={role='TANK',combat=true,health=100,mana=100,healerMana=3,status=0,tanking=false,auras={},instance=7}
UnitGroupRolesAssigned=function(unit)return unit=='party1' and 'HEALER' or unit=='party2' and state.tankPresent and 'TANK' or unit=='player' and state.role or 'NONE'end
UnitAffectingCombat=function()return state.combat end
UnitHealth=function()return state.health end;UnitHealthMax=function()return 100 end
UnitPower=function(unit)return unit=='party1' and state.healerMana or state.mana end;UnitPowerMax=function()return 100 end
UnitGUID=function(unit)return unit=='party2' and state.tankPresent and 'tank' or ({player='self',target='enemy',party1='healer',targettarget='healer'})[unit]end
UnitCanAttack=function(_,unit)return unit=='target'end;UnitCanAssist=function(_,unit)return unit=='targettarget'end
UnitName=function(unit)return ({party1='Alice',target='Enemy',targettarget='Alice'})[unit]end
UnitIsDeadOrGhost=function()return false end
UnitDetailedThreatSituation=function()if state.hiddenThreat then error('restricted')end;return state.tanking,state.status end
GetInstanceInfo=function()return 'Test','party',1,'Normal',5,0,false,state.instance end
C_UnitAuras={GetAuraDataByIndex=function(unit,index)
 if state.hiddenAura then error('restricted')end
 if index==1 and state.auras[unit]then return {spellId=state.auras[unit]}end
end}
FC.EncounterCoach={currentOffers={}}
local recorded=0;FC.FightRecorder={Record=function(_,kind)assert(kind=='role_warning');recorded=recorded+1 end}
FC.RotationCoach={GetRecommendation=function()return {spellID=123}end}
local W=FC.RoleWarnings
local function has(kind)for _,a in ipairs(W.alerts)do if a.kind==kind then return a end end end
W:Sample();assert(has('threat') and has('mana'),'Tank gets threat and healer mana alerts')
local count=recorded;W:Sample();assert(recorded==count,'Persistent conditions do not flood the timeline')
state.healerMana=10;W:Sample();assert(not has('mana'),'Routine healer mana depletion stays quiet')
state.healerMana=3;state.combat=false;W:Sample();assert(not has('mana') and not has('threat'),'No preparation warnings outside combat')
state.role='DAMAGER';state.tankPresent=true;state.combat=true;state.status=2;state.health=25;W:Sample();assert(#W.alerts==0,'Elevated threat and moderate health loss are not emergencies')
state.status=3;state.health=15;W:Sample();assert(has('health') and has('threat') and not has('mana'),'DPS gets own critical health and actual aggro warnings with a registered tank')
state.tankPresent=false;W:Sample();assert(has('health') and not has('threat'),'A party without a tank still gets health advice, but no threat warning')
state.tankPresent=true
state.hiddenThreat=true;W:Sample();assert(not has('threat'),'Hidden threat is not a danger observation');state.hiddenThreat=nil
state.role='HEALER';state.status=0;state.health=100
FC.EncounterCoach.currentOffers={{key='heal',kind='healing',unit='party1',name='Fast heal',expires=12,status='observed'},
 {key='dispel',kind='dispel',unit='party1',reason='Alice: Poison can be removed.',expires=12,status='observed'},
 {key='kick',kind='interrupt',reason='Use your kick on Enemy.',expires=12,status='observed'}}
W:Sample();assert(#W.alerts==0,'Routine heal, dispel and interrupt opportunities do not produce warnings')
state.health=15;FC.EncounterCoach.currentOffers[2].emergency=true;FC.EncounterCoach.currentOffers[3].detail={emergency=true}
W:Sample();assert(has('healing').message:find('Alice',1,true) and has('dispel') and has('interrupt'),'Critical healing and explicitly dangerous interrupt/dispel opportunities warn')
for _,alert in ipairs(W.alerts)do assert(alert.emergency==true,'Every emitted warning carries emergency evidence')end
FC.EncounterCoach.currentOffers[1].status='responded';W:Sample();assert(not has('healing'),'Resolved prompts disappear')
state.health=100;FC.EncounterCoach.currentOffers={}
W:RegisterMechanic({id='test-ground',spellID=9001,trigger='playerAura',action='move',message='MOVE OUT — test ground effect.',source='test fixture only',instanceID=7})
W:RegisterMechanic({id='test-reflect',spellID=9002,trigger='targetAura',action='stop',message='STOP DPS — test reflect.',source='test fixture only',instanceID=7})
state.auras.player=9001;W:Sample();assert(W.alerts[1].kind=='move' and W:GetBlockingRecommendation().blocksRotation,'Observed known movement mechanic outranks throughput')
assert(FC.LiveRotation:GetRecommendation().blocksRotation,'Known mechanic suppresses normal rotation')
state.auras.player=nil;state.auras.target=9002;W:Sample();assert(has('stop') and W:GetBlockingRecommendation(),'Known target buff triggers stop DPS')
state.instance=8;W:Sample();assert(not has('stop'),'A rule cannot fire in another encounter instance')
state.instance=7;state.hiddenAura=true;W:Sample();assert(not has('stop'),'Hidden aura does not invent a mechanic');state.hiddenAura=nil
assert(not pcall(W.RegisterMechanic,W,{id='invented'}),'Mechanic rules require evidence and scope')
state.auras={};state.combat=false;W:Sample();assert(#W.alerts==0 and not W:GetBlockingRecommendation(),'Warnings clear when their triggers end')
print('PASS: role-specific alerts, healer mana, threat, urgency, deduplication, scoped mechanics, hidden data and rotation suppression.')
