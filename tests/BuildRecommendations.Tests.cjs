const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['Data/LevelingBuilds.lua','Data/Level60Builds.lua','Core/BuildPlanner.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`
local planner=ForeverCoaching.BuildPlanner
for _,class in ipairs(planner.classes) do
 for _,build in ipairs(planner:GetBuilds(class)) do
  assert(build.maxLevel==60 and build.points==51,class..' partial build must not be bundled: '..build.id)
 end
end
for _,class in ipairs(planner.classes) do
 for specIndex,spec in ipairs(ForeverCoaching.TalentTrees[class]) do
  local complete=false
  for index,build in ipairs(planner:GetBuilds(class)) do
   local totals={0,0,0}
   for _,talent in ipairs(build.talents or {}) do totals[talent.treeIndex]=totals[talent.treeIndex]+talent.rank end
   local primary=1
   for i=2,3 do if totals[i]>totals[primary] then primary=i end end
   if primary==specIndex and build.maxLevel==60 and build.points==51 then
    assert(planner:GetPlan(class,60,index),class..' invalid level 60 plan: '..build.id)
    complete=true
   end
  end
  assert(complete,class..' '..spec.name..' missing full level 60 allocation')
 end
end
for _,class in ipairs(planner.classes) do
 for _,activity in ipairs(planner.activities) do
  for _,level in ipairs({1,10,20,30,40,50,60}) do
   local visible=planner:GetVisibleSpecBuilds(class,activity.id,level)
   for specIndex,spec in ipairs(ForeverCoaching.TalentTrees[class]) do
    local full=false
    for _,choice in ipairs(visible) do
     if choice.specIndex==specIndex and choice.build and choice.build.maxLevel==60 and choice.build.points==51 then
      local order=planner:GetTalentProgression(class,choice.build)
      assert(order and #order==51 and order[51].level==60,class..' '..spec.name..' incomplete visible progression')
      full=true
     end
    end
    assert(full,class..' '..spec.name..' missing visible level 60 build in '..activity.id..' at preview '..level)
   end
   local count=0
   for _,choice in ipairs(visible) do
    if choice.activityRecommended then
     count=count+1
     assert(planner:GetPlan(class,level,choice.index))
     if choice.build.evidence=='adapted' then
      assert(choice.provisional,'Adapted recommendations must remain provisional')
      assert((choice.build.boardRank or 0)==0,'Old simulation ranks must stay expired')
      if activity.id=='pvp' then assert(choice.reason:find('Not validated',1,true),'Retain duel level warning') end
     end
    end
   end
   assert(count>0,class..' missing recommended starting point in '..activity.id..' at '..level)
   for _,choice in ipairs(visible) do
    if choice.fallbackStartingPoint then
     assert(choice.provisional and choice.build.maxLevel==60 and choice.build.points==51)
     assert(planner:GetBuildSummary(choice,activity.id,visible):find('no current',1,true),'Fallback must disclose missing comparisons')
    end
   end
   assert(#visible>0,class..' missing visible builds in '..activity.id)
  end
 end
end
print('PASS: only full level 60 builds are bundled; every talent tree stays visible across four activities and seven preview levels, with complete progression and honest recommendation limits.')
`);
lua.lua_close(L);
