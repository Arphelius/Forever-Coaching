-- Standalone preview must work without live level, class or talent APIs.
local frames,selectedKinds={},{}
local previewArt
UIParent={};UISpecialFrames={};SlashCmdList={}
local methods={}
function methods:SetText(value) self.text=value end
function methods:GetFontString() return self end
function methods:GetParent() return self.parent end
function methods:SetSize(w,h) self.width=w;self.height=h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:GetFrameLevel() return 1 end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
local function object(parent)
    return setmetatable({parent=parent,scripts={}}, {__index=function(_,key) return methods[key] or function() end end})
end
function methods:CreateFontString() return object(self) end
function methods:CreateTexture() return object(self) end
function CreateFrame(_,name,parent)
    local frame=object(parent);frames[#frames+1]=frame
    if name then _G[name]=frame end
    return frame
end
function GetTime() return 12 end
function UnitLevel() error('Preview must not require a level') end
function LearnTalent() error('Preview must never spend talent points') end
ForeverCoaching={CreateTalentThemeArt=function(_,owner)
    previewArt={owner=owner,animationCalls=0,SetTheme=function(self,kind) selectedKinds[#selectedKinds+1]=kind;self.kind=kind end,
        Animate=function(self,time,w,h) assert(time==12 and w>0 and h>0);self.animated=true;self.animationCalls=self.animationCalls+1 end}
    return previewArt
end}
