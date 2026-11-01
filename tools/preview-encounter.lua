-- Browser replay adapter for the actual in-game observer. All inputs here are
-- synthetic; no API key, game client, report or personal character is involved.
local FC=ForeverCoaching
local clock=0
local names={player="Preview",target="Simulated caster",party1="Simulated ally"}
local guids={player="demo-player",target="demo-enemy",party1="demo-ally"}
UnitClass=function() return PreviewClass,PreviewClass end
UnitName=function(unit) return names[unit] end
UnitGUID=function(unit) return guids[unit] end
UnitExists=function(unit) return guids[unit]~=nil end
UnitCanAssist=function(_,unit) return unit=="player" or unit=="party1" end
UnitCanAttack=function(_,unit) return unit=="target" end
UnitIsDeadOrGhost=function() return false end
UnitLevel=function() return PreviewLevel end
GetTime=function() return clock end
GetUnitSpeed=function() return clock<1 and 7 or 0 end
UnitPower=function() return 15 end
UnitPowerMax=function() return 100 end
UnitHealth=function(unit) return unit=="party1" and 25 or 100 end
UnitHealthMax=function() return 100 end
issecretvalue=function() return false end
local knownSpells,spellNames={},{}
local dispelType
for _,lesson in ipairs(FC.AbilityLessons[PreviewClass] or {}) do
 knownSpells[lesson.ids[1]]=true;spellNames[lesson.ids[1]]=lesson.name
 if lesson.types and not dispelType then for dtype in pairs(lesson.types) do dispelType=dtype;break end end
end
IsPlayerSpell=function(id) return knownSpells[id]==true end
C_Spell={
 GetSpellInfo=function(id) return {name=spellNames[id] or ("Simulated spell "..id),iconID=0} end,
 IsSpellUsable=function() return true,false end,
 GetSpellCooldown=function() if PreviewDemoCase~="hidden" then return {startTime=0,duration=0,isEnabled=true} end end,
 IsSpellInRange=function() return true end,
}
UnitCastingInfo=function() return "Simulated dangerous cast",nil,nil,0,3000,nil,"demo-cast",false,999 end
C_UnitAuras={GetAuraDataByIndex=function(unit,index)
 if unit=="party1" and index==1 and dispelType then return {name="Simulated "..dispelType,spellId=777,auraInstanceID=1,dispelName=dispelType} end
end}
local build=FC.BuildPlanner:GetBuilds(PreviewClass)[PreviewBuild]
ForeverCoachingDB.activeTalentBuilds={['demo-player']=build and build.id}
local coach=FC.EncounterCoach
FC.FightRecorder:Begin()
coach:Begin();coach:Sample()
local prompt=coach:GetRecommendation()
clock=1
if PreviewDemoCase=="responded" or PreviewDemoCase=="wrong-target" then
 for _,opportunity in ipairs(coach.history) do
  if opportunity.spellID then coach:RecordCast(opportunity.spellID,PreviewDemoCase=="responded" and opportunity.targetGUID or "demo-unrelated-target") end
  if opportunity.spellID then FC.FightRecorder:Record('cast_succeeded',{unit='player',unitName='Preview',spellID=opportunity.spellID,spellName=opportunity.name,targetName='Simulated target'}) end
 end
end
clock=4;coach:Sample()
FC.FightRecorder:Sample()
clock=5
local result=coach:Finish()
local recording=FC.FightRecorder:Finish()
local good,investigate,improve=coach:Summarize(result)
local timeline={}
for _,o in ipairs(result.opportunities) do
 timeline[#timeline+1]={kind=o.kind,time=o.at,spellID=o.spellID,name=o.name or "Resource management",reason=o.reason,target=o.targetGUID,status=o.status,responseTime=o.respondedAt and o.respondedAt-o.at or nil}
end
FC.PreviewCoachingReplay={simulated=true,recording=recording,case=PreviewDemoCase,build=result.build,prompt=prompt,timeline=timeline,
 goodText=good~="" and good or "No matching targeted responses confirmed in this simulated run.",
 wrongText=investigate~="" and investigate or "No unresolved prompts in this simulated run.",
 improveText=improve~="" and improve or "Repeat with another response pattern to inspect the observer's behavior.",
 metrics="SIMULATED / actual Lua observer / "..PreviewClass.." / 5 seconds",movement=result.movement,
 coverage="Synthetic toolkit with curated base abilities enabled regardless of preview level. Tests observer behavior, not spell acquisition, encounter correctness or your performance."}
