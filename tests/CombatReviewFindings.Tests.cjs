const fs=require('fs');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('../tools/preview-runtime/node_modules/fengari');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code){if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));
run(fs.readFileSync('addons/ForeverCoaching/Core/CombatReview.lua','utf8'));
run(`
local fc=ForeverCoaching
local review=fc.CombatReview
local report={casts=3,started=100,characterGUID=UnitGUID('player'),duration=12,
 damageByAbility={{name='Shadow Bolt',casts=2},{name='Corruption',casts=1}},
 failedAttempts={{name='Shadow Bolt',at=103,clientMessage='Out of range'},
 {name='Shadow Bolt',at=104,clientMessage='Out of range'}}}
local good,attention,advice=review:SummarizeDecisions(report)
assert(good:find('Shadow Bolt x2',1,true) and good:find('Corruption x1',1,true),'Describe the actual spell mix')
assert(attention:find('3.0s: Shadow Bolt failed (2 attempts)',1,true),'Keep timing and group repeated failures')
assert(attention:find('Game message: Out of range',1,true),'Show the client evidence, not a generic heading')
assert(advice:find('Move within Shadow Bolt range',1,true),'Range errors require range advice')
local cases={
 {'Target not in line of sight','clear line of sight'},
 {"Can't do that while moving",'stop moving'},
 {'Not enough mana','enough resource'},
 {'Spell is not ready yet','become ready'},
 {'Invalid target','valid target'},
 {'Another action is in progress','current cast finish'},
}
for _,case in ipairs(cases) do
 report.failedAttempts={{name='Fixture Spell',time=2,clientMessage=case[1]}}
 local _,wrong,nextStep=review:SummarizeDecisions(report)
 assert(wrong:find('2.0s:',1,true) and nextStep:find(case[2],1,true),case[1]..': missing specific next step')
end
SPELL_FAILED_MOVING='Localized movement error'
report.failedAttempts={{name='Fixture Spell',time=2,clientMessage=SPELL_FAILED_MOVING}}
local _,_,localized=review:SummarizeDecisions(report)
assert(localized:find('stop moving',1,true),'Match localized client error constants')
report.failedAttempts={{name='Fixture Spell',interrupted=true}}
local _,unknown,unknownAdvice=review:SummarizeDecisions(report)
assert(unknown:find('No cause was reported',1,true))
assert(unknownAdvice:find('interruption was intentional',1,true) and not unknownAdvice:find('stop moving',1,true),'Do not invent a cause for an interruption')
report.failedAttempts={}
report.fightTimelineId='legacy'
ForeverCoachingDB.fightTimelines={{id='legacy',started=100,events={{kind='death',unit='player',time=10}}}}
local _,death,deathAdvice=review:SummarizeDecisions(report)
assert(death:find('10.0s: Player death',1,true) and deathAdvice:find('before your death',1,true))
report.encounterCoaching={build={class='WARLOCK',title='Recorded build'}}
report.scenarioCoaching={coverage='Recorded scenarios'}
fc.EncounterCoach={Summarize=function()return 'Observed response','Unconfirmed interrupt; assignment needs checking.','Check the interrupt assignment before the next pull.'end}
fc.ScenarioTracker={Summarize=function()return 'Resource pressure observed','Mana was low.','Recover mana safely between pulls.'end}
ForeverCoachingDB.reviews={report}
local summary=review:GetLatestSummary()
assert(summary.wrongText:find('assignment needs checking',1,true),'Keep encounter observation qualifications')
assert(summary.improveText:find('interrupt assignment',1,true) and summary.improveText:find('Recover mana',1,true),'Do not discard encounter/scenario next steps')
`);
lua.lua_close(L);
console.log('PASS: spell mix, timed/grouped failures, error-specific and localized next steps, unknown causes, deaths and encounter/scenario guidance. Simulated observations only.');
