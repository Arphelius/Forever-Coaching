const fs=require('fs');const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['Data/LevelingBuilds.lua','Data/Level60Builds.lua','Core/BuildPlanner.lua','Core/GuideSources.lua','Data/AbilityLessons.lua','Data/ForeverSpellCatalog.lua','Data/TalentLessonEffects.lua','Core/TalentLessons.lua','Data/SpecScenarios.lua','Data/ScenarioActions.lua','Data/CombatSituations.lua','Data/ForeverSpellGuidance.lua','Data/WowheadGuideNotes.lua','Core/SpecScenarios.lua','Core/GearGuide.lua','UI/GuideSelectors.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local count=0
for _,class in ipairs(fc.BuildPlanner.classes)do for _,build in ipairs(fc.BuildPlanner:GetBuilds(class))do
 local original=build.source.url;local source=assert(fc.GuideSources:ForBuild(class,build))
 assert(source.url:find('https://www.wowhead.com/forever/guide/classes/'..class:lower()..'/',1,true)==1)
 assert(fc.BuildPlanner:GetBuildEvidenceUrl(build)==source.url,'Build links resolve the correct class/spec: '..class..' / '..build.id..' '..fc.BuildPlanner:GetBuildEvidenceUrl(build)..' ~= '..source.url)
 assert(build.source.url==original,'Do not relabel allocation evidence as Wowhead')
 local scenarios=fc.SpecScenarios:ForPreview(class,build);assert(scenarios.guideReference.url==source.url)
 local gear=fc.GearGuide:ForBuild(class,build,60);assert(gear.guideReference.url==source.url)
 local lessons=fc.GuideBrowser:LessonsFor(class,build);for _,lesson in ipairs(lessons)do assert(lesson.guideUrl:find('wowhead.com/forever/',1,true),'Lessons have practical guide references');assert(lesson.sourceUrl:find('foreverchanges.pro',1,true),'Factual effect provenance is retained')end
 for _,scenario in ipairs(scenarios.scenarios)do for _,step in ipairs(scenario.steps)do assert(step.spell~='Lava Burst' and step.spell~='Berserk' and step.spell~='Twist of Light','Old guide advice must not restore removed abilities')end end
 count=count+1
end end
assert(fc.GuideSources:ForSpec('DRUID',2,'tank').url:find('overview-pve-tank',1,true))
assert(fc.GuideSources:ForSpec('DRUID',2,'damage').url:find('overview-pve-dps',1,true))
assert(fc.GuideSources:SpellUrl(403)=='https://www.wowhead.com/forever/spell=403' and not fc.GuideSources:SpellUrl(nil))
local rogue=fc.ScenarioActions.profiles.ROGUE[2].single;assert(rogue.steps[1].spell=='Slice and Dice')
local eviscerate;for _,step in ipairs(rogue.steps)do if step.spell=='Eviscerate'then eviscerate=step end end
assert(eviscerate.when:find('Slice and Dice',1,true))
assert(#fc.WowheadGuideReview.conflicts==3)
print('PASS: '..count..' guide references, all classes/specs/roles, Learn/Scenarios/Gear integration, original evidence, reviewed Rogue upkeep and outdated-guide exclusions.')`);
