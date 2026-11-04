// Preserve named allocations before refreshing positional tree data.
const fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('./preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function value(index){lua.lua_checkstack(L,20);const type=lua.lua_type(L,index);if(type===lua.LUA_TSTRING)return to_jsstring(lua.lua_tostring(L,index));if(type===lua.LUA_TNUMBER)return lua.lua_tonumber(L,index);if(type===lua.LUA_TBOOLEAN)return !!lua.lua_toboolean(L,index);if(type===lua.LUA_TTABLE){index=lua.lua_absindex(L,index);const result={};let count=0,array=true;lua.lua_pushnil(L);while(lua.lua_next(L,index)){const key=value(-2);result[key]=value(-1);count++;if(typeof key!=='number')array=false;lua.lua_pop(L,1);}return array&&count?Array.from({length:count},(_,i)=>result[i+1]):result;}return null;}
const file=path.resolve(__dirname,'../addons/ForeverCoaching/Data/LevelingBuilds.lua');
if(lauxlib.luaL_dostring(L,to_luastring(fs.readFileSync(file,'utf8')))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
lua.lua_getglobal(L,to_luastring('ForeverCoaching'));const data=value(-1);lua.lua_close(L);
if(!process.argv[2])throw Error('Usage: Export-ForeverBuilds.cjs output.json');
fs.writeFileSync(process.argv[2],JSON.stringify({Builds:data.Builds,TalentTrees:data.TalentTrees},null,2)+'\n');
console.log('Saved named allocations to '+process.argv[2]);
