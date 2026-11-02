local CreateFrame = ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame

-- ForeverCoaching.lua
-- Main dashboard UI

ForeverCoaching = ForeverCoaching or {}
local FC = ForeverCoaching

-- Register before dashboard setup so preview load failures remain diagnosable.
SLASH_FOREVERCOACHINGARTPREVIEW1 = "/fcpreview"
SlashCmdList = SlashCmdList or {}
if not SlashCmdList.FOREVERCOACHINGARTPREVIEW then
SlashCmdList.FOREVERCOACHINGARTPREVIEW = function(query)
    if type(FC.OpenTalentArtPreview) == "function" then
        FC:OpenTalentArtPreview(query)
    else
        print("Forever Coaching: UI/TalentArtPreview.lua has not loaded. Enable errors with /console scriptErrors 1, then /reload and report the first error. Check the installed TOC includes UI/TalentArtPreview.lua.")
    end
end
end

print("Forever Coaching: Main UI loaded")

-- Theme
local GOLD  = { 1.00, 0.72, 0.20 }
local TEXT  = { 0.88, 0.92, 1.00 }
local MUTED = { 0.58, 0.68, 0.80 }
local DARK  = { 0.045, 0.035, 0.025, 0.96 }
local PANEL = { 0.075, 0.060, 0.040, 0.94 }
local EDGE  = { 0.34, 0.27, 0.17 }

local function MakeBackdrop(frame, color, edgeColor)
    if not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    frame:SetBackdropColor(
        color[1], color[2], color[3], color[4] or 1
    )

    frame:SetBackdropBorderColor(
        edgeColor[1], edgeColor[2], edgeColor[3], 1
    )
end

local function AddText(parent, text, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size, "")
    fs:SetTextColor(color[1], color[2], color[3])
    fs:SetText(text)
    return fs
end

-- Main window
local frame = CreateFrame(
    "Frame",
    "ForeverCoachingFrame",
    UIParent,
    "BackdropTemplate"
)

frame:SetSize(760, 500)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetClampedToScreen(true)
-- Let Blizzard's standard Escape handling close the dashboard.
UISpecialFrames = UISpecialFrames or {}
local registeredForEscape = false
for _, name in ipairs(UISpecialFrames) do
    if name == "ForeverCoachingFrame" then registeredForEscape = true; break end
end
if not registeredForEscape then
    table.insert(UISpecialFrames, "ForeverCoachingFrame")
end
MakeBackdrop(frame, DARK, GOLD)
if FC.ClassicTheme then FC.ClassicTheme:Artwork(frame,.30) end

-- Header
local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
header:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
header:SetHeight(76)
MakeBackdrop(header, PANEL, GOLD)

local logo = header:CreateTexture(nil, "ARTWORK")
logo:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
logo:SetSize(48, 48)
logo:SetPoint("LEFT", header, "LEFT", 16, 0)

local title = AddText(header, "FOREVER COACHING", 23, GOLD)
title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 12, -5)

local subtitle = AddText(
    header, "YOUR PERSONAL COMBAT COACH", 10, MUTED
)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -5)

local characterText = AddText(header, "Loading character...", 12, TEXT)
local compactHeader=false
characterText:SetPoint("RIGHT", header, "RIGHT", -45, 0)
characterText:SetJustifyH("RIGHT")

local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", header, "TOPRIGHT", 1, 1)
close:SetScript("OnClick", function()
    frame:Hide()
end)

-- Sidebar
local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
sidebar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
sidebar:SetWidth(170)
MakeBackdrop(sidebar, PANEL, EDGE)
if FC.OpenLanguageSettings then
    local languageButton=CreateFrame('Button',nil,sidebar,'UIPanelButtonTemplate')
    languageButton:SetSize(146,26);languageButton:SetPoint('BOTTOMLEFT',sidebar,'BOTTOMLEFT',12,14)
    languageButton:SetText('Language');languageButton:SetScript('OnClick',function()FC:OpenLanguageSettings()end)
end

-- Content panel: its background stays in place when tabs change.
local content = CreateFrame("Frame", nil, frame, "BackdropTemplate")
content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
MakeBackdrop(content, PANEL, EDGE)
if FC.ClassicTheme then FC.ClassicTheme:Artwork(content,.24) end
local talentNav=CreateFrame("Frame",nil,content)
talentNav:SetPoint("TOPLEFT",12,-8);talentNav:SetSize(860,28);talentNav:Hide()

-- Character details
local function UpdateCharacterInfo()
    local name = UnitName("player") or "Unknown"
    local level = UnitLevel("player") or "?"
    local _, className = UnitClass("player")
    className = className or "Unknown"

    if FC.GetCharacterInfo then
        local ok, info = pcall(FC.GetCharacterInfo, FC)
        if ok and info then
            name = info.name or name
            level = info.level or level
            className = info.className or className
        end
    end

    local specName = "Specialization unavailable"
    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            local _, foundName = GetSpecializationInfo(specIndex)
            if foundName then
                specName = foundName
            end
        end
    end

    if compactHeader then
        characterText:SetText(tostring(name).." | Level "..tostring(level))
        return
    end
    characterText:SetText(
        tostring(name) .. "\n" ..
        tostring(className) .. " | Level " .. tostring(level) ..
        "\n" .. specName
    )
end

-- Page helpers
local currentPage

local function AddSection(parent, heading, description)
    local headingText = AddText(parent, heading, 20, GOLD)
    headingText:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -24)

    local desc = AddText(parent, description, 12, MUTED)
    desc:SetPoint("TOPLEFT", headingText, "BOTTOMLEFT", 0, -8)
    desc:SetPoint("RIGHT", parent, "RIGHT", -24, 0)
    desc:SetWordWrap(true)
    desc:SetJustifyH("LEFT")

    return headingText
end

local function AddCard(parent, heading, body, y, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y)
    card:SetSize(510, height)
    MakeBackdrop(card, DARK, EDGE)

    local cardTitle = AddText(card, heading, 13, GOLD)
    card.title=cardTitle
    cardTitle:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -14)

    local cardBody = AddText(card, body, 12, TEXT)
    cardBody:SetPoint("TOPLEFT", cardTitle, "BOTTOMLEFT", 0, -12)
    cardBody:SetPoint("RIGHT", card, "RIGHT", -14, 0)
    cardBody:SetJustifyH("LEFT")
    cardBody:SetJustifyV("TOP")
    cardBody:SetWordWrap(true)

    return card,cardBody
end

-- External tool URLs are selectable in the addon so they can be copied without chat.
local function AddResourceRow(parent, heading, description, url, y)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y)
    row:SetSize(510, 104)
    MakeBackdrop(row, DARK, EDGE)

    local rowTitle = AddText(row, heading, 13, GOLD)
    rowTitle:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -10)

    local rowDescription = AddText(row, description, 10, TEXT)
    rowDescription:SetPoint("TOPLEFT", rowTitle, "BOTTOMLEFT", 0, -5)
    rowDescription:SetWidth(475)
    rowDescription:SetJustifyH("LEFT")
    rowDescription:SetWordWrap(true)

    local urlBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    urlBox:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 14, 12)
    urlBox:SetPoint("RIGHT", row, "RIGHT", -14, 0)
    urlBox:SetHeight(24)
    urlBox:SetAutoFocus(false)
    urlBox:SetText(url)
    urlBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    urlBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    return row
end

local pages = {
    Rotation = {
        heading = "After-Combat Review",
        description = "Understand what went well, what went wrong, and what to improve, with explanations from recorded combat.",
        cards = {},
    },
    Talents = {
        heading = "Talent Builds",
        description = "Browse every class, compare activities, and open a build for its talents.",
        cards = {},
    },
    Scenarios = {
        heading = "Combat Scenarios",
        description = "Practice encounter responses and inspect recorded opportunities for your build.",
        cards = {},
    },
    Learn = {
        heading = "Learn Your Class",
        description = "Learn your actual abilities: when, how and why to use them.",
        cards = {},
    },
    Gear = {
        heading = "Gear & Optimization",
        description = "Stats for your selected build and tools for comparing actual upgrades.",
        cards = {},
    },
    Resources = {
        heading = "Resources & Performance",
        description = "Sources, inspiration and companion tools. Select a URL and press Ctrl+C to copy.",
        cards = {},
    },
}

local navButtons = {}
local currentTab = "Rotation"
local reviewText
local reviewWidgets

local function UpdateReviewText()
    if reviewWidgets and FC.CombatReview and FC.CombatReview.GetLatestSummary then
        local ok,result=pcall(FC.CombatReview.GetLatestSummary,FC.CombatReview)
        if ok and result then
            reviewWidgets.metrics:SetText(result.metrics)
            reviewWidgets.observation:SetText(result.goodText or result.observation or "")
            reviewWidgets.takeaway:SetText(result.wrongText or result.takeaway or "")
            reviewWidgets.nextStep:SetText(result.improveText or result.nextStep or "")
            if reviewWidgets.coverage then reviewWidgets.coverage:SetText(result.coverage or "Local cast observations; no full encounter event stream is loaded.") end
            if reviewWidgets.cards then
                local offset=0
                for i,body in ipairs({reviewWidgets.observation,reviewWidgets.takeaway,reviewWidgets.nextStep}) do
                    local card=reviewWidgets.cards[i]
                    card.title:SetText(result.headings and result.headings[i] or ({"WHAT YOU DID WELL","WHAT WENT WRONG","WHAT TO IMPROVE"})[i])
                    local height=math.max(160,body:GetStringHeight()+70)
                    card:ClearAllPoints();card:SetPoint("TOPLEFT",reviewWidgets.content,"TOPLEFT",18,-offset);card:SetHeight(height)
                    offset=offset+height+12
                end
                reviewWidgets.coverage:ClearAllPoints();reviewWidgets.coverage:SetPoint("TOPLEFT",20,-offset)
                offset=offset+math.max(50,reviewWidgets.coverage:GetStringHeight())+18
                reviewWidgets.attribution:ClearAllPoints();reviewWidgets.attribution:SetPoint("TOPLEFT",20,-offset)
                reviewWidgets.content:SetHeight(offset+70)
            end
        else
            reviewWidgets.metrics:SetText("Review unavailable")
            reviewWidgets.observation:SetText("The saved review could not be read.")
            reviewWidgets.takeaway:SetText("");reviewWidgets.nextStep:SetText("")
        end
        return
    end
    if not reviewText or not FC.CombatReview then return end
    local ok, text = pcall(FC.CombatReview.GetLatestText, FC.CombatReview)
    if not ok then
        FC.combatReviewDisplayError = tostring(text)
        text = "The combat review could not be displayed."
    elseif type(text) ~= "string" or text == "" then
        text = "Finish a fight to see your combat review here."
    end
    reviewText:SetText(text)
    reviewText:Show()
end

function FC:RefreshCombatReview()
    UpdateReviewText()
end

local function ShowTab(tabName)
    local pageData = pages[tabName]
    if not pageData then
        return
    end

    currentTab = tabName
    reviewWidgets=nil
    compactHeader=tabName=="Talents"
    header:SetHeight(compactHeader and 36 or 76)
    logo:SetSize(compactHeader and 24 or 48,compactHeader and 24 or 48)
    title:SetFont("Fonts\\FRIZQT__.TTF",compactHeader and 15 or 23,"")
    title:ClearAllPoints();title:SetPoint("LEFT",logo,"RIGHT",compactHeader and 8 or 12,compactHeader and 0 or 10)
    subtitle:SetShown(not compactHeader)
    sidebar:SetShown(not compactHeader);talentNav:SetShown(compactHeader)
    content:ClearAllPoints()
    if compactHeader then content:SetPoint("TOPLEFT",header,"BOTTOMLEFT",0,-6)
    else content:SetPoint("TOPLEFT",sidebar,"TOPRIGHT",8,0) end
    content:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-8,8)
    for _,button in pairs(navButtons) do
        button:ClearAllPoints()
        button:SetParent(compactHeader and talentNav or sidebar)
        if compactHeader then
            button:SetPoint("TOPLEFT",talentNav,"TOPLEFT",(button.navigationIndex-1)*142,0);button:SetSize(136,26)
        else
            button:SetPoint("TOPLEFT",sidebar,"TOPLEFT",10,-12-(button.navigationIndex-1)*52);button:SetSize(148,42)
        end
    end
    if tabName == "Talents" then
        frame:SetSize(900,650)
        frame:SetScale(math.min(1,((UIParent:GetWidth() or 940)-40)/900,((UIParent:GetHeight() or 690)-40)/650))
    elseif tabName == 'Learn' or tabName == 'Scenarios' or tabName == 'Gear' then
        frame:SetSize(960,700)
        frame:SetScale(math.min(1,((UIParent:GetWidth() or 1000)-40)/960,((UIParent:GetHeight() or 740)-40)/700))
    else
        frame:SetSize(760, 500)
        frame:SetScale(1)
    end

    if currentPage then
        currentPage:Hide()
        currentPage:SetParent(nil)
        currentPage = nil
    end

    for name, button in pairs(navButtons) do
        if button.SetBackdropColor then
            if name == tabName then
                button:SetBackdropColor(0.34, 0.20, 0.08, 1)
                button:SetBackdropBorderColor(
                    GOLD[1], GOLD[2], GOLD[3], 1
                )
            else
                button:SetBackdropColor(0.08, 0.055, 0.035, 1)
                button:SetBackdropBorderColor(
                    EDGE[1], EDGE[2], EDGE[3], 1
                )
            end
        end
    end

    currentPage = CreateFrame("Frame", nil, content)
    currentPage:SetScale(compactHeader and .94 or 1)
    currentPage:SetPoint("TOPLEFT", content, "TOPLEFT", 0,compactHeader and -40 or 0)
    currentPage:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

    if tabName ~= "Talents" then AddSection(currentPage, pageData.heading, pageData.description) end

    for _, cardData in ipairs((tabName=="Scenarios" or tabName=="Learn") and {} or pageData.cards) do
        AddCard(
            currentPage,
            cardData[1],
            cardData[2],
            cardData[3],
            cardData[4]
        )
    end

    if tabName == "Talents" and FC.BuildTalentPage then
        FC:BuildTalentPage(currentPage)
    end
    if (tabName=="Scenarios" or tabName=="Learn") and FC.BuildEncounterLearningPage then
        FC:BuildEncounterLearningPage(currentPage,tabName)
    end
    if tabName=="Gear" and FC.BuildGearGuidePage then FC:BuildGearGuidePage(currentPage) end

    if tabName == "Rotation" then
        local noticeButton = CreateFrame("Button", nil, currentPage, "UIPanelButtonTemplate")
        noticeButton:SetSize(190, 26)
        noticeButton:SetPoint("TOPLEFT", currentPage, "TOPLEFT", 18, -94)
        local function UpdateNoticeButton()
            local enabled = not FC.CombatReview or FC.CombatReview:GetReadyNoticeEnabled()
            noticeButton:SetText("Analysis reminders: " .. (enabled and "On" or "Off"))
        end
        UpdateNoticeButton()
        noticeButton:SetScript("OnClick", function()
            if FC.CombatReview then
                FC.CombatReview:SetReadyNoticeEnabled(not FC.CombatReview:GetReadyNoticeEnabled())
                UpdateNoticeButton()
            end
        end)
        if FC.OpenFightTimeline then
            local timelineButton=CreateFrame('Button',nil,currentPage,'UIPanelButtonTemplate');timelineButton:SetSize(160,24);timelineButton:SetPoint('TOPRIGHT',currentPage,'TOPRIGHT',-20,-126);timelineButton:SetText('View fight timeline');timelineButton:SetScript('OnClick',function()FC:OpenFightTimeline()end)
        end

        reviewText=nil
        reviewWidgets={}
        reviewWidgets.metrics=AddText(currentPage,"",11,MUTED)
        reviewWidgets.metrics:SetPoint("TOPLEFT",20,-128)
        local reviewScroll=CreateFrame("ScrollFrame",nil,currentPage,"UIPanelScrollFrameTemplate")
        reviewScroll:SetPoint("TOPLEFT",currentPage,"TOPLEFT",0,-158);reviewScroll:SetPoint("BOTTOMRIGHT",currentPage,"BOTTOMRIGHT",-26,18)
        local reviewContent=CreateFrame("Frame",nil,reviewScroll);reviewContent:SetSize(536,1040);reviewScroll:SetScrollChild(reviewContent)
        local goodCard,observation=AddCard(reviewContent,"WHAT YOU DID WELL","",0,300)
        local wrongCard,takeaway=AddCard(reviewContent,"WHAT WENT WRONG","",-312,300)
        local improveCard,nextStep=AddCard(reviewContent,"WHAT TO IMPROVE","",-624,300)
        reviewWidgets.cards={goodCard,wrongCard,improveCard};reviewWidgets.content=reviewContent
        reviewWidgets.coverage=AddText(reviewContent,"",10,MUTED);reviewWidgets.coverage:SetPoint("TOPLEFT",20,-940);reviewWidgets.coverage:SetWidth(490)
        reviewWidgets.attribution=AddText(reviewContent,"Forever Logs: https://foreverlogs.gg/  |  Imported reports are snapshots, not live fights.",10,MUTED)
        reviewWidgets.attribution:SetPoint("TOPLEFT",20,-996);reviewWidgets.attribution:SetWidth(490)
        reviewWidgets.observation=observation;reviewWidgets.takeaway=takeaway;reviewWidgets.nextStep=nextStep
        UpdateReviewText()
        if frame:IsShown() and FC.CombatReview then FC.CombatReview:MarkLatestViewed() end
    end

    if tabName == "Resources" then
        local scroll=CreateFrame("ScrollFrame",nil,currentPage,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",0,-94);scroll:SetPoint("BOTTOMRIGHT",-26,18)
        local links=CreateFrame("Frame",nil,scroll);links:SetSize(536,480);scroll:SetScrollChild(links)
        local resources={
            {"WARCRAFT LOGS - PARSES & RANKINGS","Check your parses and rankings for supported games. Inspiration for log analysis; Forever integration is deferred.","https://www.warcraftlogs.com/"},
            {"FOREVER LOGS - STATISTICS SOURCE","Source of recorded class/spec aggregate statistics. Explore the original data and website.","https://foreverlogs.gg/"},
            {"MYTHICSIM - BUILDS & SIMULATIONS","Build references and simulation research. See each build's own source for its assumptions.","https://mythicsim.com/"},
            {"SIMGEARFOREVER - GEARING COMPANION","Companion addon for gear and stat optimization. Gear integration is planned separately.","https://www.curseforge.com/wow/addons/simgearforever"},
        }
        for index,resource in ipairs(resources) do AddResourceRow(links,resource[1],resource[2],resource[3],-(index-1)*116) end
    end

    UpdateCharacterInfo()

end

-- Navigation
local tabs = {
    { name = "Rotation", label = "Combat Review" },
    { name = "Talents", label = "Talent Builds" },
    { name = "Scenarios", label = "Scenarios" },
    { name = "Learn", label = "Learn" },
    { name = "Gear", label = "Gear" },
    { name = "Resources", label = "Resources" },
}

for i, tab in ipairs(tabs) do
    local button = CreateFrame(
        "Button", nil, sidebar, "BackdropTemplate"
    )

    button:SetPoint(
        "TOPLEFT", sidebar, "TOPLEFT", 10, -12 - ((i - 1) * 52)
    )
    button:SetSize(148, 42)
    MakeBackdrop(button, DARK, EDGE)
    if FC.ClassicTheme then FC.ClassicTheme:Button(button) end

    local label = AddText(button, tab.label, 13, TEXT)
    label:SetPoint("LEFT", button, "LEFT", 12, 0)

    button:SetScript("OnClick", function()
        ShowTab(tab.name)
    end)

    navButtons[tab.name] = button
    button.navigationIndex=i
end

local motto = AddText(
    sidebar,
    "Better decisions.\nStronger performance.",
    11,
    MUTED
)
motto:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 12, 24)
motto:SetWidth(145)
motto:SetJustifyH("CENTER")

-- Window controls
function FC:ToggleWindow()
    if frame:IsShown() then
        frame:Hide()
    else
        if ForeverCoachingDB and ForeverCoachingDB.combatAnalysisReady then
            ShowTab("Rotation")
        end
        UpdateCharacterInfo()
        UpdateReviewText()
        frame:Show()
    end
end

function FC:OpenCombatReview()
    ShowTab("Rotation")
    UpdateReviewText()
    UpdateCharacterInfo()
    if FC.CombatReview then FC.CombatReview:MarkLatestViewed() end
    frame:Show()
end

frame:SetScript("OnShow", function()
    UpdateCharacterInfo()
    UpdateReviewText()
    if currentTab == "Rotation" then
        if FC.CombatReview then FC.CombatReview:MarkLatestViewed() end
        if FC.HideCombatAnalysisNotice then FC:HideCombatAnalysisNotice() end
    end
end)
-- Initial setup
UpdateCharacterInfo()
ShowTab("Rotation")
frame:Hide()

print("Forever Coaching: Dashboard ready")
