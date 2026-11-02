const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['Data/LevelingBuilds.lua','Data/Level60Builds.lua','Core/BuildPlanner.lua','Data/AbilityLessons.lua','Data/ForeverSpellCatalog.lua','Data/TalentLessonEffects.lua','Core/TalentLessons.lua','Data/SpecScenarios.lua','Data/ScenarioActions.lua','Data/CombatSituations.lua','Data/ForeverSpellGuidance.lua','Core/SpecScenarios.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local count=0
for class,data in pairs(fc.ForeverSpellCatalog.classes)do
 for name,t in pairs(data.talents)do for rank in pairs(t.ranks)do assert(tonumber(rank) and tonumber(rank)>=1 and tonumber(rank)<=t.maxRank,class..': invalid rank fingerprint '..name)end end
 for _,l in ipairs(fc.AbilityLessons[class])do assert(data.spells[l.name],class..': unsupported lesson '..l.name);assert(#l.ids>0);count=count+1 end
 for _,b in ipairs(fc.BuildPlanner:GetBuilds(class))do
  local result=fc.SpecScenarios:ForPreview(class,b)
   if result.available then for _,scenario in ipairs(result.scenarios)do for _,s in ipairs(scenario.steps)do if s.spell then assert(data.spells[s.spell],class..': unsupported scenario '..s.spell)end end end end
 end
end
assert(count>500,'Every current class spellbook must be covered')
for _,l in ipairs(fc.AbilityLessons.PRIEST)do if l.name=='Abolish Disease' or l.name=='Cure Disease' then assert(l.kind=='dispel' and l.types.Disease,'Preserve disease alerts after splitting combined lessons')end end
for _,l in ipairs(fc.AbilityLessons.DRUID)do if l.name=='Abolish Poison' or l.name=='Cure Poison' then assert(l.kind=='dispel' and l.types.Poison,'Preserve poison alerts after splitting combined lessons')end end
assert(fc.ForeverSpellCatalog.classes.HUNTER.spells['Summon Hawk'])
assert(not fc.ForeverSpellCatalog.classes.HUNTER.spells['Chimera Shot'])
assert(fc.ScenarioActions.profiles.MAGE[2].single.steps[1].when:find('Heating Up',1,true))
for _,s in ipairs(fc.ScenarioActions.profiles.SHAMAN[2].group.steps)do if s.spell=='Chain Lightning' then assert(not s.talent and not s.when:find('instant',1,true))end end
local lesson=fc.TalentLessons:GetLesson('WARRIOR',{title='test'},{name='Bloodthirst',rank=1})
assert(lesson.sourceUrl:find('foreverchanges.pro',1,true) or lesson.provenance:find('reviewed Forever',1,true))
-- Rank signatures prevent an old changed effect from silently returning.
local effect=fc.TalentLessonEffects.WARRIOR.Bloodthirst;local old=effect.description;effect.description='Old invented effect 9999'
local changed=fc.TalentLessons:GetLesson('WARRIOR',{title='test'},{name='Bloodthirst',rank=1});assert(not changed.effect:find('9999',1,true));effect.description=old
print('PASS: '..count..' spell lessons; all class/build scenario actions; current proc rules and stale talent-effect protection.')`);
// The live profile must never contain spells outside the audited toolkit.
const live=fs.readFileSync('addons/ForeverCoaching/Core/LiveRotation.lua','utf8');
for(const retired of ['Living Bomb','Chimera Shot','Explosive Shot','Steady Shot','Envenom','Fan of Knives','Vampiric Touch','Mind Sear','Haunt','Chaos Bolt','Devastate','Shockwave','Crusader Strike','Divine Storm','Mangle (Cat)','Mangle (Bear)'])if(live.includes("spell('"+retired+"'")||live.includes("dot('"+retired+"'"))throw Error('Retired live action: '+retired);
run("CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end\nGetTime=function()return 10 end\n"+live);
run(fs.readFileSync('tests/LiveRotation.Tests.lua','utf8'));
