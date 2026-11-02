ForeverCoaching=ForeverCoaching or {}
local FC=ForeverCoaching
local Live={};FC.LiveRotation=Live
local function read(fn,...)
 if not fn then return end
 local ok,a,b,c,d,e,f=pcall(fn,...);if not ok then return end
 for _,v in pairs({a,b,c,d,e,f}) do if issecretvalue and issecretvalue(v) then return end end
 return a,b,c,d,e,f
end
local function now()return read(GetTime) or 0 end
local function settings()
 ForeverCoachingDB=ForeverCoachingDB or {};ForeverCoachingDB.liveRotation=ForeverCoachingDB.liveRotation or {mode='single',items={}}
 local s=ForeverCoachingDB.liveRotation;s.items=s.items or {};s.itemScopes=s.itemScopes or {};return s
end
local function itemScope()
 local context=FC.EncounterCoach and FC.EncounterCoach:GetBuildContext()
 local spec=context and FC.SpecScenarios and FC.SpecScenarios:ForCurrent(context,true)
 if not spec or not spec.available then return nil end
 local ranks={};for _,t in pairs(context.activeTalents or {})do if t.name and type(t.rank)=='number' and t.rank>0 then ranks[#ranks+1]=t.name..'='..t.rank end end;table.sort(ranks)
 return spec.class..':'..spec.treeIndex..':'..spec.role..':'..table.concat(ranks,',')
end
function Live:GetItemScope()return itemScope()end
-- Conservative named priorities from the scenario checklists. These are not
-- simulator-derived optimal APLs. No browsed allocation substitutes for live spec.
local function spell(name,options)local r=options or {};r.name=name;return r end
local function dot(name)return spell(name,{dot=true})end
local P={
 MAGE={{{spell('Arcane Missiles',{buff='Missile Barrage'}),spell('Arcane Wrath'),spell('Arcane Blast')},{spell('Arcane Explosion',{area=true})}},
 {{spell('Pyroblast',{buff='Heating Up'}),spell('Fire Blast',{movingOnly=true}),spell('Fireball')},{spell('Flamestrike',{area=true}),spell('Arcane Explosion',{area=true})}},
 {{spell('Ice Lance',{buff='Fingers of Frost'}),spell('Frostbolt')},{spell('Blizzard',{area=true})}}},
 PRIEST={{{dot('Holy Fire'),spell('Penance'),spell('Smite')},{}},{{dot('Holy Fire'),spell('Smite')},{}},{{dot('Devouring Plague'),dot('Shadow Word: Pain'),spell('Shadow Word: Death',{execute=20}),spell('Mind Blast'),spell('Mind Flay')},{}}},
 WARLOCK={{{dot('Corruption'),dot('Bane of Agony'),spell('Wrack',{requires='Corruption'}),spell('Shadow Bolt')},{spell('Rain of Fire',{area=true})}},
 {{spell('Soul Fire',{buff='Decimation'}),spell('Searing Pain'),spell('Shadow Bolt')},{spell('Rain of Fire',{area=true})}},
 {{dot('Immolate'),spell('Conflagrate',{requires='Immolate',consumes='Immolate'}),spell('Incinerate',{requires='Immolate'}),spell('Shadow Bolt')},{spell('Rain of Fire',{area=true})}}},
 HUNTER={{{spell('Summon Hawk'),spell('Arcane Shot'),spell('Aimed Shot')},{spell('Multi-Shot',{area=true})}},
 {{spell('Sniper Shot'),dot('Serpent Sting'),spell('Aimed Shot'),spell('Arcane Shot')},{spell('Multi-Shot',{area=true})}},
 {{spell('Strider Kick'),spell('Mongoose Bite'),spell('Raptor Strike')},{spell('Explosive Trap',{area=true}),spell('Multi-Shot',{area=true})}}},
 ROGUE={{{spell('Venom',{combo=4,buffMissing='Venom'}),dot('Rupture'),spell('Mutilate',{builder=true}),spell('Sinister Strike',{builder=true})},{}},
 {{spell('Eviscerate',{combo=4}),spell('Sinister Strike',{builder=true})},{}},
 {{spell('Rupture',{combo=4,dot=true}),spell('Hemorrhage',{builder=true}),spell('Backstab',{builder=true})},{}}},
 WARRIOR={{{spell('Execute',{execute=20}),spell('Rend',{dot=true,talent='Bloodthrill'}),spell('Mortal Strike'),spell('Overpower'),spell('Spearing Strike'),spell('Slam')},{spell('Thunder Clap',{area=true})}},
 {{spell('Execute',{execute=20}),spell('Bloodthirst'),spell('Whirlwind',{area=true}),spell('Slam')},{spell('Whirlwind',{area=true})}},
 {{spell('Shield Slam'),spell('Revenge'),spell('Sunder Armor',{dot=true})},{spell('Thunder Clap',{area=true})}}},
 PALADIN={{{spell('Judgement'),spell('Holy Shock')},{}},{{spell('Hammer of the Righteous'),spell('Holy Strike'),spell('Judgement')},{spell('Consecration',{area=true})}},
 {{spell('Hammer of Wrath',{execute=20}),spell('Holy Strike'),spell('Judgement')},{spell('Consecration',{area=true})}}},
 DRUID={{{dot('Moonfire'),dot('Insect Swarm'),spell('Wrath'),spell('Starfire')},{spell('Hurricane',{area=true})}},
 {{spell('Rip',{combo=5,dot=true}),dot('Rake'),spell('Shred',{builder=true}),spell('Claw',{builder=true})},{}},{{dot('Moonfire'),spell('Wrath')},{}}}
}
-- Finishers must never be suggested at zero combo points.
P.ROGUE[1][1][2].combo=4
local bear={{spell('Primal Bite'),spell('Lacerate',{dot=true}),spell('Maul')},{spell('Swipe',{area=true})}}
local function resolve(name)
 for _,l in ipairs(FC.EncounterCoach and FC.EncounterCoach.lessons or {}) do
  if l.name==name or l.canonicalName==name then
   if read(IsPlayerSpell,l.spellID)==true or read(IsSpellKnown,l.spellID)==true then return {id=l.spellID,name=l.name,icon=l.icon} end
  end
 end
 local data=C_Spell and read(C_Spell.GetSpellInfo,name)
 local id=data and read(function()return data.spellID end)
 if not id then local _,_,_,_,_,_,legacy=read(GetSpellInfo,name);id=legacy end
 if id and (read(IsPlayerSpell,id)==true or read(IsSpellKnown,id)==true or (C_SpellBook and read(C_SpellBook.IsSpellKnown,id)==true)) then
  local n,_,icon=read(GetSpellInfo,id)
  return {id=id,name=data and read(function()return data.name end) or n or name,icon=data and read(function()return data.iconID end) or icon}
 end
end
local function aura(name,unit,filter)
 if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return nil end
 local s=resolve(name);name=s and s.name or name
 for i=1,40 do
  local ok,a=pcall(C_UnitAuras.GetAuraDataByIndex,unit or 'target',i,filter or 'HARMFUL|PLAYER')
  if not ok or (issecretvalue and issecretvalue(a)) then return nil end
  if not a then return false end
  local n,expiration=read(function()return a.name,a.expirationTime end)
  if not n then return nil end
  if n==name then if type(expiration)~='number' then return nil end;return expiration==0 or expiration-now()>3 end
 end
 return nil
end
local repeatable={['Arcane Blast']=true,['Arcane Missiles']=true,Fireball=true,Frostbolt=true,Smite=true,['Shadow Bolt']=true,['Mind Flay']=true,Incinerate=true,['Steady Shot']=true,['Sinister Strike']=true,Mutilate=true,Hemorrhage=true,Backstab=true,Devastate=true,Wrath=true,Starfire=true,Claw=true}
local function ready(s,unit,moving)
 local usable,noPower
 if C_Spell and C_Spell.IsSpellUsable then usable,noPower=read(C_Spell.IsSpellUsable,s.id) else usable,noPower=read(IsUsableSpell,s.id) end
 if usable~=true or noPower==true then return false end
 local start,duration,enabled
 local cd=C_Spell and read(C_Spell.GetSpellCooldown,s.id)
 if cd then start,duration,enabled=read(function()return cd.startTime,cd.duration,cd.isEnabled end) else start,duration,enabled=read(GetSpellCooldown,s.id) end
 if type(start)~='number' or type(duration)~='number' or enabled==false or enabled==0 then return false end
 if start>0 and duration>1.5 and start+duration>now() then return false end
 local range
 if C_Spell and C_Spell.IsSpellInRange then range=read(C_Spell.IsSpellInRange,s.id,unit) else range=read(IsSpellInRange,s.name,unit) end
 if range~=true and range~=1 then return false end
 local info=C_Spell and read(C_Spell.GetSpellInfo,s.id)
 local cast=info and read(function()return info.castTime end)
 if cast==nil then local _,_,_,v=read(GetSpellInfo,s.id);cast=v end
 if moving and (type(cast)~='number' or cast>0) then return false end
 s.repeatable=duration<=1.5;s.castTime=cast
 return true
end
local function resourceCosts(id)
 local costs=C_Spell and read(C_Spell.GetSpellPowerCost,id) or read(GetSpellPowerCost,id)
 if type(costs)~='table' then return nil end
 local result={}
 for _,c in ipairs(costs) do
  local kind,cost,perSecond=read(function()return c.type,c.cost,c.costPerSec end)
  if type(kind)~='number' or type(cost)~='number' or (type(perSecond)=='number' and perSecond>0) then return nil end
  result[kind]=(result[kind] or 0)+cost
 end
 return result
end
function Live:ProfileRecommendation()
 local context=FC.EncounterCoach and FC.EncounterCoach:GetBuildContext()
 local spec=context and FC.SpecScenarios and FC.SpecScenarios:ForCurrent(context,true)
 if not spec or not spec.available then return {message='Current specialization unavailable',reason='Readable active talents are needed for a build-specific live rotation.'} end
 if spec.class=='SHAMAN' then
  FC.RotationCoach.burstAllowed=settings().burst==true
  FC.RotationCoach.allowArea=settings().mode=='aoe'
  return FC.RotationCoach:GetRecommendation()
 end
 local profile=P[spec.class] and P[spec.class][spec.treeIndex]
 if spec.class=='DRUID' and spec.role=='tank' then profile=bear end
 if not profile then return {message='No live priority profile for this specialization'} end
 if spec.role=='healer' then return {message='Follow your healing assignment',reason='',targetHostile=false} end
 if read(UnitExists,'target')~=true or read(UnitIsDeadOrGhost,'target')~=false or read(UnitCanAttack,'player','target')~=true then return {targetHostile=false,message='Select a living enemy'} end
 if read(UnitCastingInfo,'player') or read(UnitChannelInfo,'player') then return {targetHostile=true,message='Finish the current cast',situation='casting'} end
 local moving=read(GetUnitSpeed,'player');moving=type(moving)=='number' and moving>0
 local mode=settings().mode;local rules={}
 if mode=='aoe' then for _,r in ipairs(profile[2]) do rules[#rules+1]=r end end
 for _,r in ipairs(profile[1]) do rules[#rules+1]=r end
 local health,max=read(UnitHealth,'target'),read(UnitHealthMax,'target')
 local hp=type(health)=='number' and type(max)=='number' and max>0 and health/max*100 or nil
 local combo=read(GetComboPoints,'player','target')
 local resources,used,applied,consumed={},{},{},{};local queue={}
 local talents={};for _,t in pairs(context.activeTalents or {})do if t.name and (t.rank or 0)>0 then talents[t.name]=true end end
 for step=1,4 do
  local chosen
  for _,rule in ipairs(rules) do
   local s=resolve(rule.name)
   local required=not rule.requires or (not consumed[rule.requires] and (applied[rule.requires] or aura(rule.requires)==true))
   local dotMissing=not rule.dot or (not applied[rule.name] and aura(rule.name)==false)
   local proc=not rule.buff or aura(rule.buff,'player','HELPFUL')==true
   local needsBuff=not rule.buffMissing or aura(rule.buffMissing,'player','HELPFUL')==false
   local verified=not FC.ForeverSpellCatalog or FC.ForeverSpellCatalog.classes[spec.class].spells[rule.name]~=nil
   if s and verified and proc and needsBuff and (not rule.movingOnly or moving) and (not rule.talent or talents[rule.talent]) and (not rule.area or mode=='aoe') and required and dotMissing and (not rule.execute or hp and hp<=rule.execute)
    and (not rule.combo or type(combo)=='number' and combo>=rule.combo) and not used[s.id] and ready(s,'target',moving) then
    local costs=resourceCosts(s.id);local affordable=true
    if step>1 and not costs then affordable=false end
    for kind,cost in pairs(costs or {}) do
     if resources[kind]==nil then resources[kind]=read(UnitPower,'player',kind) end
     if type(resources[kind])~='number' or resources[kind]<cost then affordable=false end
    end
    if affordable then
     chosen=s;s.costs=costs;s.reason=rule.dot and ('Apply '..rule.name..' while your effect is missing.') or ('Use '..rule.name..' from the current '..spec.spec..' '..mode..' priority.')
     local note=FC.ForeverSpellNotes and FC.ForeverSpellNotes[spec.class] and FC.ForeverSpellNotes[spec.class][rule.name]
     if note then s.reason=s.reason..' '..note end
     for kind,cost in pairs(costs or {}) do resources[kind]=resources[kind]-cost end
     if not repeatable[rule.name] or rule.dot then used[s.id]=true end
     if rule.dot then applied[rule.name]=true end
     if rule.consumes then consumed[rule.consumes]=true;applied[rule.consumes]=nil end
     if rule.combo then combo=0 end
     -- Do not assume a builder lands, grants a proc or generates combo points.
     break
    end
   end
  end
  if not chosen then break end
  queue[#queue+1]=chosen
  if not chosen.costs then break end
 end
 local first=queue[1]
 return {spellID=first and first.id,spellName=first and first.name,icon=first and first.icon,queue=queue,targetHostile=true,
  message=first and first.name or 'No verified ready action',reason=first and first.reason or 'Check resources, range, movement and the action bar.',
  situation=mode,profile=spec.spec,confidence='Curated conditional priority; future icons assume the situation stays unchanged.'}
end
function Live:ItemRecommendation()
 if read(UnitAffectingCombat,'player')~=true then return end
 local s=settings();local scope=itemScope();if not scope then return end
 local ids={};for id in pairs(s.items)do if s.itemScopes[id]==scope then ids[#ids+1]=id end end
 local priorities={health=1,mana=2,burst=3}
 table.sort(ids,function(a,b)local pa,pb=priorities[s.items[a]] or 9,priorities[s.items[b]] or 9;if pa==pb then return a<b end;return pa<pb end)
 for _,id in ipairs(ids) do
  local trigger=s.items[id];local qualifies=trigger=='burst' and s.burst==true
  if trigger=='health' or trigger=='mana' then
   local current,max
   if trigger=='health' then current,max=read(UnitHealth,'player'),read(UnitHealthMax,'player') else current,max=read(UnitPower,'player',0),read(UnitPowerMax,'player',0) end
   qualifies=type(current)=='number' and type(max)=='number' and max>0 and current/max<(trigger=='health' and .3 or .2)
  end
  local count=C_Item and read(C_Item.GetItemCount,id,false,false) or read(GetItemCount,id)
  local slot;for i=1,19 do if read(GetInventoryItemID,'player',i)==id then slot=i end end
  local start,duration,enabled
  if slot then start,duration,enabled=read(GetInventoryItemCooldown,'player',slot)
  elseif C_Container and C_Container.GetItemCooldown then start,duration,enabled=read(C_Container.GetItemCooldown,id) else start,duration,enabled=read(GetItemCooldown,id) end
  local usable=C_Item and read(C_Item.IsUsableItem,id);if usable==nil then usable=read(IsUsableItem,id) end
  local name,spellID
  if C_Item and C_Item.GetItemSpell then name,spellID=read(C_Item.GetItemSpell,id) else name,spellID=read(GetItemSpell,id) end
  if qualifies and (slot or type(count)=='number' and count>0) and usable==true and type(start)=='number' and type(duration)=='number' and enabled~=0 and enabled~=false and (start==0 or start+duration<=now()) and type(spellID)=='number' then
   local icon=C_Item and read(C_Item.GetItemIconByID,id) or read(GetItemIcon,id)
   return {itemID=id,spellID=spellID,spellName=name,icon=icon,message=name,reason='Use your configured '..trigger..' item; its inventory and cooldown checks passed.',situation='item '..trigger,queue={{id=spellID,itemID=id,name=name,icon=icon}},targetHostile=true}
  end
 end
end
function Live:GetRecommendation()
 local blocking=FC.RoleWarnings and FC.RoleWarnings:GetBlockingRecommendation()
 if blocking then return blocking end
 local urgent=FC.EncounterCoach and FC.EncounterCoach:GetRecommendation()
 if urgent and urgent.spellID then
  local data=C_Spell and read(C_Spell.GetSpellInfo,urgent.spellID)
  urgent.icon=urgent.icon or data and read(function()return data.iconID end)
  urgent.queue={{id=urgent.spellID,icon=urgent.icon,name=urgent.spellName}};return urgent
 end
 local item=self:ItemRecommendation();if item then return item end
 local rec=self:ProfileRecommendation()
 if rec and not rec.queue then
  rec.queue={}
  if rec.spellID then rec.queue[1]={id=rec.spellID,icon=rec.icon,name=rec.spellName} end
  for _,entry in ipairs(rec.forecast or (rec.nextSpell and {rec.nextSpell} or {})) do if #rec.queue<4 then rec.queue[#rec.queue+1]=entry end end
 end
 if urgent and not rec.spellID then return urgent end
 return rec
end
SlashCmdList=SlashCmdList or {};SLASH_FOREVERCOACHINGROTATION1='/fcrotation'
SlashCmdList.FOREVERCOACHINGROTATION=function(text)
 if text:match('^%s*$') and FC.OpenRotationSettings then FC:OpenRotationSettings();return end
 local s=settings();local command,a,b=text:match('^(%S+)%s*(%S*)%s*(%S*)')
 if command=='single' or command=='aoe' then s.mode=command
 elseif command=='burst' and (a=='on' or a=='off') then s.burst=a=='on'
 elseif command=='item' and tonumber(a) and tonumber(a)>0 and tonumber(a)==math.floor(tonumber(a)) and (b=='health' or b=='mana' or b=='burst' or b=='off') then
  local scope=itemScope();if b~='off' and not scope then print('Forever Coaching: establish your current specialization before assigning an item.');return end
  s.items[tonumber(a)]=b~='off' and b or nil;s.itemScopes[tonumber(a)]=b~='off' and scope or nil
 else print('Forever Coaching: /fcrotation single | aoe (only when all nearby enemies may be hit); burst on | off; item ID health | mana | burst | off. Assign only items with the matching effect. Burst resets after combat.');return end
 print('Forever Coaching: rotation setting updated.')
end
local events=CreateFrame('Frame');events:RegisterEvent('PLAYER_REGEN_ENABLED');events:RegisterEvent('PLAYER_ENTERING_WORLD')
events:SetScript('OnEvent',function()settings().burst=false end)
