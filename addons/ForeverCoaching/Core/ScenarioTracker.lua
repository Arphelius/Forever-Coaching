local FC=ForeverCoaching
local S={elapsed=0,limit=600}
FC.ScenarioTracker=S
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b,c,d,e,f,g,h,i=pcall(fn,...);if not ok then return end
 for _,v in pairs({a,b,c,d,e,f,g,h,i}) do if issecretvalue and issecretvalue(v) then return end end
 return a,b,c,d,e,f,g,h,i
end
local function clock()return read(GetTime) or 0 end
local order={'interrupt','heal','utility','resources','kite','movement','burst','pvp','aoe','cleave','single'}
local titles={single='Single target',cleave='Cleave',aoe='AoE',pvp='PvP',kite='Kiting',heal='Healing',interrupt='Interrupts',burst='Burst',movement='Movement',utility='Dispels and utility',resources='Resource pressure'}
local advice={single='Focus the engaged target; follow the ready spell suggestion.',cleave='Two engaged enemies observed. Use cleave only if both may safely be hit.',aoe='Multiple engaged enemies observed. Check crowd control and positioning before using area damage.',pvp='Watch enemy control, defensive cooldowns and your kill target.',kite='Create distance while keeping a safe route and line of sight.',heal='Check the injured ally and use a suitable ready heal.',interrupt='Check the enemy cast and your assignment before interrupting.',burst='A burst window is enabled. Check target uptime and save cooldowns for assigned mechanics.',movement='Keep moving when required; use ready mobile actions and avoid starting stationary casts.',utility='Check the removable debuff and your dispel assignment.',resources='Conserve resources; use an appropriate recovery option when safe.'}
function S:Begin()
 self.started=clock();self.windows={};self.open={};self.flags={};self.previousDistances={};self.truncated=false;self.active=true;self.checklists={};self.burstIDs={}
 local _,class=read(UnitClass,'player')
 local catalog=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[class]
 for _,name in ipairs({'Combustion','Arcane Power','Icy Veins','Adrenaline Rush','Blade Flurry','Recklessness','Death Wish','Bestial Wrath','Rapid Fire','Avenging Wrath','Power Infusion','Elemental Mastery','Shifting Power'}) do
  local spell=catalog and (catalog.spells[name] or (catalog.talents or {})[name])
  for _,id in ipairs(spell and spell.ids or {}) do self.burstIDs[id]=name end
 end
 local coach=FC.EncounterCoach
 if coach and FC.SpecScenarios then
  local ok,context=pcall(coach.GetBuildContext,coach)
  if ok and context then local success,spec=pcall(FC.SpecScenarios.ForCurrent,FC.SpecScenarios,context)
   if success and spec then for _,entry in ipairs(spec.scenarios or {}) do self.checklists[entry.id]=entry end end
  end
 end
end
function S:Observe()
 local flags,evidence={},{};local count,seen=0,{}
 local units={'target','focus'};for i=1,5 do units[#units+1]='boss'..i end;for i=1,40 do units[#units+1]='nameplate'..i end
 local px,py,_,map=read(UnitPosition,'player');local moving=read(GetUnitSpeed,'player')
 local distances={}
 for _,unit in ipairs(units) do
  local guid=read(UnitGUID,unit)
  if type(guid)=='string' and not seen[guid] and read(UnitCanAttack,'player',unit)==true and read(UnitIsDeadOrGhost,unit)~=true and read(UnitAffectingCombat,unit)==true then
   seen[guid]=true;count=count+1
   local name,_,_,_,ending,_,_,locked=read(UnitCastingInfo,unit)
   if not name then local cn,_,_,_,ce,_,cl=read(UnitChannelInfo,unit);name,ending,locked=cn,ce,cl end
   if type(name)=='string' and locked==false and type(ending)=='number' and ending>clock()*1000 then flags.interrupt=true;evidence.interrupt='An engaged enemy has an interruptible cast: '..name end
   if read(UnitIsPlayer,unit)==true then flags.pvp=true;evidence.pvp='Engaged hostile player observed.' end
   local x,y,_,unitMap=read(UnitPosition,unit)
   if type(px)=='number' and type(py)=='number' and type(x)=='number' and type(y)=='number' and map~=nil and map==unitMap then
    local distance=((x-px)^2+(y-py)^2)^.5;distances[guid]=distance
    local previous=self.previousDistances[guid]
    if type(moving)=='number' and moving>0 and previous and distance>previous+0.5 and read(UnitIsUnit,unit..'target','player')==true then flags.kite=true;evidence.kite='Moving away from an engaged enemy targeting you; distance increased.' end
   end
  end
 end
 self.previousDistances=distances
 local allies={'player'};for i=1,4 do allies[#allies+1]='party'..i end;for i=1,40 do allies[#allies+1]='raid'..i end
 for _,unit in ipairs(allies) do
  local hp,hmax=read(UnitHealth,unit),read(UnitHealthMax,unit)
  if read(UnitCanAssist,'player',unit)==true and read(UnitIsDeadOrGhost,unit)==false and type(hp)=='number' and type(hmax)=='number' and hmax>0 and hp/hmax<.35 then flags.heal=true;evidence.heal='A living friendly unit is below 35% health.' end
 end
 if count>0 then local id=count==1 and 'single' or count==2 and 'cleave' or 'aoe';flags[id]=true;evidence[id]=count..' distinct engaged enemies visible (minimum observed count).' end
 local _,instance=read(IsInInstance)
 if instance=='pvp' or instance=='arena' then flags.pvp=true;evidence.pvp='PvP instance.' end
 if type(moving)=='number' and moving>0 then flags.movement=true;evidence.movement='Player movement observed; no mechanic requirement inferred.' end
 local p,max=read(UnitPower,'player'),read(UnitPowerMax,'player');local kind=read(UnitPowerType,'player')
 if kind==0 and type(p)=='number' and type(max)=='number' and max>0 and p/max<.2 then flags.resources=true;evidence.resources='Mana below 20%.' end
 for _,offer in ipairs(FC.EncounterCoach and FC.EncounterCoach.currentOffers or {}) do
  local id=({interrupt='interrupt',healing='heal',dispel='utility',['resource recovery']='resources'})[offer.kind]
  if id and offer.status~='responded' and type(offer.expires)=='number' and offer.expires>clock() then flags[id]=true;evidence[id]=offer.reason end
 end
 -- Burst intent cannot be established from elapsed time. Use the player's explicit window setting.
 local settings=ForeverCoachingDB and ForeverCoachingDB.liveRotation
 if settings and settings.burst==true then flags.burst=true;evidence.burst='Player-enabled burst window.' end
 if C_UnitAuras then for i=1,40 do
  local aura=read(C_UnitAuras.GetAuraDataByIndex,'player',i,'HELPFUL');if not aura then break end
  local id=read(function()return aura.spellId end)
  if type(id)=='number' and self.burstIDs[id] then flags.burst=true;evidence.burst='Active player burst effect: '..self.burstIDs[id] end
 end end
 return flags,evidence
end
function S:Sample()
 if not self.active then return end
 local flags,evidence=self:Observe();local at=clock()-self.started
 for id,window in pairs(self.open) do if not flags[id] then
  window.ended=at;self.open[id]=nil
  if FC.FightRecorder then FC.FightRecorder:Record('scenario_end',{scenario=id,message=titles[id]..' window ended.'}) end
 end end
 self.primary=nil
 for _,id in ipairs(order) do if flags[id] then
  self.primary=self.primary or id
  if not self.open[id] and #self.windows<self.limit then
   local w={id=id,title=titles[id],started=at,evidence=evidence[id],casts=0,failures=0,responses=0,actions={}}
   self.windows[#self.windows+1]=w;self.open[id]=w
   if FC.FightRecorder then FC.FightRecorder:Record('scenario_start',{scenario=id,message=titles[id]..': '..(evidence[id] or '')}) end
  elseif not self.open[id] then self.truncated=true end
 end end
 self.flags=flags
end
function S:Record(kind,fields)
 if not self.active then return end
 if fields.unit~='player' and kind~='targeted_response' and kind~='client_error' then return end
 for _,window in pairs(self.open) do
  if kind=='cast_succeeded' then window.casts=window.casts+1
  elseif kind=='cast_failed' or kind=='cast_interrupted' then window.failures=window.failures+1
  elseif kind=='targeted_response' then window.responses=window.responses+1 end
  if kind=='cast_succeeded' or kind=='cast_failed' or kind=='cast_interrupted' or kind=='client_error' or kind=='targeted_response' then
   if #window.actions<80 then window.actions[#window.actions+1]={at=clock()-self.started,kind=kind,spell=fields.spellName,message=fields.message} else window.partial=true end
  end
 end
end
function S:GetGuidance()
 if not self.active or not self.primary then return end
 local labels={};for _,id in ipairs(order) do if self.flags[id] then labels[#labels+1]=titles[id] end end
 local checklist=self.checklists[self.primary]
 return table.concat(labels,' / ')..'\n'..advice[self.primary]..(checklist and checklist.avoid and '\n'..checklist.avoid or '')
end
function S:Finish()
 if not self.active then return end
 local at=clock()-self.started;for id,window in pairs(self.open) do
  window.ended=at
  if FC.FightRecorder then FC.FightRecorder:Record('scenario_end',{scenario=id,message=titles[id]..' window ended with combat.'}) end
 end
 self.active=false;self.primary=nil
 self.last={windows=self.windows,truncated=self.truncated,coverage='Overlapping scenarios inferred from readable engaged units, movement, health, mana and ready situational prompts. Enemy count is a visible minimum; kiting requires readable distance and enemy target. Burst reflects a recognized active effect or the player-enabled window. Successful casts confirm execution, not effect or optimal choice.'..(self.truncated and ' Scenario storage limit reached; partial review.' or '')}
 return self.last
end
function S:Summarize(result)
 local good,wrong,nextSteps={},{},{}
 local grouped={}
 for _,w in ipairs(result.windows or {}) do
  local g=grouped[w.id] or {title=w.title,casts=0,failures=0,responses=0,seconds=0,actions={},successes={}};grouped[w.id]=g
  g.casts=g.casts+(w.casts or 0);g.failures=g.failures+(w.failures or 0);g.responses=g.responses+(w.responses or 0);g.seconds=g.seconds+math.max(0,(w.ended or w.started)-w.started)
  for _,a in ipairs(w.actions or {}) do
   if (a.kind=='cast_succeeded' or a.kind=='targeted_response') and #g.successes<4 then g.successes[#g.successes+1]=a end
   if a.kind~='cast_succeeded' and a.kind~='targeted_response' and #g.actions<4 then g.actions[#g.actions+1]=a end
  end
 end
 for _,id in ipairs(order) do local g=grouped[id];if g then
  local label=g.title..' ('..string.format('%.1fs',g.seconds)..')'
  good[#good+1]=label..': '..g.casts..' successful casts; '..g.responses..' matching targeted responses. Effect outcomes are not established.'
  for _,a in ipairs(g.successes) do good[#good]=good[#good]..'\n'..string.format('%.1fs',a.at)..' / '..(a.spell or 'Spell')..' / '..(a.message or 'Successful cast.') end
  local lines={label..': '..g.failures..' failed/interrupted casts.'}
  for _,a in ipairs(g.actions) do lines[#lines+1]=string.format('%.1fs',a.at)..' / '..(a.spell or '')..' / '..(a.message or a.kind:gsub('_',' ')) end
  lines[#lines+1]=g.failures>0 and 'Check the adjacent client message and movement before assigning a cause.' or 'No confirmed cast failure in these observed windows; this does not establish optimal play.'
  wrong[#wrong+1]=table.concat(lines,'\n');nextSteps[#nextSteps+1]=g.title..': '..advice[id]
 end end
 return table.concat(good,'\n\n'),table.concat(wrong,'\n\n'),table.concat(nextSteps,'\n\n')
end
local frame=CreateFrame('Frame')
frame:SetScript('OnUpdate',function(_,dt)S.elapsed=S.elapsed+dt;if S.elapsed<.25 then return end;S.elapsed=0;if S.active then pcall(S.Sample,S) end end)
