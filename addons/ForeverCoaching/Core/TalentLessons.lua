local FC=ForeverCoaching
local Lessons={}
FC.TalentLessons=Lessons
local function contains(text,term) return text:find(term,1,true)~=nil end
local specific={
 ["Maelstrom Weapon"]={why="Connects melee attacks to spell casts in this hybrid build.",optimal="Watch actual stacks and the resulting cast time/cost. Use a supported spell when the proc fits the mechanic; do not stand in danger to spend it."},
 ["Stormstrike"]={why="Provides the melee setup for your next empowered lightning or Earth Shock hit.",optimal="Use during safe melee uptime, then plan the empowered follow-up. Preserve Earth Shock when an assigned interrupt is imminent."},
 ["Elemental Devastation"]={why="Lets offensive spell critical strikes improve your following melee window.",optimal="Combine safe spell and melee uptime; a proc does not justify entering unsafe melee range."},
 ["Elemental Mastery"]={why="Provides a planned spell burst window instead of only passive throughput.",optimal="Align the activation and its benefiting casts with useful target uptime. Check current client behavior before assuming how many charges or casts benefit."},
 ["Nature's Swiftness"]={why="Converts an eligible cast into an immediate response.",optimal="Reserve for an assigned urgent heal or a useful instant spell during movement. Check the spell's eligibility before spending the cooldown."},
 ["Flurry"]={why="Turns critical strikes into a temporary melee attack-speed benefit.",optimal="Maintain safe melee uptime while the effect is useful; do not chase the buff through required mechanics."},
 ["Riptide"]={why="Adds immediate and periodic healing plus the Chain Heal interaction described in the effect.",optimal="Use on an ally who needs useful healing. Plan any benefiting Chain Heal around nearby injured allies rather than casting it only to consume a bonus."},
 ["Water Shield"]={why="Supports mana sustain, especially when its listed trigger conditions occur.",optimal="Keep the intended elemental shield active and check charges. Refresh when its benefit justifies the action; only one elemental shield can be active."},
}
function Lessons:GetLesson(class,build,talent)
 local source=FC.TalentLessonEffects and FC.TalentLessonEffects[class] and FC.TalentLessonEffects[class][talent.name]
 if not source then return {name=talent.name,rank=talent.rank,effect="No matching effect in the pinned snapshot. Check the current client tooltip.",why="This allocation includes the talent, but its build interaction has not been established.",optimal="Verify the effect before using it to change a combat decision.",provenance="Missing source; no effect inferred from the talent name."} end
 local rank=talent.rank or 1
 local values=source.ranks[rank]
 local effect=source.description:gsub("{(%d+)}",function(index)
  local value=values and values[tonumber(index)+1]
  if value==nil then return "[unverified value]" end
  return tostring(value)
 end)
 local current=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[class]
 if current then
  local reviewed=current.talents[talent.name]
  local normalized=effect:lower():gsub('[^a-z0-9]','');local hash=0
  for index=1,#normalized do hash=(hash*31+normalized:byte(index))%2147483647 end
  if not reviewed or reviewed.ranks[tostring(rank)]~=hash then
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
 if current then conflicting=false;confirmed=false end
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
 if current then provenance='Effect matches the reviewed Forever '..FC.ForeverSpellCatalog.build..' rank.' end
 return {name=talent.name,rank=rank,effect=effect,why="In "..(build.title or "this build")..": "..why,optimal=optimal,sourceUrl=current and current.changesUrl or source.sourceUrl,auditUrl=source.auditUrl,confirmationUrl=source.confirmationUrl,provenance=provenance,guidanceBasis="Practical guidance derived from the effect; not a measured claim that this talent is the optimal choice."}
end
