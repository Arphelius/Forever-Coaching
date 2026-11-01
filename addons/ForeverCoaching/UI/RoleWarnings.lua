local FC=ForeverCoaching
local frame=CreateFrame('Frame','ForeverCoachingRoleWarnings',UIParent)
frame:SetSize(660,130);frame:SetPoint('CENTER',UIParent,'CENTER',0,155);frame:SetFrameStrata('HIGH');frame:EnableMouse(false)
local colors={move={1,.25,.12},stop={1,.2,.15},danger={1,.25,.12},healing={.25,1,.4},health={1,.25,.25},interrupt={1,.75,.15},dispel={.5,.7,1},threat={1,.45,.15},mana={.35,.7,1}}
local labels={}
for i=1,3 do local label=frame:CreateFontString(nil,'OVERLAY',i==1 and 'GameFontNormalLarge' or 'GameFontHighlight');label:SetPoint('TOP',0,-(i-1)*43);label:SetWidth(650);label:SetJustifyH('CENTER');label:Hide();labels[i]=label end
local elapsed=0
frame:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.2 then return end;elapsed=0
 local ok,alerts=pcall(FC.RoleWarnings.Sample,FC.RoleWarnings)
 if not ok then FC.roleWarningsLastError=tostring(alerts);alerts={} end
 for i,label in ipairs(labels)do local alert=alerts[i];if alert then local c=colors[alert.kind] or {1,1,1};label:SetText(alert.message);label:SetTextColor(c[1],c[2],c[3]);label:Show()else label:Hide()end end
end)
