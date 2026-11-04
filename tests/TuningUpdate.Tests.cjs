const fs=require('fs'),path=require('path');const f=require('../tools/preview-runtime/node_modules/fengari');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['Data/LevelingBuilds.lua','Data/Level60Builds.lua','Core/BuildPlanner.lua','Core/CustomBuilds.lua','Data/AbilityLessons.lua','Data/ForeverSpellCatalog.lua','Data/TalentLessonEffects.lua','Core/TalentLessons.lua','Data/SpecScenarios.lua','Data/ScenarioActions.lua','Data/CombatSituations.lua','Data/ForeverSpellGuidance.lua','Core/SpecScenarios.lua','Core/GearGuide.lua','UI/GuideSelectors.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local c=fc.ForeverSpellCatalog
assert(c.reviewed=='2026-11-03' and c.revision)
assert(not c.classes.SHAMAN.spells['Lava Burst'])
assert(c.classes.SHAMAN.spells['Lightning Mastery'] and c.classes.SHAMAN.spells['Totemic Call'])
assert(c.classes.ROGUE.spells.Shank and #c.classes.ROGUE.spells.Shank.ids==0,'Unpublished IDs must not be invented')
assert(c.classes.ROGUE.talents.Venom.effects['1']:find('Shank',1,true))
assert(c.classes.ROGUE.talents['Seal Fate'].maxRank==3 and c.classes.ROGUE.talents.Lethality.maxRank==2)
assert(not c.classes.ROGUE.talents.Murder and c.classes.ROGUE.talents['Death Mark'])
assert(c.classes.SHAMAN.spells.Riptide.cooldown=='12 sec cooldown')
assert(c.classes.DRUID.spells['Wild Growth'].cast=='3 sec cast')
local count=0
for _,class in ipairs(fc.BuildPlanner.classes)do
 local catalog=c.classes[class];local trees=fc.TalentTrees[class];local lookup={}
 for ti,tree in ipairs(trees)do for ni,node in ipairs(tree.nodes)do
  local t=assert(catalog.talents[node.name],class..': retired tree talent '..node.name)
  assert(t.maxRank==node.maxRank and t.row==node.row and t.col==node.col and t.treeIndex==ti)
  lookup[node.name]=node
 end end
 for i,build in ipairs(fc.BuildPlanner:GetBuilds(class))do
  assert(build.boardRank==0 and build.evidence=='adapted','Old rankings must expire after tuning')
  assert(not build.source.calculatorUrl or build.source.calculatorUrl=='','Copy must use the current talent string, not an old positional calculator link')
  assert(fc.BuildPlanner:GetPlan(class,60,i),class..':'..build.id..' has invalid encoded points')
  local order=assert(fc.BuildPlanner:GetTalentProgression(class,build))
  local draft=fc.CustomBuilds:Draft({class=class,title=build.title,role=build.role,talents=build.talents,levelingOrder=order})
  local valid,err=fc.CustomBuilds:Validate(draft);assert(valid,class..':'..build.id..': '..tostring(err))
  for _,talent in ipairs(build.talents)do
   assert(lookup[talent.name],class..': retired allocation talent '..talent.name)
   local lesson=fc.TalentLessons:GetLesson(class,build,talent)
   assert(lesson.effect==catalog.talents[talent.name].effects[tostring(talent.rank)],'Every current talent needs its current effect')
  end
  local guide=fc.SpecScenarios:ForPreview(class,build)
  assert(guide.available,class..':'..build.id)
  for _,scenario in ipairs(guide.scenarios)do for _,step in ipairs(scenario.steps)do
   if step.spell then assert(catalog.spells[step.spell],class..': obsolete scenario spell '..step.spell)end
   assert(not (step.why or ''):find('Thousand Cuts',1,true),'Retired proc advice')
  end end
  count=count+1
 end
 local choices=fc.BuildPlanner:GetVisibleSpecBuilds(class,'raids',60)
 assert(#choices>=3,class..': all main specs must remain browsable')
end
local shaman=fc.SpecScenarios:ForPreview('SHAMAN',fc.BuildPlanner:GetBuilds('SHAMAN')[1])
for _,scenario in ipairs(shaman.scenarios)do for _,step in ipairs(scenario.steps)do assert(step.spell~='Lava Burst' and step.spell~='Elemental Mastery')end end
-- A previous index pointing to another current talent cannot be reused silently.
local old={class='ROGUE',title='old',role='damage',talents={{name='Murder',rank=2,treeIndex=1,talentIndex=8}},levelingOrder={{name='Murder',treeIndex=1,talentIndex=8}}}
assert(not fc.CustomBuilds:Validate(fc.CustomBuilds:Draft(old)))
local moved={class='DRUID',title='moved',role='damage',talents={{name='Heart of the Wild',rank=5,treeIndex=2,talentIndex=2}},levelingOrder={}}
for i=1,5 do moved.levelingOrder[i]={name='Heart of the Wild',treeIndex=2,talentIndex=2}end
local draft=fc.CustomBuilds:Draft(moved);assert(draft.ranks['3:2']==5 and fc.CustomBuilds:Validate(draft))
print('PASS: current effects, all nine layouts, '..count..' legal allocations/orders, scenario spell coverage, expired rankings and safe custom-build remapping.')`);
// Parse every addon Lua file, including runtime profiles not executed by the data harness.
for(const dir of ['Core','Data','UI'])for(const name of fs.readdirSync('addons/ForeverCoaching/'+dir).filter(n=>n.endsWith('.lua'))){const file='addons/ForeverCoaching/'+dir+'/'+name;if(lauxlib.luaL_loadstring(L,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(file+': '+to_jsstring(lua.lua_tostring(L,-1)));lua.lua_pop(L,1);}
console.log('PASS: addon Lua syntax.');
const baseline=JSON.parse(fs.readFileSync('docs/research/forever-tuning-baseline.json','utf8'));
run(`assert(ForeverCoaching.ForeverSpellCatalog.revision==${JSON.stringify(baseline.revision)},'The reviewed baseline must match the shipped catalog')`);
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));
run(fs.readFileSync('addons/ForeverCoaching/Core/CombatReview.lua','utf8'));
run(`local fc=ForeverCoaching
local review={character='Fixture-TestRealm',damageSource='BlizzardDamageMeter',playerLevel=60,activeTalents={},damageByAbility={{spellID=403,casts=3,damage=300}}}
ForeverCoachingDB.reviews={review}
assert(fc.CombatReview:GetObservedDamage(403,{},60)==nil,'Pre-tuning measurements cannot calibrate current advice')
review.tuningRevision=fc.ForeverSpellCatalog.revision
assert(fc.CombatReview:GetObservedDamage(403,{},60)==100,'Current same-character, same-talent samples remain usable')
review.tuningRevision='older tuning';assert(fc.CombatReview:GetObservedDamage(403,{},60)==nil)
print('PASS: pre-tuning damage measurements are excluded from current advice.')`);
const {compare}=require('../tools/Check-ForeverTuning.cjs'),changed=structuredClone(baseline);
changed.classes.ROGUE.talents['Boot Knife']='different';delete changed.classes.SHAMAN.spells['Lightning Mastery'];changed.classes.ROGUE.spells['New learned spell']='new';
const diff=compare(baseline,changed);if(diff.length!==3||compare(baseline,baseline).length)throw Error('Tuning checker must detect changed, removed and added source facts');
console.log('PASS: future tuning diff detects additions, removals and changes.');
