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
local Theme = FC.ClassicTheme
local M = Theme.METRICS
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
    return Theme:FitButton(button, minimum, 18)
end

local function NewButton(parent, label, minimum)
    return Theme:NewButton(parent, label, minimum)
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
logo:SetSize(18, 18)
logo:SetPoint("TOPLEFT", header, "TOPLEFT", 12, -7)

local title = AddText(header, "FOREVER COACHING", 14, GOLD)
title:SetPoint("LEFT", logo, "RIGHT", 8, 0)

local characterText = AddText(header, "Loading character...", 11, MUTED)
characterText:SetPoint("LEFT", title, "RIGHT", 20, 0)
characterText:SetPoint("RIGHT", header, "TOPRIGHT", -32, -16)
characterText:SetJustifyH("RIGHT")
characterText:SetWordWrap(false)

local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
close:SetSize(24, 24)
close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -2, -3)
close:SetScript("OnClick", function()
    frame:Hide()
end)

local TAB_TOP = -28

-- Language: a dropdown at the right of the tab row. Its list belongs to the header, so it
-- always opens above the dashboard (the separate window opened behind it).
local languageButton, languageMenu
local localization = FC.Localization
if localization and localization.languages then
    languageButton = Theme:Dropdown(header, 112)
    languageButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -10, TAB_TOP)
    languageMenu = Theme:Menu(languageButton, 112)
    local rows = {}
    local function languageName(code)
        for _, language in ipairs(localization.languages) do
            if language.code == code then return language.name end
        end
        return "English"
    end
    local function syncLanguage()
        -- Native names stay untranslated: set them on the raw font string.
        local label = languageButton:GetFontString()
        if label then label:SetText(languageName(localization:GetLanguage())) end
    end
    for index, language in ipairs(localization.languages) do
        local row = Theme:NewButton(languageMenu, language.name, false)
        row:SetPoint("TOPLEFT", languageMenu, "TOPLEFT", 4, -4 - (index - 1) * 21)
        row:SetPoint("RIGHT", languageMenu, "RIGHT", -4, 0)
        local code = language.code
        row:SetScript("OnClick", function()
            languageMenu:Hide(); Theme:SetOpen(languageButton, false)
            localization:SetLanguage(code)
        end)
        rows[index] = row
    end
    languageMenu:SetHeight(#rows * 21 + 7)
    languageButton:SetScript("OnClick", function()
        if languageMenu:IsShown() then languageMenu:Hide(); Theme:SetOpen(languageButton, false); return end
        if FC.openGuidePicker then FC.openGuidePicker:Hide() end
        FC.openGuidePicker = languageMenu
        for index, row in ipairs(rows) do
            Theme:SetSelected(row, localization.languages[index].code == localization:GetLanguage())
        end
        languageMenu:Show(); Theme:SetOpen(languageButton, true)
    end)
    languageButton:HookScript("OnShow", syncLanguage)
    syncLanguage()
    FC.languageListeners = FC.languageListeners or {}
    table.insert(FC.languageListeners, syncLanguage)
    -- /fclanguage and other callers open this menu on the dashboard.
    function FC:OpenLanguageMenu()
        if not frame:IsShown() then FC:ToggleWindow() end
        if not languageMenu:IsShown() then languageButton:GetScript("OnClick")(languageButton) end
    end
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

    local cardTitle = AddText(card, heading, 12, GOLD)
    card.title=cardTitle
    cardTitle:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)

    local cardBody = AddText(card, body, 11, TEXT)
    cardBody:SetPoint("TOPLEFT", cardTitle, "BOTTOMLEFT", 0, -8)
    cardBody:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    cardBody:SetJustifyH("LEFT")
    cardBody:SetJustifyV("TOP")
    cardBody:SetWordWrap(true)

    return card,cardBody
end

-- External tool URLs are selectable in the addon so they can be copied without chat.
local function AddResourceRow(parent, heading, description, url, y)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y)
    row:SetSize(CARD_W, 66)
    MakeBackdrop(row, DARK, EDGE)

    local rowTitle = AddText(row, heading, 12, GOLD)
    rowTitle:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -9)

    local rowDescription = AddText(row, description, 10, MUTED)
    rowDescription:SetPoint("TOPLEFT", rowTitle, "BOTTOMLEFT", 0, -4)
    rowDescription:SetWidth(CARD_W - 24)
    rowDescription:SetJustifyH("LEFT")
    rowDescription:SetWordWrap(false)

    local urlBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    urlBox:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 16, 7)
    urlBox:SetWidth(math.floor(CARD_W * .7))
    urlBox:SetHeight(18)
    urlBox:SetFontObject("GameFontHighlightSmall")
    local copyHint = AddText(row, "Ctrl+C to copy", 10, MUTED)
    copyHint:SetPoint("LEFT", urlBox, "RIGHT", 10, 0)
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
        heading = "Optimization",
        description = "Observed combat rotations for trash pulls and named dungeon bosses.",
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
    return value or ''
end

local function UpdateReviewText()
    if reviewWidgets and reviewWidgets.warcraftLogs and reviewWidgets.warcraftLogs.comparisonView then
        local view=reviewWidgets.warcraftLogs
        view.refresh();reviewWidgets.metrics:SetText(view.metrics or '')
        reviewWidgets.content:SetHeight(view.height+20)
        return
    end
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
                if reviewWidgets.warcraftLogs then
                    reviewWidgets.warcraftLogs.refresh()
                    offset=reviewWidgets.warcraftLogs.height+14
                end
                for i,body in ipairs({reviewWidgets.observation,reviewWidgets.takeaway,reviewWidgets.nextStep}) do
                    local card=reviewWidgets.cards[i]
                    card:Show()
                    card.title:SetText(result.headings and result.headings[i] or ({"WHAT YOU DID WELL","WHAT WENT WRONG","WHAT TO IMPROVE"})[i])
                    local height=math.max(84,body:GetStringHeight()+44)
                    card:ClearAllPoints();card:SetPoint("TOPLEFT",reviewWidgets.content,"TOPLEFT",18,-offset);card:SetHeight(height)
                    offset=offset+height+8
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

    -- The open tab is gold and underlined, the others plain.
    for name, button in pairs(navButtons) do Theme:SelectTab(button, name == tabName) end
    if FC.openGuidePicker then FC.openGuidePicker:Hide() end

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
        local comparisonView=FC.WarcraftLogs and FC.BuildWarcraftLogsPanel
        if not comparisonView then
            local toolbar=Theme:Toolbar(currentPage,M.toolbarTop)
            local detailButton=NewButton(currentPage,'Show details',96)
            local function detailLabel()detailButton:SetText(reviewExpanded and 'Less detail' or 'Show details');FitButton(detailButton,96);toolbar:Layout()end
            detailLabel();detailButton:SetScript('OnClick',function()reviewExpanded=not reviewExpanded;detailLabel();UpdateReviewText()end)
            toolbar:Add(detailButton,6)
        end

        local rowTop=comparisonView and M.toolbarTop or M.toolbarTop-M.buttonHeight-6
        reviewText=nil
        reviewWidgets={}
        reviewWidgets.metrics=AddText(currentPage,"",11,MUTED)
        reviewWidgets.metrics:SetPoint("TOPLEFT",M.pagePadding+2,rowTop-5)
        reviewWidgets.metrics:SetPoint("RIGHT",currentPage,"RIGHT",-M.pagePadding,0)
        reviewWidgets.metrics:SetJustifyH("LEFT");reviewWidgets.metrics:SetWordWrap(false)
        local scrollTop=rowTop-M.buttonHeight-8
        local reviewScroll=CreateFrame("ScrollFrame",nil,currentPage,"UIPanelScrollFrameTemplate")
        reviewScroll:SetPoint("TOPLEFT",currentPage,"TOPLEFT",0,scrollTop);reviewScroll:SetPoint("BOTTOMRIGHT",currentPage,"BOTTOMRIGHT",-26,12)
        local reviewContent=CreateFrame("Frame",nil,reviewScroll);reviewContent:SetSize(CARD_W+36,1040);reviewScroll:SetScrollChild(reviewContent)
        if FC.BuildWarcraftLogsPanel then reviewWidgets.warcraftLogs=FC:BuildWarcraftLogsPanel(reviewContent,CARD_W) end
        reviewWidgets.content=reviewContent
        if comparisonView then
            UpdateReviewText()
            if frame:IsShown() then FC.CombatReview:MarkLatestViewed()end
            UpdateCharacterInfo()
            return
        end
        local goodCard,observation=AddCard(reviewContent,"WHAT YOU DID WELL","",0,300)
        local wrongCard,takeaway=AddCard(reviewContent,"WHAT WENT WRONG","",-312,300)
        local improveCard,nextStep=AddCard(reviewContent,"WHAT TO IMPROVE","",-624,300)
        reviewWidgets.cards={goodCard,wrongCard,improveCard};reviewWidgets.content=reviewContent
        reviewWidgets.coverage=AddText(reviewContent,"",10,MUTED);reviewWidgets.coverage:SetPoint("TOPLEFT",20,-940);reviewWidgets.coverage:SetWidth(CARD_W-20)
        reviewWidgets.attribution=AddText(reviewContent,"Warcraft Logs: https://forever.warcraftlogs.com/  |  Supplied comparisons are snapshots, not live website access.",10,MUTED)
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
            guideRow.description:SetText('Wowhead Forever guide / '..class)
            guideRow.urlBox:SetText(FC.BuildPlanner:GetBuildEvidenceUrl(build,class))
        end
        FC:BuildGuideSelectors(currentPage,updateGuideSource);updateGuideSource()
        local resources={
            {"WARCRAFT LOGS - FOREVER","Logged damage, healing and tank references for matching specs and encounters.","https://forever.warcraftlogs.com/"},
            {"FOREVER LOGS - STATISTICS SOURCE","Source of recorded class/spec aggregate statistics. Explore the original data and website.","https://foreverlogs.gg/"},
            {"MYTHICSIM - BUILDS & SIMULATIONS","Build references and simulation research. See each build's own source for its assumptions.","https://mythicsim.com/"},
            {"SIMGEARFOREVER - GEARING COMPANION","Companion addon for gear and stat optimization. Gear integration is planned separately.","https://www.curseforge.com/wow/addons/simgearforever"},
        }
        for index,resource in ipairs(resources) do AddResourceRow(links,resource[1],resource[2],resource[3],-index*72) end
    end

    UpdateCharacterInfo()

end

-- Navigation: one row of tabs under the title, each as wide as its label.
local tabs = {
    { name = "Talents", label = "Talent Builds" },
    { name = "Learn", label = "Learn" },
    { name = "Rotation", label = "Optimization" },
    { name = "Scenarios", label = "Scenarios" },
    { name = "Gear", label = "Gear" },
    { name = "Resources", label = "Resources" },
}

local function LayoutTabs()
    local previous
    for _, tab in ipairs(tabs) do
        local button = navButtons[tab.name]
        Theme:FitButton(button, 40, 20)
        button:ClearAllPoints()
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 2, 0)
        else button:SetPoint("TOPLEFT", header, "TOPLEFT", 6, TAB_TOP) end
        previous = button
    end
end

for i, tab in ipairs(tabs) do
    local button = Theme:Tab(header, tab.label)
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
-- Initial setup: the dashboard opens on Talent Builds; a finished fight opens Combat Review.
UpdateCharacterInfo()
ShowTab("Talents")
frame:Hide()

print("Forever Coaching: Dashboard ready")
