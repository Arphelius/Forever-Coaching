local FC=ForeverCoaching
local S={};FC.SpecScenarios=S
local specIDs={ [62]=1,[63]=2,[64]=3,[262]=1,[263]=2,[264]=3,[102]=1,[103]=2,[104]=2,[105]=3,[253]=1,[254]=2,[255]=3,[71]=1,[72]=2,[73]=3,[259]=1,[260]=2,[261]=3,[65]=1,[66]=2,[70]=3,[256]=1,[257]=2,[258]=3,[265]=1,[266]=2,[267]=3 }
local function safe(fn,...)
 if not fn then return nil end
 local ok,a,b,c,d,e=pcall(fn,...);if not ok then return nil end
 for _,v in pairs({a,b,c,d,e}) do if issecretvalue and issecretvalue(v) then return nil end end
 return a,b,c,d,e
end
local function primary(class,talents)
 local points={0,0,0};local names={}
 for _,talent in pairs(talents or {}) do if talent.name and (talent.rank or 0)>0 then names[talent.name]=talent.rank end end
 for index,tree in ipairs(FC.TalentTrees and FC.TalentTrees[class] or {}) do for _,node in ipairs(tree.nodes) do points[index]=points[index]+(names[node.name] or 0) end end
 local best,second=0,0;local index
 for i,value in ipairs(points) do if value>best then second,best,index=best,value,i elseif value>second then second=value end end
 if best>0 and best>second then return index end
end
local function buildPrimary(build)
 local points={0,0,0};for _,talent in ipairs(build.talents or {}) do if points[talent.treeIndex] then points[talent.treeIndex]=points[talent.treeIndex]+(talent.rank or 0) end end
 local best,second,index=0,0,nil;for i,value in ipairs(points) do if value>best then second,best,index=best,value,i elseif value>second then second=value end end
 if best>second then return index end
end
local function make(class,index,role,basis,talents,source)
 local profile=FC.SpecScenarioProfiles and FC.SpecScenarioProfiles[class] and FC.SpecScenarioProfiles[class][index]
 if not profile then return {available=false,notice='Your current specialization could not be established. Readable active talent allocation is required; a browsed build is not substituted.'} end
 local spec=profile.name;role=role or profile.role
 local copy={};for k,v in pairs(profile) do copy[k]=v end;profile=copy
 local learnedTalents={};for _,talent in pairs(talents or {}) do if (talent.rank or 0)>0 then learnedTalents[talent.name]=true end end
 if class=='SHAMAN' and index==2 and learnedTalents['Maelstrom Weapon'] then
  profile.single=profile.single..', using observed Maelstrom Weapon stacks to choose an eligible spell follow-up'
  profile.movement='an eligible Maelstrom-shortened spell only if the current stacks actually make it instant, otherwise a learned instant shock while moving safely'
  profile.resource=profile.resource..'; account for the observed Maelstrom cost reduction without assuming full stacks'
 end
 if class=='DRUID' and index==2 and role=='tank' then
  profile.identity='Bear-form threat and survival require deliberate enemy positioning and defensive resource planning.'
  profile.single='learned Bear threat tools on the assigned enemy while maintaining defensive readiness'
  profile.group='learned Bear area-threat tools while keeping controlled enemies outside damage'
  profile.resource='reserve Rage for required threat and defense, and account for mana before shifting for utility'
 end
 if class=='PRIEST' and index==1 and role=='damage' then
  profile.identity='A damage-oriented Discipline allocation uses its learned offensive and resource interactions while retaining support duties.'
  profile.single='learned offensive spells that benefit from your actual Discipline talents'
  profile.group='learned offensive tools on permitted priority targets, with emergency protection when assigned'
  profile.burst='learned offensive/support cooldowns when their recipient can act throughout the window'
  profile.resource='budget mana between offensive casts and required shielding, dispels or emergency healing'
 end
 if class=='DRUID' and index==2 and role=='tank' then spec='Feral (Bear)' end
 if class=='DRUID' and index==2 and role=='damage' then spec='Feral (Cat)' end
 local audit=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[class]
 if audit then basis=basis..' Toolkit reviewed against Forever beta '..FC.ForeverSpellCatalog.build..'.' end
 local out={available=true,spec=spec,class=class,role=role,basis=basis,contribution=profile.identity,sourceUrl=audit and audit.sourceUrl or (source and source.url),
  confidence='Qualitative toolkit guidance, not a measured performance ranking. Use only abilities you have learned; mechanic assignments override throughput priorities.',scenarios={}}
 out.guideReference=FC.GuideSources and FC.GuideSources:ForSpec(class,index,role)
 local effects={}
 for _,talent in pairs(talents or {}) do
  if (talent.rank or 0)>0 and FC.TalentLessons then
   local lesson=FC.TalentLessons:GetLesson(class,{title=spec,role=role},talent)
   effects[#effects+1]={name=talent.name,rank=talent.rank,effect=lesson.effect,sourceUrl=lesson.sourceUrl,provenance=lesson.provenance}
  end
 end
 table.sort(effects,function(a,b)return a.name<b.name end);out.talentEffects=effects
 return out
end
function S:ApplyActions(result,talents,current)
 if not result.available then return result end
 local actionData=FC.ScenarioActions
 local profile=actionData and actionData.profiles[result.class] and actionData.profiles[result.class][result.treeIndex]
 if result.class=='DRUID' and result.role=='tank' and result.treeIndex==2 then profile=actionData and actionData.bear end
 if result.class=='PRIEST' and result.role=='damage' and result.treeIndex==1 then profile=actionData and actionData.disciplineDamage end
 if not profile then result.available=false;result.notice='An exact action checklist has not been authored for this specialization.';return result end
 if actionData.Situations then profile=actionData:Situations(result.class,result.treeIndex,result.role,profile) end
 local ranks={};for _,talent in pairs(talents or {}) do if (talent.rank or 0)>0 then ranks[talent.name]=true end end
 local known={};for _,lesson in ipairs(FC.EncounterCoach and FC.EncounterCoach.lessons or {}) do known[lesson.name]=true;if lesson.canonicalName then known[lesson.canonicalName]=true end end
 local function isKnown(name,pet)
  if known[name] then return true end
  local info=C_Spell and safe(C_Spell.GetSpellInfo,name)
  local id=info and safe(function() return info.spellID end)
  return id and ((not pet and safe(IsPlayerSpell,id)==true) or safe(IsSpellKnown,id,pet==true)==true or (not pet and C_SpellBook and safe(C_SpellBook.IsSpellKnown,id))==true) or false
 end
 local titles={single='Single target (ST)',cleave='Cleave (two targets)',aoe='Area damage / group pressure (AoE)',pvp='PvP: control and kill sequence',kite='Kiting: create distance',heal='Healing: save an ally or yourself',interrupt='Interrupts: stop the cast',burst='Burst and cooldown windows',movement='Movement and positioning',utility='Dispels and group utility',resources='Resource pressure and next pull'}
 local triggers={single='One enemy is the damage priority, or one ally needs focused healing. No urgent interrupt, escape or lifesaving action takes priority.',cleave=result.role=='healer' and 'Two enemies are creating pressure on your assigned allies; maintain focused recovery and handle a second injured ally.' or 'Exactly two permitted enemies can be damaged. Keep a primary kill target.',aoe=result.role=='healer' and 'Several allies are taking damage and more than one can benefit from group recovery.' or 'Three or more attackable enemies are grouped and area damage will not break control.',pvp='You are fighting enemy players. Coordinate the kill target, off-target control and interrupts.',kite='A pursuer will overwhelm you if you stay in place. Create distance; tanks use the agreed route rather than abandoning the group.',heal=result.role=='healer' and 'An assigned ally needs recovery before the next dangerous hit.' or 'You need self-recovery, or an ally will die before another healer can act and you can safely provide a confirmed heal.',interrupt='The enemy begins the dangerous interruptible cast assigned to you. Stop your optional damage sequence.',burst='The agreed damage or healing window begins and the required targets are available.',movement='A mechanic requires a different position. Move before committing another hard cast.',utility='A specific assigned dispel, control or support action is required.',resources='Your remaining resource will not cover the next required action, or the group is preparing another pull.'}
 result.scenarios={};result.confidence='Check priorities from the top again after each action. Use the first action whose conditions are true. Movement, assigned stops and lifesaving actions override optional damage. This is a walkthrough, not a live readiness notification.'
 for _,kind in ipairs({'single','cleave','aoe','pvp','kite','heal','interrupt','burst','movement','utility','resources'}) do
  local recipe=profile[kind];local steps,unavailable={},{}
  for _,instruction in ipairs(recipe.steps) do
   local talentAllowed=not instruction.talent or ranks[instruction.talent] or (current and isKnown(instruction.talent))
   local spellAllowed=not instruction.spell or not current or isKnown(instruction.spell,instruction.pet)
   if talentAllowed and spellAllowed then steps[#steps+1]=instruction else unavailable[#unavailable+1]=instruction.spell..(instruction.talent and ' (requires '..instruction.talent..')' or '') end
  end
  local lines={};for i,instruction in ipairs(steps) do lines[#lines+1]=i..'. '..instruction.when..'\n'..instruction.action..'\nWhy: '..instruction.why end
  if #steps==0 then lines[1]='No verified action is available in this checklist for your current toolkit. Missing or unreadable abilities: '..table.concat(unavailable,', ')..'.' end
  if #steps==0 and kind=='interrupt' then lines[1]='No learned, readable interrupt is confirmed. Ask a teammate to cover the cast; do not assume a slow, dispel or stun will interrupt an immune target. Missing or unchecked: '..table.concat(unavailable,', ')..'.' end
  result.scenarios[#result.scenarios+1]={id=kind,title=titles[kind],trigger=triggers[kind],prepare=recipe.prepare,steps=steps,unavailable=unavailable,avoid=recipe.avoid,
   react=table.concat(lines,'\n\n'),performance=result.contribution,brings=table.concat((function() local names={} for _,s in ipairs((profile.utility or {}).steps or {}) do if s.spell and (not current or isKnown(s.spell)) then names[#names+1]=s.spell end end return names end)(),', ')}
 end
 return result
end
function S:ForPreview(class,build)
 if not build then return {available=false,notice='Select a build above to preview its specialization-specific scenarios. This browser cannot read your live character.'} end
 local index=buildPrimary(build);local result=make(class,index,build.role,'Walkthrough for the selected allocation; live spell learning and readiness are checked in game.',build.talents,build.source)
 result.treeIndex=index;return self:ApplyActions(result,build.talents,false)
end
function S:ForCurrent(context,identityOnly)
 local index=safe(GetPrimaryTalentTree)
 if type(index)~='number' or index<1 or index>3 then index=primary(context.class,context.activeTalents) end
 if not index and GetTalentTabInfo then
  local highest,second=0,0
  for i=1,3 do local _,_,points=safe(GetTalentTabInfo,i);if type(points)=='number' then if points>highest then second,highest,index=highest,points,i elseif points>second then second=points end end end
  if highest<=second then index=nil end
 end
 local modernRole
 local active=safe(GetSpecialization)
 if active then
  local id,_,_,_,role=safe(GetSpecializationInfo,active)
  if not index then index=specIDs[id] end
  if specIDs[id]==index then modernRole=role end
 end
 local assigned=safe(UnitGroupRolesAssigned,'player');local role=assigned=='TANK' and 'tank' or assigned=='HEALER' and 'healer' or assigned=='DAMAGER' and 'damage' or nil
 if not role then role=modernRole=='TANK' and 'tank' or modernRole=='HEALER' and 'healer' or modernRole=='DAMAGER' and 'damage' or nil end
 local matched=context.talentMatch=='Matches selected allocation'
 local source=matched and context.source or nil
 if matched and context.role~='unknown' then role=context.role end
 local result=make(context.class,index,role,'Current talent tree and readable active allocation; not the browsed build.',context.activeTalents,source)
 result.treeIndex=index
 if identityOnly then return result end
 result.availableActions={}
 for _,lesson in ipairs(FC.EncounterCoach and FC.EncounterCoach.lessons or {}) do result.availableActions[#result.availableActions+1]=lesson.name end
 return self:ApplyActions(result,context.activeTalents,true)
end
