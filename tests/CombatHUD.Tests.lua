local function tick() ForeverCoachingCombatHUD.scripts.OnUpdate(ForeverCoachingCombatHUD,1) end
local function glowingButtons()
    local count=0
    for _,frame in ipairs(TestFrames) do
        if frame.pulse and frame:IsShown() then count=count+1 end
    end
    return count
end
tick()
assert(not ForeverCoaching.combatHUDLastError,ForeverCoaching.combatHUDLastError)
assert(ForeverCoachingRotationSlot4:IsShown(),'HUD always has four slots, including unknown forecasts')
HUDRecommendation.queue={{id=6603,icon=6603},{id=403,icon=403},{id=403,icon=403},{id=403,icon=403},{id=8042,icon=8042}}
tick()
assert(not ForeverCoachingRotationSlot5,'Never create a fifth slot')
assert(ForeverCoachingRotationSlot4.icon:GetTexture()==403,'Repeated forecast actions are preserved')
HUDRecommendation.queue=nil
local completed=ForeverCoachingRotationCompleted
local events;for _,frame in ipairs(TestFrames)do if frame.events.UNIT_SPELLCAST_SUCCEEDED then events=frame end end
local previous=completed.fade.plays or 0
events.scripts.OnEvent(events,'UNIT_SPELLCAST_SUCCEEDED','party1','cast',6603)
assert((completed.fade.plays or 0)==previous,'Another player cannot complete our recommendation')
events.scripts.OnEvent(events,'UNIT_SPELLCAST_SUCCEEDED','player','cast',403)
assert((completed.fade.plays or 0)==previous,'An unrelated spell does not fade the recommendation')
events.scripts.OnEvent(events,'UNIT_SPELLCAST_SUCCEEDED','player','cast',6603)
assert(completed.fade.plays==previous+1,'Matching success fades the completed action')
assert(ForeverCoachingRotationSlot1.alpha>ForeverCoachingRotationSlot2.alpha,'Next actions are dimmer than current action')
assert(ForeverCoachingRotationStrip:IsShown(),'Weapon action should remain visible')
assert(glowingButtons()==0,'An already running auto-attack must not glow as a press instruction')
HUDRecommendation.pressRequired=true
tick()
assert(not ForeverCoaching.combatHUDLastError,ForeverCoaching.combatHUDLastError)
assert(glowingButtons()==1,'An inactive Attack button should glow when starting swings is recommended')
HUDRecommendation.pressRequired=false
tick()
assert(glowingButtons()==0,'Stop glowing as soon as auto-attack is active')
HUDRecommendation={targetHostile=false}
tick()
assert(not ForeverCoachingRotationStrip:IsShown(),'Hide the strip with no hostile target')
assert(glowingButtons()==0,'Clear weapon glow when target is gone')
