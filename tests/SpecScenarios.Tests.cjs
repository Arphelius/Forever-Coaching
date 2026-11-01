const fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(require('os').tmpdir(),'fc-lua-test-runtime/node_modules/fengari'));
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/LevelingBuilds.lua','addons/ForeverCoaching/Data/Level60Builds.lua','addons/ForeverCoaching/Core/BuildPlanner.lua','addons/ForeverCoaching/Data/SpecScenarios.lua','addons/ForeverCoaching/Data/ScenarioActions.lua','addons/ForeverCoaching/Data/CombatSituations.lua','addons/ForeverCoaching/Core/SpecScenarios.lua'])if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
const test=`
local fc=ForeverCoaching;local scenarios=fc.SpecScenarios
assert(not scenarios:ForPreview('SHAMAN',nil).available)
local count=0
for class,profiles in pairs(fc.SpecScenarioProfiles) do
 for index,profile in ipairs(profiles) do
  GetPrimaryTalentTree=function() return index end
  local s=scenarios:ForCurrent({class=class,role='unknown',talentMatch='Actual allocation unavailable'})
  assert(s.available and #s.scenarios==11 and s.spec:find(profile.name,1,true))
  for _,slide in ipairs(s.scenarios) do assert(slide.performance and slide.brings and slide.prepare and slide.react) end
  count=count+1
 end
end
assert(count==27)
fc.EncounterCoach={lessons={{name='Lightning Bolt'},{name='Earth Shock'},{name='Stormstrike'},{name='Healing Wave'},{name='Lesser Healing Wave'}}}
GetPrimaryTalentTree=function() return 1 end
local elemental=scenarios:ForCurrent({class='SHAMAN',role='healer',talentMatch='Differs from selected allocation'})
assert(elemental.spec=='Elemental' and elemental.role=='damage','A browsed healer plan cannot overwrite the current spec')
GetPrimaryTalentTree=function() return 3 end
local restoration=scenarios:ForCurrent({class='SHAMAN',role='damage',talentMatch='Differs from selected allocation'})
assert(restoration.spec=='Restoration' and restoration.role=='healer')
assert(elemental.scenarios[1].react~=restoration.scenarios[1].react,'Different specs require distinct reactions')
GetPrimaryTalentTree=function() return 2 end
local enhancement=scenarios:ForCurrent({class='SHAMAN',activeTalents={{name='Maelstrom Weapon',rank=5}}})
assert(enhancement.scenarios[1].react:find('Maelstrom',1,true) and enhancement.scenarios[1].react:find('Cast Lightning Bolt',1,true),'Active talents must produce a named follow-up action')
local withoutMaelstrom=scenarios:ForCurrent({class='SHAMAN',activeTalents={{name='Stormstrike',rank=1}}})
assert(not withoutMaelstrom.scenarios[1].react:find('Maelstrom Weapon currently',1,true),'Do not prescribe a proc talent that is not learned')
local interrupt=enhancement.scenarios[7]
assert(interrupt.steps[1].spell=='Earth Shock' and interrupt.steps[1].action:find('Cast Earth Shock',1,true))
assert(interrupt.steps[1].when:find('interruptible',1,true) and interrupt.steps[1].why~='')
assert(not interrupt.react:find('Cure Poison',1,true),'Unlearned abilities must be excluded from current-character actions')
local byId={};for _,slide in ipairs(enhancement.scenarios) do byId[slide.id]=slide end
for _,id in ipairs({'single','cleave','aoe','pvp','kite','heal','interrupt'}) do assert(byId[id] and byId[id].trigger and byId[id].prepare and byId[id].avoid) end
assert(byId.cleave.trigger:find('two',1,true) and byId.aoe.trigger:find('Three',1,true),'Cleave and AoE must have distinct entry conditions')
assert(byId.interrupt.trigger:find('Stop your optional damage',1,true),'Interrupt priority must explicitly override optional damage')
local shamanPreview=scenarios:ForPreview('SHAMAN',{role='damage',talents={{treeIndex=2,name='Maelstrom Weapon',rank=5},{treeIndex=2,name='Stormstrike',rank=1}}})
local previewById={};for _,slide in ipairs(shamanPreview.scenarios) do previewById[slide.id]=slide end
assert(previewById.kite.react:find('Frost Shock',1,true) and previewById.kite.react:find('Ghost Wolf',1,true),'Kiting must identify slow and escape actions')
assert(previewById.heal.react:find('Lesser Healing Wave',1,true),'Healing must name an actual heal')
assert(previewById.pvp.react:find('Purge',1,true),'PvP must include the class control/utility plan')
for _,profile in pairs(fc.ScenarioActions.profiles) do for _,recipes in ipairs(profile) do for _,recipe in pairs(recipes) do
 assert(recipe.prepare~='' and recipe.avoid~='')
 for _,instruction in ipairs(recipe.steps) do assert(instruction.when~='' and instruction.action~='' and instruction.why~='');assert(not instruction.action:find('eligible learned',1,true));if instruction.spell then assert(instruction.action:find(instruction.spell,1,true),'Named action must identify its ability') end end
end end end
GetPrimaryTalentTree=nil
local unavailable=scenarios:ForCurrent({class='SHAMAN',id='selected-enhancement',role='damage'})
assert(not unavailable.available,'Do not substitute selected builds for missing actual state')
local current=scenarios:ForCurrent({class='SHAMAN',activeTalents={{name='Concussion',rank=5}}})
assert(current.spec=='Elemental','Actual ranks can identify the primary talent tree')
for _,class in ipairs({'SHAMAN','DRUID','MAGE','PALADIN','PRIEST','HUNTER','ROGUE','WARLOCK','WARRIOR'}) do
 for _,build in ipairs(fc.BuildPlanner:GetBuilds(class)) do local s=scenarios:ForPreview(class,build);if s.available then assert(#s.scenarios==11) end end
end
print('PASS: 27 specialization profiles, active-spec precedence, unavailable-state handling, actual talent inference and build previews.')
`;
if(lauxlib.luaL_dostring(L,to_luastring(test))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));lua.lua_close(L);
