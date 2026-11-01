local frame = CreateFrame("Frame", "ForeverCoachingFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(460, 230)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("TOP", frame, "TOP", 0, -6)
frame.title:SetText("Forever Coaching Tools")

local function addToolLink(label, url, anchor, yOffset)
    local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset)
    name:SetText(label)

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editBox:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -8)
    editBox:SetPoint("RIGHT", frame, "RIGHT", -28, 0)
    editBox:SetHeight(28)
    editBox:SetAutoFocus(false)
    editBox:SetText(url)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    return editBox
end

local intro = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
intro:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -38)
intro:SetText("Click a URL and press Ctrl+C to copy it.")

local simGearURL = addToolLink(
    "SimGearForever",
    "https://www.curseforge.com/wow/addons/simgearforever",
    intro,
    -14
)

addToolLink(
    "Forever Logs",
    "https://foreverlogs.gg/",
    simGearURL,
    -18
)
