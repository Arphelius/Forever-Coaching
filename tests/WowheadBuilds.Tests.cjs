const fs=require('fs');const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['Data/LevelingBuilds.lua','Data/ForeverSpellCatalog.lua','Core/BuildPlanner.lua','Core/CustomBuilds.lua','Data/SpecScenarios.lua','Data/WowheadTalentLayouts.lua','Core/WowheadBuilds.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local w=fc.WowheadBuilds;local count=0
for _,class in ipairs(fc.BuildPlanner.classes)do for _,b in ipairs(fc.BuildPlanner:GetBuilds(class))do
 local draft=fc.CustomBuilds:Draft({class=class,title=b.title,role=b.role,talents=b.talents,levelingOrder=b.planningOrder})
 local url,err=w:Export(draft)
 if not url then assert(class=='WARRIOR' and err:find('Raging Blows',1,true),'Only the known source discrepancy may be withheld: '..tostring(err))else
 local imported,why=w:Import(url);assert(imported,tostring(why));assert(not imported.id,'Import must create a new draft')
 assert(#imported.order==#draft.order)
 for key,rank in pairs(draft.ranks)do assert(imported.ranks[key]==rank,'Name-based talent mapping must survive changed columns')end
 for i,pick in ipairs(draft.order)do assert(imported.order[i].treeIndex==pick.treeIndex and imported.order[i].talentIndex==pick.talentIndex,'Preserve the exact saved order')end
 local without=url:match('^(.-)/[^/]+$');local suggested=assert(w:Import(without));assert(suggested.importSource.orderSuggested);assert(fc.CustomBuilds:Validate(suggested))
 count=count+1
 end
end end
assert(count>80,'Cover all supported builds, not only one test class')
local compressed=assert(w:Import('https://www.wowhead.com/forever/talent-calc/mage/v22_t0_r1/0A'))
assert(#compressed.order==2 and compressed.ranks['1:1']==2,'Decode Wowhead full-rank compression')
compressed.name='Imported test';local saved=assert(fc.CustomBuilds:Save(compressed));assert(saved.importSource and saved.evidence=='custom')
assert(not ForeverCoachingDB.activeTalentBuilds,'Import/save must not activate or spend talents')
local restored=fc.CustomBuilds:Draft(saved);assert(w:Export(restored):find('_t0_r1',1,true))
for _,url in ipairs({'https://evil.example/forever/talent-calc/mage/v21','https://wowhead.com.evil.test/forever/talent-calc/mage/v21','https://www.wowhead.com/classic/talent-calc/mage/1','https://www.wowhead.com/forever/talent-calc/mage/v11','https://www.wowhead.com/forever/talent-calc/mage/v26','https://www.wowhead.com/forever/talent-calc/mage/v21/0B','https://www.wowhead.com/forever/talent-calc/mage/v21_t9','https://www.wowhead.com/forever/talent-calc/mage/v21/x','https://www.wowhead.com/forever/talent-calc/mage/v21---1'})do
 local ok,result=pcall(w.Import,w,url);assert(ok and not result,'Malformed/incompatible links must fail safely: '..url)
end
assert(w:Import('https://www.wowhead.com/forever/de/talent-calc/mage/v21/0a'))
local empty=assert(w:Import('https://www.wowhead.com/forever/talent-calc/rogue'));assert(#empty.order==0)
print('PASS: '..count..' Wowhead round trips, all nine classes, column remapping, saved leveling order, compressed order, missing-order planning, persistence and invalid-link rejection.')`);
