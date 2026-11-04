-- Concise original practice summaries of the linked Wowhead Forever guides.
-- Reviewed 2026-11-04. Current Blizzard tuning and the verified spell catalog
-- take precedence over older guide text; see docs/research/wowhead-guides.md.
local FC=ForeverCoaching
local A=FC.ScenarioActions
if not A or not FC.ForeverSpellCatalog then return end
local root='https://www.wowhead.com/forever/guide/classes/'
local function step(class,name,when,why,url,talent)
 local value=A.basic(name,when,why,talent);value.guideUrl=root..url;return value
end
local rogue='rogue/combat/rotation-cooldowns-pve-dps'
A.profiles.ROGUE[2].single=A.recipe('Apply weapon poisons, arrange your Kick assignment and track Slice and Dice.',{
 A.step('Slice and Dice','You have Combo Points and the attack-speed buff needs applying or refreshing.','Cast Slice and Dice on yourself.','Maintains weapon-swing uptime before spending spare points on direct damage.'),
 step('ROGUE','Shank','Energy restoration will fit below your cap and the attack is ready.','Use the current launch resource tool without overcapping Energy.',rogue),
 step('ROGUE','Sinister Strike','You have space for Combo Points and enough Energy left for assigned utility.','Build toward the next useful finisher.',rogue),
 step('ROGUE','Eviscerate','Slice and Dice will stay active, and spare Combo Points can be spent on immediate damage.','Spend excess points after securing your attack-speed uptime.',rogue)},'Do not let Slice and Dice expire merely to spend another damage finisher.')
for _,value in ipairs(A.profiles.ROGUE[2].single.steps)do if value.spell~='Shank'then value.guideUrl=root..rogue else value.tuningUrl=FC.ForeverSpellCatalog.notesUrl end end
FC.ForeverSpellNotes.ROGUE['Slice and Dice']='Maintain this attack-speed buff before spending spare Combo Points on Eviscerate.'
local fury='warrior/fury/rotation-cooldowns-pve-dps'
table.insert(A.profiles.WARRIOR[2].single.steps,1,A.step('Battle Shout','Your assigned attack-power buff is missing or needs refreshing.','Keep Battle Shout active.','Supports your own and your group\'s physical attacks.'))
A.profiles.WARRIOR[2].single.steps[#A.profiles.WARRIOR[2].single.steps+1]=step('WARRIOR','Heroic Strike','Rage is above 65 and spending it will leave enough for core attacks and required utility.','Use excess Rage without starving higher-priority actions.',fury)
local fire='mage/fire/rotation-cooldowns-pve-dps'
table.insert(A.profiles.MAGE[2].single.steps,1,step('MAGE','Scorch','Improved Scorch is selected and its assigned debuff needs stacks or a refresh.','Build the Fire vulnerability before committing the damage window.',fire,'Improved Scorch'))
for _,value in ipairs(A.profiles.MAGE[2].single.steps)do if value.spell=='Pyroblast'then value.when='Three Heating Up stacks are observed and the remaining cast can finish safely.';value.guideUrl=root..fire end end
FC.WowheadGuideReview={reviewed='2026-11-04',primary='Wowhead Forever',
 accepted={root..rogue,root..fury,root..fire,root..'druid/feral/rotation-cooldowns-pve-dps',root..'warlock/destruction/rotation-cooldowns-pve-dps'},
 conflicts={
  {url=root..'shaman/elemental/rotation-cooldowns-pve-dps',excluded='Lava Burst',reason='Removed by the launch tuning.'},
  {url=root..'druid/feral/rotation-cooldowns-pve-dps',excluded='Berserk',reason='Removed by the launch tuning.'},
  {url=root..'paladin/retribution/rotation-cooldowns-pve-dps',excluded='Twist of Light',reason='Removed; old seal behavior is not imported.'},
 }}
-- Reuse only current spell names. Live readiness is checked separately.
if FC.ReconcileForeverScenario then for class in pairs(FC.ForeverSpellCatalog.classes)do FC.ReconcileForeverScenario(class,A.profiles[class])end end
