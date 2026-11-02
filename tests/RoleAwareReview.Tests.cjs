const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));
run(`TestClass='ROGUE';TestTree=3;TestRole='DAMAGER';TestNow=10;TestHealth=20;TestAllyHealth=20
UnitClass=function()return TestClass,TestClass end;GetPrimaryTalentTree=function()return TestTree end
UnitGroupRolesAssigned=function()return TestRole end
UnitGUID=function(unit)return ({player='self',party1='ally',target='enemy'})[unit]end
UnitExists=function(unit)return UnitGUID(unit)~=nil end
UnitName=function(unit)return unit end
UnitCanAssist=function(_,unit)return unit=='player' or unit=='party1'end
UnitCanAttack=function(_,unit)return unit=='target'end
UnitIsDeadOrGhost=function()return false end
UnitAffectingCombat=function()return true end;GetUnitSpeed=function()return 0 end
UnitHealth=function(unit)return unit=='player' and TestHealth or TestAllyHealth end;UnitHealthMax=function()return 100 end
UnitPowerType=function()return TestClass=='ROGUE' and 3 or 0 end;UnitPower=function()return 100 end;UnitPowerMax=function()return 100 end
GetTime=function()return TestNow end
IsPlayerSpell=function(id)for _,spell in pairs(ForeverCoaching.ForeverSpellCatalog.classes[TestClass].spells)do for _,known in ipairs(spell.ids)do if known==id then return true end end end;return false end
C_Spell={GetSpellInfo=function(id)for name,spell in pairs(ForeverCoaching.ForeverSpellCatalog.classes[TestClass].spells)do for _,known in ipairs(spell.ids)do if known==id then return {name=name}end end end end,
 IsSpellUsable=function()return true,false end,GetSpellCooldown=function()return {startTime=0,duration=0,isEnabled=true}end,IsSpellInRange=function()return true end}
`);
for(const file of ['Data/LevelingBuilds.lua','Data/Level60Builds.lua','Core/BuildPlanner.lua','Data/AbilityLessons.lua','Data/ForeverSpellCatalog.lua','Data/TalentLessonEffects.lua','Core/TalentLessons.lua','Data/SpecScenarios.lua','Data/ScenarioActions.lua','Data/CombatSituations.lua','Data/ForeverSpellGuidance.lua','Core/SpecScenarios.lua','Core/EncounterCoach.lua','Core/ScenarioTracker.lua','Core/RoleWarnings.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local coach=fc.EncounterCoach;local s=fc.ScenarioTracker
fc.GuideBrowser={class='PRIEST',buildID='unrelated-healer'}
coach:Begin();local identity=coach.combatContext
assert(identity.class=='ROGUE' and identity.tree==3 and identity.identitySource=='detected' and not identity.canHeal,'Detect actual Rogue spec/toolkit independently of browsed builds')
coach:Sample();for _,offer in ipairs(coach.currentOffers)do assert(offer.kind~='healing','Rogue must never receive a heal-cast prompt')end
s:Begin();s:Sample();assert(s.flags.heal and s.open.heal.title=='Survival','Rogue low health is survival pressure, not a healer assignment')
local alerts=fc.RoleWarnings:Sample();for _,alert in ipairs(alerts)do if alert.kind=='health' then assert(not alert.message:find('self%-heal'),'Rogue health toast must not suggest casting a heal')end end
TestNow=13;local result=s:Finish();local _,_,nextSteps=s:Summarize(result)
assert(not nextSteps:find('use a suitable ready heal',1,true) and nextSteps:find('Evasion',1,true),'Rogue review uses learned defensive tools')
TestHealth=100;coach:Finish();coach:Begin();coach:Sample();s:Begin();s:Sample();assert(not s.flags.heal,'An injured ally alone must not assign healing to a Rogue');s:Finish();coach:Finish()
TestClass='DRUID';TestTree=1;TestRole='DAMAGER';coach:Begin();coach:Sample();assert(coach.combatContext.canHeal,'Balance can learn healing spells')
for _,offer in ipairs(coach.currentOffers)do assert(offer.kind~='healing','Damage-role off-healers are not assigned automatic group heals')end;coach:Finish()
TestClass='PRIEST';TestTree=2;TestRole='HEALER';coach:Begin();coach:Sample();s:Begin();s:Sample();assert(s.flags.heal,'Healer role retains ally-healing observations')
TestNow=16;local healer=s:Finish();local _,_,healerAdvice=s:Summarize(healer);assert(healerAdvice:find('assigned injured target',1,true));coach:Finish()
local _,_,rogueAgain=s:Summarize(result);assert(rogueAgain:find('Evasion',1,true),'Saved fights must use their recorded identity, not the current character')
local _,_,legacy=s:Summarize({windows={{id='heal',title='Healing',started=0,ended=3,actions={}}}},{class='ROGUE',role='damage'})
assert(legacy:find('Survival',1,true) and not legacy:find('ready heal',1,true),'Old Rogue recordings must also lose inappropriate healing advice')
TestClass='ROGUE';TestTree=nil;TestRole='NONE';local selected
for _,choice in ipairs(fc.BuildPlanner:GetVisibleSpecBuilds('ROGUE','raids',60))do if choice.specIndex==3 and choice.build then selected=choice.build;break end end
assert(selected);assert(coach:SetCombatSpecFallback('ROGUE',selected));assert(coach:GetCombatContext().identitySource=='manual fallback','Manual spec is used only when automatic detection is unavailable')
assert(not coach:SetCombatSpecFallback('PRIEST',fc.BuildPlanner:GetBuilds('PRIEST')[1]),'Manual selection must not replace a detected Rogue class')
TestTree=1;assert(coach:GetCombatContext().identitySource=='detected' and coach:GetCombatContext().tree==1,'Automatic identity must take priority over a saved manual fallback')
TestRole='DAMAGER'
for _,class in ipairs(fc.BuildPlanner.classes)do for tree=1,3 do
 TestClass=class;TestTree=tree;local context=coach:GetCombatContext()
 assert(context.class==class and context.tree==tree and context.identitySource=='detected',class..': automatic spec identity failed')
 if class=='ROGUE' or class=='WARRIOR' or class=='HUNTER' or class=='MAGE' then assert(not context.canHeal,class..': an unlearned healing spell must not be assumed')end
end end
print('PASS: Rogue survival advice, no unavailable heal prompts, healer/off-healer separation, saved-fight identity, old reviews, safe manual fallback and detection priority.')`);
