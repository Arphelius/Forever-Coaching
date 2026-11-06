ForeverCoaching = ForeverCoaching or {}
local Coach = {}
ForeverCoaching.TalentSnapshot = Coach
local talentCacheConfigID, talentCache, legacyTalentCache
local talentScanUnavailable = false
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
talentEvents:SetScript("OnEvent", function()
    talentCacheConfigID = nil
    talentCache = nil
    legacyTalentCache = nil
    talentScanUnavailable = false
end)

function Coach:GetActiveTalentSnapshot()
    return getActiveTalentSnapshot()
end
