const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['Data/LevelingBuilds.lua','Data/Level60Builds.lua','Core/BuildPlanner.lua','Data/AbilityLessons.lua','Data/ForeverSpellCatalog.lua','Data/TalentLessonEffects.lua','Core/TalentLessons.lua','Data/SpecScenarios.lua','Data/ScenarioActions.lua','Data/CombatSituations.lua','Data/ForeverSpellGuidance.lua','Core/SpecScenarios.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local count,effects=0,0
for class,data in pairs(fc.ForeverSpellCatalog.classes)do
 for name,spell in pairs(data.spells)do if spell.description then assert(type(spell.description)=='string' and #spell.description>0,class..': invalid actual effect '..name);effects=effects+1 end end
 for name,talent in pairs(data.talents)do for rank,effect in pairs(talent.effects or {})do assert(type(effect)=='string' and not effect:match('^%$'),class..': unresolved rank effect '..name)end end
 for name,t in pairs(data.talents)do for rank in pairs(t.ranks)do assert(tonumber(rank) and tonumber(rank)>=1 and tonumber(rank)<=t.maxRank,class..': invalid rank fingerprint '..name)end end
 for _,l in ipairs(fc.AbilityLessons[class])do assert(data.spells[l.name],class..': unsupported lesson '..l.name);assert(#l.ids>0 or data.spells[l.name].description,'New official spells may await a published ID');count=count+1 end
 for _,b in ipairs(fc.BuildPlanner:GetBuilds(class))do
  local result=fc.SpecScenarios:ForPreview(class,b)
   if result.available then for _,scenario in ipairs(result.scenarios)do for _,s in ipairs(scenario.steps)do if s.spell then assert(data.spells[s.spell],class..': unsupported scenario '..s.spell)end end end end
 end
end
assert(count>500,'Every current class spellbook must be covered')
assert(effects>450,'Import the available spell effects, leaving absent source descriptions explicitly unknown')
for _,l in ipairs(fc.AbilityLessons.PRIEST)do if l.name=='Abolish Disease' or l.name=='Cure Disease' then assert(l.kind=='dispel' and l.types.Disease,'Preserve disease alerts after splitting combined lessons')end end
for _,l in ipairs(fc.AbilityLessons.DRUID)do if l.name=='Abolish Poison' or l.name=='Cure Poison' then assert(l.kind=='dispel' and l.types.Poison,'Preserve poison alerts after splitting combined lessons')end end
assert(fc.ForeverSpellCatalog.classes.HUNTER.spells['Summon Hawk'])
assert(not fc.ForeverSpellCatalog.classes.HUNTER.spells['Chimera Shot'])
local pyro=false;for _,step in ipairs(fc.ScenarioActions.profiles.MAGE[2].single.steps)do if step.spell=='Pyroblast' and step.when:find('Heating Up',1,true)then pyro=true end end;assert(pyro)
for _,s in ipairs(fc.ScenarioActions.profiles.SHAMAN[2].group.steps)do if s.spell=='Chain Lightning' then assert(not s.talent and not s.when:find('instant',1,true))end end
local lesson=fc.TalentLessons:GetLesson('WARRIOR',{title='test'},{name='Bloodthirst',rank=1})
assert(lesson.sourceUrl:find('foreverchanges.pro',1,true) or lesson.provenance:find('reviewed Forever',1,true))
-- Rank signatures prevent an old changed effect from silently returning.
local effect=fc.TalentLessonEffects.WARRIOR.Bloodthirst;local old=effect.description;effect.description='Old invented effect 9999'
local changed=fc.TalentLessons:GetLesson('WARRIOR',{title='test'},{name='Bloodthirst',rank=1});assert(not changed.effect:find('9999',1,true));effect.description=old
print('PASS: '..count..' spell lessons; all class/build scenario actions; current proc rules and stale talent-effect protection.')`);
run(`local fc=ForeverCoaching
local examples={}
for _,choice in ipairs(fc.BuildPlanner:GetVisibleSpecBuilds('MAGE','raids',60))do
 if choice.build then examples[fc.BuildPlanner:GetBuildDisplayName('MAGE',choice.build)]=choice.build end
end
for _,entry in ipairs({{'Fire','Accelerant','Fireball'},{'Frost','Improved Frostbolt','Frostbolt'}})do
 local build=assert(examples[entry[1]]);local chosen
 for _,talent in ipairs(build.talents)do if talent.name==entry[2] then chosen=talent end end
 assert(chosen,'Missing test talent '..entry[2])
 local lesson=fc.TalentLessons:GetLesson('MAGE',build,chosen)
 local reviewed=fc.ForeverSpellCatalog.classes.MAGE.talents[chosen.name]
 if reviewed then assert(lesson.effect==reviewed.effects[tostring(chosen.rank)],'Show the sourced current talent rank, not a generic fallback')
 else assert(lesson.effect:find(entry[3],1,true) and lesson.sourceUrl,'Talents absent from the changes-only list must retain their pinned effect and source')end
 assert(lesson.buildBenefit:find(entry[3],1,true),'Build benefit must identify the affected spell')
end
print('PASS: actual spell descriptions, resolved rank effects and Fireball/Frostbolt-specific talent benefits.')`);
// The live profile must never contain spells outside the audited toolkit.
const live=fs.readFileSync('addons/ForeverCoaching/Core/LiveRotation.lua','utf8');
for(const retired of ['Living Bomb','Chimera Shot','Explosive Shot','Steady Shot','Envenom','Fan of Knives','Vampiric Touch','Mind Sear','Haunt','Chaos Bolt','Devastate','Shockwave','Crusader Strike','Divine Storm','Mangle (Cat)','Mangle (Bear)'])if(live.includes("spell('"+retired+"'")||live.includes("dot('"+retired+"'"))throw Error('Retired live action: '+retired);
run("CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end\nGetTime=function()return 10 end\n"+live);
run(fs.readFileSync('tests/LiveRotation.Tests.lua','utf8'));
