ForeverCoaching = ForeverCoaching or {}
local FC = ForeverCoaching

local notice = CreateFrame("Frame", "ForeverCoachingCombatNotice", UIParent, "BackdropTemplate")
notice:SetSize(330, 104)
notice:SetFrameStrata("DIALOG")
notice:SetClampedToScreen(true)
notice:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
notice:SetBackdropColor(0.025, 0.045, 0.075, 0.97)
notice:SetBackdropBorderColor(1, 0.72, 0.2, 0.95)
notice:Hide()

local title = notice:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", notice, "TOPLEFT", 14, -12)
title:SetTextColor(1, 0.82, 0.25)
title:SetText("Combat analysis is ready")

local detail = notice:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detail:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
detail:SetWidth(300)
detail:SetJustifyH("LEFT")
detail:SetText("Open Forever Coaching whenever you want to review it.")

local function makeButton(label, width, x, onClick)
    local button = CreateFrame("Button", nil, notice, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("BOTTOMLEFT", notice, "BOTTOMLEFT", x, 10)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

makeButton("View analysis", 126, 12, function()
    notice:Hide()
    if FC.OpenCombatReview then FC:OpenCombatReview() end
end)

makeButton("Do not show this again", 168, 148, function()
    if FC.CombatReview then FC.CombatReview:SetReadyNoticeEnabled(false) end
    notice:Hide()
end)

local noticeVersion = 0

function FC:HideCombatAnalysisNotice()
    noticeVersion = noticeVersion + 1
    notice:Hide()
end

function FC:NotifyCombatAnalysisReady()
    if FC.CombatReview and not FC.CombatReview:GetReadyNoticeEnabled() then return end
    local anchor = _G.ForeverCoachingMinimapButton or Minimap
    notice:ClearAllPoints()
    if anchor then
        notice:SetPoint("RIGHT", anchor, "LEFT", -8, 0)
    else
        notice:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -180, -200)
    end
    notice:Show()
    noticeVersion = noticeVersion + 1
    local currentVersion = noticeVersion
    if C_Timer and C_Timer.After then
        C_Timer.After(20, function()
            if currentVersion == noticeVersion then notice:Hide() end
        end)
    end
end

