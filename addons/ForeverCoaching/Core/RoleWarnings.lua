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
-- Tank threat on the current target. Forever exposes threat only for your target (and focus or group
-- targets), so only the target is read. Thresholds are coaching policy, not game rules: warn when
-- someone else reaches 80% of the pull point; after a loss, 70% or more of yours is "close" (a quick
-- threat spell wins it back) and below that a taunt is advised.
W.WARN_AT,W.CLOSE_AT=80,70
local TAUNT={WARRIOR='Taunt',DRUID='Growl',PALADIN='Hand of Reckoning'}
local function knownSpell(name)
 local data=C_Spell and read(C_Spell.GetSpellInfo,name)
 local id=data and read(function()return data.spellID end)
 if not id then local _,_,_,_,_,_,legacy=read(GetSpellInfo,name);id=legacy end
 if id and (read(IsPlayerSpell,id)==true or read(IsSpellKnown,id)==true) then return name end
end
local function groupUnits()
 local units={'pet'};for i=1,4 do units[#units+1]='party'..i;units[#units+1]='partypet'..i end
 for i=1,40 do units[#units+1]='raid'..i end
 return units
end
-- Returns nil outside a tank's fight, {state='unknown'} when the game hides threat, else
-- state = secure | warning | other-tank | lost-close | lost-far | lost (distance unknown),
-- with name/percent of the closest other player and mine (my scaled percent).
function W:TankThreat()
 if read(UnitAffectingCombat,'player')~=true or read(UnitCanAttack,'player','target')~=true then return nil end
 local tanking,_,mine=read(UnitDetailedThreatSituation,'player','target')
 if tanking==nil then return {state='unknown'} end
 local holder,holderUnit,top,topPct
 local seen={};seen[read(UnitGUID,'player') or 'player']=true
 for _,unit in ipairs(groupUnits())do
  local guid=read(UnitGUID,unit)
  if guid and not seen[guid] then
   seen[guid]=true
   local t,_,s=read(UnitDetailedThreatSituation,unit,'target')
   if t==true then holder,holderUnit=read(UnitName,unit) or unit,unit end
   if type(s)=='number' and (not topPct or s>topPct) then top,topPct=read(UnitName,unit) or unit,s end
  end
 end
 mine=type(mine)=='number' and mine or nil
 if tanking==true then
  return {state=topPct and topPct>=self.WARN_AT and 'warning' or 'secure',name=top,percent=topPct,mine=mine}
 end
 if not holderUnit and read(UnitCanAssist,'player','targettarget')==true then holder,holderUnit=read(UnitName,'targettarget'),'targettarget' end
 if not holderUnit then return {state='unknown'} end
 local result={name=holder,percent=topPct,mine=mine}
 if read(UnitGroupRolesAssigned,holderUnit)=='TANK' then result.state='other-tank'
 elseif not mine then result.state='lost'
 elseif mine>=self.CLOSE_AT then result.state='lost-close'
 else result.state='lost-far' end
 return result
end
local function quickThreatSpell()
 local ok,rec=pcall(function()return FC.LiveRotation and FC.LiveRotation.ProfileRecommendation and FC.LiveRotation:ProfileRecommendation()end)
 return ok and type(rec)=='table' and rec.spellName or nil
end
function W:Sample()
 local alerts,seen={},{};local combat=read(UnitAffectingCombat,'player')==true;local role=self:Role()
 self.threat=nil
 local function add(key,kind,message,priority,blocks)
  if seen[key]then return end;seen[key]=true
  alerts[#alerts+1]={key=key,kind=kind,message=message,priority=priority,blocksRotation=blocks==true}
 end
 if combat then
  local health,max=read(UnitHealth,'player'),read(UnitHealthMax,'player')
  if type(health)=='number' and type(max)=='number' and max>0 and health>0 and health/max<.3 then add('self-health','health','LOW HEALTH — use a ready defensive or healing item; move to safety.',2) end
  local _,status=read(UnitDetailedThreatSituation,'player','target')
  if role=='tank' then
   local t=self:TankThreat();self.threat=t
   local enemy=read(UnitName,'target') or 'Enemy'
   local state=t and t.state
   if state=='warning' then
    local q=quickThreatSpell()
    add('threat','threat','THREAT LEAD SMALL — '..(t.name or 'an ally')..' is at '..math.floor(t.percent)..'%'..(q and ('. Use '..q..'.') or '.'),4)
   elseif state=='lost-close' then
    local q=quickThreatSpell()
    add('threat','threat',enemy..' is on '..(t.name or 'an ally')..' — you are close: do not taunt, use '..(q or 'your strongest threat spell')..'.',3)
   elseif state=='lost-far' then
    local _,class=read(UnitClass,'player');local taunt=TAUNT[class] and knownSpell(TAUNT[class])
    add('threat','threat',enemy..' is on '..(t.name or 'an ally')..' — '..(taunt and ('TAUNT now ('..taunt..').') or ('far behind: use '..(quickThreatSpell() or 'your strongest threat spell')..'.')),2)
   elseif state=='lost' then
    add('threat','threat',enemy..' is targeting '..(t.name or 'an ally')..' — regain threat if assigned to you.',3)
   end
  elseif type(status)=='number' and status>=2 then add('threat','threat','HIGH THREAT — ease damage and let the tank recover; use an appropriate threat reduction if ready.',3) end
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
