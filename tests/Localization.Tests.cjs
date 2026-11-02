const fs=require('fs'),path=require('path'),os=require('os'),vm=require('vm'),assert=require('assert');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));run('ForeverCoaching={};ForeverCoachingDB={}');
for(const file of ['Data/LocaleMessages.lua','Core/Localization.lua','Data/ForeverSpellCatalog.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local l=fc.Localization;assert(l:GetLanguage()=='en')
local label=fc.CreateLocalizedFrame('Frame'):CreateFontString();label:SetText('Combat Review')
local names='Warrior / Fireball / Bloodthirst / Heating Up / Holy Fire / Shield Wall'
for _,code in ipairs({'ro','es','fr','de','pt'})do
 assert(l:SetLanguage(code));assert(ForeverCoachingDB.settings.language==code)
 assert(label.text~='Combat Review');assert(l:Text(names)==names,'Class, spell and talent names changed')
 assert(l:Text('Combat Review: Warrior — Fireball'):find('Warrior — Fireball',1,true))
 local note=l:Text('Why: Maelstrom Weapon reduces Lightning Bolt cast time and cost; do not extend the talent to Chain Lightning.')
 assert(note:find('Maelstrom Weapon',1,true) and note:find('Lightning Bolt',1,true) and note:find('Chain Lightning',1,true))
 assert(not note:find('reduces Lightning Bolt cast time',1,true),'Named spell guidance was not translated')
 assert(l:Text('https://example.test/Combat Review'):find('https://example.test/Combat',1,true))
 local marked=l:Text('|cffff0000Combat Review|r');assert(marked:find('|cffff0000',1,true) and marked:find('|r',1,true))
end
assert(not l:SetLanguage('xx'));assert(l:GetLanguage()=='pt')
assert(l:SetLanguage('en'));assert(label.text=='Combat Review','Switching back must restore original text')
assert(l:Text('Unknown future text')=='Unknown future text','Missing strings need an English fallback')
local original=CreateFrame('Frame');original:SetText('Combat Review');l:SetLanguage('ro');assert(original.text=='Combat Review','Must not translate Blizzard or other addon frames')
print('PASS: six languages, English default, saved choice, live switching, protected names, formatting and scoped widgets.')`);
const context={window:{}};vm.runInNewContext(fs.readFileSync('tools/talent-preview/locale-messages.js','utf8'),context);
for(const code of ['ro','es','fr','de','pt'])assert(Object.keys(context.window.AddonLocaleMessages[code]).length>=170);
console.log('PASS: browser and addon dictionaries cover the same five translations.');
const pending=[],storage={},nodes=[{nodeValue:'Combat Review: Warrior / Fireball / Heating Up',parentElement:{closest:()=>null}},{nodeValue:'https://example.test/Combat Review',parentElement:{closest:()=>null}},{nodeValue:'Combat Review',parentElement:{closest:()=>true}}];
function element(){return {dataset:{},append(){},add(){},setAttribute(){}};}
const browser={window:{AddonLocaleMessages:context.window.AddonLocaleMessages},localStorage:{getItem:k=>storage[k],setItem:(k,v)=>storage[k]=v},queueMicrotask:fn=>pending.push(fn),Option:function(){},MutationObserver:class{observe(){}},NodeFilter:{SHOW_TEXT:4},document:{documentElement:{},body:{},createElement:element,createTextNode:value=>({nodeValue:value}),querySelector:element,createTreeWalker(){let i=0;return {nextNode:()=>nodes[i++]||null}}}};
vm.runInNewContext(fs.readFileSync('tools/talent-preview/localization.js','utf8'),browser);
const api=browser.window.AddonI18n,flush=()=>{while(pending.length)pending.shift()();};
api.setProtectedNames(['Fireball','Heating Up']);flush();
for(const code of ['ro','es','fr','de','pt']){assert(api.setLanguage(code));flush();assert(nodes[0].nodeValue.includes('Warrior / Fireball / Heating Up'));assert(!nodes[0].nodeValue.startsWith('Combat Review'));assert.equal(nodes[2].nodeValue,'Combat Review');assert.equal(browser.document.documentElement.lang,code);assert.equal(storage['fc-language'],code);}
api.setLanguage('en');flush();assert.equal(nodes[0].nodeValue,'Combat Review: Warrior / Fireball / Heating Up');
nodes[0].nodeValue='Talent Builds';api.setLanguage('ro');flush();assert.equal(nodes[0].nodeValue,'Configurații de talente');
console.log('PASS: browser language switching, new rendered text, saved preferences and name/input protection.');
