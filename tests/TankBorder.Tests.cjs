// Tank threat on the HUD: a yellow or red border on the action button of the spell to press,
// the same spell beside the threat bar, and nothing left behind once threat is held again.
const fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require(path.join(require('os').tmpdir(),'fc-lua-test-runtime/node_modules/fengari'));
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s,name){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error((name||'test')+': '+to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'),'harness');
run(`
local base=CreateFrame('Frame');local methods=getmetatable(base).__index
TestVertex={}
SPELLS={[61]='Hand of Reckoning',[62]='Holy Shield',[63]='Seal of Righteousness'}
C_Spell={GetSpellName=function(id)return SPELLS[id] end,GetSpellTexture=function(name)return 'icon:'..name end}
GetActionInfo=function(slot)return 'spell',60+slot end
for i=1,3 do local b=CreateFrame('Button','ActionButton'..i);b.action=i end
`,'setup');
run(fs.readFileSync('addons/ForeverCoaching/UI/CombatHUD.lua','utf8'),'CombatHUD.lua');
run(`
local tank=ForeverCoaching.CombatHUDTank
assert(tank and tank.update,'The HUD exposes the tank border updater')
local function glowsOn(button)
 local found={}
 for _,frame in ipairs(TestFrames)do if frame.parts and frame:IsShown() and frame.target==button then found[#found+1]=frame end end
 return found
end
local function colorOf(glow)
 local part=glow.parts[1];return part.vertex or part.vertexColor
end
tank.update({spell='Hand of Reckoning',color='red'})
local red=glowsOn(ActionButton1)
assert(#red==1,'Lost aggro: one border on the taunt button')
assert(#glowsOn(ActionButton2)==0 and #glowsOn(ActionButton3)==0,'Only the taunt button gets the border')
local c=colorOf(red[1]);if c then assert(c[1]==1 and c[2]<.3,'Lost aggro border is red') end
assert(red[1].pulse.playing,'The border pulses gently')
tank.update({spell='Holy Shield',color='yellow'})
assert(#glowsOn(ActionButton1)==0,'The red border clears when the state changes')
local yellow=glowsOn(ActionButton2);assert(#yellow==1,'Threat slipping: one border on the threat spell')
c=colorOf(yellow[1]);if c then assert(c[1]==1 and c[2]>.7 and c[3]<.3,'Slipping border is yellow') end
tank.update(nil)
assert(#glowsOn(ActionButton1)==0 and #glowsOn(ActionButton2)==0,'Threat held: no tank border is left behind')
tank.update({spell='Blessing of Kings',color='red'})
assert(#glowsOn(ActionButton1)+#glowsOn(ActionButton2)+#glowsOn(ActionButton3)==0,'A spell not on the bars draws nothing')
print('PASS: red border on the taunt after a loss, yellow on the threat spell while slipping, cleared when held.')
`,'tank border');
