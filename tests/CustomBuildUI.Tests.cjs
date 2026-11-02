const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));run("ForeverCoaching={};ForeverCoachingDB={};UnitClass=function()return 'Mage','MAGE'end;UnitGUID=function()return 'mage-guid'end;GetSpellTexture=function(id)return id end;LearnTalent=function()error('Calculator must not spend real talents')end");
for(const file of ['Data/LevelingBuilds.lua','Data/Level60Builds.lua','Data/ForeverSpellCatalog.lua','Core/BuildPlanner.lua','Core/CustomBuilds.lua','UI/CustomBuilds.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local root=CreateFrame('Frame',nil,UIParent);root.HookScript=function(self,event,fn)self.scripts[event]=fn end;fc:BuildCustomTalentPage(root)
local function find(label)for _,frame in ipairs(TestFrames)do if frame.text==label and frame.scripts.OnClick then return frame end end end
local save,use,delete=find('Save custom build'),find('Use this build'),find('Delete build');assert(save and use and delete,'Custom editor controls missing')
local first=fc.TalentTrees.MAGE[1].nodes[1];local node
for _,frame in ipairs(TestFrames)do if frame.icon and frame.icon.texture==first.spellId and frame.scripts.OnClick then node=frame;break end end
assert(node,'Calculator talent button missing');node.scripts.OnClick(node,'LeftButton');save.scripts.OnClick(save)
local builds=fc.CustomBuilds:List('MAGE');assert(#builds==1 and builds[1].points==1,'UI save did not persist chosen point')
assert(not ForeverCoachingDB.activeTalentBuilds,'Saving must not silently activate a build')
use.scripts.OnClick(use);assert(ForeverCoachingDB.activeTalentBuilds['mage-guid']==builds[1].id,'Use build did not activate guidance')
delete.scripts.OnClick(delete);assert(#fc.CustomBuilds:List('MAGE')==1,'Delete must require confirmation')
delete.scripts.OnClick(delete);assert(#fc.CustomBuilds:List('MAGE')==0,'Confirmed delete failed')
print('PASS: calculator clicks, saved allocation, explicit activation, confirmed deletion and no live point spending.')`);
