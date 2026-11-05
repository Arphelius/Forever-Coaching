local CreateFrame = ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
local FC=ForeverCoaching
local frame=CreateFrame('Frame','ForeverCoachingRoleWarnings',UIParent)
frame:SetSize(560,60);frame:SetPoint('CENTER',UIParent,'CENTER',0,95);frame:SetFrameStrata('HIGH');frame:EnableMouse(false)
local label=frame:CreateFontString(nil,'OVERLAY','GameFontHighlightLarge')
label:SetPoint('CENTER');label:SetWidth(560);label:SetJustifyH('CENTER');label:SetWordWrap(true)
if label.SetMaxLines then label:SetMaxLines(2) end
label:Hide()
local colors={move={1,.25,.12},stop={1,.2,.15},danger={1,.25,.12},healing={.25,1,.4},health={1,.25,.25},interrupt={1,.75,.15},dispel={.5,.7,1},threat={1,.45,.15},mana={.35,.7,1}}
local short={health='Low health — use a defensive or heal.',healing='Ally needs healing.',interrupt='Interrupt the assigned cast.',dispel='Check the removable debuff.',mana='Low mana — conserve resources.'}
-- Consume all present conditions together: lower priorities do not queue up
-- when the selected notification fades. Persistent conditions stay silent.
local toast={time=0,seen={},lastShown={},sampleElapsed=0,duration=2.8,fade=.8}
FC.WarningToast=toast
function toast:Observe(alerts)
 local chosen;local currentThreatPresent=false
 local allowThreat=false
 if FC.RoleWarnings and FC.RoleWarnings.GroupThreatRelevant then
  local ok,result=pcall(function()return FC.RoleWarnings:GroupThreatRelevant(FC.RoleWarnings:Role())end)
  allowThreat=ok and result==true
 end
 for _,alert in ipairs(alerts or {}) do
  if alert.emergency==true and (alert.kind~='threat' or allowThreat) then
  if self.current and alert.key==self.current.key then
   currentThreatPresent=true
   -- An item may have been used or a heal become unavailable while the toast
   -- is fading. Replace stale advice without restarting its display timer.
   if alert.shortMessage~=self.current.shortMessage then
    self.current=alert;label:SetText(alert.shortMessage or short[alert.kind] or alert.message)
   end
  end
  local previous=self.seen[alert.key]
  local group=alert.kind=='healing' and 'health' or alert.kind
  local fresh=not previous or self.time-previous>3
  local allowed=not self.lastShown[group] or self.time-self.lastShown[group]>=12
  if fresh and allowed and (not chosen or alert.priority<chosen.priority) then chosen=alert end
  self.seen[alert.key]=self.time
  end
 end
 if self.current and self.current.kind=='threat' and (not allowThreat or not currentThreatPresent) then
  self.current=nil;label:Hide()
 end
 for key,at in pairs(self.seen) do if self.time-at>60 then self.seen[key]=nil end end
 if chosen and (not self.current or chosen.priority<self.current.priority) then
  self.current=chosen;self.started=self.time
  local group=chosen.kind=='healing' and 'health' or chosen.kind
  self.lastShown[group]=self.time
  label:SetText(chosen.shortMessage or short[chosen.kind] or chosen.message)
  local color=colors[chosen.kind] or {1,1,1};label:SetTextColor(color[1],color[2],color[3]);label:SetAlpha(1);label:Show()
 end
end
function toast:Advance(dt)
 self.time=self.time+dt
 if not self.current then return end
 local age=self.time-self.started
 if age>=self.duration then self.current=nil;label:Hide();return end
 label:SetAlpha(math.min(1,(self.duration-age)/self.fade))
end
frame:SetScript('OnUpdate',function(_,dt)
 toast:Advance(dt);toast.sampleElapsed=toast.sampleElapsed+dt
 if toast.sampleElapsed<.2 then return end;toast.sampleElapsed=0
 local ok,alerts=pcall(FC.RoleWarnings.Sample,FC.RoleWarnings)
 if not ok then FC.roleWarningsLastError=tostring(alerts);alerts={} end
 toast:Observe(alerts)
end)
