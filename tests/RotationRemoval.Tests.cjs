const assert=require('assert'),fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const root='addons/ForeverCoaching/';
for(const name of fs.readdirSync(root).filter(name=>name.endsWith('.toc'))){
 const toc=fs.readFileSync(root+name,'utf8');
 assert(!/Core\\(?:LiveRotation|RotationCoach)\.lua|UI\\(?:CombatHUD|RotationSettings)\.lua/.test(toc));
 for(const file of toc.split(/\r?\n/).filter(line=>line.trim()&&!line.startsWith('#')))assert(fs.existsSync(path.join(root,file.trim())),file);
 assert(toc.indexOf('Core\\TalentSnapshot.lua')<toc.indexOf('Core\\EncounterCoach.lua'));
}
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code){if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['tests/CombatReviewHarness.lua',root+'Core/TalentSnapshot.lua',root+'Core/EncounterCoach.lua',root+'Core/FightRecorder.lua',root+'Core/CombatReview.lua',root+'Core/RoleWarnings.lua'])run(fs.readFileSync(file,'utf8'));
run(`local fc=ForeverCoaching
assert(not fc.LiveRotation and not fc.RotationCoach)
assert(not ForeverCoachingRotationStrip and not ForeverCoachingCombatHUD)
assert(not fc.OpenRotationSettings)
assert(not SlashCmdList or not SlashCmdList.FOREVERCOACHINGROTATION)
GetNumTalents=function()return 1 end
GetTalentInfo=function(tree)return 'Talent '..tree,nil,nil,nil,1,5 end
local talents=fc.TalentSnapshot:GetActiveTalentSnapshot()
assert(talents and talents['Talent 1'].rank==1,'Legacy talent inspection survives removal')
local context=fc.EncounterCoach:GetBuildContext()
assert(context.activeTalents and context.activeTalents['Talent 1'],'Review context retains actual talents')
local recorder=fc.FightRecorder
recorder:Begin();recorder:Record('cast_succeeded',{unit='player',spellID=403})
local fight=recorder:Finish()
assert(fight and #fight.events>0 and recorder:GetLatest()==fight)
assert(recorder:Export(),'Fight export survives removal')`);
lua.lua_close(L);
console.log('PASS: addon manifests, removed rotation UI/command, talent context and fight recording/export without rotation engines.');
