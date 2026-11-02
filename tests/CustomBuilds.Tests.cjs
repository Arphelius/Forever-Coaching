const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['Data/LevelingBuilds.lua','Data/Level60Builds.lua','Data/ForeverSpellCatalog.lua','Core/BuildPlanner.lua','Core/CustomBuilds.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local c=fc.CustomBuilds;local p=fc.BuildPlanner;local playerClass='MAGE'
UnitClass=function()return playerClass,playerClass end;UnitGUID=function()return 'custom-test-character'end
ForeverCoachingDB={settings={language='ro'}}
for _,class in ipairs(p.classes)do
 local baseCount=#p:GetBuilds(class);local draft=c:New(class);draft.name='Test '..class
 for point=1,51 do
  local added=false
  for ti,tree in ipairs(fc.TalentTrees[class])do for ni,node in ipairs(tree.nodes)do
   if not added and c:Change(draft,ti,ni,1)then added=true end
  end end
  assert(added,class..': no legal point at '..point)
 end
 assert(not c:Change(draft,1,1,1),'Cannot exceed 51 points')
 local build,err=c:Save(draft);assert(build,err);assert(build.kind=='custom' and build.points==51)
 assert(#p:GetBuilds(class)==baseCount+1,'Custom build not integrated into planner')
 local plan=assert(p:GetPlan(class,10,baseCount+1));assert(plan.custom and plan.points==51)
 local order,kind=p:GetTalentProgression(class,build);assert(kind=='custom' and #order==51)
 for i,step in ipairs(order)do assert(step.level==i+9 and step.treeIndex==draft.order[i].treeIndex and step.talentIndex==draft.order[i].talentIndex,'Chosen point order was lost')end
 playerClass=class;assert(c:Select(class,build.id));assert(ForeverCoachingDB.activeTalentBuilds['custom-test-character']==build.id)
 assert(ForeverCoachingDB.selectedTalentBuilds['custom-test-character'][class..':leveling']==build.id)
 local edit=c:Draft(build);edit.name='Renamed '..class;local saved=assert(c:Save(edit));assert(saved.id==build.id and #c:List(class)==1,'Editing duplicated a build')
 assert(c:Find(class,saved.id).title==edit.name,'Edited build not persisted')
 assert(c:Delete(class,build.id));assert(not ForeverCoachingDB.activeTalentBuilds['custom-test-character'],'Deleted build stayed active')
 assert(#p:GetBuilds(class)==baseCount,'Delete changed published builds')
end
assert(ForeverCoachingDB.settings.language=='ro','Custom builds must preserve other settings')
local original=fc.TalentTrees.MAGE
fc.TalentTrees.MAGE={{name='test',nodes={{name='Foundation',spellId=1,maxRank=5,row=0,col=0},{name='Choice',spellId=2,maxRank=5,row=0,col=1},{name='Gate',spellId=3,maxRank=1,row=1,col=0,requires={name='Foundation',rank=5}}}},{name='two',nodes={}},{name='three',nodes={}}}
local draft=c:New('MAGE');assert(not c:Change(draft,1,3,1),'Tier gate ignored')
for i=1,4 do assert(c:Change(draft,1,1,1))end;assert(c:Change(draft,1,2,1));assert(not c:Change(draft,1,3,1),'Prerequisite ignored')
assert(c:Change(draft,1,1,1));assert(c:Change(draft,1,3,1));assert(not c:Change(draft,1,1,-1),'Cannot remove a dependency in use')
assert(draft.ranks['1:1']==5,'Failed change mutated the allocation')
assert(not c:Change(draft,1,1,1),'Rank cap ignored')
draft.name='';assert(not c:Save(draft),'Empty name saved')
draft.name='Experiment';playerClass='WARRIOR';local build=assert(c:Save(draft));assert(not c:Select('MAGE',build.id),'Wrong-class build activated')
fc.TalentTrees.MAGE=original
print('PASS: all nine calculators, rank/tier/prerequisite rules, 51-point budget, point order, save/edit/delete, selection and planner integration.')`);
