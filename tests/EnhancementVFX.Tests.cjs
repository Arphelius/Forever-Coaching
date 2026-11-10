const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/TalentArtPreview.Tests.lua','utf8')+`
function methods:SetFrameLevel(value)self.level=value end
function methods:GetFrameLevel()return self.level or 10 end
function methods:SetFrameStrata(value)self.strata=value end
function methods:GetFrameStrata()return self.strata or 'TOOLTIP' end
function methods:SetPoint(...)self.point={...}end
function methods:SetTexCoord(...)self.uv={...}end
function methods:SetTexture(value)self.texture=value end
function methods:GetTexCoord()return table.unpack(self.uv or {})end
`);
run(fs.readFileSync('addons/ForeverCoaching/Data/TalentBorderStyles.lua','utf8'));
const guide=fs.readFileSync('addons/ForeverCoaching/UI/BlizzardTalentGuide.lua','utf8');
run(guide.slice(0,guide.indexOf('-- An addon-owned overlay.')));
run(`local owner=CreateFrame('Frame',nil,UIParent);owner:SetFrameLevel(20)
local art=ForeverCoaching:CreateTalentThemeArt(owner)
art.target=CreateFrame('Button',nil,UIParent);art.target:SetFrameLevel(3)
art:SetTheme('enhancement',{});art:Animate(10,42,42)
assert(art.totemBackdrop.shown and art.totemBackdrop.level>owner:GetFrameLevel(),'Totem must not be buried beneath native talent panel backgrounds')
assert(art.enhancementRear.shown and art.authoredTexture.shown,'Both halves of the elemental orbit must be visible')
assert(#art.totemPieces==4)
for _,piece in ipairs(art.totemPieces)do
 assert(piece.shown and piece.width>0 and piece.height>0)
 local x,y=piece.point[4],piece.point[5]
 assert(x+piece.width/2<=-18 or x-piece.width/2>=18 or y+piece.height/2<=-18 or y-piece.height/2>=18,'Totem pieces must leave the icon center readable')
end
local initial=art.totemPieces[1].uv[1];art:Animate(10.2,42,42)
assert(art.totemPieces[1].uv[1]~=initial,'Totem remains synchronized to the animated atlas frame')
art:ShowSimpleBorder(42,42)
assert(not art.totemBackdrop.shown and not art.enhancementRear.shown and not art.authoredTexture.shown,'VFX off hides all full-art layers')
art:Animate(11,42,42);assert(art.totemBackdrop.shown and art.enhancementRear.shown,'VFX on restores totem and full orbit')
art:SetTheme('elemental',{});assert(not art.totemBackdrop.shown and not art.enhancementRear.shown,'Enhancement layers cannot leak into another spec')
local designs=0
art:SetTheme('combat',{});art:Animate(20,42,42);art:Animate(24,42,42)
assert(art.combatSmoke.shown and art.combatBlood.shown,'Combat layers must render together after the intro')
art:ShowSimpleBorder(42,42)
assert(not art.combatSmoke.shown and not art.combatBlood.shown,'VFX off must hide smoke and blood')
art:Animate(25,42,42)
assert(art.combatSmoke.shown and not art.combatBlood.shown,'Re-enabling Combat must restore smoke and restart its intro')
art:SetTheme('arcane',{})
assert(not art.combatSmoke.shown and not art.combatBlood.shown,'Combat layers cannot leak into another spec')
art:SetTheme('combat',{});art:Animate(30,42,42)
assert(not art:ShowSimpleBorder(1500,900),'Static artwork must reject a window-sized target')
assert(not art.combatSmoke.shown and not art.combatBlood.shown and not art.authoredTexture.shown,'Rejected static target must hide every Combat layer')
art:Animate(31,1500,900)
assert(not art.authoredTexture.shown and not art.combatSmoke.shown,'Animated artwork must reject a window-sized target too')
for kind in pairs(ForeverCoaching.TalentSimpleBorders)do
 for _,size in ipairs({32,36,48,64})do
  art:SetTheme(kind,{color={1,1,1},accent={1,.8,.4}})
  art:Animate(12,size,size);art:Animate(12.2,size,size)
  assert(art.authoredTexture.shown,kind..': animated art must be visible')
  for _,time in ipairs({12.5,15.6,22,100})do
   art:Animate(time,size,size)
   for _,value in ipairs(art.authoredTexture.uv)do assert(value==value and value>=0 and value<=1,kind..': atlas coordinates must remain inside its image')end
  end
  if kind=='discipline' then assert(art.authoredTexture.texture:find('Discipline.tga',1,true),'Discipline must use its own atlas')end
  if kind=='holy-priest' then assert(art.authoredTexture.texture:find('HolyPriest.tga',1,true),'Holy Priest must use its own atlas')end
  assert(art:ShowSimpleBorder(size,size),kind..': VFX off must retain its static border')
  assert(not art.authoredTexture.shown and not art.totemBackdrop.shown and not art.enhancementRear.shown,kind..': animated layers must be hidden when VFX is off')
  art:Animate(13,size,size);assert(art.authoredTexture.shown,kind..': VFX must resume after toggling on')
 end
 designs=designs+1
end
assert(designs==29)
print('PASS: all 29 class/spec/hybrid VFX designs at four icon sizes, animation, correct priest atlases, toggle restoration and layer isolation.')
print('PASS: visible totem layering, four exterior segments, unobscured icon, full front/rear orbit, synchronized frames and VFX toggle/spec isolation.')
`);
lua.lua_close(L);
