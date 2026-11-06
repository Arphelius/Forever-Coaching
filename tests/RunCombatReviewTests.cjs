// Execute the actual addon Lua against event/UI mocks. This tests control flow,
// not pixel rendering. The pinned Lua runtime is cached outside the addon.
const fs=require('fs'), path=require('path'), https=require('https'), zlib=require('zlib');
const localRuntime=path.resolve('tools/preview-runtime/node_modules');
const root=fs.existsSync(path.join(localRuntime,'fengari/package.json'))?localRuntime:path.join(require('os').tmpdir(),'fc-lua-test-runtime','node_modules');
function get(url){return new Promise((resolve,reject)=>{const r=https.get(url,s=>{const a=[];s.on('data',v=>a.push(v));s.on('end',()=>s.statusCode===200?resolve(Buffer.concat(a)):reject(new Error('HTTP '+s.statusCode)));s.on('error',reject);});r.setTimeout(20000,()=>r.destroy(new Error('timeout')));r.on('error',reject);});}
async function install(name,version){
 const dir=path.join(root,name);if(fs.existsSync(path.join(dir,'package.json')))return;
 const tar=zlib.gunzipSync(await get('https://registry.npmjs.org/'+name+'/-/'+name+'-'+version+'.tgz'));
 for(let n=0;n+512<=tar.length;){const h=tar.subarray(n,n+512);const file=h.subarray(0,100).toString().split('\0')[0];if(!file)break;const size=parseInt(h.subarray(124,136).toString().replace(/\0/g,'').trim()||'0',8);const type=String.fromCharCode(h[156]);const dest=path.resolve(dir,file.replace(/^package\//,''));if(!dest.startsWith(dir+path.sep))throw new Error('Unsafe archive path');if(type==='0'||type==='\0'){fs.mkdirSync(path.dirname(dest),{recursive:true});fs.writeFileSync(dest,tar.subarray(n+512,n+512+size));}n+=512+Math.ceil(size/512)*512;}
}
(async()=>{
 await Promise.all([['fengari','0.1.4'],['sprintf-js','1.1.3'],['readline-sync','1.4.10'],['tmp','0.0.33'],['os-tmpdir','1.0.2']].map(p=>install(...p)));
 const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(root,'fengari'));
 const suites=[
  ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Core/TalentSnapshot.lua','addons/ForeverCoaching/Data/LevelingBuilds.lua','addons/ForeverCoaching/Core/BuildPlanner.lua','addons/ForeverCoaching/Core/EncounterCoach.lua','addons/ForeverCoaching/UI/GuideSelectors.lua','addons/ForeverCoaching/Core/CombatReview.lua','addons/ForeverCoaching/UI/ClassicTheme.lua','addons/ForeverCoaching/ForeverCoaching.lua','tests/CombatReviewFlow.Tests.lua'],
  ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Data/LevelingBuilds.lua','addons/ForeverCoaching/Core/BuildPlanner.lua','tests/BuildPlanner.Tests.lua','addons/ForeverCoaching/UI/ClassicTheme.lua','addons/ForeverCoaching/UI/BuildsWindow.lua','addons/ForeverCoaching/Core/CombatReview.lua','addons/ForeverCoaching/UI/BlizzardTalentGuide.lua','addons/ForeverCoaching/ForeverCoaching.lua','tests/BuildsWindow.Tests.lua'],
 ];
 for(const files of (process.argv.includes('--combat-only')?suites.slice(0,1):suites)){
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 lauxlib.luaL_dostring(L,to_luastring('unpack=unpack or table.unpack'));
 for(const file of files){
  const status=lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(file,'utf8')));
  if(status!==lua.LUA_OK)throw new Error(file+': '+to_jsstring(lua.lua_tostring(L,-1)));
 }
 lua.lua_close(L);
 }
 console.log(process.argv.includes('--combat-only')?'PASS: review flow.':'PASS: review, build budgets/prerequisites, talent milestones and build-page navigation.');
})().catch(e=>{console.error(e.message);process.exitCode=1;});
