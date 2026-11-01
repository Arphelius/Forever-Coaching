const assert=require('assert/strict'),fs=require('fs'),vm=require('vm');
const {createClient}=require('../tools/foreverlogs-review.cjs');
class Element{constructor(tag,text=''){this.tag=tag;this.textContent=text;this.children=[];this.value='';this.style={};}append(...nodes){this.children.push(...nodes);}replaceChildren(...nodes){this.children=nodes;}setAttribute(){}add(node){this.children.push(node);}}
async function main(){
 const calls=[];const client=createClient('fixture-stats-key',async(endpoint,key)=>{assert.equal(key,'fixture-stats-key');calls.push(endpoint);if(endpoint==='/phases')return {phases:[{phase_number:1,name:'Beta',is_active:true}]};if(endpoint==='/bosses')return {bosses:[]};return {statistics:{NewClass:{specs:{'New Spec':{avg:100,median:90,min:40,max:200,total_parses:5}}}}};});
 await client.aggregateCatalog();await client.aggregateCatalog();const data=await client.aggregateStatistics({phase:1});await client.aggregateStatistics({phase:1});assert.equal(calls.length,3,'Aggregate requests are cached');assert(!calls.some(c=>c.includes('/reports')),'Statistics must not access combat reports');await assert.rejects(client.aggregateStatistics({phase:1,metric:'invalid'}),/valid/);
 const boards=await client.rankingBoards();assert.equal(boards.boards.length,5);assert.equal(boards.boards[0].rows[0].className,'NewClass');assert(calls.some(c=>c.includes('damageMode=boss-only')));assert(calls.some(c=>c.includes('damageMode=trash')));assert(calls.some(c=>c.includes('role=tank')));assert(!calls.some(c=>c.includes('/reports')));
 const requests=[],window={},host=new Element('section');
 boards.boards[0].rows=Array.from({length:7},(_,i)=>({className:'NewClass',specName:'Spec '+i,value:100-i,rank:i+1,samples:5}));
 const fetch=async(url,options)=>{const body=JSON.parse(options.body);requests.push(body.action);return {ok:true,json:async()=>boards};};
 vm.runInNewContext(fs.readFileSync('tools/talent-preview/log-statistics.js','utf8'),{window,document:{createElement:tag=>new Element(tag)},Option:class extends Element{constructor(text,value){super('option',text);this.value=value;}},fetch});
 const all=(node=host)=>[node,...node.children.flatMap(all)];
 window.CombatReviewPage.render(host);await new Promise(setImmediate);await new Promise(setImmediate);
 assert(all().some(n=>n.textContent==='NewClass'),'Unknown class/spec keys must be rendered dynamically');
 assert(!all().some(n=>n.tag==='select'||n.type==='search'||n.type==='password'),'No filters or search controls');
 assert.equal(all().filter(n=>n.className==='ranking-board').length,5);
 assert(!all().some(n=>n.textContent==='Spec 6'),'Only top five are initially shown');
 all().find(n=>n.tag==='button'&&n.textContent==='Next').onclick();assert(all().some(n=>n.textContent==='Spec 6'));assert(!all().some(n=>n.textContent==='Spec 0'),'Paging replaces rows instead of growing the card');
 assert.deepEqual(requests,['rankingBoards']);
 const path=require('path'),os=require('os');const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari'));
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Core/CombatReview.lua'])if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
 const fixture=`ForeverCoaching.ForeverLogsStatistics={phase_name='Beta',metric='avg_dps',statistics={NewClass={specs={NewSpec={median=90,total_parses=5}}}}};ForeverCoaching.CombatReview:SetSource('foreverlogs');local s=ForeverCoaching.CombatReview:GetLatestSummary();assert(s.headings[1]=='CLASS / SPEC STATISTICS');assert(s.goodText:find('NewSpec',1,true));assert(s.wrongText:find('5 samples',1,true));assert(s.improveText:find('not individual',1,true))`;
 if(lauxlib.luaL_dostring(L,to_luastring(fixture))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));lua.lua_close(L);
 console.log('PASS: aggregate scenario queries, no visible filters, ranking cards, class colors and fixed-size paginated top-five lists.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
