-- Minimal UI/event model for review flow tests; this does not render WoW UI.
TestFrames = {}
local methods = {}
local noop = function() end
local meta = { __index = function(_, key)
    if methods[key] then return methods[key] end
    if key:match('^Set') or key:match('^Get') or key:match('^Register')
        or key:match('^Enable') or key:match('^Start') or key:match('^Stop') or key:match('^Clear') then return noop end
end }
function CreateFrame(_, name, parent)
    local frame = setmetatable({ name=name, parent=parent, hidden=false, scripts={}, events={} }, meta)
    TestFrames[#TestFrames+1] = frame
    if name then _G[name]=frame end
    return frame
end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:SetScript(event, fn) self.scripts[event]=fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:SetParent(parent) self.parent=parent end
function methods:IsShown()
    return not self.hidden and (not self.parent or self.parent:IsShown())
end
function methods:Show()
    local wasShown=self:IsShown(); self.hidden=false
    if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide() self.hidden=true end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:CreateFontString() return CreateFrame('FontString',nil,self) end
function methods:CreateTexture() return CreateFrame('Texture',nil,self) end
function methods:CreateAnimationGroup() return CreateFrame('AnimationGroup',nil,self) end
function methods:CreateAnimation() return CreateFrame('Animation',nil,self) end
function methods:Play() self.playing=true;self.plays=(self.plays or 0)+1 end
function methods:SetAlpha(value)self.alpha=value end
function methods:Stop() self.playing=false end
function methods:IsPlaying() return self.playing==true end
function methods:SetTexture(texture) self.texture=texture end
function methods:GetTexture() return self.texture end
function methods:GetWidth() return self.width or 40 end
function methods:GetHeight() return self.height or 40 end
function methods:GetSize() return self:GetWidth(),self:GetHeight() end
function methods:GetTop() return 80 end
function methods:GetEffectiveScale() return 1 end
function methods:GetFrameStrata() return 'MEDIUM' end
function methods:GetFrameLevel() return 10 end
function methods:SetText(text) self.text=text end
function methods:GetText() return self.text end
function methods:SetHeight(height) self.height=height end
function methods:SetSize(width,height) self.width=width;self.height=height end
function methods:GetStringHeight() return 30 end
UIParent=CreateFrame('Frame','UIParent')
UIParent:SetSize(1920,1080)
UnitName=function() return 'Fixture' end
GetRealmName=function() return 'TestRealm' end
UnitLevel=function() return 2 end
UnitClass=function() return 'Shaman','SHAMAN' end
UnitGUID=function() return 'target-fixture' end
GetTime=function() return TestNow or 10 end
time=function() return 1000 end
issecretvalue=function() return false end
C_Spell={ GetSpellInfo=function() return {name='Lightning Bolt'} end }
TestTimers={}
C_Timer={After=function(_,fn) TestTimers[#TestTimers+1]=fn end}
ForeverCoachingDB={reviews={},settings={showCombatAnalysisNotice=false}}
