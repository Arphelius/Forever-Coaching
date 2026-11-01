print("Forever Coaching: Minimap file started")
ForeverCoaching = ForeverCoaching or {}

local button = CreateFrame(
    "Button",
    "ForeverCoachingMinimapButton",
    UIParent
)

button:SetSize(32, 32)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:RegisterForClicks("LeftButtonUp")
button:RegisterForDrag("LeftButton")
button:SetMovable(true)
button:EnableMouse(true)
button:SetClampedToScreen(false)

local angle = math.rad(135)
local function direction(x, y)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi) end
    if y ~= 0 then return y > 0 and math.pi / 2 or -math.pi / 2 end
    return angle
end

local function positionOnRing()
    -- Offsets are in the button's scale; the radius follows the minimap size.
    local scale = Minimap:GetEffectiveScale() / button:GetEffectiveScale()
    local radiusX = (Minimap:GetWidth() / 2 + 8) * scale
    local radiusY = (Minimap:GetHeight() / 2 + 8) * scale
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radiusX, math.sin(angle) * radiusY)
end

local function followCursor()
    local centerX, centerY = Minimap:GetCenter()
    if not centerX or not centerY then return end
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    angle = direction(x / scale - centerX, y / scale - centerY)
    positionOnRing()
end

positionOnRing()
Minimap:HookScript("OnSizeChanged", positionOnRing)

button:SetScript("OnDragStart", function(self)
    GameTooltip:Hide()
    self:SetScript("OnUpdate", followCursor)
    followCursor()
end)

button:SetScript("OnDragStop", function(self)
    followCursor()
    self:SetScript("OnUpdate", nil)
    ForeverCoachingDB = ForeverCoachingDB or {}
    ForeverCoachingDB.minimapAngle = angle
    ForeverCoachingDB.minimapPosition = nil
end)

-- SavedVariables are available when this addon's ADDON_LOADED event fires.
button:RegisterEvent("ADDON_LOADED")
button:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "ForeverCoaching" then return end
    ForeverCoachingDB = ForeverCoachingDB or {}
    local savedAngle = ForeverCoachingDB.minimapAngle
    local position = ForeverCoachingDB.minimapPosition
    if type(savedAngle) == "number" then
        angle = savedAngle
    elseif type(position) == "table" and type(position.x) == "number" and type(position.y) == "number" then
        local centerX, centerY = Minimap:GetCenter()
        if centerX and centerY then
            local scale = UIParent:GetEffectiveScale() / Minimap:GetEffectiveScale()
            angle = direction(position.x * scale - centerX, position.y * scale - centerY)
        end
    end
    positionOnRing()
    ForeverCoachingDB.minimapAngle = angle
    ForeverCoachingDB.minimapPosition = nil
    self:UnregisterEvent("ADDON_LOADED")
end)

button.icon = button:CreateTexture(nil, "BACKGROUND")
button.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
button.icon:SetSize(20, 20)
button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)

button.border = button:CreateTexture(nil, "OVERLAY")
button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
button.border:SetSize(54, 54)
button.border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

button:SetHighlightTexture(
    "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
)

button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Forever Coaching")
    GameTooltip:AddLine("Click to open or close your coaching window.", 1, 1, 1, true)
    GameTooltip:AddLine("Left-drag around the minimap ring.", 1, 1, 1, true)
    if ForeverCoachingDB and ForeverCoachingDB.combatAnalysisReady then
        GameTooltip:AddLine("Combat analysis is ready to review.", 1, 0.82, 0.25, true)
    end
    GameTooltip:Show()
end)

button:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

button:SetScript("OnClick", function()
    if not ForeverCoaching or not ForeverCoaching.ToggleWindow then
        print("Forever Coaching: The coaching window isn't available.")
        return
    end
    ForeverCoaching:ToggleWindow()
end)
print("Forever Coaching: Minimap file finished")
