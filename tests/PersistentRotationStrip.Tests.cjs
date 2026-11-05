const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['tests/CombatReviewHarness.lua','tests/RotationCoachHarness.lua','addons/ForeverCoaching/Core/RotationCoach.lua','addons/ForeverCoaching/Core/LiveRotation.lua'])run(fs.readFileSync(file,'utf8'));
run(`local fc=ForeverCoaching
TestSpec={available=true,class='SHAMAN',treeIndex=2,role='damage'}
fc.EncounterCoach={GetBuildContext=function()return {class='SHAMAN'}end,GetRecommendation=function()end,
 lessons={{name='Earth Shock',spellID=8042,icon=8042},{name='Lightning Bolt',spellID=403,icon=403}}}
fc.SpecScenarios={ForCurrent=function()return TestSpec end}
UnitIsDeadOrGhost=function()return false end
RotationState.known[8042]=true;RotationState.meleeRange=true;RotationState.attacking=false
InstallAttackButton()
local rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID==6603 and rec.pressRequired and rec.queue[2].id==8042,'Start swings, then ready Earth Shock')
assert(#rec.queue==2,'Before the first native swing, do not fabricate timed follow-ups')
RotationState.attacking=true;rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID==8042 and rec.queue[2].autoAttack,'Running autoattack must not delay a ready shock')
RotationState.meleeRange=false;rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID==403 and rec.situation=='ranged opener','Prefer Lightning Bolt at range even when Earth Shock is ready')
RotationState.combat=true;rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID~=403 and rec.queue[#rec.queue].autoAttack,'After combat starts, Enhancement uses instant attacks and swings instead of repeating the opener')
RotationState.speed=7;rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID~=403,'Do not hard-cast the opener while moving')
RotationState.speed=0;RotationState.known[403]=false;rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID~=403,'The opener must be learned')
RotationState.known[403]=true;RotationState.meleeRange=true;rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID==8042,'Enemy reaching melee immediately switches to instant attacks and swings')
RotationState.combat=false
local cooldown=C_Spell.GetSpellCooldown
C_Spell.GetSpellCooldown=function(id)return id==8042 and {startTime=9,duration=6,isEnabled=true} or cooldown(id)end
rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID==6603 and rec.pressRequired==false,'Swing while Shock recovers; do not repeatedly press Attack')
assert(not rec.reviewEligible,'Passive weapon swings are not scored as missed attack button presses')
RotationState.meleeRange=false;rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID==403,'Out of melee, preserve a ready ranged attack')
RotationState.meleeRange=nil;rec=fc.LiveRotation:GetRecommendation();assert(rec.spellID==403,'Unknown melee range must not invent an autoattack instruction')
assert(rec.queue[#rec.queue].autoAttack,'Unknown melee range must still display Enhancement AUTO as a follow-up')
local unknownRangeRec=fc.LiveRotation:WithShamanSwings({spellID=8042,spellName='Earth Shock',icon=8042,targetHostile=true,
 queue={{id=8042},{id=403},{id=403},{id=403}}},TestSpec)
assert(unknownRangeRec.spellID==8042 and #unknownRangeRec.queue<=4 and unknownRangeRec.queue[#unknownRangeRec.queue].autoAttack,'Reserve a visible AUTO slot even when the spell forecast fills the strip')
fc.LiveRotation:ObserveSwing(2,0)
rec=fc.LiveRotation:GetRecommendation()
assert(rec.queue[#rec.queue].swingEnds==GetTime()+2,'Unknown range still uses Blizzard swing timing')
fc.LiveRotation.swings={}
RotationState.combat=true;rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID==6603 and rec.pressRequired==false,'Unknown range in Enhancement combat cannot fall back to hard-cast Lightning Bolt')
RotationState.meleeRange=false;rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID==6603,'Out-of-range combat must not repeatedly restart the ranged opener')
RotationState.combat=false
RotationState.meleeRange=true
local proc={spellID=403,spellName='Lightning Bolt',icon=403,situation='maelstrom proc',instantCast=true,targetHostile=true}
assert(fc.LiveRotation:WithShamanSwings(proc,TestSpec).spellID==403,'Preserve Maelstrom-enhanced casting')
local partial={spellID=403,spellName='Lightning Bolt',icon=403,situation='maelstrom proc',instantCast=false,targetHostile=true}
assert(fc.LiveRotation:WithShamanSwings(partial,TestSpec).spellID~=403,'A partial Maelstrom cast-time reduction must not replace Enhancement weapon swings')
local interrupt={spellID=8042,situation='interrupt',targetHostile=true}
assert(fc.LiveRotation:WithShamanSwings(interrupt,TestSpec)==interrupt,'Interrupts are never delayed by swings')
TestSpec.treeIndex=1;rec=fc.LiveRotation:GetRecommendation();assert(rec.spellID==403,'Elemental does not receive Enhancement melee advice')
RotationState.combat=true;rec=fc.LiveRotation:GetRecommendation();assert(rec.spellID==403,'Actual Elemental spec retains caster advice during combat')
RotationState.combat=false
TestSpec.treeIndex=2
`);
run(fs.readFileSync('addons/ForeverCoaching/UI/CombatHUD.lua','utf8'));
run(`local fc=ForeverCoaching;local strip=ForeverCoachingRotationStrip
local function tick()ForeverCoachingCombatHUD.scripts.OnUpdate(ForeverCoachingCombatHUD,1);assert(not fc.combatHUDLastError,fc.combatHUDLastError)end
assert(strip:IsShown() and strip.alpha==.12,'Strip exists dimly immediately, before selecting any enemy')
UnitExists=function(unit)return unit=='player'end;tick()
assert(strip:IsShown() and strip.alpha==.12,'Idle/no-target strip stays barely visible')
assert(ForeverCoachingRotationSlot1.icon:GetTexture()==403 and ForeverCoachingRotationSlot2.caption.text=='AUTO','Idle preview starts with Lightning Bolt, followed by weapon swings')
UnitExists=function()return true end;RotationState.combat=true;tick()
assert(strip:IsShown() and strip.alpha==1,'Combat makes the strip fully visible')
assert(not ForeverCoachingRotationSlot1.highlight:IsShown(),'Already running autoattack has no press highlight')
RotationState.attacking=false;tick();assert(ForeverCoachingRotationSlot1.highlight:IsShown(),'Starting autoattack is an actual press instruction')
UnitExists=function(unit)return unit=='player'end;tick();assert(strip:IsShown() and strip.alpha==1,'Losing a target in combat does not hide the strip')
RotationState.combat=false;tick();assert(strip:IsShown() and strip.alpha==.12,'After combat the strip returns to its idle brightness')
fc.LiveRotation.GetIdleRecommendation=function()error('unavailable preview state')end
tick();assert(strip:IsShown(),'An unavailable preview cannot remove the persistent strip')
print('PASS: immediate idle/no-target preview, combat brightness, return to dim, AUTO labels, melee shock weaving, active autoattack handling, range gates and proc/interrupt/caster preservation.')
`);
lua.lua_close(L);
