ForeverCoaching = ForeverCoaching or {}
local FC = ForeverCoaching

-- A shown controller keeps updating even when the icon strip is hidden.
local controller = CreateFrame("Frame", "ForeverCoachingCombatHUD", UIParent)
controller:SetSize(1, 1)
controller:SetPoint("BOTTOM")
controller:EnableMouse(false)
local encounterText=controller:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
encounterText:SetPoint("BOTTOM",UIParent,"BOTTOM",0,220)
encounterText:SetWidth(520);encounterText:SetJustifyH("CENTER");encounterText:Hide()

local GROUPS = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button",
    "MultiBar6Button", "MultiBar7Button",
}
local overlays, active = {}, {}
local cachedSpell, cachedButtons
local elapsed, anchorElapsed = 1, 1
local function secret(value)
    return issecretvalue and issecretvalue(value)
end
local function shown(button)
    if not button then return false end
    local ok, visible = pcall(button.IsShown, button)
    return ok and not secret(visible) and visible == true
end
local function findButtons(rec)
    local cacheKey=(rec.itemID and 'item:'..rec.itemID or rec.spellID)
    if cachedSpell == cacheKey and cachedButtons then return cachedButtons end
    local matches = { [rec.itemID or rec.spellID] = true }
    for _, id in ipairs(rec.spellRanks or {}) do matches[id] = true end
    local buttons = {}
    if GetActionInfo then
        for _, group in ipairs(GROUPS) do
            for index = 1, 12 do
                local button = _G[group .. index]
                if shown(button) then
                    local ok, slot = pcall(function() return button.action end)
                    if ok and not secret(slot) and type(slot) == "number" then
                        local infoOK, kind, id = pcall(GetActionInfo, slot)
                        if infoOK and not secret(kind) and not secret(id) then
                            if rec.itemID then
                                if kind=='macro' and GetMacroItem then
                                    local macroOK,_,link=pcall(GetMacroItem,id)
                                    id=macroOK and not secret(link) and type(link)=='string' and tonumber(link:match('item:(%d+)')) or nil
                                elseif kind~='item' then id=nil end
                            elseif kind == "macro" and GetMacroSpell then
                                local macroOK, first, _, spellID = pcall(GetMacroSpell, id)
                                if macroOK and not secret(spellID) and type(spellID) == "number" then
                                    id = spellID
                                else
                                    id = macroOK and first or nil
                                end
                            elseif kind ~= "spell" then
                                id = nil
                            end
                            if id and not secret(id) and matches[id] then buttons[#buttons + 1] = button end
                        end
                    end
                end
            end
        end
    end
    cachedSpell, cachedButtons = cacheKey, buttons
    return buttons
end

local function makeGlow(button)
    -- Independent of protected action buttons: only draw above them.
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:EnableMouse(false)
    frame:SetFrameStrata(button:GetFrameStrata())
    frame:SetFrameLevel(button:GetFrameLevel() + 20)
    frame:SetSize(button:GetWidth() + 6, button:GetHeight() + 6)
    frame:SetScale(button:GetEffectiveScale() / UIParent:GetEffectiveScale())
    frame:SetPoint("CENTER", button, "CENTER")
    for _, scale in ipairs({ 1.65, 1.3 }) do
        local halo = frame:CreateTexture(nil, "OVERLAY")
        halo:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        halo:SetBlendMode("ADD")
        halo:SetPoint("CENTER")
        halo:SetSize(frame:GetWidth() * scale, frame:GetHeight() * scale)
        halo:SetVertexColor(1, 0.68, 0.08, 1)
    end
    for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local line = frame:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(1, 0.82, 0.18, 1)
        if edge == "TOP" or edge == "BOTTOM" then
            line:SetSize(frame:GetWidth(), 3)
        else
            line:SetSize(3, frame:GetHeight())
        end
        line:SetPoint(edge, frame, edge)
    end
    frame.pulse = frame:CreateAnimationGroup()
    frame.pulse:SetLooping("BOUNCE")
    local alpha = frame.pulse:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.72)
    alpha:SetToAlpha(1)
    alpha:SetDuration(0.4)
    frame:Hide()
    return frame
end

local function updateGlows(buttons)
    local desired = {}
    for _, button in ipairs(buttons or {}) do
        if shown(button) then
            desired[button] = true
            local glow = overlays[button]
            if not glow then
                glow = makeGlow(button)
                overlays[button] = glow
            end
            glow:Show()
            if not glow.pulse:IsPlaying() then glow.pulse:Play() end
        end
    end
    for button, glow in pairs(active) do
        if not desired[button] then
            glow.pulse:Stop()
            glow:Hide()
            active[button] = nil
        end
    end
    for button in pairs(desired) do active[button] = overlays[button] end
end

local strip = CreateFrame("Frame", "ForeverCoachingRotationStrip", UIParent)
strip:SetSize(48, 56)
strip:SetFrameStrata("HIGH")
strip:EnableMouse(false)
strip:SetClampedToScreen(true)
strip:Hide()
local slots, layoutKey, currentID = {}

local function positionStrip()
    local top = 90
    -- Some client layouts expose action buttons positioned at the top of the
    -- screen. Only bottom-bar coordinates may influence this strip's anchor.
    local ceiling = math.min(180, UIParent:GetHeight() * 0.25)
    local parentScale = UIParent:GetEffectiveScale()
    for _, group in ipairs({ "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton" }) do
        for index = 1, 12 do
            local button = _G[group .. index]
            if shown(button) then
                local ok, value = pcall(function()
                    return button:GetTop() * button:GetEffectiveScale() / parentScale
                end)
                if ok and not secret(value) and type(value) == "number"
                    and value > 0 and value <= ceiling then top = math.max(top, value) end
            end
        end
    end
    strip:ClearAllPoints()
    strip:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, top + 53)
end

local function makeSlot(index)
    local slot = CreateFrame("Frame", 'ForeverCoachingRotationSlot'..index, strip)
    slot:EnableMouse(false)
    local background = slot:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.015, 0.02, 0.03, 0.95)
    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetPoint("TOPLEFT", 2, -2)
    slot.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    slot.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    slot.highlight = slot:CreateTexture(nil, "OVERLAY")
    slot.highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    slot.highlight:SetBlendMode("ADD")
    slot.highlight:SetPoint("CENTER")
    slot.highlight:SetVertexColor(1, 0.8, 0.15)
    slot.enter = slot:CreateAnimationGroup()
    local alpha = slot.enter:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.25)
    alpha:SetToAlpha(1)
    alpha:SetDuration(0.22)
    slots[index] = slot
    return slot
end

local ghost = CreateFrame("Frame", 'ForeverCoachingRotationCompleted', strip)
ghost:SetFrameLevel(strip:GetFrameLevel() + 5)
ghost:EnableMouse(false)
ghost.icon = ghost:CreateTexture(nil, "OVERLAY")
ghost.icon:SetAllPoints()
ghost.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
ghost.fade = ghost:CreateAnimationGroup()
local fadeAlpha = ghost.fade:CreateAnimation("Alpha")
fadeAlpha:SetFromAlpha(0.85)
fadeAlpha:SetToAlpha(0)
fadeAlpha:SetDuration(0.25)
local fadeMove = ghost.fade:CreateAnimation("Translation")
fadeMove:SetOffset(0, 18)
fadeMove:SetDuration(0.25)
ghost.fade:SetScript("OnFinished", function() ghost:Hide() end)
ghost:Hide()
local lastFadeAt = -1
local function fadeCurrent()
    if not strip:IsShown() or not slots[1] or GetTime() - lastFadeAt < 0.15 then return end
    lastFadeAt = GetTime()
    ghost.fade:Stop()
    ghost:SetSize(slots[1]:GetSize())
    ghost:ClearAllPoints()
    ghost:SetPoint("CENTER", slots[1], "CENTER")
    ghost.icon:SetTexture(slots[1].icon:GetTexture())
    ghost:Show()
    ghost.fade:Play()
    slots[1].enter:Stop()
    slots[1].enter:Play()
end

local function renderStrip(rec)
    local entries=rec.queue or {{id=rec.spellID,icon=rec.icon}}
    if not rec.queue and rec.nextSpell then entries[2]=rec.nextSpell end
    local keys = { tostring(rec.spellID), rec.nextSpell and tostring(rec.nextSpell.id) or "-" }
    for index=1,4 do local spell=entries[index];keys[#keys+1]=spell and (tostring(spell.itemID or spell.id)..':'..tostring(spell.icon)) or '-' end
    local key = table.concat(keys, ":")
    -- A situation change is not evidence that the previous action was used.
    currentID = rec.spellID
    if layoutKey ~= key then
        local width = 0
        for index=1,4 do
            local spell=entries[index]
            local slot = slots[index] or makeSlot(index)
            local isNext = index == 2
            local size = index == 1 and 48 or (isNext and 40 or 34)
            slot:SetSize(size, size)
            slot:ClearAllPoints()
            slot:SetPoint("LEFT", strip, "LEFT", width, 0)
            slot.icon:SetTexture(spell and (spell.icon or "Interface\\Icons\\INV_Misc_QuestionMark") or nil)
            slot.highlight:SetSize(size * 1.65, size * 1.65)
            slot.highlight:SetShown(index == 1)
            slot:Show()
            width = width + size + (index == 1 and 14 or 6)
        end
        for index = 5, #slots do slots[index]:Hide() end
        strip:SetSize(math.max(48, width - 6), 56)
        layoutKey = key
        slots[1].enter:Stop()
        slots[1].enter:Play()
    end
    -- Restore brightness after a cast, even if the recommendation repeats.
    for index = 1,4 do
        slots[index]:SetAlpha(entries[index] and (index == 1 and 1 or (index == 2 and 0.6 or 0.3)) or 0.12)
        slots[index].highlight:SetShown(index == 1)
    end
    strip:Show()
end

local function clearDisplay()
    strip:Hide()
    ghost.fade:Stop()
    ghost:Hide()
    layoutKey, currentID = nil, nil
    updateGlows(nil)
end

local events = CreateFrame("Frame")
for _, event in ipairs({
    "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR",
    "UPDATE_OVERRIDE_ACTIONBAR", "UPDATE_BINDINGS", "PLAYER_ENTERING_WORLD",
    "UNIT_SPELLCAST_SUCCEEDED",
}) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if not secret(unit) and not secret(spellID) and unit == "player" then
            if spellID == currentID then fadeCurrent() end
            elapsed = 1
        end
    else
        cachedSpell, cachedButtons = nil, nil
        anchorElapsed, elapsed = 1, 1
    end
end)

controller:SetScript("OnUpdate", function(_, dt)
    elapsed, anchorElapsed = elapsed + dt, anchorElapsed + dt
    if anchorElapsed >= 1 then
        anchorElapsed = 0
        pcall(positionStrip)
    end
    if elapsed < 0.12 then return end
    elapsed = 0
    local engine=FC.LiveRotation or FC.RotationCoach
    if not engine or not engine.GetRecommendation then
        encounterText:Hide()
        pcall(clearDisplay)
        return
    end
    local ok, rec = pcall(engine.GetRecommendation, engine)
    if not FC.LiveRotation and FC.EncounterCoach then
        local situationOK,situation=pcall(FC.EncounterCoach.GetRecommendation,FC.EncounterCoach)
        if situationOK and situation then ok,rec=true,situation end
    end
    if not ok or type(rec) ~= "table" then
        encounterText:Hide()
        FC.combatHUDLastError = tostring(rec or "No recommendation returned")
        pcall(clearDisplay)
        return
    end
    if FC.CombatReview then pcall(FC.CombatReview.SetLatestRecommendation, FC.CombatReview, rec) end
    if rec.blocksRotation then encounterText:Hide()
    elseif rec.encounterPrompt or not rec.spellID and rec.targetHostile~=false then encounterText:SetText(rec.reason or rec.message or '');encounterText:Show() else encounterText:Hide() end
    if rec.targetHostile == false and not rec.encounterPrompt then
        pcall(clearDisplay)
        return
    end
    if type(rec.spellID) == "number" and not secret(rec.spellID) then
        local renderOK, renderError = pcall(renderStrip, rec)
        if not renderOK then
            FC.combatHUDLastError = tostring(renderError)
            pcall(clearDisplay)
            return
        end
        local buttonsOK, buttons = pcall(findButtons, rec)
        if rec.pressRequired == false and slots[1] then
            slots[1].highlight:Hide()
            slots[1]:SetAlpha(0.65)
        end
        local glowOK, glowError = pcall(updateGlows, rec.pressRequired ~= false and buttonsOK and buttons or nil)
        if not glowOK then FC.combatHUDLastError = tostring(glowError) end
    else
        pcall(updateGlows, nil)
        if rec.targetHostile ~= true or rec.situation~='casting' then
            pcall(clearDisplay)
        elseif strip:IsShown() then
            for _, slot in ipairs(slots) do
                slot.enter:Stop()
                slot:SetAlpha(0.25)
                slot.highlight:Hide()
            end
        end
    end
end)

