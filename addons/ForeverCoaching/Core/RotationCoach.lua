ForeverCoaching = ForeverCoaching or {}
local FC = ForeverCoaching

local Coach = {}
ForeverCoaching.RotationCoach = Coach
local cooldownDataHidden = false
local rangeDataUnavailable = false
local usabilityDataUnavailable = false
local talentCacheConfigID
local talentCache
local talentScanUnavailable = false
local actionBarDamageSpellCache
local rotationSpells = {}
local rotationNextSpell
local rotationForecast={}
local movementBlockedSpell
local legacyTalentCache
local function legacyTalentSnapshot()
    if legacyTalentCache then return legacyTalentCache end
    if not GetNumTalents or not GetTalentInfo then return nil end
    local snapshot={}
    for tree=1,3 do
        local ok,count=pcall(GetNumTalents,tree)
        if not ok or (issecretvalue and issecretvalue(count)) or type(count)~='number' then return nil end
        for index=1,count do
            local success,name,_,_,_,rank,maxRank=pcall(GetTalentInfo,tree,index)
            if success and not (issecretvalue and (issecretvalue(name) or issecretvalue(rank) or issecretvalue(maxRank)))
                and type(name)=='string' and type(rank)=='number' and rank>0 then
                local id
                if C_Spell and C_Spell.GetSpellInfo then
                    local found,data=pcall(C_Spell.GetSpellInfo,name)
                    if found and data then local safe,value=pcall(function()return data.spellID end);if safe and not (issecretvalue and issecretvalue(value)) then id=value end end
                end
                snapshot[id or name]={spellID=id,name=name,rank=rank,maxRank=maxRank}
            end
        end
    end
    legacyTalentCache=snapshot
    return snapshot
end

local function secretCheck(check, ...)
    if not check then return false end
    local ok, value = pcall(check, ...)
    if not ok then return true end
    return value == true or (issecretvalue and issecretvalue(value))
end

-- Ranked WoW Forever spell IDs. The highest spell the player has learned is selected.
-- Priorities are situation rules, not a fixed specialization rotation.
-- Mechanic sources and remaining assumptions: docs/research/shaman-evidence.md.
-- Website links do not supply live data; no Forever Logs samples are bundled.
local SPELLS = {
    lightningBolt = { 403, 529, 548, 915, 943, 6041, 10391, 10392, 15207, 15208 },
    earthShock = { 8042, 8044, 8045, 8046, 10412, 10413, 10414 },
    flameShock = { 8050, 8052, 8053, 10447, 10448, 29228 },
    frostShock = { 8056, 8058, 10472, 10473 },
    chainLightning = { 421, 930, 2860, 10605 },
    fireNova = { 408341, 408342, 408343, 408344, 408345 },
    stormstrike = { 17364 },
    rageOfTheFarseer = { 425336 },
    lightningMastery = { 16166 },
}
local spellNames={lightningBolt='Lightning Bolt',earthShock='Earth Shock',flameShock='Flame Shock',frostShock='Frost Shock',chainLightning='Chain Lightning',fireNova='Fire Nova',stormstrike='Stormstrike',rageOfTheFarseer='Rage of the Farseer',lightningMastery='Lightning Mastery'}
local currentCatalog=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes.SHAMAN
if currentCatalog then
 for key,name in pairs(spellNames)do local source=currentCatalog.spells[name];SPELLS[key]=source and source.ids or {} end
end

local function spellInfo(id)
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, id)
        if ok and info and not (issecretvalue and issecretvalue(info)) then
            local fieldsOK, name, icon = pcall(function()
                return info.name, info.iconID or info.originalIconID
            end)
            if fieldsOK then return name, icon end
        end
    end
    if GetSpellInfo then
        local ok, name, _, icon = pcall(GetSpellInfo, id)
        if ok then return name, icon end
    end
end

local function known(id)
    local checks = {}
    if C_SpellBook and C_SpellBook.IsSpellKnown then checks[#checks + 1] = C_SpellBook.IsSpellKnown end
    if IsPlayerSpell then checks[#checks + 1] = IsPlayerSpell end
    if IsSpellKnown then checks[#checks + 1] = IsSpellKnown end
    for _, check in ipairs(checks) do
        if check then
            local ok, value = pcall(check, id)
            if ok and not (issecretvalue and issecretvalue(value))
                and (value == true or value == 1) then
                return true
            end
        end
    end
    return false
end

local function getActiveTalentSnapshot()
    if not C_ClassTalents or not C_ClassTalents.GetActiveConfigID or not C_Traits
        or not C_Traits.GetConfigInfo or not C_Traits.GetTreeNodes
        or not C_Traits.GetNodeInfo or not C_Traits.GetEntryInfo
        or not C_Traits.GetDefinitionInfo or talentScanUnavailable then
        return legacyTalentSnapshot()
    end

    local configOK, configID = pcall(C_ClassTalents.GetActiveConfigID)
    if not configOK or not configID then
        talentScanUnavailable = true
        return nil
    end
    if talentCache and talentCacheConfigID == configID then return talentCache end

    local infoOK, configInfo = pcall(C_Traits.GetConfigInfo, configID)
    if not infoOK or not configInfo or not configInfo.treeIDs then
        talentScanUnavailable = true
        return nil
    end

    local snapshot = {}
    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodesOK, nodeIDs = pcall(C_Traits.GetTreeNodes, treeID)
        if nodesOK and nodeIDs then
            for _, nodeID in ipairs(nodeIDs) do
                local nodeOK, node = pcall(C_Traits.GetNodeInfo, configID, nodeID)
                local rank = nodeOK and node and node.currentRank
                if issecretvalue and issecretvalue(rank) then rank = nil end
                if rank == 0 or rank == nil then rank = nodeOK and node and node.activeRank end
                if issecretvalue and issecretvalue(rank) then rank = nil end
                if rank ~= nil and rank > 0 then
                    local activeEntry = node.activeEntry
                    local entryID = activeEntry and activeEntry.entryID
                    local entry, definition
                    if entryID then
                        local entryOK, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID)
                        if entryOK then entry = entryInfo end
                    end
                    if entry and entry.definitionID then
                        local definitionOK, definitionInfo = pcall(C_Traits.GetDefinitionInfo, entry.definitionID)
                        if definitionOK then definition = definitionInfo end
                    end
                    local spellID = definition and definition.spellID
                    if spellID and not (issecretvalue and issecretvalue(spellID)) then
                        local name = definition.overrideName
                        if not name then name = spellInfo(spellID) end
                        snapshot[spellID] = {
                            spellID = spellID,
                            name = name or ("Talent " .. spellID),
                            rank = rank,
                            maxRank = node.maxRanks or rank,
                        }
                    end
                end
            end
        end
    end
    talentCacheConfigID = configID
    talentCache = snapshot
    talentScanUnavailable = false
    return talentCache
end

local talentEvents = CreateFrame("Frame")
talentEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
talentEvents:RegisterEvent("TRAIT_CONFIG_UPDATED")
for _,event in ipairs({'PLAYER_TALENT_UPDATE','CHARACTER_POINTS_CHANGED','SPELLS_CHANGED'})do pcall(talentEvents.RegisterEvent,talentEvents,event) end
talentEvents:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
talentEvents:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
talentEvents:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
talentEvents:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
talentEvents:SetScript("OnEvent", function()
    talentCacheConfigID = nil
    talentCache = nil
    legacyTalentCache = nil
    talentScanUnavailable = false
    actionBarDamageSpellCache = nil
end)

local function resolve(key)
    local ranks = SPELLS[key]
    if not ranks then return nil end
    for i = #ranks, 1, -1 do
        local id = ranks[i]
        if known(id) then
            local name, icon = spellInfo(id)
            if name then return { id = id, baseID = ranks[1], ranks = ranks, name = name, icon = icon, key = key } end
        end
    end
end

local function usable(spell)
    if not spell then return false, false end
    local ok, canCast, insufficientPower
    if C_Spell and C_Spell.IsSpellUsable then
        ok, canCast, insufficientPower = pcall(C_Spell.IsSpellUsable, spell.id)
    elseif IsUsableSpell then
        ok, canCast, insufficientPower = pcall(IsUsableSpell, spell.id)
    else
        return true, false
    end
    if not ok or (issecretvalue and (issecretvalue(canCast) or issecretvalue(insufficientPower))) then
        usabilityDataUnavailable = true
        return nil, nil
    end
    if canCast == 1 then
        canCast = true
    elseif canCast == 0 then
        canCast = false
    end
    if type(canCast) ~= "boolean" then
        usabilityDataUnavailable = true
        return nil, nil
    end
    if insufficientPower == 1 then
        insufficientPower = true
    elseif insufficientPower == 0 then
        insufficientPower = false
    end
    if insufficientPower ~= nil and type(insufficientPower) ~= "boolean" then
        usabilityDataUnavailable = true
        insufficientPower = nil
    end
    return canCast, insufficientPower
end

local function cooldown(spell)
    if not spell then return math.huge end
    if C_Secrets and secretCheck(C_Secrets.ShouldSpellCooldownBeSecret, spell.id) then
        cooldownDataHidden = true
        return nil
    end
    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local ok, duration = pcall(C_Spell.GetSpellCooldownDuration, spell.id, true)
        if ok and issecretvalue and issecretvalue(duration) then
            cooldownDataHidden = true
            return nil
        end
        -- The duration API describes an active spell cooldown and may return
        -- nil when there is none. In that case the spell is ready; do not let
        -- the structured fallback mistake the global cooldown for a spell CD.
        if ok and duration == nil then return 0 end
        if ok and duration and duration.GetRemainingDuration then
            local remainingOK, remaining = pcall(duration.GetRemainingDuration, duration)
            if remainingOK then
                if issecretvalue and issecretvalue(remaining) then
                    cooldownDataHidden = true
                    return nil
                end
                if type(remaining) == "number" then return math.max(0, remaining) end
            end
        end
    end
    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, info = pcall(C_Spell.GetSpellCooldown, spell.id)
        if ok and info then
            if issecretvalue and (issecretvalue(info.isEnabled) or issecretvalue(info.isActive)
                or issecretvalue(info.startTime) or issecretvalue(info.duration)) then
                cooldownDataHidden = true
                return nil
            end
            if info.isEnabled == false then return math.huge end
            if info.isActive == false then return 0 end
            if type(info.startTime) == "number" and type(info.duration) == "number" then
                if info.startTime > 0 and info.duration > 0 then
                    return math.max(0, info.startTime + info.duration - GetTime())
                end
                return 0
            end
        end
    end
    if GetSpellCooldown then
        local ok, start, length, enabled = pcall(GetSpellCooldown, spell.id)
        if ok then
            if issecretvalue and (issecretvalue(start) or issecretvalue(length) or issecretvalue(enabled)) then
                cooldownDataHidden = true
                return nil
            end
            if enabled == 0 then return math.huge end
            if type(start) == "number" and type(length) == "number" and start > 0 and length > 0 then
                return math.max(0, start + length - GetTime())
            end
            if type(start) == "number" and type(length) == "number" then return 0 end
        end
    end
    return 0
end

local function inRange(spell, unit)
    if C_Spell and C_Spell.IsSpellInRange then
        local ok, result = pcall(C_Spell.IsSpellInRange, spell.id, unit or "target")
        if ok then
            if not (issecretvalue and issecretvalue(result)) and result ~= nil then
                return result == true or result == 1
            end
        end
    end
    if IsSpellInRange then
        local ok, result = pcall(IsSpellInRange, spell.name, unit or "target")
        if ok then
            if not (issecretvalue and issecretvalue(result)) and result ~= nil then
                return result == true or result == 1
            end
        end
    end
    rangeDataUnavailable = true
    return nil
end

local function visibleUnitGUID(unit)
    if C_Secrets and secretCheck(C_Secrets.ShouldUnitIdentityBeSecret, unit) then return nil end
    if not UnitGUID then return nil end
    local ok, guid = pcall(UnitGUID, unit)
    if not ok or (issecretvalue and issecretvalue(guid)) then return nil end
    return guid
end

local function ready(spell, unit, checkRange, ignoreCooldown)
    if not spell then return false end
    local remaining = ignoreCooldown and 0 or cooldown(spell)
    -- During combat the client may hide cooldown values. In that case the
    -- action's usable check is still authoritative when it says the spell can
    -- be cast; keep coaching and let the player confirm the action-bar state.
    if remaining == nil and not cooldownDataHidden then return nil end
    if remaining and remaining > 0 then return false end
    local canCast = usable(spell)
    if canCast == nil then return nil end
    if not canCast then return false end
    if checkRange == false then return true end
    local range = inRange(spell, unit)
    return range == true, range
end

local function targetStatus(unit)
    if not UnitExists or not UnitCanAttack or not UnitIsDead then return nil end
    local ok, exists = pcall(UnitExists, unit)
    if not ok or (issecretvalue and issecretvalue(exists)) then return nil end
    if exists ~= true and exists ~= 1 then return "missing" end
    local attackOK, canAttack = pcall(UnitCanAttack, "player", unit)
    local deadOK, isDead = pcall(UnitIsDead, unit)
    if not attackOK or not deadOK
        or (issecretvalue and (issecretvalue(canAttack) or issecretvalue(isDead))) then
        return nil
    end
    if isDead == true or isDead == 1 then return "dead" end
    if canAttack == true or canAttack == 1 then return "hostile" end
    return "friendly"
end

local function targetHostility(unit)
    local status = targetStatus(unit)
    if status == "hostile" then return true end
    if status then return false end
    return nil
end

local function hostileTarget(unit)
    return targetHostility(unit) == true
end

local function playerInCombat()
    if not UnitAffectingCombat then return false end
    local ok, value = pcall(UnitAffectingCombat, "player")
    if not ok or (issecretvalue and issecretvalue(value)) then return false end
    return value == true
end

local function targetHasInterruptibleCast()
    if C_Secrets and secretCheck(C_Secrets.ShouldUnitSpellCastingBeSecret, "target") then return false end
    if not UnitCastingInfo then return false end
    local cast = { pcall(UnitCastingInfo, "target") }
    if not cast[1] then return false end
    if issecretvalue and (issecretvalue(cast[2]) or issecretvalue(cast[6])
        or issecretvalue(cast[9]) or issecretvalue(cast[10])) then return false end
    if cast[2] then
        return cast[9] == false, cast[10], cast[6]
    end

    if UnitChannelInfo then
        local channel = { pcall(UnitChannelInfo, "target") }
        if channel[1] and not (issecretvalue and (issecretvalue(channel[2])
            or issecretvalue(channel[6]) or issecretvalue(channel[8]) or issecretvalue(channel[9]))) then
            if channel[2] then
                return channel[8] == false, channel[9], channel[6]
            end
        end
    end
    return false
end

local function manaState()
    if not UnitPower or not UnitPowerMax then return nil end
    -- Read safely and check the returned values themselves. A failed policy
    -- query must not discard otherwise readable player mana on this client.
    local manaOK, mana = pcall(UnitPower, "player", 0)
    local maxOK, maxMana = pcall(UnitPowerMax, "player", 0)
    if not manaOK or not maxOK then return nil end
    if issecretvalue and (issecretvalue(maxMana) or issecretvalue(mana)) then return nil end
    if type(mana) ~= "number" or type(maxMana) ~= "number" then return nil end
    if not maxMana or maxMana <= 0 then return mana, 0, 100 end
    return mana, maxMana, mana / maxMana * 100
end

local function manaCost(spell, maxMana)
    local getter = C_Spell and C_Spell.GetSpellPowerCost or GetSpellPowerCost
    if not spell or not getter then return nil end
    local ok, costs = pcall(getter, spell.id)
    if not ok or (issecretvalue and issecretvalue(costs)) then return nil end
    if not costs then return nil end
    local manaType = Enum and Enum.PowerType and Enum.PowerType.Mana or 0
    local total = 0
    local readOK, readTotal = pcall(function()
        for _, cost in ipairs(costs) do
            if issecretvalue and issecretvalue(cost) then return nil end
            if cost.type == manaType or cost.name == "MANA" then
                -- `cost` is the full effective cost. `costPercent` describes how
                -- that cost is formed; adding both would count percent-cost spells
                -- twice. Prefer the engine's numeric cost, including talent/aura
                -- modifiers, then fall back to the minimum cost.
                local effectiveCost = cost.cost
                local minimumCost = cost.minCost
                local percentCost = cost.costPercent
                if issecretvalue and (issecretvalue(effectiveCost) or issecretvalue(minimumCost)
                    or issecretvalue(percentCost)) then return nil end
                if type(effectiveCost) ~= "number" then effectiveCost = minimumCost end
                if type(effectiveCost) == "number" and effectiveCost >= 0 then
                    total = total + effectiveCost
                elseif type(percentCost) == "number" and percentCost > 0 then
                    if not maxMana or maxMana <= 0 then return nil end
                    total = total + percentCost * maxMana / 100
                else
                    return nil
                end
            end
        end
        return total
    end)
    if not readOK then return nil end
    return readTotal
end

local function effectiveManaCost(spell, maxMana)
    -- The engine's effective cost already includes active cost modifiers.
    -- Applying the researched Maelstrom discount here again underprices casts.
    return manaCost(spell, maxMana)
end

-- Use the client's rank-specific tooltip values instead of assuming one
-- fixed priority for every level and talent setup. These are estimates; the
-- combat review records actual damage for later profile tuning.
local function estimatedSpellDamage(spell)
    if not spell or not C_Spell or not C_Spell.GetSpellDescription then return nil end
    local ok, description = pcall(C_Spell.GetSpellDescription, spell.id)
    if not ok or type(description) ~= "string" then return nil end
    local total, found = 0, false
    for segment in description:gmatch("([^%.]-damage)") do
        local low, high = segment:match("(%d[%d,]*)%s+to%s+(%d[%d,]*)%s+[%a]+%s+damage")
        if low and high then
            total = total + (tonumber((low:gsub(",", ""))) + tonumber((high:gsub(",", "")))) / 2
            found = true
        else
            local value = segment:match("(%d[%d,]*)%s+[%a]+%s+damage")
            value = value and tonumber((value:gsub(",", "")))
            if value then
                total = total + value
                found = true
            end
        end
    end
    if not found then return nil end
    local talents = getActiveTalentSnapshot()
    if talents then
        if (spell.key == "lightningBolt" or spell.key == "earthShock" or spell.key == "chainLightning")
            and talents[16035] then
            total = total * (1 + talents[16035].rank / 100)
        elseif (spell.key == "flameShock" or spell.key == "fireNova")
            and talents[16038] then
            total = total * (1 + talents[16038].rank * 0.05)
        end
    end
    return total
end

local ACTION_BUTTON_GROUPS = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
}

local function readableActionSlot(button)
    if not button then return nil end
    local ok, actionSlot = pcall(function() return button.action end)
    if not ok or type(actionSlot) ~= "number"
        or (issecretvalue and issecretvalue(actionSlot)) then return nil end
    return actionSlot
end

local function isButtonShown(button)
    if not button then return false end
    local ok, shown = pcall(function() return button:IsShown() end)
    return ok and shown == true
end

local function getActionBarShamanSpells()
    if actionBarDamageSpellCache then return actionBarDamageSpellCache end
    local discovered, seen = {}, {}
    local function addSpell(spellID)
        if type(spellID) ~= "number" or (issecretvalue and issecretvalue(spellID)) or seen[spellID] then return end
        if spellID == 6603 then return end -- Auto-attack is a toggle, not a damage cast.
        seen[spellID] = true
        local name, icon = spellInfo(spellID)
        if not name then return end
        if currentCatalog then
            local verified=false
            for _,entry in pairs(currentCatalog.spells)do for _,id in ipairs(entry.ids)do if id==spellID then verified=true;break end end;if verified then break end end
            if not verified then return end
        end
        local key, ranks
        for candidateKey, candidateRanks in pairs(SPELLS) do
            for _, candidateID in ipairs(candidateRanks) do
                if candidateID == spellID then
                    key, ranks = candidateKey, candidateRanks
                    break
                end
            end
            if key then break end
        end
        -- Fire Nova needs totem-position context unavailable to the addon. The
        -- static profile handles it only when that context can be evaluated.
        if key == "fireNova" then return end
        local spell = {
            id = spellID,
            baseID = ranks and ranks[1] or spellID,
            ranks = ranks or { spellID },
            name = name,
            icon = icon,
            key = key or "actionBar",
        }
        local recognizedDamage = key == "lightningBolt" or key == "earthShock"
            or key == "frostShock" or key == "chainLightning"
            or key == "stormstrike" or key == "flameShock"
            or key == "rageOfTheFarseer" or key == "lightningMastery"
        if recognizedDamage then
            -- These recognized Shaman spells remain usable even on client builds
            -- that don't expose spell descriptions for numeric damage ranking.
            discovered[#discovered + 1] = spell
            return
        end
        local description
        if C_Spell and C_Spell.GetSpellDescription then
            local descriptionOK
            descriptionOK, description = pcall(C_Spell.GetSpellDescription, spellID)
            if not descriptionOK then description = nil end
        end
        if type(description) == "string" then
            local lower = description:lower()
            local likelyAreaDamage = lower:find("all enemies", 1, true)
                or lower:find("nearby enemies", 1, true)
                or lower:find("each enemy", 1, true)
                or lower:find("up to %d+ enemies")
                or lower:find("jumps to", 1, true)
            -- Tooltip text varies by client build and locale. Numeric parsing is
            -- needed to rank spells, but it must not decide whether a damaging
            -- action-bar spell exists at all: keep it as an actionable fallback
            -- so the HUD can still name and highlight the player's learned spell.
            local hasDamageDescription = lower:find("damage", 1, true) ~= nil
            if (spell.key == "chainLightning" or not likelyAreaDamage)
                and (hasDamageDescription or estimatedSpellDamage(spell)) then
                discovered[#discovered + 1] = spell
            end
        end
    end

    if GetActionInfo then
        for _, group in ipairs(ACTION_BUTTON_GROUPS) do
            for index = 1, 12 do
                local button = _G[group .. index]
                local actionSlot = readableActionSlot(button)
                if actionSlot and isButtonShown(button) then
                    local actionOK, actionType, actionID = pcall(GetActionInfo, actionSlot)
                    if actionOK and not (issecretvalue and issecretvalue(actionID)) then
                        if actionType == "spell" then
                            addSpell(actionID)
                        elseif actionType == "macro" and GetMacroSpell and type(actionID) == "number" then
                            local macroOK, first, _, spellID = pcall(GetMacroSpell, actionID)
                            if macroOK then
                                if not (issecretvalue and issecretvalue(spellID)) and type(spellID) == "number" then
                                    addSpell(spellID)
                                else
                                    addSpell(first)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    actionBarDamageSpellCache = discovered
    return actionBarDamageSpellCache
end

local function spellCastSeconds(spell, talents, maelstromReduction, lightningMasteryActive)
    if not spell then return 1.5 end
    local seconds = 1.5
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spell.id)
        local milliseconds = ok and info and info.castTime
        if milliseconds and not (issecretvalue and issecretvalue(milliseconds)) then
            seconds = milliseconds / 1000
        end
    end
    if talents and talents[16578]
        and (spell.key == "lightningBolt" or spell.key == "chainLightning") then
        local rank = talents[16578].rank
        local reduction = rank == 1 and 0.17 or (rank == 2 and 0.33 or (rank >= 3 and 0.50 or 0))
        seconds = seconds - reduction
    end
    if spell.key == "lightningBolt" and maelstromReduction and maelstromReduction > 0 then
        seconds = seconds * math.max(0, 1 - math.min(100, maelstromReduction) / 100)
    end
    if lightningMasteryActive
        and (spell.key == "lightningBolt") then
        seconds = seconds - 0.5
    end
    return math.max(0, seconds)
end

local function castTimeSeconds(spell, talents, maelstromReduction, lightningMasteryActive)
    return math.max(1.5, spellCastSeconds(spell, talents, maelstromReduction, lightningMasteryActive))
end

local function playerIsMoving()
    if not GetUnitSpeed then return false end
    local ok, speed = pcall(GetUnitSpeed, "player")
    if not ok or (issecretvalue and issecretvalue(speed)) then return false end
    return type(speed) == "number" and speed > 0
end

local canSpend

local function currentTargetHealth()
    if not UnitHealth then return nil end
    local ok, health = pcall(UnitHealth, "target")
    if not ok or (issecretvalue and issecretvalue(health)) then return nil end
    if type(health) ~= "number" or health <= 0 then return nil end
    return health
end

local function bestDamageCandidate(candidates, currentMana, maxMana, manaPercent, reservePercent, freeCast, targetCount, activeTalents, allowObserved, playerLevel, lightningMasteryActive)
    local eligible = {}
    local targetHealth = currentTargetHealth()
    local moving = playerIsMoving()
    local fallbackSpell, outOfRangeSpell, unknownRangeSpell
    for _, candidate in ipairs(candidates) do
        local spell = candidate.spell
        local reduction = spell and spell.key == "lightningBolt" and (candidate.maelstromReduction or 0) or 0
        local spellReady, rangeResult
        if spell then spellReady, rangeResult = ready(spell, nil, candidate.checkRange, candidate.ignoreCooldown) end
        local blockedMoving = spell and moving and spellCastSeconds(spell, activeTalents, reduction, lightningMasteryActive) > 0
        if blockedMoving then
            if spellReady then movementBlockedSpell = movementBlockedSpell or spell end
            spellReady = false
        end
        if spell and rangeResult == false and canSpend(spell, currentMana, maxMana, reservePercent, freeCast, reduction)
            and not outOfRangeSpell then
            outOfRangeSpell = spell
        end
        if spell and not blockedMoving and candidate.checkRange ~= false and rangeResult == nil and not unknownRangeSpell then
            local readyWithoutRange = ready(spell, nil, false, candidate.ignoreCooldown)
            if readyWithoutRange and canSpend(spell, currentMana, maxMana, reservePercent, freeCast, reduction) then
                unknownRangeSpell = spell
            end
        end
        if spell and spellReady then
            local affordable = canSpend(spell, currentMana, maxMana, reservePercent, freeCast, reduction)
            if affordable then
                local observed, sampleCount
                if allowObserved and candidate.useObserved ~= false and not candidate.aoe
                    and activeTalents and FC.CombatReview and FC.CombatReview.GetObservedDamage then
                    observed, sampleCount = FC.CombatReview:GetObservedDamage(spell.id, activeTalents, playerLevel)
                end
                if not candidate.requireObserved or observed then
                    fallbackSpell = fallbackSpell or spell
                end
                local tooltipDamage = estimatedSpellDamage(spell)
                if tooltipDamage and candidate.damageMultiplier then
                    tooltipDamage = tooltipDamage * candidate.damageMultiplier
                end
                if candidate.requireObserved then tooltipDamage = nil end
                if (not candidate.requireObserved or observed) and (observed or tooltipDamage) then
                    eligible[#eligible + 1] = {
                        candidate = candidate,
                        observed = observed,
                        sampleCount = sampleCount,
                        tooltipDamage = tooltipDamage,
                    }
                end
            end
        end
    end

    -- Use measured damage for spells with enough matching-level/talent samples.
    -- Bring the remaining tooltip estimates onto the same character-specific
    -- scale using the median observed-to-tooltip ratio. This lets real combat
    -- evidence improve the choices before every learned spell has been cast
    -- three times.
    local calibrationRatios = {}
    for _, item in ipairs(eligible) do
        if item.observed and item.tooltipDamage and item.tooltipDamage > 0 then
            calibrationRatios[#calibrationRatios + 1] = item.observed / item.tooltipDamage
        end
    end
    table.sort(calibrationRatios)
    local calibrationRatio
    if #calibrationRatios > 0 then
        local middle = math.floor((#calibrationRatios + 1) / 2)
        if #calibrationRatios % 2 == 0 then
            calibrationRatio = (calibrationRatios[middle] + calibrationRatios[middle + 1]) / 2
        else
            calibrationRatio = calibrationRatios[middle]
        end
    end
    local scored = {}
    for _, item in ipairs(eligible) do
        local spell = item.candidate.spell
        local damage, dataSource
        if item.observed then
            damage, dataSource = item.observed, "observed"
        elseif item.tooltipDamage then
            damage = item.tooltipDamage * (calibrationRatio or 1)
            dataSource = calibrationRatio and "calibrated" or "tooltip"
        end
        if damage then
            -- Avoid rewarding damage the target cannot take. For AoE, other
            -- targets' health is unknown, so keep the uncapped pack estimate.
            local scoreDamage = damage
            local totalDamage = damage
            local healthCapped = not item.candidate.aoe and targetHealth and damage > targetHealth
            if healthCapped then scoreDamage = targetHealth end
            local targets = 1
            if item.candidate.aoe then
                local observedTargets = item.candidate.targetCount or targetCount or 1
                targets = math.max(1, observedTargets)
                if item.candidate.targetCap then
                    targets = math.min(targets, item.candidate.targetCap)
                end
                local damagePerJump = 1 - (item.candidate.damageReductionPerJump or 0)
                local jumpMultiplier = 1
                totalDamage = 0
                for jump = 1, targets do
                    local jumpDamage = damage * jumpMultiplier
                    if jump == 1 and item.candidate.primaryTargetDamageMultiplier then
                        jumpDamage = jumpDamage * item.candidate.primaryTargetDamageMultiplier
                    end
                    totalDamage = totalDamage + jumpDamage
                    jumpMultiplier = jumpMultiplier * damagePerJump
                end
                scoreDamage = totalDamage
            end
            local reduction = spell.key == "lightningBolt" and (item.candidate.maelstromReduction or 0) or 0
            local castSeconds = castTimeSeconds(spell, activeTalents, reduction, lightningMasteryActive)
            local cost = freeCast and 0 or effectiveManaCost(spell, maxMana, reduction)
            local score = scoreDamage / castSeconds
            -- Preserve throughput at high mana; increase mana efficiency
            -- weighting as the character approaches the reserve threshold.
            if cost ~= nil and not freeCast and maxMana and maxMana > 0 and manaPercent then
                local fraction = cost / maxMana
                local resourcePressure = math.max(0, 1 - manaPercent / 100)
                score = score / (1 + fraction * 4 * resourcePressure)
            end
            scored[#scored + 1] = {
                spell = spell,
                damage = totalDamage,
                scoreDamage = scoreDamage,
                dataSource = dataSource,
                healthCapped = healthCapped,
                seconds = castSeconds,
                mana = cost,
                manaKnown = cost ~= nil,
                samples = item.sampleCount,
                score = score,
                aoe = item.candidate.aoe,
                primaryDamage = damage * (item.candidate.primaryTargetDamageMultiplier or 1),
            }
        end
    end
    local hasKnownManaCost = false
    for _, item in ipairs(scored) do
        if item.manaKnown then
            hasKnownManaCost = true
            break
        end
    end
    local ranked = {}
    local unknownManaCostOmitted = false
    for _, item in ipairs(scored) do
        if not hasKnownManaCost or item.manaKnown then
            ranked[#ranked + 1] = item
        else
            unknownManaCostOmitted = true
        end
    end
    table.sort(ranked, function(a, b) return a.score > b.score end)
    local best = ranked[1]
    local comparison = {}
    for index = 1, math.min(2, #ranked) do
        local item = ranked[index]
        local source = item.dataSource == "observed" and "observed"
            or (item.dataSource == "calibrated" and "calibrated estimate" or "tooltip estimate")
        if item.healthCapped then
            comparison[#comparison + 1] = string.format(
                "%s %s ~%.0f damage (scored at %.0f target HP)/%.1fs, %s",
                item.spell.name, source, item.damage, item.scoreDamage, item.seconds,
                item.manaKnown and string.format("%.0f Mana", item.mana) or "Mana cost unavailable"
            )
        else
            comparison[#comparison + 1] = string.format(
                "%s %s ~%.0f damage/%.1fs, %s",
                item.spell.name, source, item.damage, item.seconds,
                item.manaKnown and string.format("%.0f Mana", item.mana) or "Mana cost unavailable"
            )
        end
    end
    return best and best.spell, best and best.score, best and best.damage, best and best.dataSource,
        best and best.samples, table.concat(comparison, "; "), best and best.healthCapped,
        calibrationRatio, fallbackSpell, outOfRangeSpell, best and best.manaKnown,
        unknownManaCostOmitted, unknownRangeSpell, ranked
end

canSpend = function(spell, currentMana, maxMana, reservePercent, freeCast, maelstromReduction)
    if freeCast then return true, 0 end
    -- If the client restricts resource values, keep evaluating the spell's
    -- usable state, range, cooldown, and damage. Report that mana could not
    -- be checked instead of suppressing every recommendation.
    if type(currentMana) ~= "number" or type(maxMana) ~= "number" then
        return true, nil
    end
    local cost = effectiveManaCost(spell, maxMana, maelstromReduction)
    if cost == 0 then return true, 0 end
    if cost == nil then
        return maxMana <= 0 or currentMana / maxMana * 100 >= reservePercent
    end
    local reserve = maxMana and maxMana > 0 and maxMana * reservePercent / 100 or 0
    return currentMana >= cost and currentMana - cost >= reserve, cost
end

local function playerIsCasting()
    if UnitCastingInfo then
        local ok, castName = pcall(UnitCastingInfo, "player")
        if not ok then return false end
        if not (issecretvalue and issecretvalue(castName)) and castName ~= nil then return true end
    end
    if UnitChannelInfo then
        local ok, channelName = pcall(UnitChannelInfo, "player")
        if not ok then return false end
        if not (issecretvalue and issecretvalue(channelName)) and channelName ~= nil then return true end
    end
    return false
end

local function targetHasAura(spellRanks)
    if not C_UnitAuras or not C_UnitAuras.GetUnitAuraBySpellID then return nil end
    if C_Secrets and secretCheck(C_Secrets.ShouldAurasBeSecret) then return nil end
    for _, id in ipairs(spellRanks) do
        if C_Secrets and secretCheck(C_Secrets.ShouldSpellAuraBeSecret, id) then return nil end
        local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", id)
        if not ok then return nil end
        if aura then
            if issecretvalue and issecretvalue(aura) then return nil end
            local expirationOK, expiration = pcall(function() return aura.expirationTime end)
            if not expirationOK then return nil end
            if issecretvalue and issecretvalue(expiration) then return true, nil end
            if expiration and expiration > 0 and GetTime then
                return true, math.max(0, expiration - GetTime())
            end
            return true, nil
        end
    end
    return false
end

local function playerAuraStacks(spellID)
    if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return nil end
    if C_Secrets and secretCheck(C_Secrets.ShouldAurasBeSecret) then return nil end
    if C_Secrets and secretCheck(C_Secrets.ShouldSpellAuraBeSecret, spellID) then return nil end
    local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
    if not ok or (issecretvalue and issecretvalue(aura)) then return nil end
    if not aura then return 0 end
    local stacksOK, stacks = pcall(function() return aura.applications or aura.charges or 1 end)
    if not stacksOK then return nil end
    if issecretvalue and issecretvalue(stacks) then return nil end
    return stacks
end

local function hasActiveFireTotem()
    if not GetTotemInfo then return nil end
    if C_Secrets and secretCheck(C_Secrets.ShouldTotemSlotBeSecret, 1) then return nil end
    local values = { pcall(GetTotemInfo, 1) }
    if not values[1] then return nil end
    if issecretvalue and (issecretvalue(values[2]) or issecretvalue(values[3])) then return nil end
    return values[2] == true and values[3] ~= nil and values[3] ~= ""
end

local function nearbyHostileCount(spell)
    local found = {}
    local foundUnits = {}
    local function register(unit)
        -- GUIDs can be hidden in combat. UnitIsUnit still prevents counting a
        -- target and its visible nameplate as two enemies in that case.
        if UnitIsUnit then
            for _, existing in ipairs(foundUnits) do
                local ok, sameUnit = pcall(UnitIsUnit, unit, existing)
                if ok and not (issecretvalue and issecretvalue(sameUnit)) and sameUnit == true then return end
            end
        end
        foundUnits[#foundUnits + 1] = unit
        found[visibleUnitGUID(unit) or unit] = true
    end

    local function qualifies(unit)
        if not hostileTarget(unit) then return false end
        return inRange(spell, unit) == true
    end
    if qualifies("target") then
        register("target")
    end
    -- Visible nameplates provide a conservative, client-observable AoE estimate.
    for index = 1, 40 do
        local unit = "nameplate" .. index
        if qualifies(unit) then
            register(unit)
        end
    end
    local count = 0
    for _ in pairs(found) do count = count + 1 end
    return count
end

local function result(message, reason, spell, situation, targetGUID)
    local playerLevel
    local targetLevel
    if UnitLevel then
        local playerOK, playerValue = pcall(UnitLevel, "player")
        local targetOK, targetValue = pcall(UnitLevel, "target")
        if playerOK then playerLevel = playerValue end
        if targetOK then targetLevel = targetValue end
    end
    if issecretvalue and issecretvalue(playerLevel) then playerLevel = nil end
    if issecretvalue and issecretvalue(targetLevel) then targetLevel = nil end
    if spell and spell.key ~= "weaponAttack" and cooldownDataHidden then
        reason = (reason or "") .. " Cooldown data is restricted; the client usable check passed, but confirm the action bar shows this spell ready."
    end
    -- Waiting/no-target HUD results have no ability to explain, so avoid
    -- scanning the talent tree on every live refresh until a spell is actually
    -- recommended.
    local talents = spell and getActiveTalentSnapshot() or nil
    if spell and talents then
        local talentNote
        if (spell.key == "lightningBolt" or spell.key == "earthShock" or spell.key == "chainLightning")
            and talents[16035] then
            talentNote = string.format("Concussion adds %d%% damage.", talents[16035].rank)
        elseif (spell.key == "flameShock" or spell.key == "fireNova")
            and talents[16038] then
            talentNote = string.format("Call of Flame adds %d%% fire damage.", talents[16038].rank * 5)
        end
        if (spell.key == "lightningBolt" or spell.key == "chainLightning")
            and talents[16578] then
            local castReduction = talents[16578].rank == 1 and 0.17 or (talents[16578].rank == 2 and 0.33 or 0.50)
            local castNote = string.format("Elemental Alacrity cuts cast time by %.2fs.", castReduction)
            talentNote = talentNote and (talentNote .. " " .. castNote) or castNote
        end
        if talentNote then reason = reason .. " " .. talentNote end
    end
    return {
        message = message,
        reason = reason,
        spellID = spell and spell.id,
        baseSpellID = spell and spell.baseID,
        spellRanks = spell and spell.ranks,
        spellName = spell and spell.name,
        icon = spell and spell.icon,
        situation = situation,
        playerLevel = playerLevel,
        targetLevel = targetLevel,
        targetHostile = targetHostility("target"),
        talents = talents,
        targetGUID = targetGUID,
        rotation = rotationSpells,
        nextSpell = rotationNextSpell,
        forecast = rotationForecast,
        at = GetTime and GetTime() or 0,
    }
end

local function weaponRecommendation(message, reason, situation, targetGUID, meleeSpell)
    if not playerInCombat() then
        local rec = result("Recover mana", "Recover mana before pulling another enemy.", nil, situation, targetGUID)
        rec.shortReason = "Recover mana before pulling another enemy."
        return rec
    end
    local inMelee, attacking
    if meleeSpell then
        if C_Spell and C_Spell.IsSpellInRange then
            local ok, value = pcall(C_Spell.IsSpellInRange, meleeSpell.id, "target")
            if ok and not (issecretvalue and issecretvalue(value)) then
                if value == true or value == 1 then inMelee = true end
            end
        end
    end
    if IsCurrentSpell then
        local ok, value = pcall(IsCurrentSpell, 6603)
        if ok and not (issecretvalue and issecretvalue(value)) then
            if value == true or value == 1 then attacking = true
            elseif value == false or value == 0 then attacking = false end
        end
    end
    -- Use only affirmative client range results. Unknown range is not melee.
    -- These are visual/read-only checks; never start attacks from addon code.
    if IsAttackAction and IsActionInRange then
        for _, group in ipairs(ACTION_BUTTON_GROUPS) do
            for index = 1, 12 do
                local button = _G[group .. index]
                local slot = readableActionSlot(button)
                if slot and isButtonShown(button) then
                    local attackOK, isAttack = pcall(IsAttackAction, slot)
                    if attackOK and not (issecretvalue and issecretvalue(isAttack))
                        and (isAttack == true or isAttack == 1) then
                        local rangeOK, range = pcall(IsActionInRange, slot, "target")
                        if rangeOK and not (issecretvalue and issecretvalue(range))
                            and (range == true or range == 1) then inMelee = true end
                        if attacking == nil and IsCurrentAction then
                            local currentOK, current = pcall(IsCurrentAction, slot)
                            if currentOK and not (issecretvalue and issecretvalue(current)) then
                                if current == true or current == 1 then attacking = true
                                elseif current == false or current == 0 then attacking = false end
                            end
                        end
                    end
                end
            end
        end
    end
    if inMelee and attacking ~= nil then
        local name, icon = spellInfo(6603)
        local attack = { id = 6603, baseID = 6603, ranks = {6603}, name = name or "Attack", icon = icon or "Interface\\Icons\\INV_Sword_04", key = "weaponAttack" }
        local rec = result(attack.name, reason, attack, situation, targetGUID)
        rec.pressRequired = not attacking
        rec.shortReason = attacking and "Keep your weapon swings going while saving mana."
            or "Start weapon attacks in melee while saving mana."
        return rec
    end
    return result(message, reason, nil, situation, targetGUID)
end

function Coach:GetActiveTalentSnapshot()
    return getActiveTalentSnapshot()
end

function Coach:GetRecommendation()
    movementBlockedSpell = nil
    rotationSpells = {}
    rotationNextSpell = nil
    rotationForecast = {}
    cooldownDataHidden = false
    rangeDataUnavailable = false
    usabilityDataUnavailable = false
    local _, classToken = UnitClass("player")
    if classToken ~= "SHAMAN" then
        return result("Class profile in progress", "This live decision profile currently covers Shaman abilities.")
    end
    local targetState = targetStatus("target")
    if targetState == "missing" then
        return result("Target an enemy", "Select a living hostile creature to get a combat recommendation.")
    elseif targetState == "friendly" then
        return result("Target is friendly", "Select a hostile creature to get a combat recommendation.")
    elseif targetState == "dead" then
        return result("Target is dead", "Select a living hostile creature to get a combat recommendation.")
    elseif targetState == nil then
        return result("Target data unavailable", "The client did not expose a safe target state, so the coach cannot evaluate this combat situation yet.", nil, "restricted data")
    end
    local targetGUID = visibleUnitGUID("target")
    if playerIsCasting() then
        return result("Finish your cast", "You are already casting; the recommendation will update when the cast ends.", nil, "casting", targetGUID)
    end

    local spells = {
        bolt = resolve("lightningBolt"),
        earthShock = resolve("earthShock"),
        frostShock = resolve("frostShock"),
        flameShock = resolve("flameShock"),
        chainLightning = resolve("chainLightning"),
        fireNova = resolve("fireNova"),
        stormstrike = resolve("stormstrike"),
        rageOfTheFarseer = resolve("rageOfTheFarseer"),
        lightningMastery = resolve("lightningMastery"),
    }
    local actionBarShamanSpells = getActionBarShamanSpells()
    local actionBarSpellFields = {
        lightningBolt = "bolt",
        earthShock = "earthShock",
        frostShock = "frostShock",
        flameShock = "flameShock",
        chainLightning = "chainLightning",
        stormstrike = "stormstrike",
        rageOfTheFarseer = "rageOfTheFarseer",
        lightningMastery = "lightningMastery",
    }
    for _, actionBarSpell in ipairs(actionBarShamanSpells) do
        local field = actionBarSpellFields[actionBarSpell.key]
        if field and not spells[field] then spells[field] = actionBarSpell end
    end
    local stormstrikeSpell = spells.stormstrike
    local currentMana, maxMana, mana = manaState()
    local resourceDataAvailable = currentMana ~= nil
    local seenRotation = {}
    local function addRotationSpell(spell)
        local family = spell and (spell.baseID or spell.id)
        if spell and spell.key ~= "fireNova" and not seenRotation[family] then
            seenRotation[family] = true
            rotationSpells[#rotationSpells + 1] = spell
        end
    end
    for _, field in ipairs({ "bolt", "earthShock", "flameShock", "frostShock", "stormstrike", "chainLightning", "lightningMastery", "rageOfTheFarseer" }) do
        addRotationSpell(spells[field])
    end
    for _, spell in ipairs(actionBarShamanSpells) do addRotationSpell(spell) end
    -- A conditional follow-up for setup abilities; damage choices below refine
    -- this with the same ranked candidates and projected resource spend.
    if spells.bolt and ready(spells.bolt)
        and canSpend(spells.bolt, currentMana, maxMana, 10) then
        rotationNextSpell = spells.bolt
    end

    -- Earth Shock is the Shaman's learned interrupt. Resource/range readiness
    -- comes from the client, rather than assuming a particular talent build.
    local targetCastInterruptible, targetCastSpellID, targetCastEndsAt = targetHasInterruptibleCast()
    if spells.earthShock and targetCastInterruptible and ready(spells.earthShock) then
        local interruptReason = "Earth Shock is ready while the target is casting; use it if the cast can be interrupted."
        if targetCastSpellID and C_Spell and C_Spell.GetSpellInfo then
            local infoOK, info = pcall(C_Spell.GetSpellInfo, targetCastSpellID)
            if infoOK and info and info.name then
                interruptReason = string.format("The target is casting %s. Earth Shock is ready and in range to interrupt it.", info.name)
            end
        end
        local recommendation = result(spells.earthShock.name, interruptReason, spells.earthShock, "interrupt", targetGUID)
        recommendation.targetCastSpellID = targetCastSpellID
        recommendation.targetCastEndsAt = targetCastEndsAt and targetCastEndsAt / 1000 or nil
        return recommendation
    end

    local flameShockActive, flameShockRemaining = targetHasAura(SPELLS.flameShock)
    local stormstrikeBonus = targetHasAura(SPELLS.stormstrike)
    local maelstromStacks
    local activeTalents = getActiveTalentSnapshot()
    local maelstromRank = activeTalents and activeTalents[408498] and activeTalents[408498].rank or 0
    if maelstromRank > 0 or known(408498) then
        -- 408498 is the passive talent; 408505 is its stack-bearing player buff.
        maelstromStacks = playerAuraStacks(408505)
    end
    local maelstromReduction = maelstromStacks and maelstromRank > 0
        and maelstromRank * 4 * maelstromStacks or 0
    local coherenceActive = (activeTalents and (activeTalents[416081] or activeTalents[415096]) ~= nil)
        or known(416081) or known(415096)
    local clearcastingStacks = playerAuraStacks(16246)
    local clearcasting = clearcastingStacks ~= nil and clearcastingStacks > 0
    local lightningMasteryStacks = playerAuraStacks(SPELLS.lightningMastery[1])
    local lightningMasteryActive = lightningMasteryStacks ~= nil and lightningMasteryStacks > 0

    -- This WoW Forever Enhancement talent is a zero-cost, self-applied attack
    -- speed cooldown. Offer it only after combat starts and while its buff is
    -- absent; its learned state naturally gates it to players with the talent.
    local farseerBuff = playerAuraStacks(SPELLS.rageOfTheFarseer[1])
    if self.burstAllowed~=false and spells.rageOfTheFarseer and farseerBuff == 0 and playerInCombat()
        and ready(spells.rageOfTheFarseer, nil, false) then
        return result(spells.rageOfTheFarseer.name,
            "Rage of the Farseer is ready. Its 30% attack-speed increase lasts 25 seconds; use it during this fight while you can benefit from weapon attacks.",
            spells.rageOfTheFarseer, "attack speed cooldown", targetGUID)
    end

    -- Stormstrike empowers the next Lightning Bolt, Chain Lightning, or Earth
    -- Shock by 20%; spend it before the boosted spell when available.
    if stormstrikeSpell and stormstrikeBonus == false
        and canSpend(stormstrikeSpell, currentMana, maxMana, 5)
        and ready(stormstrikeSpell) then
        return result(stormstrikeSpell.name, "Stormstrike is ready in melee range and increases the damage of your next Lightning Bolt, Chain Lightning, or Earth Shock by 20% for 12 seconds.", stormstrikeSpell, "melee attack", targetGUID)
    end

    if self.burstAllowed~=false and spells.lightningMastery and lightningMasteryStacks == 0 and playerInCombat()
        and ready(spells.lightningMastery, nil, false) then
        local empoweredSpellReady = (spells.bolt
            and ready(spells.bolt)
            and canSpend(spells.bolt, currentMana, maxMana, 10, clearcasting, maelstromReduction))
            or (spells.chainLightning
                and ready(spells.chainLightning, nil, nil, true)
                and canSpend(spells.chainLightning, currentMana, maxMana, 10, clearcasting))
        if empoweredSpellReady then
            return result(spells.lightningMastery.name,
                "Lightning Mastery is ready. It shortens Lightning Bolt casts by 0.5 seconds and removes Chain Lightning's cooldown for 15 seconds.",
                spells.lightningMastery, "elemental cooldown", targetGUID)
        end
    end

    -- Use chain lightning only when visible hostile units indicate a real pack.
    -- The action-bar fallback can discover it even when this client reports
    -- the spellbook's known-spell query inconsistently, so include that copy.
    local chainLightning = spells.chainLightning
    if not chainLightning then
        for _, actionBarSpell in ipairs(actionBarShamanSpells) do
            if actionBarSpell.key == "chainLightning" then
                chainLightning = actionBarSpell
                break
            end
        end
    end
    local nearbyCount = chainLightning and ready(chainLightning, nil, nil, lightningMasteryActive)
        and nearbyHostileCount(chainLightning) or 1
    if self.allowArea==false then nearbyCount=1 end
    local fireTotemActive = spells.fireNova and hasActiveFireTotem() == true
    local stormstrikeMultiplier = stormstrikeBonus == true and 1.2 or 1
    local candidates = {
        {
            spell = spells.bolt,
            maelstromReduction = maelstromReduction,
            damageMultiplier = stormstrikeMultiplier,
        },
        { spell = spells.earthShock, damageMultiplier = stormstrikeMultiplier },
        { spell = spells.frostShock },
    }
    if spells.flameShock and (flameShockActive == false
        or (flameShockActive == true and flameShockRemaining and flameShockRemaining <= 3)) then
        -- The tooltip combines periodic and direct damage without knowing how
        -- long a leveling target will live. Only use Flame Shock after observed
        -- cast data has learned its realized value on this character.
        candidates[#candidates + 1] = { spell = spells.flameShock, requireObserved = true }
    end
    if chainLightning and nearbyCount >= 2 then
        candidates[#candidates + 1] = {
            spell = chainLightning,
            aoe = true,
            targetCount = nearbyCount,
            targetCap = coherenceActive and 4 or 3,
            damageReductionPerJump = coherenceActive and 0.20 or 0.30,
            primaryTargetDamageMultiplier = stormstrikeMultiplier,
            ignoreCooldown = lightningMasteryActive,
        }
    end
    local alreadyCandidate = {}
    for _, candidate in ipairs(candidates) do
        if candidate.spell then alreadyCandidate[candidate.spell.id] = true end
    end
    for _, spell in ipairs(actionBarShamanSpells) do
        if not alreadyCandidate[spell.id] then
            alreadyCandidate[spell.id] = true
            if spell.key == "stormstrike" then
                -- Stormstrike is handled above as a setup attack for its buff.
            elseif spell.key == "rageOfTheFarseer" or spell.key == "lightningMastery"
                or spell.key == "fireNova" then
                -- These are handled by their situation-specific profile rules.
            elseif spell.key == "chainLightning" then
                if nearbyCount >= 2 then
                    candidates[#candidates + 1] = {
                        spell = spell,
                        aoe = true,
                        targetCount = nearbyCount,
                        targetCap = coherenceActive and 4 or 3,
                        damageReductionPerJump = coherenceActive and 0.20 or 0.30,
                        primaryTargetDamageMultiplier = stormstrikeMultiplier,
                        ignoreCooldown = lightningMasteryActive,
                    }
                end
            elseif spell.key == "lightningBolt" then
                candidates[#candidates + 1] = {
                    spell = spell,
                    maelstromReduction = maelstromReduction,
                    damageMultiplier = stormstrikeMultiplier,
                }
            elseif spell.key == "earthShock" then
                candidates[#candidates + 1] = {
                    spell = spell,
                    damageMultiplier = stormstrikeMultiplier,
                }
            elseif spell.key == "flameShock" then
                if flameShockActive == false
                    or (flameShockActive == true and flameShockRemaining and flameShockRemaining <= 3) then
                    candidates[#candidates + 1] = { spell = spell, requireObserved = true }
                end
            else
                candidates[#candidates + 1] = { spell = spell }
            end
        end
    end
    -- Fire Nova hits enemies around the totem, but the client does not expose
    -- that totem's position. Do not guess its AoE count or call the combat-
    -- restricted CheckInteractDistance API from this live update.
    local fireNovaTargetsUnknown = fireTotemActive == true

    local playerLevel
    if UnitLevel then
        local levelOK, level = pcall(UnitLevel, "player")
        if levelOK then playerLevel = level end
    end
    if issecretvalue and issecretvalue(playerLevel) then playerLevel = nil end
    local bestSpell, bestScore, bestDamage, damageSource, damageSamples, comparison, healthCapped, calibrationRatio, fallbackSpell, outOfRangeSpell, manaCostKnown, unknownManaCostOmitted, unknownRangeSpell, ranked = bestDamageCandidate(
        candidates, currentMana, maxMana, mana, 10, clearcasting, nearbyCount,
        activeTalents, stormstrikeBonus ~= true, playerLevel, lightningMasteryActive
    )
    if bestSpell then
        local currentMaelstromReduction = bestSpell.key == "lightningBolt" and maelstromReduction or 0
        local castSeconds = castTimeSeconds(bestSpell, activeTalents, currentMaelstromReduction, lightningMasteryActive)
        local cost = clearcasting and 0 or effectiveManaCost(bestSpell, maxMana, currentMaelstromReduction)
        -- Preview one action ahead, rather than calling the second-highest
        -- current score the next action. Spend this cast's mana, consume its
        -- proc assumptions, and exclude its cooldown/shared shock cooldown.
        rotationNextSpell = nil
        local afterMana = currentMana and cost and math.max(0, currentMana - cost) or nil
        local health = currentTargetHealth()
        local primaryDamage = ranked and ranked[1] and ranked[1].primaryDamage or bestDamage
        local afterHealth = health and math.max(0, health - primaryDamage) or nil
        local shock = { earthShock = true, frostShock = true, flameShock = true }
        local projectedUsed={}
        if bestSpell.key~='lightningBolt' and not (bestSpell.key=='chainLightning' and lightningMasteryActive) then projectedUsed[bestSpell.id]=true end
        local shockSpent=shock[bestSpell.key]
        for forecastStep=1,3 do
          local nextScore,chosen
          if not afterHealth or afterHealth > 0 then
            for _, item in ipairs(ranked or {}) do
                local nextSpell = item.spell
                local sameSpell = nextSpell.id == bestSpell.id
                local repeatable = nextSpell.key == "lightningBolt"
                    or (nextSpell.key == "chainLightning" and lightningMasteryActive)
                local sharedCooldown = shockSpent and shock[nextSpell.key]
                -- Current effective costs cannot price the next cast after a
                -- consumable discount ends. Omit that preview rather than
                -- claiming a second discounted/free cast without evidence.
                local futureCostKnown = not clearcasting
                    and not (nextSpell.key == "lightningBolt" and currentMaelstromReduction > 0)
                    -- Ranked damage includes the current Stormstrike bonus;
                    -- do not carry a consumed bonus into future comparisons.
                    and stormstrikeBonus~=true
                local canCastWhileMoving = not playerIsMoving()
                    or spellCastSeconds(nextSpell, activeTalents, 0, lightningMasteryActive) == 0
                if (not sameSpell or repeatable) and not sharedCooldown and not projectedUsed[nextSpell.id]
                    and futureCostKnown
                    and canCastWhileMoving
                    and canSpend(nextSpell, afterMana, maxMana, 10) then
                    local damage = item.damage
                    if afterHealth and not item.aoe then damage = math.min(damage, afterHealth) end
                    local score = damage / castTimeSeconds(nextSpell, activeTalents, 0, lightningMasteryActive)
                    local nextCost = effectiveManaCost(nextSpell, maxMana, 0)
                    if afterMana and maxMana and maxMana > 0 and nextCost then
                        score = score / (1 + nextCost / maxMana * 4 * math.max(0, 1 - afterMana / maxMana))
                    end
                    if not nextScore or score > nextScore then
                        nextScore, chosen = score, nextSpell
                    end
                end
            end
          end
          if not chosen then break end
          rotationForecast[#rotationForecast+1]=chosen
          rotationNextSpell=rotationForecast[1]
          local projectedCost=effectiveManaCost(chosen,maxMana,0)
          if afterMana and projectedCost then afterMana=math.max(0,afterMana-projectedCost) else break end
          for _,item in ipairs(ranked or {}) do if item.spell.id==chosen.id and afterHealth then afterHealth=math.max(0,afterHealth-(item.primaryDamage or item.damage)) end end
          if chosen.key~='lightningBolt' and not (chosen.key=='chainLightning' and lightningMasteryActive) then projectedUsed[chosen.id]=true end
          if shock[chosen.key] then shockSpent=true end
        end
        local scoreText
        if damageSource == "observed" then
            scoreText = string.format("your recent combat average is %.0f damage from %d casts", bestDamage, damageSamples)
        elseif damageSource == "calibrated" then
            if bestSpell.key == "chainLightning" then
                scoreText = string.format("your recent spell results scale the tooltip into an estimate of %.0f total Chain Lightning damage", bestDamage)
            else
                scoreText = string.format("your tooltip estimate is %.0f damage, scaled by %.0f%% from your recent spell results", bestDamage, calibrationRatio * 100)
            end
        elseif bestSpell.key == "chainLightning" then
            scoreText = string.format("the first-hit tooltip estimate, adjusted for jump falloff, gives about %.0f total damage over %.1fs", bestDamage, castSeconds)
        else
            scoreText = string.format("the client tooltip estimates about %.0f damage over %.1fs", bestDamage, castSeconds)
        end
        local reason
        if resourceDataAvailable and manaCostKnown and cost ~= nil then
            reason = string.format(
                "%s scores highest among your ready, in-range learned attacks after cast time and mana cost are considered. %.0f mana remains after the cast.",
                scoreText, math.max(0, currentMana - cost)
            )
            if unknownManaCostOmitted then
                reason = reason .. " An attack with hidden mana cost was left out of the damage ranking."
            end
        elseif resourceDataAvailable then
            reason = string.format(
                "%s scores highest among your ready, in-range learned attacks after cast time is considered. The client's usable check and resource reserve rule were applied, but this spell's mana cost was unavailable, so mana efficiency could not be compared.",
                scoreText
            )
        else
            reason = string.format(
                "%s scores highest among your ready, in-range learned attacks after cast time is considered. The client restricted mana values, so resource affordability and mana efficiency could not be checked; confirm the action bar shows the spell as usable.",
                scoreText
            )
        end
        if healthCapped then
            reason = reason .. " Its score was capped at the target's current health to avoid overvaluing overkill."
        end
        if bestSpell.key == "chainLightning" then
            local chainTargets = math.min(nearbyCount, coherenceActive and 4 or 3)
            local jumpLoss = coherenceActive and 20 or 30
            reason = string.format("%s Across up to %d visible enemies, damage is reduced by %d%% on each jump. Chain Lightning may hit fewer if the enemies are too far apart.", reason, chainTargets, jumpLoss)
        end
        if fireNovaTargetsUnknown then
            reason = reason .. " Fire Nova was not compared because the client exposes no safe combat query for which enemies are within 10 yards of its active totem."
        end
        if clearcasting then reason = reason .. " Clearcasting removes its mana cost." end
        if lightningMasteryActive and bestSpell.key == "chainLightning" then
            reason = reason .. " Lightning Mastery is active and removes Chain Lightning's cooldown."
        elseif lightningMasteryActive and (bestSpell.key == "lightningBolt") then
            reason = reason .. " Lightning Mastery is active and shortens this cast by 0.5 seconds."
        end
        if stormstrikeSpell and stormstrikeBonus == nil then
            reason = reason .. " Stormstrike's target-buff status was unavailable, so no 20% damage bonus was assumed."
        end
        if comparison ~= "" then reason = reason .. " Compared options: " .. comparison .. "." end
        if stormstrikeBonus == true and bestSpell.key == "chainLightning" then
            reason = reason .. " Stormstrike's 20% bonus applies to Chain Lightning's original target."
        elseif stormstrikeBonus == true and (bestSpell.key == "lightningBolt" or bestSpell.key == "earthShock") then
            reason = reason .. " Stormstrike increases this spell's damage by 20%."
        end
        if bestSpell.key == "lightningBolt" and maelstromReduction > 0 then
            reason = reason .. string.format(" Maelstrom Weapon reduces its cast time and mana cost by %d%%.", maelstromReduction)
        end
        local recommendation = result(bestSpell.name, reason, bestSpell, bestSpell.key == "chainLightning" and "area damage" or (maelstromReduction > 0 and bestSpell.key == "lightningBolt" and "maelstrom proc" or "damage choice"), targetGUID)
        if recommendation.situation == "damage choice" then
            if resourceDataAvailable and manaCostKnown and cost ~= nil then
                if playerInCombat() then
                    recommendation.shortReason = string.format("Use %s: about %.0f damage for %.0f mana, with enough mana left afterward.", bestSpell.name, bestDamage, cost)
                else
                    recommendation.shortReason = string.format("Open with %s: about %.0f damage for %.0f mana, with your target in range.", bestSpell.name, bestDamage, cost)
                end
            else
                recommendation.shortReason = string.format("Use %s: it has the strongest estimated damage value among your ready attacks.", bestSpell.name)
            end
        end
        return recommendation
    end

    -- Keep a useful actionable cue if this client did not expose enough
    -- damage data to rank the ready attacks.
    if fallbackSpell then
        local reason = string.format(
            "%s is learned, ready, affordable, and in range. The client did not expose enough damage data to compare your ready attacks, so this is a practical fallback rather than a measured damage winner.",
            fallbackSpell.name
        )
        if fireNovaTargetsUnknown then
            reason = reason .. " Fire Nova was not compared because the client exposes no safe combat query for which enemies are within 10 yards of its active totem."
        end
        return result(fallbackSpell.name, reason, fallbackSpell, "fallback damage choice", targetGUID)
    end

    if unknownRangeSpell then
        local reason = string.format(
            "%s is learned, ready, and affordable, but the client did not return a range result. Use it only if the action bar shows it in range; the coach cannot safely compare range-dependent options right now.",
            unknownRangeSpell.name
        )
        return result(unknownRangeSpell.name, reason, unknownRangeSpell, "range check unavailable", targetGUID)
    end

    local boltSpell = spells.bolt
    if not boltSpell then
        for _, actionBarSpell in ipairs(actionBarShamanSpells) do
            if actionBarSpell.key == "lightningBolt" then
                boltSpell = actionBarSpell
                break
            end
        end
    end
    if boltSpell then
        local _, insufficientPower = usable(boltSpell)
        if insufficientPower then
            return weaponRecommendation("Conserve mana", "Not enough mana for Lightning Bolt. Use weapon attacks if the target is in melee range.", "resource recovery", targetGUID, stormstrikeSpell)
        end
        local canAfford = canSpend(boltSpell, currentMana, maxMana, 10, clearcasting, maelstromReduction)
        if resourceDataAvailable and not canAfford and maxMana > 0 then
            return weaponRecommendation("Conserve mana", string.format("Casting would spend the coach's 10%% mana reserve (currently %.0f%%). Use weapon attacks if the target is in melee range.", mana), "resource recovery", targetGUID, stormstrikeSpell)
        end
    end

    if movementBlockedSpell then
        return result("Move safely", "No ready instant attack was found. Finish required movement first; cast " .. movementBlockedSpell.name .. " when the position is safe.", nil, "movement", targetGUID)
    end
    if cooldownDataHidden then
        return result("Cooldown data unavailable", "The game is hiding cooldowns in this combat, so the coach cannot safely decide which ability is ready. Check the action bar and use your weapon between abilities.", nil, "restricted data", targetGUID)
    end
    if usabilityDataUnavailable then
        return result("Ability readiness unavailable", "The client did not expose a safe usable-state result for your learned attacks. Check the action bar's usability coloring before choosing; the coach will not assume an ability is ready.", nil, "restricted data", targetGUID)
    end
    if rangeDataUnavailable then
        return result("Range data unavailable", "The client did not confirm that a recommended attack is in range. Check the action bar range indicator before using it.", nil, "restricted data", targetGUID)
    end
    if outOfRangeSpell then
        return result("Move into attack range", string.format("%s is learned, ready, and affordable, but the target is out of range. Move closer so the coach can compare your available attacks.", outOfRangeSpell.name), nil, "out of range", targetGUID)
    end
    if not resourceDataAvailable then
        return result("Use your weapon", "No learned Shaman attack currently passes the range and readiness checks. Mana data is restricted, so confirm resource affordability on the action bar while the coach reassesses your situation.", nil, "weapon attack", targetGUID)
    end
    return result("Use your weapon", "No learned Shaman attack currently passes the range, readiness, and mana checks. Keep attacking while the coach reassesses your situation.", nil, "weapon attack", targetGUID)
end
