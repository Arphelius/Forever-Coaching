const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/TalentArtPreview.Tests.lua','utf8'));
for(const file of ['Data/LevelingBuilds.lua','Data/Level60Builds.lua','Data/TalentBorderStyles.lua','Data/ForeverSpellCatalog.lua','Core/BuildPlanner.lua','Core/CustomBuilds.lua','UI/BlizzardTalentGuide.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;ForeverCoachingDB={};UnitClass=function()return 'Mage','MAGE'end;UnitGUID=function()return 'mage-guid'end
local d=fc.CustomBuilds:New('MAGE');d.name='My Arcane experiment'
local index;for ni,n in ipairs(fc.TalentTrees.MAGE[1].nodes)do if n.row==0 and n.maxRank>=2 then index=ni;break end end
assert(fc.CustomBuilds:Change(d,1,index,1));assert(fc.CustomBuilds:Change(d,1,index,1))
local saved=assert(fc.CustomBuilds:Save(d));assert(fc.CustomBuilds:Select('MAGE',saved.id))
local rank,unspent,locked=0,1,false
fc.ReadLiveTalentState=function()
 local ranks={};for ti,t in ipairs(fc.TalentTrees.MAGE)do for ni,n in ipairs(t.nodes)do ranks[ti..':'..ni]=0 end end
 ranks['1:'..index]=rank
 return ranks,rank,{rank,0,0},unspent,{['1:'..index]=not locked}
end
local build,step,theme=fc:GetSelectedTalentGuidance()
assert(build.id==saved.id and step.rank==1 and step.talentIndex==index and theme.kind=='arcane','Custom selection must drive its next point and artwork')
rank=1;build,step=fc:GetSelectedTalentGuidance();assert(step.rank==2,'Next point must follow saved order after learning')
unspent=0;build,step=fc:GetSelectedTalentGuidance();assert(not step,'Do not highlight without an available point')
unspent=1;locked=true;build,step=fc:GetSelectedTalentGuidance();assert(not step,'Do not highlight a locked talent')
locked=false;rank=2;build,step=fc:GetSelectedTalentGuidance();assert(not step,'Completed partial build must not invent more points')
fc:SetTalentVFXEnabled(false);assert(not fc:IsTalentVFXEnabled());build,step,theme=fc:GetSelectedTalentGuidance();assert(theme.kind=='arcane','Static border setting must retain custom spec artwork')
local fire=fc.CustomBuilds:New('MAGE');fire.name='Custom Fire';assert(fc.CustomBuilds:Change(fire,2,1,1));local fireBuild=assert(fc.CustomBuilds:Save(fire));assert(fc.CustomBuilds:Select('MAGE',fireBuild.id))
build,step,theme=fc:GetSelectedTalentGuidance();assert(step.treeIndex==2 and theme.kind=='fire','Switching custom builds must switch specialization artwork')
UnitClass=function()return 'Druid','DRUID'end
local bear=fc.CustomBuilds:New('DRUID');bear.name='Custom Bear';bear.role='tank';assert(fc.CustomBuilds:Change(bear,2,1,1));local bearBuild=assert(fc.CustomBuilds:Save(bear));assert(fc.CustomBuilds:Select('DRUID',bearBuild.id))
fc.ReadLiveTalentState=function()local ranks={};for ti,t in ipairs(fc.TalentTrees.DRUID)do for ni in ipairs(t.nodes)do ranks[ti..':'..ni]=0 end end;return ranks,0,{0,0,0},1,{}end
build,step,theme=fc:GetSelectedTalentGuidance();assert(step.treeIndex==2 and theme.kind=='feral-tank','Custom Bear must use Bear artwork, not Cat')
print('PASS: saved custom selection, real guidance lookup, next rank after learning, point availability, locked/completed plans and specialization artwork.')`);
