local FC=ForeverCoaching
local Lessons={}
FC.TalentLessons=Lessons
local function contains(text,term) return text:find(term,1,true)~=nil end
local function buildBenefit(class,build,effect)
 local lower=effect:lower();local totals={0,0,0};local selected={}
 for _,talent in ipairs(build.talents or {}) do selected[talent.name]=true;if totals[talent.treeIndex] then totals[talent.treeIndex]=totals[talent.treeIndex]+(talent.rank or 0) end end
 local tree=1;for i=2,3 do if totals[i]>totals[tree] then tree=i end end
 local data=FC.ScenarioActions;local profile=data and data.profiles[class] and data.profiles[class][tree]
 if class=='DRUID' and build.role=='tank' then profile=data and data.bear end
 if class=='PRIEST' and tree==1 and build.role=='damage' then profile=data and data.disciplineDamage end
 local spells=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[class] and FC.ForeverSpellCatalog.classes[class].spells or {}
 local names,used={},{}
 for _,step in ipairs(profile and profile.single and profile.single.steps or {}) do
  if step.spell and (not step.talent or selected[step.talent]) then names[#names+1]=step.spell;used[step.spell]=true end
 end
 local named={};for name in pairs(spells) do if lower:find(name:lower(),1,true) then named[#named+1]=name end end
 table.sort(named,function(a,b)return #a>#b end)
 local affected={};local school
 for _,value in ipairs({'arcane','fire','frost','shadow','holy','nature'}) do if lower:find(value..' spell',1,true) or lower:find(value..' damage',1,true) then school=value;break end end
 for _,name in ipairs(names) do
  local included=#named==0
  for _,match in ipairs(named) do if name==match then included=true end end
  if included and (not school or ((spells[name] and spells[name].tab or ''):lower():find(school,1,true))) then affected[#affected+1]=name;if #affected==3 then break end end
 end
 local actions=table.concat(affected,', ')
 if #named>0 and #affected==0 then return 'Its benefit applies to '..table.concat(named,', ')..', rather than every ability in this build.' end
 if actions=='' then actions=school and (school:sub(1,1):upper()..school:sub(2)..' spells') or 'the abilities named in the effect' end
 if class=='MAGE' and lower:find('intellect',1,true) and used['Arcane Blast'] then return 'Arcane Blast converts Intellect into spell damage, so this talent supports that interaction in your Arcane build.' end
 if lower:find('mana',1,true) and (lower:find('cost',1,true) or lower:find('restor',1,true) or lower:find('regenerat',1,true)) then return 'Preserves Mana for '..actions..' during longer fights.' end
 if lower:find('cast time',1,true) or lower:find('casting time',1,true) or lower:find('instant',1,true) then return 'Helps fit '..actions..' into shorter casting windows when its conditions are met.' end
 if lower:find('cooldown',1,true) then return 'Lets you plan the affected cooldown around more useful damage, healing or utility windows.' end
 if lower:find('heal',1,true) or lower:find('absorb',1,true) then return 'Supports the healing or protection described above for the targets this build is assigned to keep alive.' end
 if lower:find('hit chance',1,true) or lower:find('chance to hit',1,true) or lower:find('chance to miss',1,true) or (lower:find('resist',1,true) and lower:find('chance',1,true)) then return 'Improves the hit or resistance reliability described above for '..actions..'.' end
 if lower:find('critical',1,true) or lower:find('chance',1,true) then return 'Supports '..actions..' through the critical-strike or proc interaction described above; the trigger is not guaranteed.' end
 if lower:find('threat',1,true) or lower:find('armor',1,true) or lower:find('dodge',1,true) or lower:find('parry',1,true) or lower:find('block',1,true) then return 'Adds the listed threat or defensive benefit while you perform this build\'s role.' end
 if lower:find('speed',1,true) or lower:find('slow',1,true) or lower:find('stun',1,true) or lower:find('immobil',1,true) then return 'Improves the positioning or control options described above, helping you maintain safe uptime or escape pressure.' end
 if lower:find('damage',1,true) or lower:find('attack',1,true) then return 'Supports damage from '..actions..' while you use this build\'s attack plan.' end
 return 'In '..(build.title or 'this build')..', use the specific benefit described above; it does not improve unrelated abilities.'
end
local specific={
 ["Maelstrom Weapon"]={why="Connects melee attacks to spell casts in this hybrid build.",optimal="Watch actual stacks and the resulting cast time/cost. Use a supported spell when the proc fits the mechanic; do not stand in danger to spend it."},
 ["Stormstrike"]={why="Provides the melee setup for your next empowered lightning or Earth Shock hit.",optimal="Use during safe melee uptime, then plan the empowered follow-up. Preserve Earth Shock when an assigned interrupt is imminent."},
 ["Elemental Devastation"]={why="Lets offensive spell critical strikes improve your following melee window.",optimal="Combine safe spell and melee uptime; a proc does not justify entering unsafe melee range."},
 ["Lightning Mastery"]={why="Provides a planned Lightning spell burst window.",optimal="Align the activation with safe Lightning Bolt or Chain Lightning casts; Lava Burst is no longer part of the toolkit."},
 ["Nature's Swiftness"]={why="Converts an eligible cast into an immediate response.",optimal="Reserve for an assigned urgent heal or a useful instant spell during movement. Check the spell's eligibility before spending the cooldown."},
 ["Flurry"]={why="Turns critical strikes into a temporary melee attack-speed benefit.",optimal="Maintain safe melee uptime while the effect is useful; do not chase the buff through required mechanics."},
 ["Riptide"]={why="Adds periodic healing and supports the Chain Heal interaction described in the effect; it has no initial heal.",optimal="Apply ahead of sustained damage. Use a direct heal for immediate recovery; the base cooldown is now 12 seconds."},
 ["Water Shield"]={why="Supports mana sustain, especially when its listed trigger conditions occur.",optimal="Keep the intended elemental shield active and check charges. Refresh when its benefit justifies the action; only one elemental shield can be active."},
}
function Lessons:GetLesson(class,build,talent)
 local rank=talent.rank or 1
 local current=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[class]
 local reviewed=current and current.talents[talent.name]
 local currentEffect=reviewed and reviewed.effects and reviewed.effects[tostring(rank)]
 local source=FC.TalentLessonEffects and FC.TalentLessonEffects[class] and FC.TalentLessonEffects[class][talent.name]
 if not source and currentEffect then source={description=currentEffect,ranks={},observed={},rankSource='reviewed Forever',sourceUrl=current.changesUrl} end
 if not source then return {name=talent.name,rank=talent.rank,effect="No matching effect in the pinned snapshot. Check the current client tooltip.",why="This allocation includes the talent, but its build interaction has not been established.",optimal="Verify the effect before using it to change a combat decision.",provenance="Missing source; no effect inferred from the talent name."} end
 local values=source.ranks[rank]
 local effect=currentEffect or source.description:gsub("{(%d+)}",function(index)
  local value=values and values[tonumber(index)+1]
  if value==nil then return "[unverified value]" end
  return tostring(value)
 end)
 if current and not currentEffect then
  local normalized=effect:lower():gsub('[^a-z0-9]','');local hash=0
  for index=1,#normalized do hash=(hash*31+normalized:byte(index))%2147483647 end
  if reviewed and reviewed.ranks[tostring(rank)]~=hash then
   local note=FC.ForeverSpellNotes and FC.ForeverSpellNotes[class] and FC.ForeverSpellNotes[class][talent.name]
   return {name=talent.name,rank=rank,effect=note or 'The bundled effect does not match the reviewed Forever rank. Open the current source or in-game tooltip for this rank.',
    why=note or 'Use the current Forever effect rather than the older bundled description.',
    optimal='Check the current rank and its trigger before changing a combat decision.',sourceUrl=current.changesUrl,
    provenance='Reviewed against Forever beta '..FC.ForeverSpellCatalog.build..'; outdated or unmatched numeric effects withheld.',
    guidanceBasis='Source review; not an optimal-rotation claim.'}
  end
 end
 local conflicting,confirmed=false,false
 for _,r in ipairs(source.conflictingRanks or {}) do if r==rank then conflicting=true end end
 for _,r in ipairs(source.confirmedRanks or {}) do if r==rank then confirmed=true end end
 if current and reviewed then conflicting=false;confirmed=false end
 if conflicting then effect=effect:gsub("%d+%.?%d*","[check current client]") end
 local lower=effect:lower();local role=build.role or "unspecified"
 local why,optimal
 if contains(lower,"mana") and (contains(lower,"cost") or contains(lower,"restor")) then
  why="Improves the resource budget for the spells or effects named above, helping this "..role.." build sustain its work."
  optimal="Apply the benefit to the listed spells or triggers. Budget mana for the remaining fight and next pull; reduced cost is not a reason to cast into avoidable overhealing or downtime."
 elseif contains(lower,"cooldown") then
  why="Changes how often the affected ability can be available in this build."
  optimal="Plan uses around the changed cooldown and upcoming assignments. Avoid losing a useful activation, but reserve it when the next mechanic requires it."
 elseif contains(lower,"casting time") or contains(lower,"cast time") or contains(lower,"instant") then
  why="Changes the cast windows available to this build and can help fit actions between mechanics."
  optimal="Use the affected spell within the actual shortened or instant window. Check proc conditions and current cast time; required movement takes priority."
 elseif contains(lower,'hit chance') or contains(lower,'chance to hit') or contains(lower,'chance to miss') or (contains(lower,'resist') and contains(lower,'chance')) then
  why='Makes the affected attacks or spells more reliable against the resistance or miss condition described above.'
  optimal='Account for the benefit when checking the current target and hit requirement; additional hit beyond the useful requirement is not another gain.'
 elseif contains(lower,"chance") or contains(lower,"critical") then
  why="Changes critical or proc behavior for the actions named above; its value depends on how often this build uses those actions."
  optimal="Track any resulting proc and duration. Use eligible actions when their conditions are met; a chance-based effect is not guaranteed on the next cast."
 elseif contains(lower,"heal") or contains(lower,"absorb") then
  why="Improves a recovery or protection tool in this "..role.." allocation."
  optimal="Apply it to useful healing or protection, accounting for incoming damage, overhealing and other healers. Follow the exact target and trigger restrictions above."
 elseif contains(lower,"threat") or contains(lower,"armor") or contains(lower,"dodge") or contains(lower,"parry") or contains(lower,"block") then
  why="Contributes to the threat or survival tools named in the effect; this matters when those attacks or defenses are part of your assignment."
  optimal="Meet the equipment, stance, target and trigger requirements. Evaluate survival and threat separately; a damage ranking does not establish defensive value."
 elseif contains(lower,"range") or contains(lower,"speed") or contains(lower,"immobil") or contains(lower,"stun") or contains(lower,"slow") then
  why="Changes positioning or control options that this build can use around encounter mechanics."
  optimal="Plan the affected movement or control around the assigned mechanic. Check immunity, range and control overlap; increased range does not make every position safe."
 elseif contains(lower,"damage") or contains(lower,"attack") then
  why="Improves the listed attacks or damage effects used by this "..role.." build. Its value depends on those attacks reaching useful targets."
  optimal="Use the affected attacks during safe target uptime and meet any conditions above. Do not ignore priority targets, interrupts or movement to chase the bonus."
 else
  why="Adds the capability described above to this allocation. Its usefulness depends on the encounter and the actions the build actually uses."
  optimal="Follow the effect's trigger, target and duration requirements. Plan its use around the encounter assignment and verify the live tooltip before relying on uncertain snapshot values."
 end
 local curated=specific[talent.name];if curated then why,optimal=curated.why,curated.optimal end
 if source.optimal then optimal=source.optimal end
 local observed=false;for _,r in ipairs(source.observed) do if r==rank then observed=true end end
 local basis=observed and "rank observed in source capture" or ("rank basis: "..source.rankSource)
 local provenance="Pinned engine snapshot; "..basis.."; "..(source.audited and "audit corrections applied" or source.reviewed and "source marked reviewed" or "source capture not marked reviewed")..". Live client values may differ."
 if source.qualitative then provenance="Qualitative summary of the linked beta client data or simulator implementation. Exact numeric rank values must be checked in the current client." end
 if confirmed then provenance=provenance.." Numeric sequence matches the pinned beta confirmation record." end
 if conflicting then provenance="The older effect capture's numeric values differ from the pinned beta confirmation record. Conflicting numbers are withheld; check the current client tooltip. "..provenance end
 if current and reviewed then provenance='Effect matches the reviewed Forever '..FC.ForeverSpellCatalog.build..' rank.' end
 return {name=talent.name,rank=rank,effect=effect,why=why,buildBenefit=buildBenefit(class,build,effect),optimal=optimal,sourceUrl=current and reviewed and current.changesUrl or source.sourceUrl,auditUrl=source.auditUrl,confirmationUrl=source.confirmationUrl,provenance=provenance,guidanceBasis="Practical guidance derived from the effect; not a measured claim that this talent is the optimal choice."}
end
