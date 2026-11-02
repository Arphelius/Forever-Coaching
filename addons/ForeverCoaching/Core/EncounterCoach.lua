ForeverCoaching = ForeverCoaching or {}
local FC = ForeverCoaching
local Coach = {opportunities={},history={},lessons={},elapsed=0}
FC.EncounterCoach = Coach
local function read(fn,...)
 if not fn then return nil end
 local ok,a,b,c,d,e,f,g,h,i=pcall(fn,...)
 if not ok then return nil end
 for _,v in pairs({a,b,c,d,e,f,g,h,i}) do if issecretvalue and issecretvalue(v) then return nil end end
 return a,b,c,d,e,f,g,h,i
end
local function now() return GetTime and GetTime() or 0 end
local function known(id)
 return read(IsPlayerSpell,id)==true or read(IsSpellKnown,id)==true or (C_SpellBook and read(C_SpellBook.IsSpellKnown,id))==true
end
local function info(id)
 local data=C_Spell and read(C_Spell.GetSpellInfo,id)
 if data then return data.name,data.iconID end
 local name,_,icon=read(GetSpellInfo,id);return name,icon
end
local function ready(id,unit)
 local usable,noMana
 if C_Spell and C_Spell.IsSpellUsable then usable,noMana=read(C_Spell.IsSpellUsable,id) else usable,noMana=read(IsUsableSpell,id) end
 if usable~=true or noMana==true then return false end
 local cd=C_Spell and read(C_Spell.GetSpellCooldown,id)
 local start,duration,enabled
 if cd then start,duration,enabled=cd.startTime,cd.duration,cd.isEnabled else start,duration,enabled=read(GetSpellCooldown,id) end
 if type(start)~="number" or type(duration)~="number" or enabled==false or enabled==0 then return false end
 if start>0 and duration>1.5 and start+duration>now() then return false end
 if unit then
  local range
  if C_Spell and C_Spell.IsSpellInRange then range=read(C_Spell.IsSpellInRange,id,unit) else range=read(IsSpellInRange,info(id),unit) end
  if range~=true and range~=1 then return false end
 end
 return true
end
function Coach:RefreshLessons()
 local _,class=read(UnitClass,"player")
 local lessons,seen={},{}
 for _,entry in ipairs(FC.AbilityLessons and FC.AbilityLessons[class] or {}) do
  local id
  for i=#entry.ids,1,-1 do if known(entry.ids[i]) then id=entry.ids[i];break end end
  if id then
   local name,icon=info(id)
   local lesson={spellID=id,name=name or entry.name,canonicalName=entry.name,icon=icon,kind=entry.kind,types=entry.types,why=entry.why,when=entry.when,how=entry.how,curated=true,sourceUrl=entry.sourceUrl,sourceBuild=entry.sourceBuild}
   lesson.description=C_Spell and read(C_Spell.GetSpellDescription,id) or nil
   lessons[#lessons+1]=lesson;seen[id]=true
  end
 end
 -- Include the complete exposed learned spellbook. Uncurated spells keep the
 -- actual client description; no fabricated timing or build explanation.
 local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
 local count=C_SpellBook and read(C_SpellBook.GetNumSpellBookSkillLines)
 if type(count)=="number" and bank then
  for line=1,count do
   local data=read(C_SpellBook.GetSpellBookSkillLineInfo,line)
   if data and type(data.itemIndexOffset)=="number" and type(data.numSpellBookItems)=="number" then
    for slot=data.itemIndexOffset+1,data.itemIndexOffset+data.numSpellBookItems do
     local item=read(C_SpellBook.GetSpellBookItemInfo,slot,bank)
     local id=item and item.spellID
     if type(id)=="number" and not seen[id] and known(id) then
      local name,icon=info(id)
      lessons[#lessons+1]={spellID=id,name=name or tostring(id),icon=icon,kind="spellbook",description=C_Spell and read(C_Spell.GetSpellDescription,id),why="Learned in your current spellbook. Build-specific interaction has not been curated.",when="Read the client description and check the encounter's requirements.",how="Practice on a suitable target outside dangerous mechanics."};seen[id]=true
     end
    end
   end
  end
 end
 self.lessons=lessons;return lessons
end
function Coach:GetBuildContext()
 local guid=read(UnitGUID,"player")
 local _,class=read(UnitClass,"player")
 local id=guid and ForeverCoachingDB and ForeverCoachingDB.activeTalentBuilds and ForeverCoachingDB.activeTalentBuilds[guid]
 local build
 if FC.BuildPlanner and class then for _,candidate in ipairs(FC.BuildPlanner:GetBuilds(class)) do if candidate.id==id then build=candidate;break end end end
 local context={id=id,title=build and build.title or "No build selected",role=build and build.role or "unknown",class=class,source=build and build.source,selected=true,talentMatch="Actual allocation unavailable"}
 if FC.RotationCoach and FC.RotationCoach.GetActiveTalentSnapshot then
  local ok,talents=pcall(FC.RotationCoach.GetActiveTalentSnapshot,FC.RotationCoach)
  if ok and talents then
   context.activeTalents={};local actual={}
   for spellID,talent in pairs(talents) do
    context.activeTalents[spellID]={spellID=talent.spellID,name=talent.name,rank=talent.rank}
    if talent.name and type(talent.rank)=="number" and talent.rank>0 then actual[talent.name]=talent.rank end
   end
   if build then
    local expected={};local matches=true
    for _,talent in ipairs(build.talents or {}) do if (talent.rank or 0)>0 then expected[talent.name]=talent.rank end end
    for name,rank in pairs(expected) do if actual[name]~=rank then matches=false end end
    for name,rank in pairs(actual) do if expected[name]~=rank then matches=false end end
    context.talentMatch=matches and "Matches selected allocation" or "Differs from selected allocation (including incomplete leveling plans)"
   end
  end
 end
 return context
end
function Coach:Begin()
 self:RefreshLessons();self.opportunities={};self.history={};self.casts={};self.movement={};self.truncated=false;self.current=nil;self.currentOffers={};self.started=now();self.active=true;self.wasMoving=nil
 self.build=self:GetBuildContext()
end
function Coach:Offer(key,kind,unit,lesson,reason,expires,detail)
 local opportunity=self.opportunities[key]
 if opportunity and opportunity.status=='responded' and kind~='interrupt' and opportunity.respondedAt and now()-opportunity.respondedAt>=2 then self.opportunities[key]=nil;opportunity=nil end
 if not opportunity then
  opportunity={key=key,kind=kind,unit=unit,spellID=lesson and lesson.spellID,name=lesson and lesson.name,
   reason=reason,at=now(),expires=expires or now()+2,status="observed",detail=detail,targetGUID=read(UnitGUID,unit)}
  self.opportunities[key]=opportunity
  if FC.FightRecorder then FC.FightRecorder:Record('opportunity',{message=reason,spellID=opportunity.spellID,spellName=opportunity.name,targetGUID=opportunity.targetGUID,opportunityKind=kind}) end
  if #self.history<3000 then self.history[#self.history+1]=opportunity else self.truncated=true end
 end
 opportunity.expires=expires or now()+2
 return opportunity
end
function Coach:Sample()
 local offers={}
 local speed=read(GetUnitSpeed,"player")
 local moving=type(speed)=="number" and speed>0 or nil
 if type(speed)=="number" and moving~=self.wasMoving then
  if #self.movement<1000 then self.movement[#self.movement+1]={at=now(),moving=speed>0,speed=speed} end
  self.wasMoving=moving
 end
 local function offer(...) local o=self:Offer(...);if o.status=='observed' then offers[#offers+1]=o end end
 local mana,maxMana=read(UnitPower,"player",0),read(UnitPowerMax,"player",0)
 if type(mana)=="number" and type(maxMana)=="number" and maxMana>0 and mana/maxMana<.2 then
  offer("mana","resource recovery","player",nil,"Mana is below 20%. Use efficient actions; recover between pulls when safe. This threshold is coaching policy.",nil,{mana=mana,maxMana=maxMana})
 end
 local enemies={'target','focus','boss1','boss2','boss3','boss4','boss5'};for i=1,40 do enemies[#enemies+1]='nameplate'..i end
 local enemySeen={}
 for _,unit in ipairs(enemies)do
  local guid=read(UnitGUID,unit)
  if guid and not enemySeen[guid] and read(UnitCanAttack,'player',unit)==true then
   enemySeen[guid]=true
   local cast,_,_,startTime,endTime,_,castID,notInterruptible,enemySpell=read(UnitCastingInfo,unit)
   if not cast then local name,_,_,start,ending,_,blocked,id=read(UnitChannelInfo,unit);cast,startTime,endTime,notInterruptible,enemySpell=name,start,ending,blocked,id end
   if cast and notInterruptible==false and type(endTime)=='number' and endTime/1000>now() then
    for _,lesson in ipairs(self.lessons)do if lesson.kind=='interrupt' and ready(lesson.spellID,unit)then
     offer('interrupt:'..guid..':'..tostring(startTime),'interrupt',unit,lesson,(read(UnitName,unit) or unit)..' is casting '..cast..'. Use '..lesson.name..' if assigned; check teammates before duplicating a kick.',endTime/1000,{enemySpellID=enemySpell,castID=castID});break
    end end
   end
  end
 end
 local units={"player","party1","party2","party3","party4"}
 for i=1,40 do if read(UnitExists,"raid"..i)==true then units[#units+1]="raid"..i end end
 local seen={}
 for _,unit in ipairs(units) do
  local guid=read(UnitGUID,unit)
  if guid and not seen[guid] and read(UnitIsDeadOrGhost,unit)==false and read(UnitCanAssist,"player",unit)==true then
   seen[guid]=true
   local health,maxHealth=read(UnitHealth,unit),read(UnitHealthMax,unit)
   if type(health)=="number" and type(maxHealth)=="number" and maxHealth>0 and health/maxHealth<.35 then
    for _,lesson in ipairs(self.lessons) do if lesson.kind=="heal" and ready(lesson.spellID,unit) then
     offer("heal:"..guid,"healing",unit,lesson,(read(UnitName,unit) or unit).." is below 35% health. Consider a safe heal if this is your responsibility.",nil,{health=health,maxHealth=maxHealth});break
    end end
   end
   if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    for index=1,40 do
     local aura=read(C_UnitAuras.GetAuraDataByIndex,unit,index,"HARMFUL")
     if not aura then break end
     local dtype=aura.dispelName
     if type(dtype)=="string" then for _,lesson in ipairs(self.lessons) do
      if lesson.kind=="dispel" and lesson.types[dtype] and ready(lesson.spellID,unit) then
       offer("dispel:"..guid..":"..tostring(aura.auraInstanceID or aura.spellId),"dispel",unit,lesson,(read(UnitName,unit) or unit)..": "..(aura.name or dtype).." can be removed by your learned ability. Check the mechanic before dispelling.",nil,{auraSpellID=aura.spellId,dispelType=dtype});break
      end
     end end
    end
   end
  end
 end
 local priority={interrupt=1,healing=2,dispel=3,["resource recovery"]=4}
 table.sort(offers,function(a,b) return (priority[a.kind] or 9)<(priority[b.kind] or 9) end)
 self.current=offers[1]
 self.currentOffers=offers
 -- End old opportunities without labeling them mistakes: a target can become
 -- unreachable, a teammate may act, or the underlying mechanic may change.
 for key,o in pairs(self.opportunities) do if o.expires<now() then self.opportunities[key]=nil end end
 return self.current
end
function Coach:GetRecommendation()
 local o=self.current
 if not o or o.expires<now() or o.status=="responded" then return nil end
 return {message=o.name or "Conserve mana",spellName=o.name,spellID=o.spellID,reason=o.reason,shortReason=o.reason,situation=o.kind,
  targetGUID=o.targetGUID,targetHostile=read(UnitCanAttack,"player",o.unit)==true,encounterPrompt=true,
  pressRequired=o.spellID~=nil and read(UnitGUID,"target")==o.targetGUID,at=now(),unit=o.unit}
end
function Coach:RecordCast(spellID,targetGUID)
 if not self.active then return end
 if type(spellID)~="number" then return end
 if #self.casts<5000 then self.casts[#self.casts+1]={at=now(),spellID=spellID,targetGUID=targetGUID,mana=read(UnitPower,"player",0),speed=read(GetUnitSpeed,"player")} end
 for _,o in pairs(self.opportunities) do
  if o.spellID==spellID and o.expires>=now() and o.status=="observed" and targetGUID and o.targetGUID==targetGUID then
   o.status="responded";o.respondedAt=now();o.responseSpellID=spellID
   if FC.FightRecorder then FC.FightRecorder:Record('targeted_response',{unit='player',spellID=spellID,spellName=o.name,targetGUID=targetGUID,message='Matching cast on the observed target; effect outcome not established.'}) end
  end
 end
end
function Coach:Finish()
 if not self.active then return nil end
 self.active=false
 self.current=nil
 self.currentOffers={}
 local result={build=self.build,opportunities=self.history,casts=self.casts,movement=self.movement,started=self.started,ended=now(),truncated=self.truncated}
 self.last=result
 ForeverCoachingDB=ForeverCoachingDB or {};ForeverCoachingDB.encounterPractice=ForeverCoachingDB.encounterPractice or {}
 local progress=ForeverCoachingDB.encounterPractice
 for _,o in ipairs(self.history) do
  local key=(self.build.id or self.build.class or "unknown")..":"..o.kind
  progress[key]=progress[key] or {observed=0,responded=0}
  progress[key].observed=progress[key].observed+1
  if o.status=="responded" then progress[key].responded=progress[key].responded+1 end
 end
 return result
end
function Coach:Summarize(result)
 local good,investigate,nextSteps={},{},{}
 for _,o in ipairs(result.opportunities or {}) do
  local at=string.format("%.1fs",o.at-result.started)
  if o.status=="responded" then good[#good+1]=at..": "..o.name.." cast on the observed target after "..o.kind.." prompt. Response time: "..string.format("%.1fs",o.respondedAt-o.at)..". Effect success is not established by a cast event."
  else investigate[#investigate+1]=at..": "..o.reason.." No matching response on the observed target was confirmed; assignment, teammate actions and mechanic safety still need checking." end
 end
 if #investigate>0 then nextSteps[1]="Choose one unconfirmed response above. Check assignment and mechanic safety, then rehearse the appropriate action before the next pull." end
 if #(result.movement or {})>0 then
  nextSteps[#nextSteps+1]="Movement transitions were recorded alongside casts. Compare their timestamps with mechanics before judging interrupted or delayed casts; movement can be the correct response."
 end
 if result.truncated then nextSteps[#nextSteps+1]="The observation storage limit was reached; this fight is partial." end
 return table.concat(good,"\n\n"),table.concat(investigate,"\n\n"),table.concat(nextSteps,"\n")
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","SPELLS_CHANGED","PLAYER_ENTERING_WORLD","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_SENT"}) do events:RegisterEvent(event) end
local sentTargets={}
events:SetScript("OnEvent",function(_,event,unit,castGUID,spellID,...)
 if event=="PLAYER_REGEN_DISABLED" then sentTargets={};Coach:Begin()
 elseif event=="PLAYER_REGEN_ENABLED" then Coach:Finish()
 elseif event=="SPELLS_CHANGED" or event=="PLAYER_ENTERING_WORLD" then Coach:RefreshLessons()
 elseif event=="UNIT_SPELLCAST_SENT" and not (issecretvalue and issecretvalue(unit)) and unit=="player" then
  -- SENT signature is unit, targetName, castGUID, spellID. Match the name to
  -- visible group/target identities, rather than assuming the current target.
  local targetName=castGUID;local actualCastGUID=spellID;local actualSpellID=...
  if not (issecretvalue and (issecretvalue(targetName) or issecretvalue(actualCastGUID) or issecretvalue(actualSpellID))) then
   local candidates={"target","player","party1","party2","party3","party4"};for i=1,40 do candidates[#candidates+1]="raid"..i end
   local found,ambiguous
   for _,candidate in ipairs(candidates) do if read(UnitName,candidate)==targetName then local guid=read(UnitGUID,candidate);if found and found~=guid then ambiguous=true end;found=guid end end
   if actualCastGUID and found and not ambiguous then sentTargets[actualCastGUID]=found end
  end
 elseif event=="UNIT_SPELLCAST_SUCCEEDED" and not (issecretvalue and (issecretvalue(unit) or issecretvalue(castGUID) or issecretvalue(spellID))) and unit=="player" then
  Coach:RecordCast(spellID,sentTargets[castGUID]);if castGUID then sentTargets[castGUID]=nil end
 end
end)
events:SetScript("OnUpdate",function(_,elapsed)
 Coach.elapsed=Coach.elapsed+elapsed;if Coach.elapsed<.25 then return end;Coach.elapsed=0
 if Coach.active then
  local ok,err=pcall(Coach.Sample,Coach)
  if not ok then Coach.current=nil;Coach.lastError=tostring(err) end
 else
  local mana,maxMana=read(UnitPower,"player",0),read(UnitPowerMax,"player",0)
  if type(mana)=="number" and type(maxMana)=="number" and maxMana>0 and mana/maxMana<.2 then
   Coach.current={kind="resource recovery",unit="player",targetGUID=read(UnitGUID,"player"),reason="Mana below 20% before the next pull. Drink when safe and give the group time to prepare.",expires=now()+1,status="observed"}
  else Coach.current=nil end
 end
end)
