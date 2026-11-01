// Read the actual Lua catalog/planner and emit a source-coverage report.
// No game frames, combat, networking, credentials or addon settings are used.
const fs=require('fs'),path=require('path'),os=require('os');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(os.tmpdir(),'fc-lua-test-runtime','node_modules','fengari'));
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code){if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['addons/ForeverCoaching/Data/LevelingBuilds.lua','addons/ForeverCoaching/Core/BuildPlanner.lua'])run(fs.readFileSync(file,'utf8'));
run(String.raw`
local p=ForeverCoaching.BuildPlanner
local lines={'# Build source coverage audit','', 'Generated from the bundled catalog and planner. A destination or provisional recommendation is not a measured winner.','', '| Class | Activity | Source-backed picks at preview level 30 | Target levels |','| --- | --- | --- | --- |'}
local missing=0
for _,class in ipairs(p.classes) do
  for index,build in ipairs(p:GetBuilds(class)) do
    local plan,err=p:GetPlan(class,30,index)
    if not plan then error(class..' '..build.id..': '..tostring(err)) end
  end
  for _,activity in ipairs(p.activities) do
    local names,levels={},{}
    for _,choice in ipairs(p:GetSpecRecommendations(class,activity.id,30)) do
      if choice.recommendedIndex then
        names[#names+1]=choice.spec..(choice.provisional and ' (provisional)' or '')
        levels[#levels+1]=tostring(choice.build.maxLevel)
      end
    end
    if #names==0 then missing=missing+1 end
    lines[#lines+1]='| '..class..' | '..activity.title..' | '..table.concat(names,', ')..' | '..table.concat(levels,', ')..' |'
  end
end
lines[#lines+1]=''
lines[#lines+1]='Class/activity combinations without a sourced pick: '..missing..' / 36.'
CoverageReport=table.concat(lines,'\n')
`);
lua.lua_getglobal(L,to_luastring('CoverageReport'));
const report=to_jsstring(lua.lua_tostring(L,-1));
fs.writeFileSync('docs/research/build-coverage-audit.md',report+'\n');
console.log(report);lua.lua_close(L);
