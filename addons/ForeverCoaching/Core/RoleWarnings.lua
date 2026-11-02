local FC=ForeverCoaching
local W={rules={},alerts={},lastLog={}};FC.RoleWarnings=W
local function read(fn,...)
 if not fn then return end
 local ok,a,b,c,d,e,f,g,h=pcall(fn,...);if not ok then return end
 for _,v in pairs({a,b,c,d,e,f,g,h})do if issecretvalue and issecretvalue(v)then return end end
 return a,b,c,d,e,f,g,h
end
local function now()return read(GetTime) or 0 end
function W:Role()
 local assigned=read(UnitGroupRolesAssigned,'player')
 if assigned=='TANK' then return 'tank' elseif assigned=='HEALER' then return 'healer' elseif assigned=='DAMAGER' then return 'damage' end
 local context=FC.EncounterCoach and FC.EncounterCoach:GetBuildContext()
 local spec=context and FC.SpecScenarios and FC.SpecScenarios:ForCurrent(context,true)
 return spec and spec.available and spec.role or 'unknown'
end
-- Only evidence-backed IDs belong here. A rule is scoped to an instance and
-- observed aura/cast; it cannot infer coordinates or unseen ground effects.
function W:RegisterMechanic(rule)
 assert(type(rule)=='table' and type(rule.id)=='string' and type(rule.spellID)=='number' and rule.spellID>0,'A named mechanic and real spell ID are required')
 assert(rule.trigger=='playerAura' or rule.trigger=='targetAura' or rule.trigger=='cast','Unsupported mechanic trigger')
 assert(rule.action=='move' or rule.action=='stop' or rule.action=='danger','Unsupported mechanic action')
 assert(type(rule.message)=='string' and type(rule.source)=='string' and #rule.source>0 and type(rule.instanceID)=='number','Mechanics need an instruction, source and instance scope')
 self.rules[rule.id]=rule
end
local function hasAura(unit,filter,id)
 if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return false end
 for i=1,40 do
  local aura=read(C_UnitAuras.GetAuraDataByIndex,unit,i,filter);if not aura then break end
  local spellID=read(function()return aura.spellId or aura.spellID end)
  if spellID==id then return true end
 end
 return false
end
function W:Sample()
 local alerts,seen={},{};local combat=read(UnitAffectingCombat,'player')==true;local role=self:Role()
 local function add(key,kind,message,priority,blocks,shortMessage)
  if seen[key]then return end;seen[key]=true
  alerts[#alerts+1]={key=key,kind=kind,message=message,priority=priority,blocksRotation=blocks==true,shortMessage=shortMessage}
 end
 if combat then
  local health,max=read(UnitHealth,'player'),read(UnitHealthMax,'player')
  if type(health)=='number' and type(max)=='number' and max>0 and health>0 and health/max<.3 then
   local context=FC.EncounterCoach and FC.EncounterCoach.combatContext
   local message=context and context.canHeal and 'Low health — use a ready defensive or self-heal.' or 'Low health — reduce damage and get to safety.'
   add('self-health','health',message,2,false,message)
  end
  local tanking,status=read(UnitDetailedThreatSituation,'player','target')
  if role=='tank' and tanking==false and type(status)=='number' and read(UnitCanAttack,'player','target')==true and read(UnitCanAssist,'player','targettarget')==true then
   add('threat','threat',(read(UnitName,'target') or 'Enemy')..' is targeting '..(read(UnitName,'targettarget') or 'an ally')..' — regain threat if assigned to you.',3)
  elseif role~='tank' and type(status)=='number' and status>=2 then add('threat','threat','HIGH THREAT — ease damage and let the tank recover; use an appropriate threat reduction if ready.',3) end
  for _,o in ipairs(FC.EncounterCoach and FC.EncounterCoach.currentOffers or {})do
   if o.expires>=now() and o.status=='observed' then
    if o.kind=='interrupt' then add(o.key,'interrupt','INTERRUPT: '..o.reason,2)
    elseif o.kind=='healing' and role=='healer' then add(o.key,'healing','URGENT HEAL: '..(read(UnitName,o.unit) or o.unit)..' — '..(o.name or 'use a ready heal')..'. Check range and incoming damage.',2)
    elseif o.kind=='dispel' then add(o.key,'dispel','DISPEL: '..o.reason,4)
    elseif o.kind=='resource recovery' then add(o.key,'mana',o.reason,5) end
   end
  end
  local _,_,_,_,_,_,_,instance=read(GetInstanceInfo)
  for id,rule in pairs(self.rules)do
   if instance==rule.instanceID and (not rule.role or rule.role==role) then
    local active=false
    if rule.trigger=='playerAura' then active=hasAura('player','HARMFUL',rule.spellID)
    elseif rule.trigger=='targetAura' then active=read(UnitCanAttack,'player','target')==true and hasAura('target','HELPFUL',rule.spellID)
    else
     for _,unit in ipairs({'target','focus','boss1','boss2','boss3','boss4','boss5'})do
      local name,_,_,_,ends=read(UnitCastingInfo,unit)
      -- Read spell ID separately because it is the ninth cast return value.
      local observed=read(function()return select(9,UnitCastingInfo(unit))end)
      if not name then local n,_,_,_,e,_,_,id=read(UnitChannelInfo,unit);name,ends,observed=n,e,id end
      if name and type(ends)=='number' and ends/1000>now() and observed==rule.spellID and read(UnitCanAttack,'player',unit)==true then active=true;break end
     end
    end
    if active then add('mechanic:'..id,rule.action,rule.message,1,rule.action=='stop' or rule.action=='move') end
   end
  end
 end
 if role=='tank' then
  local units={};for i=1,4 do units[#units+1]='party'..i end;for i=1,40 do units[#units+1]='raid'..i end
  local groupSeen={}
  for _,unit in ipairs(units)do
   local guid=read(UnitGUID,unit)
   if guid and not groupSeen[guid] and read(UnitGroupRolesAssigned,unit)=='HEALER' and read(UnitIsDeadOrGhost,unit)==false then
    groupSeen[guid]=true
    local mana,max=read(UnitPower,unit,0),read(UnitPowerMax,unit,0)
    if type(mana)=='number' and type(max)=='number' and max>0 and mana/max<.2 then add('healer-mana:'..guid,'mana',(read(UnitName,unit) or 'Healer')..' has low Mana — '..(combat and 'avoid adding another pack; protect the healer.' or 'wait before pulling and let them drink.'),combat and 4 or 2) end
   end
  end
 end
 table.sort(alerts,function(a,b)if a.priority==b.priority then return a.key<b.key end;return a.priority<b.priority end)
 self.alerts=alerts
 local present={}
 for _,alert in ipairs(alerts)do
  present[alert.key]=true
  if not self.lastLog[alert.key]then
   if FC.FightRecorder then FC.FightRecorder:Record('role_warning',{message=alert.message,warningKind=alert.kind,role=role,unit='player'}) end
  end
 end
 self.lastLog=present
 return alerts
end
function W:GetBlockingRecommendation()
 for _,alert in ipairs(self.alerts)do if alert.blocksRotation then return {message=alert.message,reason=alert.message,situation=alert.kind,encounterPrompt=true,blocksRotation=true,queue={}} end end
end
for _,rule in ipairs(FC.EncounterWarningRules or {})do W:RegisterMechanic(rule) end
