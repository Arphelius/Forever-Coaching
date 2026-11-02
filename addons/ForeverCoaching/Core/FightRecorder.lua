ForeverCoaching=ForeverCoaching or {}
local FC=ForeverCoaching
local R={limit=12000,keep=5,elapsed=0};FC.FightRecorder=R
local function read(fn,...)
 if not fn then return nil end
 local ok,a,b,c,d,e,f,g,h,i=pcall(fn,...);if not ok then return nil end
 for _,value in pairs({a,b,c,d,e,f,g,h,i}) do if issecretvalue and issecretvalue(value) then return nil end end
 return a,b,c,d,e,f,g,h,i
end
local function clock()return GetTime and GetTime() or 0 end
local cachedIdentity
local function identity()
 local guid=read(UnitGUID,'player');local name=read(UnitName,'player')
 if guid then cachedIdentity=guid elseif name then cachedIdentity=name..'-'..(read(GetRealmName) or '') end
 return cachedIdentity or 'Unknown'
end
local function spell(id)
 local info=C_Spell and read(C_Spell.GetSpellInfo,id)
 if info then return read(function()return info.name end) end
 return read(GetSpellInfo,id)
end
local function saved()
 ForeverCoachingDB=ForeverCoachingDB or {};ForeverCoachingDB.fightTimelines=ForeverCoachingDB.fightTimelines or {};return ForeverCoachingDB.fightTimelines
end
function R:Record(kind,fields)
 local fight=self.active;if not fight then return end
 local actor=fields and (fields.unit=='player' and 'player' or fields.unitGUID)
 if actor and kind=='death' then if self.deaths[actor] then return end;self.deaths[actor]=true elseif actor and kind=='alive' then self.deaths[actor]=nil end
 if #fight.events>=self.limit then fight.truncated=true;return end
 local event={time=math.max(0,clock()-fight.started),kind=kind}
 for key,value in pairs(fields or {}) do
  if not (issecretvalue and issecretvalue(value)) and (type(value)=='string' or type(value)=='number' or type(value)=='boolean') then
   if type(value)~='number' or (value==value and value~=math.huge and value~=-math.huge) then event[key]=value end
  end
 end
 fight.events[#fight.events+1]=event
 if FC.ScenarioTracker then FC.ScenarioTracker:Record(kind,event) end
end
function R:Begin()
 if self.active then return end
 self.sequence=(self.sequence or 0)+1
 self.active={id=tostring(time and time() or 0)..'-'..self.sequence,character=identity(),player=read(UnitName,'player'),started=clock(),events={},missing={},coverage='Readable unit events and state changes. Raw combat-log access is not assumed. Health changes do not identify damage/healing sources. Restricted fields are omitted.'}
 self.states={};self.auras={};self.abilities={};self.targets={};self.sent={};self.deaths={};self.elapsed=0
 local before=self.before or {};self.before={}
 for _,event in ipairs(before)do if clock()-event.at<=8 then local fields={};for k,v in pairs(event.fields)do fields[k]=v end;fields.time=event.at-self.active.started;fields.recordedBeforeCombat=true;self:Record(event.kind,fields) end end
 if FC.EncounterCoach then
  local ok,build=pcall(FC.EncounterCoach.GetCombatContext or FC.EncounterCoach.GetBuildContext,FC.EncounterCoach)
  if ok and build then
   self.active.build=build;self.active.class=build.class;self.active.specTree=build.tree;self.active.specRole=build.role
   if FC.SpecScenarios then
    local readable,spec=pcall(FC.SpecScenarios.ForCurrent,FC.SpecScenarios,build,true)
    if readable and spec and spec.available then self.active.specTree=spec.treeIndex;self.active.specRole=spec.role end
   end
  end
 end
 if FC.ScenarioTracker then FC.ScenarioTracker:Begin();FC.ScenarioTracker:Sample() end
 self:Record('combat_start',{message='Combat recording started.'});self:Sample()
end
function R:Snapshot(unit)
 if not self.active then return end
 local guid=read(UnitGUID,unit);if not guid then self.active.missing.identity=true;return end
 local name=read(UnitName,unit) or unit
 local health,maxHealth=read(UnitHealth,unit),read(UnitHealthMax,unit)
 local powerType=read(UnitPowerType,unit);local power,maxPower
 if type(powerType)=='number' then power,maxPower=read(UnitPower,unit,powerType),read(UnitPowerMax,unit,powerType)
 elseif unit=='player' then powerType=0;power,maxPower=read(UnitPower,unit,0),read(UnitPowerMax,unit,0) end
 local dead=read(UnitIsDeadOrGhost,unit)
 local speed=unit=='player' and read(GetUnitSpeed,unit) or nil
 local previous=self.states[guid] or {}
 if type(health)=='number' and health~=previous.health then self:Record('health',{unit=unit,unitGUID=guid,unitName=name,health=health,maxHealth=maxHealth,change=previous.health and health-previous.health or nil}) elseif health==nil then self.active.missing.health=true end
 if type(power)=='number' and (power~=previous.power or powerType~=previous.powerType) then self:Record('resource',{unit=unit,unitGUID=guid,unitName=name,power=power,maxPower=maxPower,powerType=powerType}) elseif power==nil then self.active.missing.resources=true end
 if type(dead)=='boolean' and dead~=previous.dead then self:Record(dead and 'death' or 'alive',{unit=unit,unitGUID=guid,unitName=name}) end
 if type(speed)=='number' and (previous.speed==nil or (speed>0)~=(previous.speed>0)) then self:Record(speed>0 and 'movement_start' or 'movement_stop',{unit='player',unitGUID=guid,unitName=name,speed=speed}) elseif unit=='player' and speed==nil then self.active.missing.movement=true end
 self.states[guid]={health=health,power=power,powerType=powerType,dead=dead,speed=speed}
end
function R:Auras(unit)
 if not self.active then return end
 local guid=read(UnitGUID,unit);if not guid then return end
 if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then self.active.missing.auras=true;return end
 local observed={};local readable=true
 for _,filter in ipairs({'HELPFUL','HARMFUL'}) do
  for index=1,40 do
   local aura=read(C_UnitAuras.GetAuraDataByIndex,unit,index,filter);if not aura then break end
   local id=read(function()return aura.spellId end);local instance=read(function()return aura.auraInstanceID end)
   local name=read(function()return aura.name end);local stacks=read(function()return aura.applications end)
   if type(id)=='number' and type(name)=='string' then
    local key=filter..':'..tostring(instance or id);observed[key]={spellID=id,spellName=name,stacks=stacks,helpful=filter=='HELPFUL'}
   else readable=false;self.active.missing.auras=true end
  end
 end
 if not readable then return end
 local previous=self.auras[guid]
 for key,aura in pairs(observed) do if not previous or not previous[key] or previous[key].stacks~=aura.stacks then self:Record(previous and previous[key] and 'aura_stacks' or 'aura_present',{unit=unit,unitGUID=guid,unitName=read(UnitName,unit),spellID=aura.spellID,spellName=aura.spellName,stacks=aura.stacks,helpful=aura.helpful}) end end
 if previous then for key,aura in pairs(previous) do if not observed[key] then self:Record('aura_no_longer_visible',{unit=unit,unitGUID=guid,unitName=read(UnitName,unit),spellID=aura.spellID,spellName=aura.spellName}) end end end
 self.auras[guid]=observed
end
function R:Sample()
 if not self.active then return end
 local units={'player','target','focus','pet','party1','party2','party3','party4'}
 for i=1,40 do if read(UnitExists,'raid'..i)==true then units[#units+1]='raid'..i end end
 local seen={}
 for _,unit in ipairs(units) do local guid=read(UnitGUID,unit);if guid and not seen[guid] then seen[guid]=true;self:Snapshot(unit);if not self.auras[guid] then local ok=pcall(self.Auras,self,unit);if not ok then self.active.missing.auras=true end end end end
 local target=read(UnitGUID,'target')
 if target~=self.target then self:Record('target_changed',{unit='player',targetGUID=target,targetName=read(UnitName,'target')});self.target=target;local ok=pcall(self.Auras,self,'target');if not ok then self.active.missing.auras=true end end
 for _,lesson in ipairs(FC.EncounterCoach and FC.EncounterCoach.lessons or {}) do
  local id=lesson.spellID;local cd=C_Spell and read(C_Spell.GetSpellCooldown,id)
  local start=cd and read(function()return cd.startTime end);local duration=cd and read(function()return cd.duration end)
  local usable=C_Spell and read(C_Spell.IsSpellUsable,id);local range=C_Spell and read(C_Spell.IsSpellInRange,id,'target')
  if type(duration)=='number' and duration<=1.5 then start,duration=0,0 end
  local previous=self.abilities[id]
  if not previous or previous.start~=start or previous.duration~=duration or previous.usable~=usable or previous.range~=range then
   self:Record('ability_state',{unit='player',spellID=id,spellName=lesson.name,cooldownStart=start,cooldownDuration=duration,usable=usable,inRange=range,targetGUID=target})
  end
  if start==nil then self.active.missing.cooldowns=true end
  self.abilities[id]={start=start,duration=duration,usable=usable,range=range}
 end
end
function R:Finish()
 local fight=self.active;if not fight then return end
 self:Sample();self:Record('combat_end',{message='Combat recording finished.'});fight.ended=clock();fight.duration=math.max(0,fight.ended-fight.started)
 if FC.ScenarioTracker then fight.scenarios=FC.ScenarioTracker:Finish() end
 self.active=nil;self.last=fight;local history=saved();table.insert(history,1,fight);while #history>self.keep do table.remove(history) end
 return fight
end
function R:GetLatest()
 if self.active then return self.active end
 for _,fight in ipairs(saved()) do if fight.character==identity() then return fight end end
end
function R:Find(id)for _,fight in ipairs(saved()) do if fight.id==id and fight.character==identity() then return fight end end end
function R:Analyze(fight)
 local casts,failures,deaths=0,0,0
 for _,event in ipairs(fight.events or {}) do
  if event.unit=='player' then if event.kind=='cast_succeeded' then casts=casts+1 elseif event.kind=='cast_failed' or event.kind=='cast_interrupted' then failures=failures+1 elseif event.kind=='death' then deaths=deaths+1 end end
 end
 return {good=casts..' successful player casts recorded in the timeline.',investigate=(failures>0 and failures..' failed/interrupted player casts: inspect their timestamps and nearby movement or client errors before assigning fault.' or 'No failed player cast events were recorded.')..(deaths>0 and '\n'..deaths..' player deaths recorded. Inspect the preceding Health, aura and cast events; the log does not establish blame.' or ''),coverage=fight.coverage..(fight.truncated and ' Storage limit reached: this timeline is partial.' or '')}
end
function R:Describe(event)
 local subject=event.unitName or event.unit or event.targetName or ''
 local text=event.message or event.spellName or event.kind:gsub('_',' ')
 if event.kind=='health' then text='Health '..tostring(event.health)..'/'..tostring(event.maxHealth or '?')..(event.change and ' ('..(event.change>0 and '+' or '')..event.change..')' or '') end
 if event.kind=='resource' then text='Resource '..tostring(event.powerType or '?')..': '..tostring(event.power)..'/'..tostring(event.maxPower or '?') end
 return string.format('%.1fs',event.time)..' / '..subject..' / '..event.kind:gsub('_',' ')..' / '..text..(event.targetName and ' -> '..event.targetName or '')
end
local function json(value)
 local kind=type(value)
 if kind=='string' then return '"'..value:gsub('[%z\1-\31\\"]',function(c)if c=='"' then return '\\"' elseif c=='\\' then return '\\\\' else return string.format('\\u%04x',c:byte()) end end)..'"' end
 if kind=='number' or kind=='boolean' then return tostring(value) end
 if kind~='table' then return 'null' end
 local values={};if #value>0 then for _,v in ipairs(value)do values[#values+1]=json(v)end;return '['..table.concat(values,',')..']' end
 for k,v in pairs(value)do if type(k)=='string' then values[#values+1]=json(k)..':'..json(v)end end;return '{'..table.concat(values,',')..'}'
end
function R:Export()local fight=self:GetLatest();if not fight then return nil end;return json({format='ForeverCoachingFight-v1',fight=fight})end
local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED','PLAYER_DEAD','PLAYER_TARGET_CHANGED','PLAYER_STARTED_MOVING','PLAYER_STOPPED_MOVING','UNIT_HEALTH','UNIT_POWER_UPDATE','UNIT_AURA','UNIT_SPELLCAST_SENT','UNIT_SPELLCAST_START','UNIT_SPELLCAST_CHANNEL_START','UNIT_SPELLCAST_CHANNEL_STOP','UNIT_SPELLCAST_SUCCEEDED','UNIT_SPELLCAST_FAILED','UNIT_SPELLCAST_INTERRUPTED','UNIT_SPELLCAST_STOP','UI_ERROR_MESSAGE'}) do pcall(events.RegisterEvent,events,event) end
events:SetScript('OnEvent',function(_,event,...)
 if event=='PLAYER_ENTERING_WORLD' then identity();R.before={};return elseif event=='PLAYER_REGEN_DISABLED' then R:Begin();return elseif event=='PLAYER_REGEN_ENABLED' then R:Finish();return end
 local args={...};for _,value in pairs(args) do if issecretvalue and issecretvalue(value) then if R.active then R.active.missing.events=true end;return end end
 if not R.active then
  if args[1]=='player' and (event=='UNIT_SPELLCAST_SENT' or event=='UNIT_SPELLCAST_START' or event=='UNIT_SPELLCAST_SUCCEEDED') then
   local sent=event=='UNIT_SPELLCAST_SENT';local id=sent and args[4] or args[3];local cast=sent and args[3] or args[2];local target=sent and args[2] or nil
   R.before=R.before or {};if not target then for i=#R.before,1,-1 do if R.before[i].fields.castGUID==cast then target=R.before[i].fields.targetName;break end end end
   R.before[#R.before+1]={at=clock(),kind=event:lower():gsub('unit_spellcast_','cast_'),fields={unit='player',unitName=read(UnitName,'player'),castGUID=cast,spellID=id,spellName=id and spell(id),targetName=target}}
   while #R.before>32 do table.remove(R.before,1)end
  end
  return
 end
 local unit=args[1]
 if event=='PLAYER_DEAD' then R:Record('death',{unit='player',unitName=read(UnitName,'player'),message='Player death event.'})
 elseif event=='PLAYER_TARGET_CHANGED' or event=='PLAYER_STARTED_MOVING' or event=='PLAYER_STOPPED_MOVING' then R:Sample()
 elseif event=='UI_ERROR_MESSAGE' then R:Record('client_error',{message=type(args[2])=='string' and args[2] or 'Client error; message unavailable.'})
 elseif event=='UNIT_HEALTH' or event=='UNIT_POWER_UPDATE' then R:Snapshot(unit)
 elseif event=='UNIT_AURA' then local ok=pcall(R.Auras,R,unit);if not ok then R.active.missing.auras=true end
 elseif event=='UNIT_SPELLCAST_SENT' then
  local targetName,castGUID,spellID=args[2],args[3],args[4]
  if unit=='player' and type(castGUID)=='string' then R.sent[castGUID]=targetName end
  R:Record('cast_sent',{unit=unit,unitGUID=read(UnitGUID,unit),unitName=read(UnitName,unit),targetName=targetName,castGUID=castGUID,spellID=spellID,spellName=spellID and spell(spellID)})
 else
  local castGUID,spellID=args[2],args[3];local name,_,_,startTime,endTime,_,_,notInterruptible=read(UnitCastingInfo,unit)
  local interruptible;if type(notInterruptible)=='boolean' then interruptible=notInterruptible==false end
  R:Record(event:lower():gsub('unit_spellcast_','cast_'),{unit=unit,unitGUID=read(UnitGUID,unit),unitName=read(UnitName,unit),castGUID=castGUID,spellID=spellID,spellName=spellID and spell(spellID) or name,targetName=castGUID and R.sent[castGUID],castEnd=endTime,interruptible=interruptible})
  if event=='UNIT_SPELLCAST_SUCCEEDED' or event=='UNIT_SPELLCAST_FAILED' or event=='UNIT_SPELLCAST_INTERRUPTED' then if castGUID then R.sent[castGUID]=nil end end
 end
end)
events:SetScript('OnUpdate',function(_,elapsed)R.elapsed=R.elapsed+elapsed;if R.elapsed<1 then return end;R.elapsed=0;if R.active then local ok=pcall(R.Sample,R);if not ok then R.active.missing.samples=true end end end)
