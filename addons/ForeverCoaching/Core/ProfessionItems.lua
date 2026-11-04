local FC=ForeverCoaching
local Items={};FC.CraftedItems=Items
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a,b,c,d,e,f,g=pcall(fn,...);if not ok then return end
 for _,v in pairs({a,b,c,d,e,f,g})do if issecretvalue and issecretvalue(v)then return end end
 return a,b,c,d,e,f,g
end
local function settings()ForeverCoachingDB=ForeverCoachingDB or {};ForeverCoachingDB.liveRotation=ForeverCoachingDB.liveRotation or {};return ForeverCoachingDB.liveRotation end
function Items:IsEnabled()return settings().craftedItems~=false end
function Items:SetEnabled(value)settings().craftedItems=value==true;self.nextScan=0 end
local function professionRank(id)
 if GetProfessions and GetProfessionInfo then
  local indices={read(GetProfessions)}
  for _,index in pairs(indices)do
   local rank,line=read(function()local _,_,r,_,_,_,skill=GetProfessionInfo(index);return r,skill end)
   if line==id and type(rank)=='number' then return rank end
  end
 end
 -- Classic clients expose localized skill names rather than profession indices.
 local info=C_Spell and read(C_Spell.GetSpellInfo,4036);local name=info and read(function()return info.name end) or read(GetSpellInfo,4036)
 local count=read(GetNumSkillLines)
 if name and type(count)=='number' then for i=1,count do local skill,header,_,rank=read(GetSkillLineInfo,i);if skill==name and not header and type(rank)=='number'then return rank end end end
end
local function ready(item)
 local count=C_Item and read(C_Item.GetItemCount,item.id,false,false,false) or read(GetItemCount,item.id,false,false)
 if type(count)~='number' or count<=0 then return end
 if C_Item and C_Item.RequestLoadItemDataByID then
  Items.requested=Items.requested or {};if not Items.requested[item.id] then read(C_Item.RequestLoadItemDataByID,item.id);Items.requested[item.id]=true end
 end
 local usable=C_Item and read(C_Item.IsUsableItem,item.id);if usable==nil then usable=read(IsUsableItem,item.id)end
 if usable~=true then return end
 local start,duration,enabled
 if C_Container and C_Container.GetItemCooldown then start,duration,enabled=read(C_Container.GetItemCooldown,item.id)else start,duration,enabled=read(GetItemCooldown,item.id)end
 local now=read(GetTime) or 0
 if type(start)~='number' or type(duration)~='number' or (enabled~=1 and enabled~=true) or (start>0 and start+duration>now)then return end
 local name,id
 if C_Item and C_Item.GetItemSpell then name,id=read(C_Item.GetItemSpell,item.id)else name,id=read(GetItemSpell,item.id)end
 if id~=item.spellID or type(name)~='string' then return end
 return name,C_Item and read(C_Item.GetItemIconByID,item.id) or read(GetItemIcon,item.id) or item.icon
end
function Items:GetRecommendation()
 if not self:IsEnabled() or read(UnitAffectingCombat,'player')~=true then return end
 local now=read(GetTime) or 0
 if self.nextScan and now<self.nextScan then return self.cached end
 self.nextScan=now+.25;self.cached=nil
 local s=settings();local _,class=read(UnitClass,'player');local level=read(UnitLevel,'player')
 if not class or type(level)~='number' or read(UnitIsDeadOrGhost,'player')~=false then return end
 local context=FC.EncounterCoach and FC.EncounterCoach.GetBuildContext and FC.EncounterCoach:GetBuildContext()
 local spec=context and FC.SpecScenarios and FC.SpecScenarios:ForCurrent(context,true)
 if spec and spec.class~=class then spec=nil end
 local role=spec and spec.available and spec.role;local tree=spec and spec.treeIndex
 local family=role=='healer' and 'healing' or ((class=='WARRIOR' or class=='ROGUE' or class=='HUNTER' or (class=='DRUID' and tree==2) or (class=='PALADIN' and tree==3) or (class=='SHAMAN' and tree==2)) and 'attack' or 'spell')
 local health,maxHealth=read(UnitHealth,'player'),read(UnitHealthMax,'player');local power=read(UnitPowerType,'player')
 local current,maximum;if type(power)=='number'then current,maximum=read(UnitPower,'player',power),read(UnitPowerMax,'player',power)end
 local hostile=read(UnitExists,'target')==true and read(UnitIsDeadOrGhost,'target')==false and read(UnitCanAttack,'player','target')==true
 local casting=read(UnitCastingInfo,'player') or read(UnitChannelInfo,'player')
 local moving=read(GetUnitSpeed,'player');moving=type(moving)=='number' and moving>0
 local engineering=professionRank(202);local candidates={}
 for _,item in ipairs(FC.ProfessionItems and FC.ProfessionItems.items or {})do
  if level>=item.minLevel and (not item.classes or item.classes[class]) and not (s.excludedCraftedItems and s.excludedCraftedItems[item.id]) and not (s.items and s.items[item.id]) then
   local kind=item.kind;local priority,missing
   if kind=='health' and type(health)=='number' and type(maxHealth)=='number' and health>0 and maxHealth>0 and health/maxHealth<.3 then priority=1;missing=maxHealth-health
   elseif kind=='mana' and power==0 and type(current)=='number' and type(maximum)=='number' and maximum>0 and current/maximum<.2 then priority=2;missing=maximum-current
   elseif kind=='energy' and power==3 and type(current)=='number' and type(maximum)=='number' and maximum-current>=80 then priority=3;missing=maximum-current
   elseif kind=='rage' and power==1 and type(current)=='number' and current<20 then priority=4;missing=(maximum or 100)-current
   elseif kind==family and role and s.burst==true and (hostile or role=='healer') and type(health)=='number' and type(maxHealth)=='number' and maxHealth>0 and health/maxHealth>=.3 then priority=5
   elseif kind=='aoe' and hostile and role and role~='healer' and s.mode=='aoe' and engineering and engineering>=item.skill and not casting and not moving then priority=6 end
   if priority then candidates[#candidates+1]={item=item,priority=priority,useful=missing and math.min(missing,item.amount) or item.amount,waste=missing and math.max(0,item.amount-missing) or 0}end
  end
 end
 table.sort(candidates,function(a,b)if a.priority~=b.priority then return a.priority<b.priority end;if a.useful~=b.useful then return a.useful>b.useful end;if a.waste~=b.waste then return a.waste<b.waste end;return a.item.id<b.item.id end)
 for _,candidate in ipairs(candidates)do
  local item=candidate.item;local name,icon=ready(item)
  if name then
   local reasons={health='Your Health is below 30%; use the ready healing potion.',mana='Your Mana is below 20%; restore it before required spells become unaffordable.',energy='You have room for Thistle Tea\'s Energy return.',rage='Your Rage is low; the ready potion supports your next attacks.',attack='Use the attack-power potion during your chosen burst window.',spell='Use the spell-damage potion during your chosen burst window.',healing='Use the healing-power potion for your planned healing window.',aoe='Area damage is allowed. Place the grenade on permitted enemies without breaking control.'}
   self.cached={itemID=item.id,spellID=item.spellID,spellName=name,icon=icon,message=name,reason=reasons[item.kind],situation='crafted '..item.kind,targetHostile=hostile,encounterPrompt=true,craftedItem=true,itemPriority=candidate.priority,sourceUrl=item.sourceUrl,queue={{id=item.spellID,itemID=item.id,name=name,icon=icon}}}
   return self.cached
  end
 end
end
function Items:Invalidate()self.nextScan=0;self.cached=nil end
local events=CreateFrame('Frame')
for _,event in ipairs({'BAG_UPDATE_DELAYED','SPELL_UPDATE_COOLDOWN','PLAYER_ENTERING_WORLD','UNIT_HEALTH','UNIT_POWER_UPDATE','UNIT_DISPLAYPOWER','PLAYER_REGEN_ENABLED','GET_ITEM_INFO_RECEIVED'})do pcall(events.RegisterEvent,events,event)end
events:SetScript('OnEvent',function(_,event,unit)if event:sub(1,5)~='UNIT_' or unit=='player' then Items:Invalidate()end end)
