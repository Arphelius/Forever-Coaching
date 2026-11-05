const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(source){if(lauxlib.luaL_dostring(L,to_luastring(source))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
for(const file of ['tests/CombatReviewHarness.lua','addons/ForeverCoaching/Core/LiveRotation.lua','addons/ForeverCoaching/Core/CombatReview.lua'])run(fs.readFileSync(file,'utf8'));
run(`
local fc=ForeverCoaching;local review=fc.CombatReview
local names={[403]='Lightning Bolt',[529]='Lightning Bolt',[8042]='Earth Shock',[331]='Healing Wave'}
C_Spell.GetSpellInfo=function(id)return {name=names[id]}end
UnitName=function(unit)return unit=='target' and 'Enemy' or 'Fixture'end
UnitGUID=function(unit)return unit=='target' and 'enemy-guid' or 'player-guid'end
local listener
for _,f in ipairs(TestFrames)do if f.events.UNIT_SPELLCAST_FAILED_QUIET then listener=f end end
local function fire(event,...)listener.scripts.OnEvent(listener,event,...)end
local function suggest(id,reason,eligible)
 review:SetLatestRecommendation({spellID=id,spellName=names[id],reason=reason,situation='damage choice',reviewEligible=eligible~=false,targetGUID='enemy-guid'})
end
local function cast(id,guid,target)
 fire('UNIT_SPELLCAST_SENT','player',target or 'Enemy',guid,id)
 fire('UNIT_SPELLCAST_SUCCEEDED','player',guid,id)
end
local function finish()
 TestNow=TestNow+1;fire('PLAYER_REGEN_ENABLED');for _,fn in ipairs(TestTimers)do fn()end;TestTimers={}
 return ForeverCoachingDB.reviews[1],review:GetLatestSummary()
end
TestNow=10;fire('PLAYER_REGEN_DISABLED')
TestNow=12;suggest(403,'Lightning Bolt has the higher estimated damage for this cast window.');cast(8042,'bad-1')
TestNow=13;suggest(403,'Lightning Bolt has the higher estimated damage for this cast window.');cast(8042,'bad-2')
local first,summary=finish()
assert(#first.decisions==2 and not first.decisions[1].matched)
assert(summary.wrongText:find('2.0s: Used Earth Shock while Lightning Bolt',1,true))
assert(summary.wrongText:find('2 similar choices',1,true))
assert(summary.improveText:find('use Lightning Bolt before Earth Shock',1,true))
assert(summary.improveText:find('higher estimated damage',1,true))
assert(not summary.wrongText:find('failed',1,true))
-- Encounter summaries must not replace the rotation findings with generic failure counts.
fc.EncounterCoach={Summarize=function()return 'Confirmed interrupt.','',''end}
first.encounterCoaching={build={title='Fixture'}}
local encounter=review:GetLatestSummary()
assert(encounter.improveText:find('use Lightning Bolt before Earth Shock',1,true))
assert(encounter.goodText:find('Confirmed interrupt.',1,true))
fc.EncounterCoach=nil
-- Next fight: ranks of the same spell match, utility is ignored, and no invented correction.
TestNow=20;fire('PLAYER_REGEN_DISABLED')
TestNow=21;suggest(403,'Correct ranged filler.');cast(529,'rank-match')
TestNow=22;suggest(403,'Correct ranged filler.');cast(331,'heal')
local second,clean=finish()
assert(#second.decisions==1 and second.decisions[1].matched)
assert(clean.wrongText=='No mistakes recorded this fight.' and clean.improveText=='everything worked perfectly fine this fight','A clean fight shows the requested success message')
assert(not clean.improveText:find('Earth Shock',1,true),'Previous fight must not leak')
second.encounterCoaching={build={title='Clean fight'}}
fc.EncounterCoach={Summarize=function()return 'Successful response.','Unconfirmed response.','Practice mechanics and check your movement.'end}
local cleanEncounter=review:GetLatestSummary()
assert(cleanEncounter.improveText=='everything worked perfectly fine this fight','Generic encounter observations must not replace the success message with corrections')
fc.EncounterCoach=nil
-- Stale, ambiguous target, failed, unverified and absent-SENT observations are excluded.
TestNow=30;fire('PLAYER_REGEN_DISABLED');suggest(403,'Stale')
TestNow=31;cast(8042,'stale')
suggest(403,'Other target');cast(8042,'other','Friendly')
suggest(403,'Unknown range',false);cast(8042,'unknown')
suggest(403,'Failed');fire('UNIT_SPELLCAST_SENT','player','Enemy','failed',8042);fire('UNIT_SPELLCAST_FAILED','player','failed',8042)
fire('UNIT_SPELLCAST_SUCCEEDED','player','no-sent',8042)
local third,unknown=finish()
assert(#third.decisions==0 and unknown.wrongText=='No mistakes recorded this fight.' and unknown.improveText=='everything worked perfectly fine this fight','No recorded mistake shows the success message instead of corrective advice')
assert(not unknown.wrongText:find('failed',1,true))
assert(fc.LiveRotation:IsReviewableAttack('MAGE','Fireball'))
assert(not fc.LiveRotation:IsReviewableAttack('MAGE','Counterspell'))
assert(not fc.LiveRotation:IsReviewableAttack('PALADIN','Lay on Hands'))
-- Shaman learners can receive safe spellbook-based advice before choosing talents.
fc.EncounterCoach={GetBuildContext=function()return {class='SHAMAN'}end,GetRecommendation=function()end}
fc.SpecScenarios={ForCurrent=function()return {available=false}end}
fc.RotationCoach={GetRecommendation=function()return {spellID=403,spellName='Lightning Bolt',situation='damage choice'}end}
local rec=fc.LiveRotation:GetRecommendation();assert(rec.reviewEligible and rec.spellID==403)
print('PASS: timestamped priority alternatives, repeated choices, good fights, fight isolation, spell ranks, utility/failed/stale/target exclusions, encounter integration and pre-talent Shaman support.')
`);
lua.lua_close(L);
