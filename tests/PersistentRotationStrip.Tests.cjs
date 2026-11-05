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
local cooldown=C_Spell.GetSpellCooldown
C_Spell.GetSpellCooldown=function(id)return id==8042 and {startTime=9,duration=6,isEnabled=true} or cooldown(id)end
rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID==6603 and rec.pressRequired==false,'Swing while Shock recovers; do not repeatedly press Attack')
assert(not rec.reviewEligible,'Passive weapon swings are not scored as missed attack button presses')
RotationState.meleeRange=false;rec=fc.LiveRotation:GetRecommendation()
assert(rec.spellID==403,'Out of melee, preserve a ready ranged attack')
RotationState.meleeRange=nil;rec=fc.LiveRotation:GetRecommendation();assert(rec.spellID==403,'Unknown melee range must not invent an autoattack instruction')
RotationState.meleeRange=true
local proc={spellID=403,spellName='Lightning Bolt',icon=403,situation='maelstrom proc',targetHostile=true}
assert(fc.LiveRotation:WithShamanSwings(proc,TestSpec).spellID==403,'Preserve Maelstrom-enhanced casting')
local interrupt={spellID=8042,situation='interrupt',targetHostile=true}
assert(fc.LiveRotation:WithShamanSwings(interrupt,TestSpec)==interrupt,'Interrupts are never delayed by swings')
TestSpec.treeIndex=1;rec=fc.LiveRotation:GetRecommendation();assert(rec.spellID==403,'Elemental does not receive Enhancement melee advice')
TestSpec.treeIndex=2
`);
run(fs.readFileSync('addons/ForeverCoaching/UI/CombatHUD.lua','utf8'));
run(`local fc=ForeverCoaching;local strip=ForeverCoachingRotationStrip
local function tick()ForeverCoachingCombatHUD.scripts.OnUpdate(ForeverCoachingCombatHUD,1);assert(not fc.combatHUDLastError,fc.combatHUDLastError)end
assert(strip:IsShown() and strip.alpha==.12,'Strip exists dimly immediately, before selecting any enemy')
UnitExists=function(unit)return unit=='player'end;tick()
assert(strip:IsShown() and strip.alpha==.12,'Idle/no-target strip stays barely visible')
assert(ForeverCoachingRotationSlot1.caption.text=='AUTO','Passive swings have an AUTO label')
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
