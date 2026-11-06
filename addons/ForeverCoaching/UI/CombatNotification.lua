local CreateFrame = ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
ForeverCoaching = ForeverCoaching or {}
local FC = ForeverCoaching

local notice = CreateFrame("Frame", "ForeverCoachingCombatNotice", UIParent, "BackdropTemplate")
notice:SetSize(390, 132)
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
title:SetText("Fight finished — review your fight")

local detail = notice:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detail:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
detail:SetWidth(356)
detail:SetJustifyH("LEFT")
detail:SetText("Check Combat Review for what went well and what needs improving.")

local function makeButton(label, width, x, onClick)
    local button = CreateFrame("Button", nil, notice, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("BOTTOMLEFT", notice, "BOTTOMLEFT", x, 10)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

makeButton("Review fight", 146, 12, function()
    FC:HideCombatAnalysisNotice()
    if FC.CombatReview then FC.CombatReview:SetSource("local") end
    if FC.OpenCombatReview then FC:OpenCombatReview() end
end)

makeButton("Silence reminders", 188, 172, function()
    if FC.CombatReview then FC.CombatReview:SetReadyNoticeEnabled(false) end
    notice:Hide()
end)
local dismiss=CreateFrame("Button",nil,notice,"UIPanelCloseButton")
dismiss:SetPoint("TOPRIGHT",notice,"TOPRIGHT",-3,-3)
dismiss:SetScript("OnClick",function() FC:HideCombatAnalysisNotice() end)

local noticeVersion = 0

function FC:HideCombatAnalysisNotice()
    noticeVersion = noticeVersion + 1
    notice:Hide()
end

function FC:NotifyCombatAnalysisReady(report)
    if FC.CombatReview and not FC.CombatReview:GetReadyNoticeEnabled() then return end
    if UnitAffectingCombat and UnitAffectingCombat("player") then return end
    local summary="Check Combat Review for what went well and what needs improving."
    if report then
        local format="%ds fight · %d casts recorded."
        if FC.Text then format=FC:Text(format) end
        summary=string.format(format,math.floor(report.duration or 0),report.casts or 0).."\n"..summary
    end
    detail:SetText(summary)
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

-- Never leave a post-fight popup covering the next combat.
notice:RegisterEvent("PLAYER_REGEN_DISABLED")
notice:SetScript("OnEvent",function() FC:HideCombatAnalysisNotice() end)
if not SlashCmdList then SlashCmdList={} end
SLASH_FOREVERCOACHINGREMINDERS1="/fcreminders"
SlashCmdList.FOREVERCOACHINGREMINDERS=function(message)
    local command=(message or ""):lower():match("^%s*(%S*)")
    if command=="on" or command=="off" then
        FC.CombatReview:SetReadyNoticeEnabled(command=="on")
        print("Forever Coaching: post-fight reminders "..(command=="on" and "enabled." or "silenced. Recording continues."))
    else print("Forever Coaching: /fcreminders on | off. You can also toggle Analysis reminders in Combat Review.") end
end

