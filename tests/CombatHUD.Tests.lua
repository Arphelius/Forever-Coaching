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
assert(ForeverCoachingRotationStrip:IsShown() and ForeverCoachingRotationStrip.alpha==1,'No target keeps the strip visible during combat')
assert(glowingButtons()==0,'Clear weapon glow when target is gone')
-- Tank threat bar: colour and fill follow RoleWarnings.threat; hidden when threat is unknown.
local bar=ForeverCoachingThreatBar
bar.SetStatusBarColor=function(self,r,g,b)self.color={r,g,b}end
bar.SetValue=function(self,v)self.value=v end
ForeverCoaching.RoleWarnings=ForeverCoaching.RoleWarnings or {}
local W=ForeverCoaching.RoleWarnings
assert(not bar:IsShown(),'No threat state: no bar')
W.threat={state='secure',name='Mage',percent=40,mine=100};tick()
assert(bar:IsShown() and bar.color[2]>bar.color[1] and bar.value==40,'Secure: green, filled to the closest other player')
W.threat={state='warning',name='Mage',percent=85,mine=100};tick()
assert(bar.color[1]==1 and bar.value==85 and bar.label.text:find('Mage 85%',1,true),'Warning: yellow with who is close')
W.threat={state='other-tank',name='Offtank',mine=40};tick()
assert(bar.color[3]==1 and bar.label.text:find('(tank)',1,true),'Another tank: blue')
W.threat={state='lost-far',name='Mage',percent=100,mine=30};tick()
assert(bar.color[1]>0.9 and bar.color[2]<0.3 and bar.value==30,'Lost: red, filled to your share')
W.threat={state='lost',name='Mage',percent=100};tick()
assert(bar.value==0,'Lost with your share unknown: empty, never the other player\'s value')
W.threat={state='unknown'};tick();assert(not bar:IsShown(),'Unknown threat: hidden')
W.threat=nil;tick();assert(not bar:IsShown(),'Out of a tank fight: hidden')
