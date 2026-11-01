const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(require('os').tmpdir(),'fc-lua-test-runtime/node_modules/fengari'));
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/LevelingBuilds.lua','addons/ForeverCoaching/Data/Level60Builds.lua','addons/ForeverCoaching/Core/BuildPlanner.lua','addons/ForeverCoaching/Data/TalentLessonEffects.lua','addons/ForeverCoaching/Core/TalentLessons.lua']){
 if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(file+': '+to_jsstring(lua.lua_tostring(L,-1)));
}
const code=`
local fc=ForeverCoaching
local build={title='Elemental test',role='damage'}
local c=fc.TalentLessons:GetLesson('SHAMAN',build,{name='Concussion',rank=5})
assert(c.effect:find('5%%') and not c.effect:find('{',1,true),'Selected rank values must be interpolated')
assert(c.why:find('Elemental test',1,true) and c.optimal~='')
assert(c.provenance:find('classic',1,true),'Classic-derived ranks must not be labeled verified')
local s=fc.TalentLessons:GetLesson('SHAMAN',build,{name='Stormstrike',rank=1})
assert(s.optimal:find('interrupt',1,true),'Curated interaction must explain the interrupt tradeoff')
local missing=fc.TalentLessons:GetLesson('SHAMAN',build,{name='Unknown fixture',rank=1})
assert(missing.provenance:find('Missing source',1,true))
local total,missingCount=0,0
for _,class in ipairs({'DRUID','HUNTER','MAGE','PALADIN','PRIEST','ROGUE','SHAMAN','WARLOCK','WARRIOR'}) do
 for _,b in ipairs(fc.BuildPlanner:GetBuilds(class)) do
  for _,talent in ipairs(b.talents or {}) do
   local lesson=fc.TalentLessons:GetLesson(class,b,talent)
   total=total+1
   assert(lesson.effect and lesson.why and lesson.optimal)
   assert(not lesson.effect:find('table:',1,true) and not lesson.effect:find('{%d+}'),'No unresolved template or table values')
   if not lesson.sourceUrl then missingCount=missingCount+1;print('MISSING: '..class..' / '..talent.name) end
  end
 end
end
print('Talent lessons: '..total..' allocated entries; '..missingCount..' explicitly missing sources.')
assert(missingCount==0,'Every talent in the bundled build catalog must have an attributed effect lesson')
`;
if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
lua.lua_close(L);
const ui=lauxlib.luaL_newstate();lualib.luaL_openlibs(ui);
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/LevelingBuilds.lua','addons/ForeverCoaching/Core/BuildPlanner.lua','addons/ForeverCoaching/Data/TalentLessonEffects.lua','addons/ForeverCoaching/Core/TalentLessons.lua','addons/ForeverCoaching/UI/EncounterLearning.lua']){
 if(lauxlib.luaL_dostring(ui,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(ui,-1)));
}
const uiCode=`
local fc=ForeverCoaching
local b=fc.BuildPlanner:GetBuilds('SHAMAN')[1]
fc.EncounterCoach={GetBuildContext=function() return {id=b.id,title=b.title,role=b.role,class='SHAMAN',talentMatch='Fixture'} end,RefreshLessons=function() return {} end}
local parent=CreateFrame('Frame',nil,UIParent)
fc:BuildEncounterLearningPage(parent,'Learn')
for _,frame in ipairs(TestFrames) do if frame.parent==parent and frame.text=='Talents in this build' then frame.scripts.OnClick(frame);break end end
local found=false
for _,frame in ipairs(TestFrames) do if frame:IsShown() and frame.text and frame.text:find('What it does:',1,true) then found=true end end
assert(found,'In-game talent toggle must render the actual effect lesson')
`;
if(lauxlib.luaL_dostring(ui,to_luastring(uiCode))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(ui,-1)));
lua.lua_close(ui);
console.log('PASS: rank interpolation, build context, provenance, curated interaction and catalog-wide lesson formatting.');
