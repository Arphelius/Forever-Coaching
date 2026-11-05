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
 MAGE={{{spell('Arcane Missiles',{buff='Missile Barrage'}),spell('Arcane Wrath'),spell('Arcane Blast')},{spell('Arcane Explosion',{area=true,self=true})}},
 {{spell('Pyroblast',{buff='Heating Up',buffStacks=3}),spell('Fire Blast'),spell('Fireball')},{spell('Flamestrike',{area=true,ground=true}),spell('Arcane Explosion',{area=true,self=true})}},
 {{spell('Ice Barrier',{selfBuff=true,self=true}),spell('Ice Lance',{buff='Fingers of Frost'}),spell('Frostbolt')},{spell('Blizzard',{area=true,ground=true})}}},
 PRIEST={{{dot('Holy Fire'),spell('Penance'),spell('Smite')},{}},{{dot('Holy Fire'),spell('Smite')},{}},{{dot('Devouring Plague'),dot('Shadow Word: Pain'),spell('Shadow Word: Death',{execute=20}),spell('Mind Blast'),spell('Mind Flay')},{}}},
 WARLOCK={{{dot('Corruption'),dot('Bane of Agony'),spell('Wrack',{requires='Corruption'}),spell('Shadow Bolt')},{spell('Rain of Fire',{area=true,ground=true})}},
 {{spell('Soul Fire',{buff='Decimation'}),spell('Searing Pain'),spell('Shadow Bolt')},{spell('Rain of Fire',{area=true,ground=true})}},
 {{dot('Immolate'),spell('Conflagrate',{requires='Immolate',consumes='Immolate'}),spell('Incinerate',{requires='Immolate'}),spell('Shadow Bolt')},{spell('Rain of Fire',{area=true,ground=true})}}},
 HUNTER={{{spell('Summon Hawk'),spell('Arcane Shot'),spell('Aimed Shot')},{spell('Multi-Shot',{area=true})}},
 {{spell('Sniper Shot'),dot('Serpent Sting'),spell('Aimed Shot'),spell('Arcane Shot')},{spell('Multi-Shot',{area=true})}},
 {{spell('Strider Kick'),spell('Mongoose Bite'),spell('Raptor Strike')},{spell('Explosive Trap',{area=true,self=true}),spell('Multi-Shot',{area=true})}}},
 ROGUE={{{spell('Shank',{energyDeficit=40}),spell('Rupture',{combo=4,dot=true}),spell('Eviscerate',{combo=4}),spell('Mutilate',{builder=true}),spell('Sinister Strike',{builder=true})},{}},
 {{spell('Slice and Dice',{combo=1,selfBuff=true,self=true}),spell('Shank',{energyDeficit=40}),spell('Eviscerate',{combo=4}),spell('Sinister Strike',{builder=true})},{}},
 {{spell('Death Mark',{combo=5,dot=true}),spell('Shank',{energyDeficit=25,comboAtMost=3}),spell('Rupture',{combo=4,dot=true}),spell('Hemorrhage',{builder=true}),spell('Backstab',{builder=true})},{}}},
 WARRIOR={{{spell('Execute',{execute=20}),spell('Rend',{dot=true,talent='Bloodthrill'}),spell('Mortal Strike'),spell('Overpower'),spell('Spearing Strike'),spell('Slam')},{spell('Thunder Clap',{area=true,self=true})}},
 {{spell('Battle Shout',{selfBuff=true,self=true}),spell('Execute',{execute=20}),spell('Bloodthirst'),spell('Whirlwind',{area=true,self=true}),spell('Heroic Strike',{rage=65}),spell('Slam')},{spell('Whirlwind',{area=true,self=true})}},
 -- Tank profiles (Protection Warrior, Protection Paladin, Bear below) follow MythicSim's Forever tank APLs
 -- (github.com/sage3648/mythicsim-forever-engine-go, MIT), translated to spell names so every rank the
 -- player knows resolves. The sim also casts Thunder Clap and Consecration on one target; here they stay
 -- area spells, which wait for /fcrotation aoe so crowd-controlled enemies are not broken.
 {{spell('Defensive Stance',{stance=true,self=true}),spell('Shield Slam'),spell('Revenge'),spell('Battle Shout',{selfBuff=true,self=true}),
   spell('Sunder Armor',{stacksBelow=5}),spell('Heroic Strike',{rage=45}),spell('Sunder Armor')},
  {spell('Thunder Clap',{area=true,self=true}),spell('Cleave',{area=true,rage=45})}}},
 PALADIN={{{spell('Judgement'),spell('Holy Shock')},{}},
 {{spell('Lay on Hands',{selfHealth=10,unit='player'}),spell('Righteous Fury',{selfBuff=true,self=true}),
   spell('Judgement',{requiresSelf='Seal of Righteousness'}),spell('Seal of Righteousness',{selfBuff=true,refresh=1,self=true}),
   spell('Holy Shield',{selfBuff=true,self=true}),spell('Hammer of Wrath',{execute=20}),spell('Holy Strike')},
  {spell('Hammer of the Righteous',{area=true}),spell('Consecration',{area=true,self=true})}},
 {{spell('Hammer of Wrath',{execute=20}),spell('Holy Strike'),spell('Judgement')},{spell('Consecration',{area=true,self=true})}}},
 DRUID={{{dot('Moonfire'),dot('Insect Swarm'),spell('Wrath'),spell('Starfire')},{spell('Hurricane',{area=true,ground=true})}},
 {{spell('Rip',{combo=5,dot=true}),dot('Rake'),spell('Shred',{builder=true}),spell('Claw',{builder=true})},{}},{{dot('Moonfire'),spell('Wrath')},{}}}
}
-- Forever's Bear: Primal Bite replaces Mangle and the bear swipe is named Swipe.
local bear={{dot('Faerie Fire (Feral)'),spell('Demoralizing Roar',{dot=true,self=true}),spell('Primal Bite'),
  spell('Lacerate',{stacksBelow=5,refresh=4.5}),spell('Maul',{rage=25}),spell('Lacerate')},{spell('Swipe',{area=true})}}
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
-- nil: unknown (hidden or unreadable), false: absent, table: {remaining=seconds,stacks=n}.
local function findAura(unit,filter,name)
 if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return nil end
 local s=resolve(name);name=s and s.name or name
 for i=1,40 do
  local ok,a=pcall(C_UnitAuras.GetAuraDataByIndex,unit,i,filter)
  if not ok or (issecretvalue and issecretvalue(a)) then return nil end
  if not a then return false end
  local n,expiration,stacks=read(function()return a.name,a.expirationTime,a.applications end)
  if not n then return nil end
  if n==name then
   if type(expiration)~='number' then return nil end
   return {remaining=expiration==0 and math.huge or expiration-now(),stacks=type(stacks)=='number' and stacks or 1}
  end
 end
 return nil
end
local function aura(name,unit,filter)
 local a=findAura(unit or 'target',filter or 'HARMFUL|PLAYER',name)
 if type(a)~='table' then return a end
 return a.remaining>3
end
-- Is the player in this stance or form? nil when the client does not say.
local function inStance(name)
 local count=read(GetNumShapeshiftForms)
 if type(count)~='number' then return nil end
 for i=1,count do
  local _,a,b,c=read(GetShapeshiftFormInfo,i)
  local active,formName=a,nil
  if type(a)=='string' then formName,active=a,b elseif c then formName=read(GetSpellInfo,c) end
  if active then if not formName then return nil end;return formName==name end
 end
 return false
end
local function playerHealthPercent()
 local health,max=read(UnitHealth,'player'),read(UnitHealthMax,'player')
 if type(health)=='number' and type(max)=='number' and max>0 then return health/max*100 end
end
local repeatable={['Arcane Blast']=true,['Arcane Missiles']=true,Fireball=true,Frostbolt=true,Smite=true,['Shadow Bolt']=true,['Mind Flay']=true,Incinerate=true,['Steady Shot']=true,['Sinister Strike']=true,Mutilate=true,Hemorrhage=true,Backstab=true,Devastate=true,Wrath=true,Starfire=true,Claw=true,['Sunder Armor']=true,Lacerate=true}
-- Tank rule checks. Each returns true only when the state is read and the rule applies; unknown never fires.
local function selfRulesPass(rule,s,applied,resources)
 if rule.selfBuff then
  if applied['self:'..rule.name] then return false end
  local a=findAura('player','HELPFUL',rule.name)
  if a==nil or (a and a.remaining>(rule.refresh or 0)) then return false end
 end
 if rule.stance then
  if applied['self:'..rule.name] or inStance(s.name)~=false then return false end
 end
 if rule.requiresSelf and not applied['self:'..rule.requiresSelf] and type(findAura('player','HELPFUL',rule.requiresSelf))~='table' then return false end
 if rule.selfHealth then
  local hp=playerHealthPercent()
  if not hp or hp>=rule.selfHealth then return false end
 end
 if rule.stacksBelow then
  local a=findAura('target','HARMFUL|PLAYER',rule.name)
  if a==nil or (a and a.stacks>=rule.stacksBelow and not (rule.refresh and a.remaining<=rule.refresh)) then return false end
 end
 if rule.rage then
  if resources[1]==nil then resources[1]=read(UnitPower,'player',1) end
  if type(resources[1])~='number' or resources[1]<rule.rage then return false end
 end
 if rule.energyDeficit then
  local energy,maximum=read(UnitPower,'player',3),read(UnitPowerMax,'player',3)
  if type(energy)~='number' or type(maximum)~='number' or maximum-energy<rule.energyDeficit then return false end
 end
 return true
end
local function ruleReason(rule,spec,mode)
 if rule.stance then return 'Enter '..rule.name..' before tanking.' end
 if rule.selfBuff then return 'Keep '..rule.name..' active.' end
 if rule.selfHealth then return 'Your health is below '..rule.selfHealth..'%.' end
 if rule.stacksBelow then return 'Build or refresh '..rule.name..' on your target.' end
 if rule.dot then return 'Apply '..rule.name..' while your effect is missing.' end
 return 'Use '..rule.name..' from the current '..spec.spec..' '..mode..' priority.'
end
local function ready(s,unit,moving)
 local usable,noPower
 if C_Spell and C_Spell.IsSpellUsable then usable,noPower=read(C_Spell.IsSpellUsable,s.id) else usable,noPower=read(IsUsableSpell,s.id) end
 if usable~=true or noPower==true then return false end
 local start,duration,enabled
 local cd=C_Spell and read(C_Spell.GetSpellCooldown,s.id)
 if cd then start,duration,enabled=read(function()return cd.startTime,cd.duration,cd.isEnabled end) else start,duration,enabled=read(GetSpellCooldown,s.id) end
 if type(start)~='number' or type(duration)~='number' or enabled==false or enabled==0 then return false end
 if start>0 and duration>1.5 and start+duration>now() then return false end
 -- unit nil: a self-centred spell (stance, own buff, Consecration) or one placed on the ground (Blizzard) has no
 -- range the API can report; the player places ground spells, and area spells wait for /fcrotation aoe.
 if unit then
  local range
  if C_Spell and C_Spell.IsSpellInRange then range=read(C_Spell.IsSpellInRange,s.id,unit) else range=read(IsSpellInRange,s.name,unit) end
  if range~=true and range~=1 then return false end
 end
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
local function autoAttack()
 local data=C_Spell and read(C_Spell.GetSpellInfo,6603)
 return {id=6603,name='Autoattack',icon=data and read(function()return data.iconID end) or 'Interface\\Icons\\INV_Sword_04',autoAttack=true}
end
-- Same anchor as Blizzard_SwingTimer: PLAYER_SWING(duration, swingType),
-- with expiration = GetTime() + duration. Never seed a swing from weapon speed.
-- Source: Gethe/wow-ui-source @ 70ef1b2f, Blizzard_SwingTimer.lua.
function Live:ObserveSwing(duration,hand)
 if (issecretvalue and (issecretvalue(duration) or issecretvalue(hand)))
  or type(duration)~='number' or duration<=0 or duration~=duration or duration==math.huge then return end
 local types=Enum and Enum.PlayerSwingType or {MainHand=0,OffHand=1,Ranged=2}
 if hand~=types.MainHand and hand~=types.OffHand then return end
 self.swings=self.swings or {}
 self.swings[hand]={duration=duration,ends=now()+duration,hand=hand}
end
function Live:GetUpcomingSwings()
 local queue={}
 for hand,state in pairs(self.swings or {}) do
  if state.ends>now() then
   local entry=autoAttack();entry.swingEnds=state.ends;entry.swingDuration=state.duration;entry.hand=hand
   queue[#queue+1]=entry
  end
 end
 table.sort(queue,function(a,b)if a.swingEnds==b.swingEnds then return a.hand<b.hand end;return a.swingEnds<b.swingEnds end)
 return queue
end
function Live:WithAutoPreview(rec)
 if not rec.spellID then return rec end
 local swings=self:GetUpcomingSwings()
 if #swings==0 then swings[1]=autoAttack() end
 if rec.spellID==6603 then rec.queue=swings;return rec end
 local source=rec.queue or rec.forecast or {}
 local queue={{id=rec.spellID,name=rec.spellName,icon=rec.icon}}
 for _,entry in ipairs(source) do
  if #queue<4-#swings and entry.id~=rec.spellID and entry.id~=6603 then queue[#queue+1]=entry end
 end
 for _,entry in ipairs(swings) do queue[#queue+1]=entry end
 rec.queue=queue
 return rec
end
function Live:GetIdleRecommendation()
 local _,class=read(UnitClass,'player')
 local context=FC.EncounterCoach and FC.EncounterCoach:GetBuildContext()
 local spec=context and FC.SpecScenarios and FC.SpecScenarios:ForCurrent(context,true)
 local queue={}
 if class=='SHAMAN' then
  local bolt=resolve('Lightning Bolt');if bolt then queue[#queue+1]=bolt end
  queue[#queue+1]=autoAttack()
  local shock=resolve('Earth Shock');if shock then queue[#queue+1]=shock end
  queue[#queue+1]=autoAttack()
 elseif spec and spec.available then
  local profile=class=='DRUID' and spec.role=='tank' and bear or P[class] and P[class][spec.treeIndex]
  for _,rule in ipairs(profile and profile[1] or {}) do
   local s=resolve(rule.name);if s and #queue<4 then queue[#queue+1]=s end
  end
 end
 if #queue==0 then queue[1]=autoAttack() end
 return {queue=queue,preview=true,pressRequired=false,reviewEligible=false}
end
function Live:WithShamanSwings(rec,spec)
 if not rec or rec.targetHostile~=true or rec.situation=='casting' or rec.situation=='interrupt' then return rec end
 local attacking=read(IsCurrentSpell,6603)
 local enhancement=spec and spec.available and spec.treeIndex==2
 -- Before talent specialization exists, use observed weapon range rather
 -- than treating a browsed talent build as the character's live allocation.
 if not enhancement and spec and spec.available then return rec end
 local melee=resolve('Stormstrike')
 local types=Enum and Enum.PlayerSwingType or {MainHand=0}
 local inRange=C_SwingTimer and read(C_SwingTimer.IsTargetWithinSwingRange,types.MainHand)
 if inRange==nil and melee and C_Spell then inRange=read(C_Spell.IsSpellInRange,melee.id,'target') end
 if inRange==nil then
  for _,prefix in ipairs({'ActionButton','MultiBarBottomLeftButton','MultiBarBottomRightButton','MultiBarRightButton','MultiBarLeftButton','MultiBar5Button','MultiBar6Button','MultiBar7Button'}) do
   for i=1,12 do
    local b=_G[prefix..i];local slot=b and read(function()return b.action end)
    if type(slot)=='number' and read(IsAttackAction,slot)==true then
     local value=read(IsActionInRange,slot,'target')
     if value==true or value==1 then inRange=true elseif (value==false or value==0) and inRange==nil then inRange=false end
    end
   end
  end
 end
 if inRange~=true and inRange~=1 then
  -- Prefer a ranged pull while the enemy is outside weapon reach, even when
  -- an instant Shock has a higher per-cast damage score. Recheck every update
  -- so closing to melee immediately hands back to weapon/instant priorities.
  local speed=read(GetUnitSpeed,'player')
  local bolt=resolve('Lightning Bolt')
  if (inRange==false or inRange==0) and speed==0 and bolt and ready(bolt,'target',false) then
   return {spellID=bolt.id,spellName=bolt.name,icon=bolt.icon,targetHostile=true,targetGUID=read(UnitGUID,'target'),
    situation='ranged opener',reason='Open with Lightning Bolt while the enemy is outside melee range; switch to weapon swings and instant attacks when it closes.',
    queue={bolt,autoAttack()}}
  end
  -- Missing range data must not remove Enhancement's weapon swings from
  -- the strip. Keep them as follow-ups without claiming melee is in range.
  return self:WithAutoPreview(rec)
 end
 local auto=autoAttack()
 if not rec.spellID or (rec.spellName=='Lightning Bolt' and rec.situation~='maelstrom proc') then
  local shock=resolve('Earth Shock')
  if shock and ready(shock,'target',false) then
   rec={spellID=shock.id,spellName=shock.name,icon=shock.icon,targetHostile=true,targetGUID=read(UnitGUID,'target'),
    situation='melee attack',reason='Use the ready Earth Shock between weapon swings; keep autoattack running.'}
  else
   rec={spellID=auto.id,spellName=auto.name,icon=auto.icon,targetHostile=true,targetGUID=read(UnitGUID,'target'),
    situation='weapon attack',reason='Keep weapon swings running while your melee abilities recover.',pressRequired=attacking~=true}
  end
 end
 if not rec.spellID then return rec end
 local ability={id=rec.spellID,name=rec.spellName,icon=rec.icon,autoAttack=rec.spellID==6603}
 local swings=attacking==true and self:GetUpcomingSwings() or {}
 -- One actual in-flight swing per hand. With no native timing, show a single
 -- untimed AUTO indicator rather than inventing future swing boundaries.
 if attacking==false and ability.id~=6603 then
  rec.queue={auto,ability};rec.spellID=6603;rec.spellName=auto.name;rec.icon=auto.icon
  rec.pressRequired=true;rec.reason='Start autoattack in melee, then use the ready ability between swings.'
 else
  rec.queue={}
  if ability.id~=6603 then rec.queue[1]=ability end
  for _,swing in ipairs(swings) do rec.queue[#rec.queue+1]=swing end
  if #swings==0 then rec.queue[#rec.queue+1]=auto end
  if ability.id==6603 then rec.pressRequired=attacking~=true end
 end
 return rec
end
function Live:ProfileRecommendation()
 local context=FC.EncounterCoach and FC.EncounterCoach:GetBuildContext()
 local spec=context and FC.SpecScenarios and FC.SpecScenarios:ForCurrent(context,true)
 if context and context.class=='SHAMAN' and (not spec or not spec.available or spec.role~='healer') then
  FC.RotationCoach.burstAllowed=settings().burst==true
  FC.RotationCoach.allowArea=settings().mode=='aoe'
  return self:WithShamanSwings(FC.RotationCoach:GetRecommendation(),spec)
 end
 if not spec or not spec.available then return {message='Current specialization unavailable',reason='Readable active talents are needed for a build-specific live rotation.'} end
 if spec.role=='healer' then return {message='Follow your healing assignment',reason='',targetHostile=false} end
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
 local resources,used,applied,consumed,usedBuff={},{},{},{},{};local queue={}
 local talents={};for _,t in pairs(context.activeTalents or {})do if t.name and (t.rank or 0)>0 then talents[t.name]=true end end
 for step=1,4 do
  local chosen
  for _,rule in ipairs(rules) do
   local s=resolve(rule.name)
   if s and (rule.name=='Heroic Strike' or rule.name=='Cleave') and read(IsCurrentSpell,s.id)==true then s=nil end
   local required=not rule.requires or (not consumed[rule.requires] and (applied[rule.requires] or aura(rule.requires)==true))
   local dotMissing=not rule.dot or (not applied[rule.name] and aura(rule.name)==false)
   local proc=not rule.buff or (not usedBuff[rule.buff] and aura(rule.buff,'player','HELPFUL')==true)
   if proc and rule.buffStacks then local observed=findAura('player','HELPFUL',rule.buff);proc=type(observed)=='table' and observed.stacks>=rule.buffStacks end
   local needsBuff=not rule.buffMissing or aura(rule.buffMissing,'player','HELPFUL')==false
   local verified=not FC.ForeverSpellCatalog or FC.ForeverSpellCatalog.classes[spec.class].spells[rule.name]~=nil
   if s and verified and proc and needsBuff and (not rule.movingOnly or moving) and (not rule.talent or talents[rule.talent]) and (not rule.area or mode=='aoe') and required and dotMissing and (not rule.execute or hp and hp<=rule.execute)
    and (not rule.combo or type(combo)=='number' and combo>=rule.combo) and not used[s.id]
    and (not rule.comboAtMost or type(combo)=='number' and combo<=rule.comboAtMost)
    and selfRulesPass(rule,s,applied,resources) and ready(s,not (rule.self or rule.ground) and (rule.unit or 'target') or nil,moving) then
    local costs=resourceCosts(s.id);local affordable=true
    if step>1 and not costs then affordable=false end
    for kind,cost in pairs(costs or {}) do
     if resources[kind]==nil then resources[kind]=read(UnitPower,'player',kind) end
     if type(resources[kind])~='number' or resources[kind]<cost then affordable=false end
    end
    if affordable then
     chosen=s;s.costs=costs;s.reason=ruleReason(rule,spec,mode)
     local note=FC.ForeverSpellNotes and FC.ForeverSpellNotes[spec.class] and FC.ForeverSpellNotes[spec.class][rule.name]
     if note then s.reason=s.reason..' '..note end
     if rule.selfBuff or rule.stance then applied['self:'..rule.name]=true end
     for kind,cost in pairs(costs or {}) do resources[kind]=resources[kind]-cost end
     if not repeatable[rule.name] or rule.dot then used[s.id]=true end
     if rule.dot then applied[rule.name]=true end
     if rule.consumes then consumed[rule.consumes]=true;applied[rule.consumes]=nil end
     if rule.buff then usedBuff[rule.buff]=true end
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
 local s=settings();local scope=itemScope()
 local automatic=FC.CraftedItems and FC.CraftedItems:GetRecommendation()
 local ids={};for id in pairs(s.items)do if scope and s.itemScopes[id]==scope then ids[#ids+1]=id end end
 local priorities={health=1,mana=2,burst=5}
 table.sort(ids,function(a,b)local pa,pb=priorities[s.items[a]] or 9,priorities[s.items[b]] or 9;if pa==pb then return a<b end;return pa<pb end)
 for _,id in ipairs(ids) do
  if automatic and automatic.itemPriority<(priorities[s.items[id]] or 9)then return automatic end
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
 return automatic
end
-- The ready tank spell with the most threat per cast at the player's level, from SimGear's sims
-- (Data/TankThreat.lua). Only spells in the tank's own priority are considered, area ones only in area
-- mode. nil without data or without a ready spell: callers fall back to the priority order.
local TANK_PROFILE={PALADIN=function()return P.PALADIN[2] end,WARRIOR=function()return P.WARRIOR[3] end,DRUID=function()return bear end}
function Live:BestThreatSpell()
 local data=FC.TankThreat
 -- Pre-tuning threat simulations cannot rank the new coefficients and talents.
 if FC.ForeverSpellCatalog and (not data or data.tuningRevision~=FC.ForeverSpellCatalog.revision) then return nil end
 local _,class=read(UnitClass,'player')
 local spells=data and class and data[class];local profile=TANK_PROFILE[class] and TANK_PROFILE[class]()
 local level=read(UnitLevel,'player')
 if not spells or not profile or type(level)~='number' then return nil end
 local mode=settings().mode
 local moving=read(GetUnitSpeed,'player');moving=type(moving)=='number' and moving>0
 local best,bestValue
 for _,list in ipairs(profile) do
  for _,rule in ipairs(list) do
   local byLevel=spells[rule.name] or spells[(rule.name:gsub(' %(Feral%)$',''))]
   if byLevel and (not rule.area or mode=='aoe') then
    -- The highest simmed level at or below the player's, else the lowest simmed one.
    local pick,lowest
    for lv in pairs(byLevel) do
     if lv<=level and (not pick or lv>pick) then pick=lv end
     if not lowest or lv<lowest then lowest=lv end
    end
    local value=byLevel[pick or lowest]
    local s=resolve(rule.name)
    if s and type(value)=='number' and (not bestValue or value>bestValue) and ready(s,not (rule.self or rule.ground) and (rule.unit or 'target') or nil,moving) then
     best,bestValue=s,value
    end
   end
  end
 end
 return best
end
-- Only compare rotational attacks. Utility, healing, stances and defensive
-- actions can be deliberate encounter responses rather than damage mistakes.
function Live:IsReviewableAttack(class,name)
 if class=='SHAMAN' then
  return name=='Lightning Bolt' or name=='Chain Lightning' or name=='Earth Shock'
   or name=='Flame Shock' or name=='Frost Shock' or name=='Stormstrike' or name=='Fire Nova'
 end
 local function includes(profile)
  for _,rules in ipairs(profile or {}) do for _,rule in ipairs(rules) do
   if rule.name==name and not rule.selfBuff and not rule.stance and rule.unit~='player' then return true end
  end end
 end
 for _,profile in ipairs(P[class] or {}) do if includes(profile) then return true end end
 return class=='DRUID' and includes(bear) or false
end
function Live:ShieldRecommendation()
 local _,class=read(UnitClass,'player')
 if class~='SHAMAN' or read(UnitIsDeadOrGhost,'player')~=false
  or read(UnitCastingInfo,'player') or read(UnitChannelInfo,'player') then return end
 -- Do not replace a chosen shield, or treat unreadable auras as missing.
 for _,name in ipairs({'Lightning Shield','Water Shield','Earth Shield'}) do
  if findAura('player','HELPFUL',name)~=false then return end
 end
 local shield=resolve('Lightning Shield')
 local source=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes.SHAMAN.spells['Lightning Shield']
 for i=#(source and source.ids or {}),1,-1 do
  local id=source.ids[i]
  if read(IsPlayerSpell,id)==true or read(IsSpellKnown,id)==true
   or (C_SpellBook and read(C_SpellBook.IsSpellKnown,id)==true) then
   local data=C_Spell and read(C_Spell.GetSpellInfo,id)
   shield={id=id,name=data and read(function()return data.name end) or 'Lightning Shield',icon=data and read(function()return data.iconID end)}
   break
  end
 end
 if not shield or not ready(shield,nil,false) then return end
 return {spellID=shield.id,spellName=shield.name,icon=shield.icon,message=shield.name,
  reason='Lightning Shield is missing; apply it before your next attack.',situation='buff upkeep',
  selfBuff=true,targetHostile=false,reviewEligible=false,targetGUID=read(UnitGUID,'player'),
  queue={{id=shield.id,name=shield.name,icon=shield.icon}}}
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
 local shield=self:ShieldRecommendation();if shield then return shield end
 local rec=self:ProfileRecommendation()
 if rec then
  local _,class=read(UnitClass,'player')
  local uncertain=rec.situation=='range check unavailable' or rec.situation=='fallback damage choice'
  rec.reviewEligible=not uncertain and rec.spellID~=nil and self:IsReviewableAttack(class,rec.spellName)==true
 end
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
 elseif command=='crafted' and (a=='on' or a=='off') then if FC.CraftedItems then FC.CraftedItems:SetEnabled(a=='on')else s.craftedItems=a=='on'end
 elseif command=='item' and tonumber(a) and tonumber(a)>0 and tonumber(a)==math.floor(tonumber(a)) and (b=='health' or b=='mana' or b=='burst' or b=='off') then
  local scope=itemScope();if b~='off' and not scope then print('Forever Coaching: establish your current specialization before assigning an item.');return end
  s.items[tonumber(a)]=b~='off' and b or nil;s.itemScopes[tonumber(a)]=b~='off' and scope or nil
  s.excludedCraftedItems=s.excludedCraftedItems or {};s.excludedCraftedItems[tonumber(a)]=b=='off' or nil
 else print('Forever Coaching: /fcrotation single | aoe (only when all nearby enemies may be hit); burst on | off; item ID health | mana | burst | off. Assign only items with the matching effect. Burst resets after combat.');return end
 print('Forever Coaching: rotation setting updated.')
 if FC.CraftedItems then FC.CraftedItems:Invalidate()end
end
local events=CreateFrame('Frame');events:RegisterEvent('PLAYER_REGEN_ENABLED');events:RegisterEvent('PLAYER_ENTERING_WORLD')
for _,event in ipairs({'PLAYER_SWING','PLAYER_DEAD','PLAYER_LEAVE_COMBAT','PLAYER_EQUIPMENT_CHANGED'})do pcall(events.RegisterEvent,events,event)end
events:SetScript('OnEvent',function(_,event,...)
 if event=='PLAYER_SWING' then Live:ObserveSwing(...);return end
 Live.swings={}
 if event=='PLAYER_REGEN_ENABLED' or event=='PLAYER_ENTERING_WORLD' then settings().burst=false end
end)
