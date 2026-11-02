-- Toolkit audit against ForeverChanges beta 1.60.1.70707 (2026-11-01).
local FC=ForeverCoaching
local catalog=FC.ForeverSpellCatalog
if not catalog then return end
local A=FC.ScenarioActions
local notes={
 WARRIOR={
  ['Rend']='Bloodthrill can enable Overpower against your Rend target; watch the actual trigger.',
  ['Spearing Strike']='An Arms attack with a dismount and bonuses against Giants, Dragonkin and mounted enemies.',
  ['Slam']='Slam has a cooldown; Improved Slam changes its timing without delaying weapon swings.',
  ['Bloodthirst']='Bloodthirst supplies movement speed. Its old on-hit healing is not the current effect; Gore Drinker provides separate healing triggers.',
  ['Whirlwind']='Whirlwind attacks with both melee weapons and can hit four nearby enemies.',
  ['Shield Block']='Shield Block covers two attacks for up to seven seconds, not an unlimited number of hits.',
  ['Shield Wall']='Base Shield Wall reduces damage by 60% for 12 seconds; talents can change its cooldown.',
  ['Thunder Clap']='Thunder Clap works in Battle or Defensive Stance, with a four-target limit.',
  ['Victory Rush']='Use after a qualifying kill while its short eligibility window is active.',
 },
 HUNTER={
  ['Summon Hawk']='Summon Hawk shares its cooldown with Arcane Shot; no more than two hawks can be active.',
  ['Aimed Shot']='Aimed Shot is trained, not a talent unlock.',
  ['Sniper Shot']='Sniper Shot extends the range of your next three Shots.',
  ['Strider Kick']='A melee weapon attack that briefly improves movement speed.',
  ['Mongoose Bite']='Expose Prey can enable Mongoose Bite against a marked enemy; use the observed trigger.',
  ['Explosive Trap']='Trap placement and the shared control plan matter; do not break assigned crowd control.',
 },
 MAGE={
  ['Arcane Blast']='Stacks raise spell damage from Intellect and increase Arcane Blast cost. Budget the stack window.',
  ['Arcane Wrath']='Arcane Wrath gains spell damage from maximum Mana.',
  ['Arcane Missiles']='Missile Barrage provides a faster, free channel; verify that the proc is active.',
  ['Pyroblast']='Heating Up reduces cast time by 25% per stack, up to three stacks; this is not an automatic instant Hot Streak.',
  ['Ice Lance']='Frozen targets or Fingers of Frost enable its bonus.',
  ['Frostfire Bolt']='A trained Frostfire spell with a slow and periodic damage.',
 },
 ROGUE={
  ['Venom']='A combo-point finisher that buffs poison damage and application; it is not Envenom.',
  ['Mutilate']='Attacks with both weapons and rewards attacking a poisoned target.',
  ['Hemorrhage']='Improves your Rupture damage on the target.',
  ['Rupture']='With Thousand Cuts, periodic ticks discount your next Hemorrhage or Backstab.',
  ['Ambush']='Cutthroat can permit Ambush without Stealth; check the actual proc and weapon requirements.',
 },
 PRIEST={
  ['Penance']='Penance can damage an enemy or heal an ally; select the intended recipient.',
  ['Prayer of Mending']='Can jump after damage or non-periodic healing; use on allies who can trigger useful recovery.',
  ['Devouring Plague']='Devouring Contagion can spread its remaining duration when the afflicted target dies.',
  ['Shadow Word: Death']='Early Demise benefits low-health targets; account for the spell\'s self-damage risk.',
  ['Smite']='Power in Light rewards Holy Fire or Shadow Word: Pain setup.',
 },
 WARLOCK={
  ['Wrack']='A channel that amplifies your other Shadow periodic damage on its target.',
  ['Bane of Agony']='Banes are separate from Curses; only one of your Banes can affect a target.',
  ['Bane of Havoc']='Transfers part of damage dealt to other targets; plan which enemy receives the Bane.',
  ['Soul Fire']='Decimation changes Soul Fire after qualifying Shadow Bolt or Searing Pain hits below 35% health.',
  ['Searing Pain']='Demonic Brand connects this cast to your demon\'s next attacks.',
  ['Conflagrate']='Consumes Immolate unless the applicable Shadow and Flame chance prevents consumption.',
 },
 PALADIN={
  ['Holy Strike']='Use the trained Holy weapon attack; this toolkit does not use Crusader Strike.',
  ['Consecration']='Consecration is trained. Place its area where permitted enemies will remain.',
  ['Hammer of the Righteous']='A trained shield-tank attack; check its live equipment and target requirements.',
  ['Holy Shock']='A talent ability usable for damage or healing; choose the correct target.',
  ["Light's Vigil"]='A Holy talent ability; use its current client targeting and duration requirements.',
 },
 DRUID={
  ['Wrath']='Eclipse lets Wrath shorten subsequent Starfire casts; it is not the alternating retail Eclipse cycle.',
  ['Primal Bite']='Bear threat attack; use the correct form and Rage budget.',
  ['Lacerate']='Stacks up to five times and contributes Bear threat and bleeding.',
  ['Shifting Power']='Trades Mana for Energy without requiring a Cat Form powershift.',
  ['Wild Growth']='Heals the target and their party over time; group placement matters.',
  ['Rejuvenation']='Bloom rewards natural expiration; refreshing early can lose that final heal.',
  ['Barkskin']='Usable in animal forms and Moonkin Form; a defensive does not require leaving those forms.',
 },
 SHAMAN={
  ['Lightning Bolt']='Maelstrom Weapon reduces Lightning Bolt cast time and cost; do not extend the talent to Chain Lightning.',
  ['Lava Burst']='Flame Shock increases Lava Burst damage; it does not guarantee a critical strike.',
  ['Fire Nova']='Erupts from your active fire totem, not a separately summoned Fire Nova Totem.',
  ['Elemental Mastery']='Shortens Lightning Bolt and Lava Burst casts and removes Chain Lightning cooldown during its window.',
  ['Riptide']='Chain Heal cast directly on the Riptide target benefits from the healing interaction.',
 },
}
FC.ForeverSpellNotes=notes
-- Reconcile every curated ID with the new spellbook and include newly trained spells.
for class,data in pairs(catalog.classes) do
 local existing,byID={},{}
 for _,lesson in ipairs(FC.AbilityLessons[class] or {}) do existing[lesson.name]=lesson;for _,id in ipairs(lesson.ids)do byID[id]=lesson end end
 local lessons={};local names={}
 for name in pairs(data.spells) do names[#names+1]=name end;table.sort(names)
 for _,name in ipairs(names) do
  local spell=data.spells[name];local old=existing[name]
  if not old then for _,id in ipairs(spell.ids)do if byID[id] then old=byID[id];break end end end
  local entry={ids=spell.ids,name=name,kind=old and old.kind or 'spellbook',types=old and old.types,
   why=(notes[class] or {})[name] or (old and old.why) or 'Part of the current Forever toolkit. Read the current client effect before choosing a target.',
   when=old and old.when or 'The spell is learned, ready, affordable and appropriate for your assignment.',
   how=old and old.how or 'Check the live tooltip, target requirements and the encounter before using it.',
   sourceUrl=data.sourceUrl,sourceBuild=catalog.build,trainingLevel=spell.level,
   baseCast=spell.cast,baseCost=spell.cost,baseCooldown=spell.cooldown}
  lessons[#lessons+1]=entry
 end
 FC.AbilityLessons[class]=lessons
end
local conditions={
 ['Summon Hawk']='Fewer than two hawks are active, the assigned target is attackable, and the shared Arcane Shot cooldown is ready.',
 ['Arcane Shot']='The shot is ready; account for the shared Summon Hawk cooldown and your build before spending it.',
 ['Mongoose Bite']='A dodge or Expose Prey has actually enabled Mongoose Bite and you have safe melee access.',
 ['Strider Kick']='The learned melee attack is ready and the enemy is safely in weapon range.',
 ['Raptor Strike']='You can safely deliver the melee attack without losing an assigned control action.',
 ['Hammer of Wrath']='The enemy meets the live low-health requirement and the cast can complete safely.',
 ['Conflagrate']='Your Immolate is on this target and consuming it fits your next actions.',
 ['Soul Fire']='A qualifying Decimation proc is observed or a normal Soul Fire cast and shard cost are safe.',
 ['Ambush']='Stealth or an observed Cutthroat proc permits Ambush and its weapon and positioning requirements are met.',
 ['Premeditation']='Stealth and target requirements are met and the extra combo points will not be wasted.',
 ['Cold Snap']='A relevant Frost cooldown is unavailable and resetting it serves the planned encounter window.',
 ['Rupture']='You have combo points and enough target lifetime for the bleed; avoid overwriting useful ticks.',
 ['Eviscerate']='You have combo points and Energy, and a direct finisher fits the remaining target lifetime.',
 ['Wrack']='Your Shadow periodic effects are active on this target and you have a safe channel window.',
 ['Explosive Trap']='A safe placement can damage only the intended enemies without breaking control.',
}
local function action(class,name,when,talent)
 return A.basic(name,when,(notes[class] or {})[name] or 'Use this learned action only when its target and resource requirements are satisfied.',talent)
end
local function set(class,index,kind,names)
 local p=A.profiles[class][index];local steps={}
 for _,name in ipairs(names) do steps[#steps+1]=action(class,name,conditions[name] or 'The ability is learned and ready, its target conditions are met, and no assigned urgent action takes priority.') end
 p[kind]=A.recipe('Check your current Forever toolkit, resources, range and encounter assignment.',steps,'Do not continue through required movement, control or an assigned interrupt.')
end
set('HUNTER',1,'single',{'Summon Hawk','Arcane Shot','Aimed Shot'})
set('HUNTER',2,'single',{'Sniper Shot','Serpent Sting','Aimed Shot','Arcane Shot'})
set('HUNTER',3,'single',{'Strider Kick','Mongoose Bite','Raptor Strike'})
set('HUNTER',3,'group',{'Explosive Trap','Multi-Shot'})
set('MAGE',3,'burst',{'Cold Snap','Frostbolt'})
set('DRUID',1,'burst',{'Wrath','Starfire'})
set('DRUID',2,'burst',{'Shifting Power','Claw'})
set('PRIEST',2,'group',{'Prayer of Mending','Prayer of Healing'})
set('PRIEST',3,'group',{'Devouring Plague','Mind Flay'})
set('WARLOCK',1,'single',{'Corruption','Bane of Agony','Wrack','Shadow Bolt'})
set('WARLOCK',1,'group',{'Rain of Fire'})
set('WARLOCK',1,'burst',{'Wrack','Shadow Bolt'})
set('WARLOCK',2,'single',{'Searing Pain','Corruption','Shadow Bolt'})
set('WARLOCK',2,'burst',{'Searing Pain','Soul Fire'})
set('WARLOCK',3,'single',{'Immolate','Conflagrate','Incinerate'})
set('WARLOCK',3,'burst',{'Immolate','Conflagrate','Shadowburn'})
set('PALADIN',3,'single',{'Holy Strike','Judgement','Hammer of Wrath'})
set('PALADIN',3,'group',{'Consecration','Holy Strike'})
set('PALADIN',3,'burst',{'Holy Strike','Judgement'})
set('ROGUE',1,'group',{'Rupture','Eviscerate'})
set('ROGUE',3,'group',{'Rupture','Hemorrhage'})
set('ROGUE',3,'burst',{'Premeditation','Ambush'})
-- Explicit proc conditions replace imported expansion-era assumptions.
local function prepend(class,index,kind,step)table.insert(A.profiles[class][index][kind].steps,1,step)end
prepend('MAGE',1,'single',action('MAGE','Arcane Wrath','Missile Barrage is absent and a safe cast fits the Mana budget.','Arcane Wrath'))
A.profiles.MAGE[2].prepare='Watch Heating Up stacks and the actual Pyroblast cast time; reserve Counterspell.'
A.profiles.MAGE[2].single.steps[1]=action('MAGE','Pyroblast','Heating Up has reduced its cast time enough for the safe cast window.','Heating Up')
for _,s in ipairs(A.profiles.MAGE[2].burst.steps)do if s.spell=='Fireball' then s.when='Combustion is active and a Fireball cast fits before the next required action.' end end
prepend('ROGUE',1,'single',action('ROGUE','Venom','You have combo points, poisons are applied, and the buff needs refreshing.','Venom'))
prepend('PRIEST',1,'single',action('PRIEST','Penance','The assigned ally needs direct recovery and you can safely channel.','Penance'))
prepend('WARRIOR',1,'single',action('WARRIOR','Rend','Bloodthrill is learned, the enemy can bleed, and Rend needs applying.','Bloodthrill'))
prepend('WARRIOR',1,'single',action('WARRIOR','Spearing Strike','The attack is learned and a mounted, Giant or Dragonkin target is in range.','Spearing Strike'))
prepend('DRUID',3,'single',action('DRUID','Regrowth','The ally needs its direct heal and periodic recovery; check Bloom before refreshing.'))
if A.bear then
 A.bear.burst=A.recipe('Plan Rage generation and survival before a tanking window.',{
  action('DRUID','Enrage','Extra Rage is needed and the current defensive penalty is safe.'),
  action('DRUID','Primal Bite','The attack is learned and ready in Bear Form, and Rage remains for required defense.')},'Do not trade away survival for optional Rage generation.')
 table.insert(A.bear.single.steps,1,action('DRUID','Primal Bite','The attack is learned and ready in Bear Form, with sufficient Rage.','Primal Bite'))
end
for _,s in ipairs(A.profiles.DRUID[2].burst.steps)do if s.spell=='Shifting Power' then s.when='Energy is low enough to avoid wasting the gain and the Mana cost is affordable.' end end
for _,s in ipairs(A.profiles.WARRIOR[3].single.steps)do if s.spell=='Revenge' then s.when='A block, dodge or parry has enabled Revenge and Defensive Stance is active.' end end
FC.SpecScenarioProfiles.MAGE[2].burst='Combustion during safe Fire uptime; Heating Up shortens Pyroblast without guaranteeing an instant cast'
FC.SpecScenarioProfiles.HUNTER[3].identity='Melee attacks, trap placement and observed Mongoose Bite triggers define the Forever Survival toolkit.'
-- Maelstrom Weapon does not shorten Chain Lightning in Forever.
for _,s in ipairs(A.profiles.SHAMAN[2].group.steps) do if s.spell=='Chain Lightning' then s.when='At least two permitted enemies are in jump range and you can finish the normal cast safely.';s.why='Do not assume Maelstrom Weapon shortens Chain Lightning.';s.talent=nil end end
-- Retire unsupported entries everywhere, including dynamically assembled situations.
local aliases={WARLOCK={['Curse of Agony']='Bane of Agony',['Curse of Doom']='Bane of Doom'},DRUID={['Swipe (Bear)']='Swipe'}}
local function reconcile(class,value,seen)
 if type(value)~='table' then return end;seen=seen or {};if seen[value] then return end;seen[value]=true
 if value.steps then
  local steps={}
  for _,s in ipairs(value.steps) do
   if s.spell then
    s.spell=(aliases[class] or {})[s.spell] or s.spell
    if catalog.classes[class].spells[s.spell] then
     if (notes[class] or {})[s.spell] then s.why=notes[class][s.spell] end
     -- A trained spell must not be hidden behind an obsolete talent gate.
     if s.spell=='Aimed Shot' or s.spell=='Consecration' then s.talent=nil end
     steps[#steps+1]=s
    end
   else steps[#steps+1]=s end
  end
  value.steps=steps
 end
 for _,v in pairs(value) do if type(v)=='table' then reconcile(class,v,seen) end end
end
for class in pairs(catalog.classes) do reconcile(class,A.profiles[class]);reconcile(class,A.shared[class]) end
reconcile('DRUID',A.bear);reconcile('PRIEST',A.disciplineDamage)
local situations=A.Situations
function A:Situations(class,index,role,base)
 local result=situations(self,class,index,role,base);reconcile(class,result);return result
end
FC.ReconcileForeverScenario=reconcile
