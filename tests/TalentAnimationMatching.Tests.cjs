const fs=require('fs'),assert=require('assert');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run('ForeverCoaching={}');
run(fs.readFileSync('addons/ForeverCoaching/Data/LevelingBuilds.lua','utf8'));
run(fs.readFileSync('addons/ForeverCoaching/Data/ForeverSpellCatalog.lua','utf8'));
const guide=fs.readFileSync('addons/ForeverCoaching/UI/BlizzardTalentGuide.lua','utf8');
run(guide.slice(guide.indexOf('local function call(fn,'),guide.indexOf('local function selectedBuild()'))+'\n'+
 guide.slice(guide.indexOf('local function matches(button,step)'),guide.indexOf('function FC:GetSelectedTalentGuidance()'))+`
local count,trees,classes=0,0,0
local names={};C_Spell={GetSpellName=function(id)return names[id]end}
C_ClassTalents={GetActiveConfigID=function()return 1 end}
local liveDefinition
C_Traits={GetEntryInfo=function()return {definitionID=1}end,GetDefinitionInfo=function()return liveDefinition end}
for class,layout in pairs(ForeverCoaching.TalentTrees)do
 classes=classes+1
 for ti,tree in ipairs(layout)do
  trees=trees+1
  for ni,node in ipairs(tree.nodes)do
   count=count+1;names={}
   local step={spellId=node.spellId,name=node.name,treeIndex=ti,talentIndex=ni}
   assert(not matches({},step),class..': the talent window itself is not a talent button')
   local liveID=(node.spellId or count)+10000000
   if step.spellId then names[step.spellId]=node.name;assert(matches({GetSpellID=function()return step.spellId end},step),class..': base spell')end
   names[liveID]=node.name
   assert(matches({GetSpellID=function()return liveID end},step),class..': current-rank spell')
   assert(not matches({GetSpellID=function()return liveID end,IsInspecting=function()return true end},step),'Inspect must not highlight')
   liveDefinition={spellID=liveID}
   local traitButton={GetNodeInfo=function()return {entryIDs={1}}end}
   assert(matches(traitButton,step),class..': trait rank spell')
   names[liveID]='Different talent'
   assert(not matches(traitButton,step),class..': wrong talent')
   liveDefinition={spellID=liveID,overrideName=node.name}
   assert(matches(traitButton,step),class..': client override name')
   liveDefinition={}
   assert(not matches(traitButton,step),class..': absent IDs must not match each other')
   if step.spellId then
    names[liveID]='Localized talent';names[step.spellId]='Localized talent'
    assert(matches({GetSpellID=function()return liveID end},step),class..': localized rank name')
   end
  end
 end
end
assert(classes==9 and trees==27)
print('PASS: native animation target matching across '..classes..' classes / '..trees..' talent trees / '..count..' talents; base/current-rank IDs, trait definitions, localization, inspection and wrong-target rejection.')
`);
lua.lua_close(L);
const root='addons/ForeverCoaching/Media/TalentEffects';let atlases=0;
for(const file of fs.readdirSync(root).filter(x=>x.endsWith('.tga'))){
 const data=fs.readFileSync(`${root}/${file}`),w=data.readUInt16LE(12),h=data.readUInt16LE(14);
 assert.equal(data[2],2,file);assert.equal(data[16],32,file);assert.equal(data[17],40,file);
 assert([1024,2048].includes(w)&&h===1024,file+': atlas dimensions');
 assert.equal(data.length,18+w*h*4,file+': complete pixel data');
 const frames=['Affliction.tga','Demonology.tga','Destruction.tga','Arms.tga'].includes(file)?108:file==='SimpleBorders.tga'?26:/Border\.tga$|FeralFangs/.test(file)?1:36;
 for(let f=0;f<frames;f++){
  const x=(f%(w/128))*128,y=Math.floor(f/(w/128))*128;let visible=false;
  for(let yy=y;yy<y+128&&!visible;yy++)for(let xx=x;xx<x+128;xx++)if(data[18+(yy*w+xx)*4+3]){visible=true;break;}
  // Intro/blood layers can intentionally start transparent.
  if(f===frames-1)assert(visible,file+': final used frame unexpectedly empty');
 }
 atlases++;
}
console.log(`PASS: ${atlases} bundled talent atlases have valid dimensions, alpha, complete pixel data and populated final frames.`);
