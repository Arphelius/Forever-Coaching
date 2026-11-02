local FC=ForeverCoaching
local coach=FC.EncounterCoach
UnitGroupRolesAssigned=function()return 'HEALER'end
local guid={player='self',target='enemy',party1='ally'}
local names={player='Self',target='Enemy',party1='Ally'}
UnitGUID=function(unit) return guid[unit] end
UnitName=function(unit) return names[unit] end
UnitCanAssist=function(_,unit) return unit=='player' or unit=='party1' end
UnitCanAttack=function(_,unit) return unit=='target' end
UnitIsDeadOrGhost=function() return false end
UnitExists=function(unit) return guid[unit]~=nil end
UnitPower=function() return 100 end
UnitPowerMax=function() return 100 end
UnitHealth=function(unit) return unit=='party1' and 20 or 100 end
UnitHealthMax=function() return 100 end
IsPlayerSpell=function(id) return id==8042 or id==331 or id==526 end
GetTime=function() return TestNow end
TestNow=10
C_Spell={GetSpellInfo=function(id) return {name='Spell '..id} end,
 IsSpellUsable=function() return true,false end,
 GetSpellCooldown=function() return {startTime=0,duration=0,isEnabled=true} end,
 IsSpellInRange=function() return true end}
UnitCastingInfo=function() return 'Danger',nil,nil,10000,13000,nil,'cast-enemy',false,999 end
C_UnitAuras={GetAuraDataByIndex=function(unit,index) if unit=='party1' and index==1 then return {name='Poison',spellId=777,auraInstanceID=8,dispelName='Poison'} end end}
coach:Begin();coach:Sample()
assert(coach.current.kind=='interrupt')
local interrupt=coach.current
assert(interrupt.spellID==8042 and interrupt.targetGUID=='enemy')
coach:RecordCast(8042,'ally');assert(interrupt.status=='observed','Wrong targets cannot satisfy an opportunity')
TestNow=11;coach:RecordCast(8042,'enemy');assert(interrupt.status=='responded')
assert(coach:GetRecommendation()==nil,'Do not repeat a fulfilled prompt')
local healing
for _,o in ipairs(coach.history) do if o.kind=='healing' then healing=o end end
assert(healing and healing.targetGUID=='ally')
local eventFrame=TestFrames[#TestFrames]
-- Find the module's frame rather than depending on load order.
for _,frame in ipairs(TestFrames) do if frame.events.SPELLS_CHANGED and frame.scripts.OnUpdate then eventFrame=frame end end
eventFrame.scripts.OnEvent(eventFrame,'UNIT_SPELLCAST_SENT','player','Ally','cast-own',331)
eventFrame.scripts.OnEvent(eventFrame,'UNIT_SPELLCAST_SUCCEEDED','player','cast-own',331)
assert(healing.status=='responded','SENT target identity must match the successful cast')
TestNow=14
local result=coach:Finish()
assert(result.build.class=='SHAMAN')
local good,investigate=coach:Summarize(result)
assert(good:find('Response time',1,true))
assert(investigate:find('Poison',1,true))
assert(ForeverCoachingDB.encounterPractice['SHAMAN:interrupt'].responded==1)
-- Unknown cooldown/range must suppress actionable prompts.
coach:Begin();C_Spell.GetSpellCooldown=function() return nil end;coach:Sample()
assert(not coach.current,'Hidden readiness cannot become a ready recommendation')
coach:Finish()
print('PASS: actual learned abilities, ready interrupt, healing and poison opportunities, targeted responses, practice persistence and hidden-state suppression.')
local previousCasting=UnitCastingInfo
UnitCastingInfo=function()return nil end
UnitChannelInfo=function(unit)if unit=='focus'then return 'Channel',nil,nil,14000,18000,nil,false,1001 end end
guid.focus='focus-enemy';names.focus='Focus Enemy'
UnitCanAttack=function(_,unit)return unit=='target' or unit=='focus'end
C_Spell.GetSpellCooldown=function()return {startTime=0,duration=0,isEnabled=true}end
TestNow=15;coach:Begin();coach:Sample()
assert(coach.current.kind=='interrupt' and coach.current.unit=='focus' and coach.current.targetGUID=='focus-enemy','A visible focus channel can produce a targeted interrupt prompt')
coach:Finish();guid.focus=nil;names.focus=nil;UnitCastingInfo=previousCasting;UnitChannelInfo=nil
UnitCanAttack=function(_,unit)return unit=='target'end
print('PASS: focus channel interrupts with correct target identity.')
