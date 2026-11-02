const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));
run('ForeverCoaching={};ForeverCoachingDB.settings.showCombatAnalysisNotice=true');
for(const file of ['Core/CombatReview.lua','UI/CombatNotification.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local review=fc.CombatReview;local notice=ForeverCoachingCombatNotice
local events
for _,frame in ipairs(TestFrames)do if frame~=notice and frame.events.PLAYER_REGEN_DISABLED then events=frame end end
assert(events,'Review combat event listener missing')
local function fire(event,...)events.scripts.OnEvent(events,event,...)end
local function flush()local pending=TestTimers;TestTimers={};for _,fn in ipairs(pending)do fn()end end
local function fight()
 fire('PLAYER_REGEN_DISABLED');fire('UNIT_SPELLCAST_SENT','player','target','cast',403);fire('UNIT_SPELLCAST_SUCCEEDED','player','cast',403)
 TestNow=(TestNow or 10)+4;fire('PLAYER_REGEN_ENABLED');flush()
end
fire('PLAYER_ENTERING_WORLD');fight();assert(notice:IsShown(),'Completed fight must show a reminder')
local reviewButton,muteButton,dismiss
for _,frame in ipairs(TestFrames)do if frame.parent==notice then
 if frame.text=='Review fight' then reviewButton=frame elseif frame.text=='Silence reminders' then muteButton=frame
 elseif frame.scripts.OnClick then dismiss=frame end end end
assert(reviewButton and muteButton and dismiss,'Review, silence and dismiss controls required')
local opened=0;fc.OpenCombatReview=function()opened=opened+1;assert(review:GetSource()=='local');review:MarkLatestViewed()end
review:SetSource('foreverlogs');reviewButton.scripts.OnClick();assert(opened==1 and not notice:IsShown(),'Reminder must open local review')
fight();dismiss.scripts.OnClick();assert(not notice:IsShown() and review:GetReadyNoticeEnabled(),'Dismiss must not mute future reminders')
fight();assert(notice:IsShown());muteButton.scripts.OnClick();assert(not review:GetReadyNoticeEnabled() and not notice:IsShown())
local saved=#ForeverCoachingDB.reviews;fight();assert(#ForeverCoachingDB.reviews==saved+1 and not notice:IsShown(),'Mute must preserve recording')
assert(ForeverCoachingDB.settings.showCombatAnalysisNotice==false,'Silence preference must persist')
SlashCmdList.FOREVERCOACHINGREMINDERS('on');fight();assert(notice:IsShown(),'Re-enabled reminders return next fight')
notice.scripts.OnEvent(notice,'PLAYER_REGEN_DISABLED');assert(not notice:IsShown(),'Hide reminder when the next fight begins')
fc:NotifyCombatAnalysisReady({duration=12,casts=3});assert(notice:IsShown());flush();assert(not notice:IsShown(),'Reminder times out')
SlashCmdList.FOREVERCOACHINGREMINDERS('off');assert(not review:GetReadyNoticeEnabled())
print('PASS: post-fight reminder, local review navigation, dismiss, saved mute, continued recording, re-enable, combat hiding and timeout.')`);
