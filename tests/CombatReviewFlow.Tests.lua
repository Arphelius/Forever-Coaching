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
for _,heading in ipairs({'WHAT YOU DID WELL','WHAT WENT WRONG','WHAT TO IMPROVE'}) do
 local visible=false;for _,f in ipairs(TestFrames) do if f.text==heading and f:IsShown() then visible=true end end
 assert(visible,'Missing review section: '..heading)
end
local resourcesButton
for _,f in ipairs(TestFrames) do
    if f.text=='Resources' then resourcesButton=f.parent end
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
ForeverCoachingDB.reviews[1].recommendations[1].shortReason='Updated review fixture.'
FC:RefreshCombatReview()
local refreshed=false
for _,f in ipairs(TestFrames) do
    if type(f.text)=='string' and f.text:find('Updated review fixture.',1,true) and f:IsShown() then refreshed=true end
end
assert(refreshed,'Open review failed to refresh its text')
review:SetSource('foreverlogs');ForeverCoachingDB.combatAnalysisReady=true
review:MarkLatestViewed()
assert(ForeverCoachingDB.combatAnalysisReady,'Viewing an imported snapshot must not mark a live fight read')
review:SetSource('local')
