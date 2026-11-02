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
local MUTED = FC.ClassicTheme and FC.ClassicTheme.MUTED or { 0.85, 0.83, 0.78 }
local DARK  = { 0.045, 0.035, 0.025, 0.96 }
local PANEL = { 0.075, 0.060, 0.040, 0.94 }
local EDGE  = { 0.34, 0.27, 0.17 }

-- Layout: SimGear-style slim header (title row, then a row of tabs sized to their text),
-- no sidebar, one window size for every tab (UI/ClassicTheme.lua METRICS).
local M = FC.ClassicTheme and FC.ClassicTheme.METRICS or {
    width = 940, height = 620, gutter = 8, headerHeight = 62, tabHeight = 22, buttonHeight = 22,
    pageTop = -10, toolbarTop = -34, documentTop = -66, pagePadding = 14, contentAlpha = .55, readingAlpha = .82,
}
local CONTENT_W = M.width - 2 * M.gutter
local CARD_W = CONTENT_W - 2 * 18 - 26 -- inside a scroll frame: margins and the scroll bar

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

local function FitButton(button, minimum)
    if FC.ClassicTheme then return FC.ClassicTheme:FitButton(button, minimum) end
    return button
end

local function NewButton(parent, label, minimum)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetHeight(M.buttonHeight)
    button:SetText(label)
    return FitButton(button, minimum)
end

-- Main window
local frame = CreateFrame(
    "Frame",
    "ForeverCoachingFrame",
    UIParent,
    "BackdropTemplate"
)

frame:SetSize(M.width, M.height)
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

-- Header: row 1 icon, title, character and close; row 2 the tabs and Language.
local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
header:SetPoint("TOPLEFT", frame, "TOPLEFT", M.gutter, -M.gutter)
header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -M.gutter, -M.gutter)
header:SetHeight(M.headerHeight)
MakeBackdrop(header, { PANEL[1], PANEL[2], PANEL[3], .80 }, GOLD)

local logo = header:CreateTexture(nil, "ARTWORK")
logo:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
logo:SetSize(20, 20)
logo:SetPoint("TOPLEFT", header, "TOPLEFT", 12, -7)

local title = AddText(header, "FOREVER COACHING", 15, GOLD)
title:SetPoint("LEFT", logo, "RIGHT", 8, 0)

local characterText = AddText(header, "Loading character...", 11, TEXT)
characterText:SetPoint("LEFT", title, "RIGHT", 20, 0)
characterText:SetPoint("RIGHT", header, "TOPRIGHT", -34, -17)
characterText:SetJustifyH("RIGHT")
characterText:SetWordWrap(false)

local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
close:SetSize(26, 26)
close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -2, -2)
close:SetScript("OnClick", function()
    frame:Hide()
end)

local TAB_TOP = -32
local languageButton
if FC.OpenLanguageSettings then
    languageButton = NewButton(header, "Language", 72)
    languageButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -10, TAB_TOP)
    languageButton:SetScript("OnClick", function() FC:OpenLanguageSettings() end)
end

-- Content panel: its background stays in place when tabs change. Translucent, so the
-- background art shows; reading panels and text groups keep darker strips behind text.
local content = CreateFrame("Frame", nil, frame, "BackdropTemplate")
content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -M.gutter, M.gutter)
MakeBackdrop(content, { PANEL[1], PANEL[2], PANEL[3], M.contentAlpha }, EDGE)
if FC.ClassicTheme then FC.ClassicTheme:Artwork(content,.24) end

-- Character details, one line in the header.
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

    local specName
    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            local _, foundName = GetSpecializationInfo(specIndex)
            specName = foundName
        end
    end

    characterText:SetText(
        tostring(name) .. "  ·  Level " .. tostring(level) .. "  ·  " .. tostring(className) ..
        (specName and ("  ·  " .. specName) or "")
    )
end

-- Page helpers
local currentPage

-- Heading and its description on one line; the description is cut with "..." when long.
local function AddSection(parent, heading, description)
    local headingText = AddText(parent, heading, 14, GOLD)
    headingText:SetPoint("TOPLEFT", parent, "TOPLEFT", M.pagePadding, M.pageTop)

    local desc = AddText(parent, description, 11, MUTED)
    desc:SetPoint("LEFT", headingText, "RIGHT", 12, 0)
    desc:SetPoint("RIGHT", parent, "RIGHT", -M.pagePadding, 0)
    desc:SetWordWrap(false)
    desc:SetJustifyH("LEFT")

    return headingText
end

local function AddCard(parent, heading, body, y, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y)
    card:SetSize(CARD_W, height)
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
    row:SetSize(CARD_W, 92)
    MakeBackdrop(row, DARK, EDGE)

    local rowTitle = AddText(row, heading, 13, GOLD)
    rowTitle:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -10)

    local rowDescription = AddText(row, description, 11, TEXT)
    rowDescription:SetPoint("TOPLEFT", rowTitle, "BOTTOMLEFT", 0, -5)
    rowDescription:SetWidth(CARD_W - 28)
    rowDescription:SetJustifyH("LEFT")
    rowDescription:SetWordWrap(true)

    local urlBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    urlBox:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 18, 10)
    urlBox:SetPoint("RIGHT", row, "RIGHT", -14, 0)
    urlBox:SetHeight(22)
    urlBox:SetAutoFocus(false)
    urlBox:SetText(url)
    urlBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    urlBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    row.title=rowTitle;row.description=rowDescription;row.urlBox=urlBox
    return row
end

local pages = {
    Rotation = {
        heading = "After-Combat Review",
        description = "What went well, what needs work, and what to try next.",
        cards = {},
    },
    Talents = {
        heading = "Talent Builds",
        description = "Browse every class, compare activities, and open a build for its talents.",
        cards = {},
    },
    Scenarios = {
        heading = "Combat Scenarios",
        description = "Browse a class, specialization and combat situation.",
        cards = {},
    },
    Learn = {
        heading = "Learn Your Class",
        description = "Choose an ability or talent: when, how and why to use it.",
        cards = {},
    },
    Gear = {
        heading = "Gear & Optimization",
        description = "Useful stats and upgrade comparisons for your chosen build.",
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
local reviewExpanded=false
local function reviewDisplay(value)
    if reviewExpanded then return value or '' end
    local lines={}
    for line in (value or ''):gmatch('[^\n]+') do
        lines[#lines+1]=line
        if #lines>=4 then break end
    end
    return table.concat(lines,'\n\n')
end

local function UpdateReviewText()
    if reviewWidgets and FC.CombatReview and FC.CombatReview.GetLatestSummary then
        local filter=FC.GuideBrowser and FC.GuideBrowser:GetReviewFilter()
        local ok,result=pcall(FC.CombatReview.GetLatestSummary,FC.CombatReview,filter)
        if ok and result then
            reviewWidgets.metrics:SetText(result.metrics)
            reviewWidgets.observation:SetText(reviewDisplay(result.goodText or result.observation))
            reviewWidgets.takeaway:SetText(reviewDisplay(result.wrongText or result.takeaway))
            reviewWidgets.nextStep:SetText(reviewDisplay(result.improveText or result.nextStep))
            if reviewWidgets.coverage then reviewWidgets.coverage:SetText(result.coverage or "Local cast observations; no full encounter event stream is loaded.") end
            if reviewWidgets.cards then
                local offset=0
                for i,body in ipairs({reviewWidgets.observation,reviewWidgets.takeaway,reviewWidgets.nextStep}) do
                    local card=reviewWidgets.cards[i]
                    card.title:SetText(result.headings and result.headings[i] or ({"WHAT YOU DID WELL","WHAT WENT WRONG","WHAT TO IMPROVE"})[i])
                    local height=math.max(110,body:GetStringHeight()+60)
                    card:ClearAllPoints();card:SetPoint("TOPLEFT",reviewWidgets.content,"TOPLEFT",18,-offset);card:SetHeight(height)
                    offset=offset+height+10
                end
                reviewWidgets.coverage:SetShown(reviewExpanded)
                reviewWidgets.attribution:Hide()
                if reviewExpanded then
                    reviewWidgets.coverage:ClearAllPoints();reviewWidgets.coverage:SetPoint("TOPLEFT",20,-offset)
                    offset=offset+math.max(50,reviewWidgets.coverage:GetStringHeight())+18
                end
                reviewWidgets.content:SetHeight(offset+20)
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
    frame:SetSize(M.width,M.height)
    frame:SetScale(math.min(1,((UIParent:GetWidth() or 800)-40)/M.width,((UIParent:GetHeight() or 600)-40)/M.height))

    if currentPage then
        currentPage:Hide()
        currentPage:SetParent(nil)
        currentPage = nil
    end

    -- The open tab is lit, the others plain (SimGear's view tabs).
    for name, button in pairs(navButtons) do
        local label = button:GetFontString()
        if name == tabName then
            if button.LockHighlight then button:LockHighlight() end
            if label then label:SetTextColor(GOLD[1], GOLD[2], GOLD[3]) end
        else
            if button.UnlockHighlight then button:UnlockHighlight() end
            if label then label:SetTextColor(TEXT[1], TEXT[2], TEXT[3]) end
        end
    end

    currentPage = CreateFrame("Frame", nil, content)
    currentPage:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    currentPage:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

    -- Talent Builds lays out its own title row; the tab names the page.
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
        -- Toolbar: class, spec, Use this spec, Show details. Second row: the fight's metrics,
        -- then reminders and the timeline on the right.
        local _,toolbar=FC:BuildGuideSelectors(currentPage,function()
            FC.CombatReview:SetSource('local');UpdateReviewText()
        end)
        local specButton=NewButton(currentPage,'Use this spec',96)
        specButton:SetScript('OnClick',function()
            local class,build=FC.GuideBrowser:GetContext()
            local ok,message=FC.EncounterCoach:SetCombatSpecFallback(class,build)
            print('Forever Coaching: '..message)
        end)
        local detailButton=NewButton(currentPage,'Show details',96)
        local function detailLabel()detailButton:SetText(reviewExpanded and 'Less detail' or 'Show details');FitButton(detailButton,96);toolbar:Layout()end
        detailLabel();detailButton:SetScript('OnClick',function()reviewExpanded=not reviewExpanded;detailLabel();UpdateReviewText()end)
        toolbar:Add(specButton,8);toolbar:Add(detailButton,6)

        local rowTop=M.toolbarTop-M.buttonHeight-6
        local rightEdge=-M.pagePadding
        if FC.OpenFightTimeline then
            local timelineButton=NewButton(currentPage,'View fight timeline',120)
            timelineButton:SetPoint('TOPRIGHT',currentPage,'TOPRIGHT',rightEdge,rowTop)
            timelineButton:SetScript('OnClick',function()FC:OpenFightTimeline()end)
            rightEdge=rightEdge-timelineButton:GetWidth()-6
        end
        local noticeButton = NewButton(currentPage, "Analysis reminders: On", 140)
        noticeButton:SetPoint("TOPRIGHT", currentPage, "TOPRIGHT", rightEdge, rowTop)
        local function UpdateNoticeButton()
            local enabled = not FC.CombatReview or FC.CombatReview:GetReadyNoticeEnabled()
            noticeButton:SetText("Analysis reminders: " .. (enabled and "On" or "Off"))
            FitButton(noticeButton, 140)
        end
        UpdateNoticeButton()
        noticeButton:SetScript("OnClick", function()
            if FC.CombatReview then
                FC.CombatReview:SetReadyNoticeEnabled(not FC.CombatReview:GetReadyNoticeEnabled())
                UpdateNoticeButton()
            end
        end)

        reviewText=nil
        reviewWidgets={}
        reviewWidgets.metrics=AddText(currentPage,"",11,MUTED)
        reviewWidgets.metrics:SetPoint("TOPLEFT",M.pagePadding+2,rowTop-5)
        reviewWidgets.metrics:SetPoint("RIGHT",noticeButton,"LEFT",-10,0)
        reviewWidgets.metrics:SetJustifyH("LEFT");reviewWidgets.metrics:SetWordWrap(false)
        local scrollTop=rowTop-M.buttonHeight-8
        local reviewScroll=CreateFrame("ScrollFrame",nil,currentPage,"UIPanelScrollFrameTemplate")
        reviewScroll:SetPoint("TOPLEFT",currentPage,"TOPLEFT",0,scrollTop);reviewScroll:SetPoint("BOTTOMRIGHT",currentPage,"BOTTOMRIGHT",-26,12)
        local reviewContent=CreateFrame("Frame",nil,reviewScroll);reviewContent:SetSize(CARD_W+36,1040);reviewScroll:SetScrollChild(reviewContent)
        local goodCard,observation=AddCard(reviewContent,"WHAT YOU DID WELL","",0,300)
        local wrongCard,takeaway=AddCard(reviewContent,"WHAT WENT WRONG","",-312,300)
        local improveCard,nextStep=AddCard(reviewContent,"WHAT TO IMPROVE","",-624,300)
        reviewWidgets.cards={goodCard,wrongCard,improveCard};reviewWidgets.content=reviewContent
        reviewWidgets.coverage=AddText(reviewContent,"",10,MUTED);reviewWidgets.coverage:SetPoint("TOPLEFT",20,-940);reviewWidgets.coverage:SetWidth(CARD_W-20)
        reviewWidgets.attribution=AddText(reviewContent,"Forever Logs: https://foreverlogs.gg/  |  Imported reports are snapshots, not live fights.",10,MUTED)
        reviewWidgets.attribution:SetPoint("TOPLEFT",20,-996);reviewWidgets.attribution:SetWidth(CARD_W-20)
        reviewWidgets.observation=observation;reviewWidgets.takeaway=takeaway;reviewWidgets.nextStep=nextStep
        UpdateReviewText()
        if frame:IsShown() and FC.CombatReview then FC.CombatReview:MarkLatestViewed() end
    end

    if tabName == "Resources" then
        local scroll=CreateFrame("ScrollFrame",nil,currentPage,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",0,M.documentTop);scroll:SetPoint("BOTTOMRIGHT",-26,12)
        local links=CreateFrame("Frame",nil,scroll);links:SetSize(CARD_W+36,600);scroll:SetScrollChild(links)
        local guideRow=AddResourceRow(links,'Build guide','','',0)
        local function updateGuideSource()
            local class,build=FC.GuideBrowser:GetContext()
            guideRow.title:SetText(build and build.title or class)
            guideRow.description:SetText('Build guide / '..class)
            guideRow.urlBox:SetText(FC.BuildPlanner:GetBuildEvidenceUrl(build))
        end
        FC:BuildGuideSelectors(currentPage,updateGuideSource);updateGuideSource()
        local resources={
            {"WARCRAFT LOGS - PARSES & RANKINGS","Check your parses and rankings for supported games. Inspiration for log analysis; Forever integration is deferred.","https://www.warcraftlogs.com/"},
            {"FOREVER LOGS - STATISTICS SOURCE","Source of recorded class/spec aggregate statistics. Explore the original data and website.","https://foreverlogs.gg/"},
            {"MYTHICSIM - BUILDS & SIMULATIONS","Build references and simulation research. See each build's own source for its assumptions.","https://mythicsim.com/"},
            {"SIMGEARFOREVER - GEARING COMPANION","Companion addon for gear and stat optimization. Gear integration is planned separately.","https://www.curseforge.com/wow/addons/simgearforever"},
        }
        for index,resource in ipairs(resources) do AddResourceRow(links,resource[1],resource[2],resource[3],-index*102) end
    end

    UpdateCharacterInfo()

end

-- Navigation: one row of tabs under the title, each as wide as its label.
local tabs = {
    { name = "Rotation", label = "Combat Review" },
    { name = "Talents", label = "Talent Builds" },
    { name = "Scenarios", label = "Scenarios" },
    { name = "Learn", label = "Learn" },
    { name = "Gear", label = "Gear" },
    { name = "Resources", label = "Resources" },
}

local function LayoutTabs()
    local previous
    for _, tab in ipairs(tabs) do
        local button = navButtons[tab.name]
        FitButton(button, 64)
        button:ClearAllPoints()
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 4, 0)
        else button:SetPoint("TOPLEFT", header, "TOPLEFT", 10, TAB_TOP) end
        previous = button
    end
    if languageButton then FitButton(languageButton, 72) end
end

for i, tab in ipairs(tabs) do
    local button = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    button:SetHeight(M.tabHeight)
    button:SetText(tab.label)
    button:SetScript("OnClick", function()
        ShowTab(tab.name)
    end)

    navButtons[tab.name] = button
    button.navigationIndex=i
end
LayoutTabs()

-- A language change re-translates labels; re-fit the tabs and rebuild the open page.
FC.languageListeners = FC.languageListeners or {}
table.insert(FC.languageListeners, function()
    LayoutTabs()
    if frame:IsShown() then ShowTab(currentTab) end
end)

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
    if FC.GuideBrowser then FC.GuideBrowser.class=nil;FC.GuideBrowser.buildID=nil end
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
