local FC=ForeverCoaching
local review=FC.CombatReview
local events
for _, frame in ipairs(TestFrames) do
    if frame.events.PLAYER_REGEN_DISABLED then events=frame end
end
assert(events,'Review event listener missing')
local function fire(event,...) events.scripts.OnEvent(events,event,...) end
fire('PLAYER_ENTERING_WORLD')
review:SetLatestRecommendation({spellID=403,spellName='Lightning Bolt',reason='fixture',shortReason='Use Lightning Bolt: good damage for its mana cost.',situation='damage choice',targetGUID='target-fixture'})
fire('PLAYER_REGEN_DISABLED')
review:SetLatestRecommendation({spellID=403,spellName='Lightning Bolt',reason='fixture',shortReason='Use Lightning Bolt: good damage for its mana cost.',situation='damage choice',targetGUID='target-fixture'})
fire('UNIT_SPELLCAST_SENT','player','target','cast-fixture',403)
fire('UNIT_SPELLCAST_SUCCEEDED','player','cast-fixture',403)
TestNow=15
fire('PLAYER_REGEN_ENABLED')
assert(#ForeverCoachingDB.reviews==0,'Save should wait for postcombat callback')
for _,fn in ipairs(TestTimers) do fn() end
assert(#ForeverCoachingDB.reviews==1,'Fight was not saved')
assert(ForeverCoachingDB.reviews[1].casts==1,'Cast missing from report')
assert(review:GetLatestText():find('Lightning Bolt',1,true),'Saved advice missing')
assert(ForeverCoachingDB.combatAnalysisReady,'New review should be unread')
FC:ToggleWindow()
assert(ForeverCoachingFrame:IsShown(),'Manual open failed')
assert(not ForeverCoachingDB.combatAnalysisReady,'Visible review should be marked read')
local reviewText
for _,f in ipairs(TestFrames) do
    if f.text==review:GetLatestSummary().improveText and f:IsShown() then reviewText=f end
end
assert(reviewText,'Visible explained review area missing')
for _,heading in ipairs({'LOCAL RECORDING','PEER ROTATION COMPARISON','GET SPEC-SPECIFIC COACHING'}) do
 local visible=false;for _,f in ipairs(TestFrames) do if f.text==heading and f:IsShown() then visible=true end end
 assert(visible,'Missing review section: '..heading)
end
local resourcesButton
for _,f in ipairs(TestFrames) do
    if f.navigationIndex==6 then resourcesButton=f end
end
assert(resourcesButton,'Resources navigation missing')
resourcesButton.scripts.OnClick(resourcesButton)
FC:ToggleWindow() -- close on Resources
ForeverCoachingDB.combatAnalysisReady=true
FC:ToggleWindow() -- new unread review must open the review page
local displayed=false
for _,f in ipairs(TestFrames) do
    if f.text==review:GetLatestSummary().improveText and f:IsShown() then displayed=true end
end
assert(displayed,'Manual open stayed on Resources instead of showing new review')
-- Merely browsing another page must not mark an unseen report as read.
resourcesButton.scripts.OnClick(resourcesButton)
FC:ToggleWindow()
ForeverCoachingDB.combatAnalysisReady=true
ForeverCoachingFrame:Show()
assert(ForeverCoachingDB.combatAnalysisReady,'Opening another page discarded unread state')
FC:RefreshCombatReview()
assert(ForeverCoachingDB.combatAnalysisReady,'Hidden review refresh discarded unread state')
FC:OpenCombatReview()
ForeverCoachingDB.reviews[1].casts=2
FC:RefreshCombatReview()
local refreshed=false
for _,f in ipairs(TestFrames) do
    if type(f.text)=='string' and f.text:find('2 successful casts',1,true) and f:IsShown() then refreshed=true end
end
assert(refreshed,'Open review failed to refresh its text')
review:SetSource('foreverlogs');ForeverCoachingDB.combatAnalysisReady=true
review:MarkLatestViewed()
assert(ForeverCoachingDB.combatAnalysisReady,'Viewing an imported snapshot must not mark a live fight read')
review:SetSource('local')
-- Exercise the recorder and review together, including a previously imported source.
local recorderEvents
for _, frame in ipairs(TestFrames) do
 if frame.events.PLAYER_STARTED_MOVING then recorderEvents=frame end
end
assert(recorderEvents,'Fight recorder listener missing')
local function combatEvent(event,...)
 recorderEvents.scripts.OnEvent(recorderEvents,event,...)
 fire(event,...)
end
review:SetSource('foreverlogs')
TestTimers={};TestNow=30
combatEvent('PLAYER_REGEN_DISABLED')
combatEvent('UNIT_SPELLCAST_SENT','player','target','linked-cast',403)
combatEvent('UNIT_SPELLCAST_SUCCEEDED','player','linked-cast',403)
combatEvent('UNIT_SPELLCAST_FAILED','player','failed-cast',403)
combatEvent('UI_ERROR_MESSAGE',1,'Out of range')
TestNow=35
combatEvent('PLAYER_REGEN_ENABLED')
for _,fn in ipairs(TestTimers) do fn() end
local latest=ForeverCoachingDB.reviews[1]
assert(latest.casts==1 and latest.duration==5,'Linked fight metrics missing')
assert(FC.FightRecorder:Find(latest.fightTimelineId),'Review must link to its saved timeline')
assert(review:GetSource()=='local','Finished fight hidden behind imported source')
local _,attempts,nextStep=review:SummarizeDecisions(latest)
assert(attempts:find('Out of range',1,true),'Recorded client failure missing from review')
assert(nextStep:find('range',1,true),'Range failure needs specific range guidance')
FC:OpenCombatReview()
local visibleCoachingStatus,visibleCasts,visibleImportStep=false,false,false
for _,frame in ipairs(TestFrames) do
 if frame:IsShown() and type(frame.text)=='string' then
  if frame.text:find('No comparison with other players',1,true) then visibleCoachingStatus=true end
  if frame.text:find('Casts: Lightning Bolt x1',1,true) then visibleCasts=true end
  if frame.text:find('matching same-spec reference fights',1,true) then visibleImportStep=true end
 end
end
assert(visibleCoachingStatus and visibleCasts and visibleImportStep,'Local diagnostics must not masquerade as peer coaching; show the path to a matched review')
-- Forever can rename its realm display label. Recover legacy reviews by the
-- GUID in the linked timeline, without mixing same-name characters on realms.
latest.characterGUID=nil
GetRealmName=function()return 'RenamedRealm'end
assert(review:GetLatestSummary().goodText:find('1 successful casts',1,true),'Realm label change hid a saved fight')
assert(latest.characterGUID==UnitGUID('player'),'Legacy timeline GUID was not migrated')
assert(review:GetLatestText():find('Out of range',1,true),'Text lookup ignored recovered identity')
local oldRecorder=FC.FightRecorder
FC.FightRecorder=nil
assert(review:GetLatestSummary().goodText:find('1 successful casts',1,true),'Migrated identity must survive timeline expiry')
FC.FightRecorder=oldRecorder
latest.character=UnitName('player')..'-'..GetRealmName()
latest.characterGUID='different-player'
ForeverCoachingDB.reviews={latest}
assert(review:GetLatestSummary().metrics=='Local observations / No fight recorded yet','A different GUID must not match by character name')
