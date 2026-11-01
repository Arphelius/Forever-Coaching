const fs=require('fs'),path=require('path'),os=require('os');
let f;for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
if(!f)throw Error('Lua test runtime unavailable');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
// Keep assertions in the same chunk as the local mock state.
const guide=fs.readFileSync('addons/ForeverCoaching/UI/BlizzardTalentGuide.lua','utf8');
const vfxSettings=guide.slice(0,guide.indexOf('function FC:CreateTalentThemeArt'));
const borders=fs.readFileSync('addons/ForeverCoaching/Data/TalentBorderStyles.lua','utf8');
run(fs.readFileSync('tests/TalentArtPreview.Tests.lua','utf8')+'\n'+borders+'\n'+vfxSettings+'\n'+fs.readFileSync('addons/ForeverCoaching/UI/TalentArtPreview.lua','utf8')+`
assert(SLASH_FOREVERCOACHINGARTPREVIEW1=='/fcpreview')
local command=assert(SlashCmdList.FOREVERCOACHINGARTPREVIEW)
command('assassination')
assert(selectedKinds[#selectedKinds]=='assassination')
assert(ForeverCoachingTalentArtPreview.shown)
local before=#frames
for _,kind in ipairs({'enhancement','holy-paladin','discipline','holy-priest','shadow-priest','frostfire'}) do
 command(kind);assert(selectedKinds[#selectedKinds]==kind)
end
assert(#frames==before,'Reopening should reuse the window')
local update=assert(ForeverCoachingTalentArtPreview.scripts.OnUpdate)
update(ForeverCoachingTalentArtPreview,.04)
assert(ForeverCoaching:IsTalentVFXEnabled(),'VFX should default to on')
local toggle
for _,frame in ipairs(frames) do if frame.text=='VFX: On' then toggle=frame end end
assert(toggle and toggle.scripts.OnClick,'VFX toggle missing')
local calls=previewArt.animationCalls
toggle.scripts.OnClick()
update(ForeverCoachingTalentArtPreview,.04)
assert(ForeverCoachingDB.talentVFXEnabled==false,'Disabled setting must persist')
assert(not previewArt.owner.shown and previewArt.animationCalls==calls,'Disabled VFX must hide and stop animating')
command('fury');update(ForeverCoachingTalentArtPreview,.04)
assert(selectedKinds[#selectedKinds]=='fury' and not previewArt.owner.shown,'Changing designs must respect VFX off')
toggle.scripts.OnClick();update(ForeverCoachingTalentArtPreview,.04)
assert(ForeverCoachingDB.talentVFXEnabled==true and previewArt.owner.shown,'VFX should resume when enabled')
assert(previewArt.animationCalls>calls)
for _,frame in ipairs(frames) do
 if frame.text=='Icon size: 48' then frame.scripts.OnClick();assert(frame.text=='Icon size: 64') end
end
command('off');assert(not ForeverCoachingTalentArtPreview.shown)
command('');assert(ForeverCoachingTalentArtPreview.shown)
`);
console.log('Talent art preview: command, selection, frame reuse, animation, sizing, and closing passed.');
// Exercise the real renderer when switching from full art to the static border and back.
run(fs.readFileSync('tests/TalentArtPreview.Tests.lua','utf8')+'\n'+borders+'\n'+guide.slice(0,guide.indexOf('-- An addon-owned overlay.'))+`
local owner=CreateFrame('Frame',nil,UIParent)
local art=ForeverCoaching:CreateTalentThemeArt(owner)
art:SetTheme('arms',{})
assert(art.authoredTexture.shown)
assert(art:ShowSimpleBorder(54,54),'Arms must have a static sword border')
assert(not art.authoredTexture.shown and not art.totemBackdrop.shown,'Border mode must hide authored animation')
art:Animate(12,54,54)
assert(art.authoredTexture.shown,'Full animation must return after border mode')
art:SetTheme('fury',{})
assert(art:ShowSimpleBorder(54,54) and art.simpleBorderKind=='fury','Fury must select its own border')
art:SetTheme('arms',{})
assert(art:ShowSimpleBorder(54,54) and art.simpleBorderKind=='arms','Switching back must restore the Arms border')
art:SetTheme('protection-warrior',{})
assert(art:ShowSimpleBorder(54,54) and art.simpleBorderKind=='protection-warrior','Protection must use its own bulwark border')
local count=0
for kind,style in pairs(ForeverCoaching.TalentSimpleBorders) do
 art:SetTheme(kind,{})
 assert(art:ShowSimpleBorder(54,54) and art.simpleBorderKind==kind,'Missing simple border: '..kind)
 assert(not art.authoredTexture.shown and not art.totemBackdrop.shown,'Full VFX leaked into border mode: '..kind)
 count=count+1
end
assert(count==29,'All 29 designs must have simple borders')
art:SetTheme('unknown',{color={1,1,1},accent={1,1,1}})
assert(not art:ShowSimpleBorder(54,54),'Unknown specs must not inherit a previous border')
`);
console.log('All 29 static borders: full VFX, border fallback, restore, and spec isolation passed.');
