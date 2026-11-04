ForeverCoaching = ForeverCoaching or {}
local FC = ForeverCoaching
local Review = { latestRecommendation = nil }
FC.CombatReview = Review

local session
local pendingRecommendations = {}
local cachedCharacterKey

local function isSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

local function visibleUnitGUID(unit)
    if C_Secrets and C_Secrets.ShouldUnitIdentityBeSecret then
        local ok, secret = pcall(C_Secrets.ShouldUnitIdentityBeSecret, unit)
        if not ok or secret == true or isSecret(secret) then return nil end
    end
    if not UnitGUID then return nil end
    local ok, guid = pcall(UnitGUID, unit)
    if not ok or isSecret(guid) then return nil end
    return guid
end

local function spellName(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and info and not isSecret(info) then
            local nameOK, name = pcall(function() return info.name end)
            if nameOK and type(name) == "string" then return name end
        end
    end
    if GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, spellID)
        if ok and type(name) == "string" then return name end
    end
end

local function characterKey()
    local name, realm
    if UnitName then
        local ok, value = pcall(UnitName, "player")
        if ok then name = value end
    end
    if GetRealmName then
        local ok, value = pcall(GetRealmName)
        if ok then realm = value end
    end
    if isSecret(name) or isSecret(realm) or not name then return cachedCharacterKey end
    cachedCharacterKey = tostring(name) .. "-" .. tostring(realm or "")
    return cachedCharacterKey
end

local function copyTalents(talents)
    if not talents then return nil end
    local copy = {}
    for _, talent in pairs(talents) do
        copy[#copy + 1] = {
            spellID = talent.spellID,
            name = talent.name,
            rank = talent.rank,
            maxRank = talent.maxRank or talent.rank,
        }
    end
    table.sort(copy, function(a, b) return a.name < b.name end)
    return copy
end

function Review:SetLatestRecommendation(recommendation)
    if not recommendation then
        self.latestRecommendation = nil
        if session then session.recommendationKey = nil end
        return
    end
    local latest = {
        spellID = recommendation.spellID,
        spellName = recommendation.spellName,
        reason = recommendation.reason,
        shortReason = recommendation.shortReason,
        situation = recommendation.situation,
        playerLevel = recommendation.playerLevel,
        targetLevel = recommendation.targetLevel,
        targetGUID = recommendation.targetGUID or visibleUnitGUID("target"),
        shownAt = GetTime and GetTime() or 0,
    }
    self.latestRecommendation = latest
    if session and recommendation and recommendation.talents then
        if not session.activeTalents and recommendation.talents then
            session.activeTalents = copyTalents(recommendation.talents)
        end
    end
    if session then
        local castSpellID = not isSecret(recommendation.targetCastSpellID) and recommendation.targetCastSpellID or nil
        local key = table.concat({
            tostring(recommendation.spellID or recommendation.message or "no recommendation"),
            tostring(recommendation.situation or ""),
            tostring(latest.targetGUID or ""),
            tostring(castSpellID or ""),
        }, "|")
        local last = session.recommendations[#session.recommendations]
        if session.recommendationKey == key and last then
            -- Refresh volatile mana and target-health details in place instead
            -- of recording another history row for each HUD update.
            last.reason = recommendation.reason
            last.shortReason = recommendation.shortReason
            last.playerLevel = recommendation.playerLevel
            last.targetLevel = recommendation.targetLevel
            last.name = recommendation.spellName or recommendation.message or "No recommendation"
        else
            session.recommendations[#session.recommendations + 1] = {
                spellID = recommendation.spellID,
                name = recommendation.spellName or recommendation.message or "No recommendation",
                reason = recommendation.reason,
                shortReason = recommendation.shortReason,
                situation = recommendation.situation,
                playerLevel = recommendation.playerLevel,
                targetLevel = recommendation.targetLevel,
            }
        end
        session.recommendationKey = key
    end
end

local function ensureSavedData()
    ForeverCoachingDB = ForeverCoachingDB or {}
    ForeverCoachingDB.reviews = ForeverCoachingDB.reviews or {}
    ForeverCoachingDB.settings = ForeverCoachingDB.settings or {}
end

function Review:GetReadyNoticeEnabled()
    ensureSavedData()
    return ForeverCoachingDB.settings.showCombatAnalysisNotice ~= false
end

function Review:SetReadyNoticeEnabled(enabled)
    ensureSavedData()
    ForeverCoachingDB.settings.showCombatAnalysisNotice = enabled == true
    if not enabled and FC.HideCombatAnalysisNotice then
        FC:HideCombatAnalysisNotice()
    end
end

function Review:MarkLatestViewed()
    if self:GetSource()=="foreverlogs" then return end
    ensureSavedData()
    ForeverCoachingDB.combatAnalysisReady = false
    if FC.HideCombatAnalysisNotice then FC:HideCombatAnalysisNotice() end
end

local function beginCombat()
    local opener = Review.latestRecommendation
    Review.latestRecommendation = nil
    pendingRecommendations = {}
    local playerLevel
    if UnitLevel then
        local ok, value = pcall(UnitLevel, "player")
        if ok then playerLevel = value end
    end
    if isSecret(playerLevel) then playerLevel = nil end
    session = {
        started = GetTime and GetTime() or 0,
        character = characterKey(),
        playerLevel = playerLevel,
        tuningRevision = FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.revision,
        casts = 0,
        matched = 0,
        compared = 0,
        recommendations = {},
        activeTalents = nil,
        alternatives = {},
        failedAttempts = {},
        damage = {},
        totalDamage = 0,
    }
    if UnitClass then
        local ok,_,class=pcall(UnitClass,'player')
        if ok and not isSecret(class) then session.class=class end
    end
    if FC.EncounterCoach and FC.SpecScenarios then
        local ok,context=pcall(FC.EncounterCoach.GetCombatContext or FC.EncounterCoach.GetBuildContext,FC.EncounterCoach)
        if ok and context then
            session.combatContext=context
            session.specTree=context.tree;session.specRole=context.role
            local readable,spec=pcall(FC.SpecScenarios.ForCurrent,FC.SpecScenarios,context,true)
            if readable and spec and spec.available then session.specTree=spec.treeIndex;session.specRole=spec.role end
        end
    end
    -- Keep the opener's explanation when the first cast starts the fight.
    local targetGUID = visibleUnitGUID("target")
    if opener and opener.spellID and targetGUID and opener.targetGUID == targetGUID
        and GetTime() - (opener.shownAt or 0) <= 2 then
        session.recommendations[1] = {
            spellID = opener.spellID,
            name = opener.spellName,
            reason = opener.reason,
            shortReason = opener.shortReason,
            situation = opener.situation,
            playerLevel = opener.playerLevel,
            targetLevel = opener.targetLevel,
        }
    end
end

local function recordFailedAttempt(spellID, interrupted)
    if not session or not spellID or isSecret(spellID) then return end
    local name = spellName(spellID) or ("Spell " .. spellID)
    local now = GetTime()
    local last = session.failedAttempts[#session.failedAttempts]
    -- FAILED and FAILED_QUIET can describe the same attempt.
    if last and last.spellID == spellID and now - last.at < 0.15 then
        last.interrupted = last.interrupted or interrupted
        pendingRecommendations[spellID] = nil
        return
    end
    session.failedAttempts[#session.failedAttempts + 1] = {
        name = name,
        spellID = spellID,
        at = now,
        clientMessage = session.lastUIError and now - session.lastUIError.at <= 0.4
            and session.lastUIError.message or nil,
        interrupted = interrupted,
    }
    pendingRecommendations[spellID] = nil
end

local function recordCast(spellID, shownRecommendation, hasSentSnapshot)
    if not session or not spellID then return end
    session.casts = session.casts + 1
    local name = spellName(spellID) or ("Spell " .. spellID)
    session.damage[spellID] = session.damage[spellID] or { spellID = spellID, name = name, casts = 0, damage = 0 }
    session.damage[spellID].casts = session.damage[spellID].casts + 1

    local rec = shownRecommendation
    if not hasSentSnapshot then
        local current = Review.latestRecommendation
        local age = current and (GetTime() - (current.shownAt or 0)) or math.huge
        local currentTarget = visibleUnitGUID("target")
        if current and currentTarget and age <= 2 and current.targetGUID == currentTarget then rec = current end
    end
    if rec and rec.spellID then
        session.compared = session.compared + 1
        if rec.spellID == spellID then session.matched = session.matched + 1 end
        if rec.spellID ~= spellID then
            local suggestedName = rec.spellName or spellName(rec.spellID) or ("Spell " .. rec.spellID)
            local castName = spellName(spellID) or name
            local key = string.format("%s while %s was suggested (%s)", castName, suggestedName, rec.reason or "no reason recorded")
            session.alternatives[key] = (session.alternatives[key] or 0) + 1
        end
    end
end

local function readDamageMeterSpellDamage(reviewSession)
    local meter = C_DamageMeter
    local meterType = Enum and Enum.DamageMeterType and Enum.DamageMeterType.DamageDone
    local sessionType = Enum and Enum.DamageMeterSessionType and Enum.DamageMeterSessionType.Expired
    if not meter or not meter.GetCombatSessionFromType or not meter.GetCombatSessionSourceFromType
        or meterType == nil or sessionType == nil then
        return false
    end

    -- Forever blocks raw combat-log events for addons. Read Blizzard's own
    -- meter after combat, when its session fields are no longer secret.
    local sessionOK, meterSession = pcall(meter.GetCombatSessionFromType, sessionType, meterType)
    if not sessionOK or not meterSession or not meterSession.combatSources then return false end
    local playerSource
    for _, source in ipairs(meterSession.combatSources) do
        if source.isLocalPlayer == true then
            playerSource = source
            break
        end
    end
    local sourceGUID = playerSource and playerSource.sourceGUID
    if not sourceGUID or isSecret(sourceGUID) then return false end

    local sourceOK, meterSource = pcall(
        meter.GetCombatSessionSourceFromType, sessionType, meterType, sourceGUID
    )
    if not sourceOK or not meterSource or not meterSource.combatSpells then return false end

    local totals = {}
    for _, spellData in ipairs(meterSource.combatSpells) do
        local spellID, amount = spellData.spellID, spellData.totalAmount
        if not isSecret(spellID) and not isSecret(amount)
            and type(spellID) == "number" and type(amount) == "number" then
            totals[spellID] = (totals[spellID] or 0) + amount
        end
    end
    if not next(totals) then return false end

    local totalDamage = 0
    for spellID, amount in pairs(totals) do
        totalDamage = totalDamage + amount
        local row = reviewSession.damage[spellID]
        if not row then
            local name = spellName(spellID) or ("Spell " .. spellID)
            row = { spellID = spellID, name = name, casts = 0, damage = 0 }
            reviewSession.damage[spellID] = row
        end
        row.damage = amount
    end
    reviewSession.totalDamage = totalDamage
    reviewSession.damageMeterAvailable = true
    return true
end

local briefAdvice = {
    ["damage choice"] = "Use %s here: it gives the best damage for its cast time.",
    ["fallback damage choice"] = "Use %s here: it is ready and your target is in range.",
    ["range check unavailable"] = "Use %s if in range: it is ready, but distance could not be checked.",
    ["area damage"] = "Use %s against this group: its jumps can damage several enemies.",
    ["interrupt"] = "Use %s here to stop the enemy's interruptible cast.",
    ["maelstrom proc"] = "Use %s now: Maelstrom Weapon reduces its cast time and mana cost.",
    ["melee attack"] = "Use %s in melee: it strengthens your next lightning spell or Earth Shock.",
    ["attack speed cooldown"] = "Use %s here: faster weapon swings help during sustained melee combat.",
    ["elemental cooldown"] = "Use %s now to speed up casts and remove Chain Lightning's cooldown.",
}

local function shortText(value, limit)
    local words = {}
    for word in tostring(value or ""):gmatch("%S+") do
        if #words == limit then
            words[#words + 1] = "..."
            break
        end
        words[#words + 1] = word
    end
    return table.concat(words, " ")
end

local function compactReviewText(review)
    local choices, seen = {}, {}
    for _, item in ipairs(review.recommendations or {}) do
        local key = item.spellID or (item.situation == "resource recovery" and "mana")
            or (item.situation == "movement" and "movement")
        if key and not seen[key] then
            seen[key] = true
            choices[#choices + 1] = item
        end
    end
    -- Put the most useful situational lesson first; ordinary damage follows.
    local priority = { ["resource recovery"] = 0, interrupt = 1, ["area damage"] = 2, ["maelstrom proc"] = 3 }
    table.sort(choices, function(a, b)
        local ap, bp = priority[a.situation] or 4, priority[b.situation] or 4
        if ap ~= bp then return ap < bp end
        return (a.spellID or 0) < (b.spellID or 0)
    end)
    local lines = {}
    local item = choices[1]
    if item then
        if item.situation == "resource recovery" then
            lines[1] = item.shortReason or "Save mana: use weapon attacks when the target is in melee range."
        elseif item.situation == "movement" then
            lines[1] = "Complete required movement first; no ready instant attack was available. Resume casting when safe."
        else
            lines[1] = item.shortReason or string.format(briefAdvice[item.situation] or "Use %s when ready and in range.", shortText(item.name, 6))
        end
        if item.situation == "damage choice" and not item.shortReason then
            local reason = item.reason or ""
            if reason:find("mana cost are considered", 1, true) then
                lines[2] = "Your target is in range, and the mana cost fits your reserve."
            end
        end
    end
    local failed = review.failedAttempts and review.failedAttempts[1]
    if failed then
        local detail = failed.interrupted and "Cast interrupted."
            or "Cast failed; cause unknown."
        if failed.clientMessage then detail = "Game message: " .. shortText(failed.clientMessage, 10) end
        local failureLine = shortText(failed.name, 6) .. ": " .. detail
        if #lines == 0 then lines[1] = failureLine else lines[2] = failureLine end
    end
    if #lines == 0 then return "No spell advice recorded. Select an enemy during your next fight." end
    return table.concat(lines, "\n")
end

local function buildReport(reviewSession)
    if not reviewSession then return nil end
    local session = reviewSession
    local duration = math.max(1, (session.ended or (GetTime and GetTime()) or session.started) - session.started)
    local rows = {}
    for _, entry in pairs(session.damage) do rows[#rows + 1] = entry end
    table.sort(rows, function(a, b) return a.damage > b.damage end)

    local savedDamage = {}
    for i, row in ipairs(rows) do
        savedDamage[i] = {
            spellID = row.spellID,
            name = row.name,
            casts = row.casts,
            damage = row.damage,
        }
    end
    local matchPercent
    if session.compared > 0 then matchPercent = session.matched / session.compared * 100 end
    local recommendationHistory = {}
    for i, item in ipairs(session.recommendations) do
        recommendationHistory[i] = {
            spellID = item.spellID,
            name = item.name,
            reason = item.reason,
            shortReason = item.shortReason,
            situation = item.situation,
            playerLevel = item.playerLevel,
            targetLevel = item.targetLevel,
        }
    end
    return {
        text = compactReviewText(session),
        encounterCoaching = session.encounterCoaching,
        scenarioCoaching = session.scenarioCoaching,
        fightTimelineId = session.fightTimelineId,
        failedAttempts = session.failedAttempts,
        timestamp = time and time() or 0,
        character = session.character,
        tuningRevision = session.tuningRevision,
        class = session.class,
        specTree = session.specTree,
        specRole = session.specRole,
        combatContext = session.combatContext,
        playerLevel = session.playerLevel,
        duration = duration,
        casts = session.casts,
        recommendationMatchPercent = matchPercent,
        comparedCasts=session.compared,
        matchedCasts=session.matched,
        recommendations = recommendationHistory,
        activeTalents = copyTalents(session.activeTalents) or {},
        damageByAbility = savedDamage,
        damageSource = session.damageMeterAvailable and "BlizzardDamageMeter" or nil,
    }
end

function Review:GetLatestText()
    ensureSavedData()
    local currentCharacter = characterKey()
    if not currentCharacter then return "Character identity is unavailable, so this review cannot be matched safely." end
    for _, review in ipairs(ForeverCoachingDB.reviews) do
        if review.character == currentCharacter then return compactReviewText(review) end
    end
    return "No combat review for this character yet. Finish a fight with a hostile target to record one."
end

function Review:MatchesFilter(report,filter)
    if not filter then return true end
    local context=report.encounterCoaching and report.encounterCoaching.build or {}
    local class=report.class or context.class
    if class~=filter.class then return false end
    local tree=report.specTree
    if not tree then
        local ranks={};for _,talent in pairs(context.activeTalents or report.activeTalents or {}) do if talent.name then ranks[talent.name]=talent.rank or 0 end end
        local totals={0,0,0}
        for ti,layout in ipairs(FC.TalentTrees and FC.TalentTrees[class] or {}) do for _,talent in ipairs(layout.nodes or {}) do totals[ti]=totals[ti]+(ranks[talent.name] or 0) end end
        local highest,tied=0,false
        for ti,value in ipairs(totals) do if value>highest then highest=value;tree=ti;tied=false elseif value==highest and value>0 then tied=true end end
        if tied then tree=nil end
    end
    if filter.tree and tree~=filter.tree then return false end
    if filter.role and report.specRole and report.specRole~=filter.role then return false end
    if class=='DRUID' and tree==2 and filter.role and not report.specRole then return false end
    return true
end
function Review:GetLatestSummary(filter)
    ensureSavedData()
    if self:GetSource()=="foreverlogs" then
        local statistics=FC.ForeverLogsStatistics
        if statistics and statistics.boards then
            local rankings,coverage={},{}
            for _,board in ipairs(statistics.boards) do
                local lines={board.title.." ("..board.unit..")"}
                for i,row in ipairs(board.rows or {}) do if i<=5 then lines[#lines+1]=row.rank..". "..row.className.." / "..row.specName..": "..string.format("%.0f",row.value) end end
                if #(board.rows or {})==0 then lines[#lines+1]=board.note or "No recorded rankings available yet." end
                rankings[#rankings+1]=table.concat(lines,"\n")
                for _,row in ipairs(board.rows or {}) do coverage[#coverage+1]=board.title.." / "..row.className.." / "..row.specName..": "..row.samples.." samples" end
            end
            return {metrics="Forever Logs / Class performance",headings={"SCENARIO RANKINGS","RECORDED SAMPLES","ABOUT THESE RANKINGS"},goodText=table.concat(rankings,"\n\n"),wrongText=#coverage>0 and table.concat(coverage,"\n") or "No aggregate samples available yet.",improveText=statistics.basis or statistics.notice or "Rankings not yet available.",coverage="Source: https://foreverlogs.gg/ / aggregate rankings; individual parses and external fight reviews deferred until release."}
        end
        if statistics and statistics.statistics then
            local rows={}
            for class,group in pairs(statistics.statistics) do for spec,values in pairs(group.specs or {}) do
                if type(values.median)=="number" and (values.total_parses or 0)>0 then rows[#rows+1]={name=class.." / "..spec,value=values.median,samples=values.total_parses} end
            end end
            table.sort(rows,function(a,b) if statistics.metric=="avg_dtps" then return a.value<b.value end return a.value>b.value end)
            local ranks,counts={},{}
            for i,row in ipairs(rows) do if i<=10 then ranks[#ranks+1]=i..". "..row.name..": "..string.format("%.1f",row.value);counts[#counts+1]=row.name..": "..row.samples.." samples" end end
            return {metrics="Forever Logs / "..(statistics.phase_name or "Selected phase").." / "..(statistics.metric or "").." / "..(statistics.difficulty or ""),
                headings={"CLASS / SPEC STATISTICS","SAMPLE COVERAGE","COMPARISON CONTEXT"},
                goodText=#rows>0 and table.concat(ranks,"\n") or "No aggregate samples are available for this selection.",
                wrongText=#rows>0 and table.concat(counts,"\n") or "Choose another phase, difficulty or encounter in the local preview, then copy the updated addon and restart WoW.",
                improveText="Values are recorded class/spec medians, not individual player parses. Build, gear and assignments affect the results. Lower damage taken alone does not prove better survival.",
                coverage="Imported aggregate snapshot / Forever Logs: https://foreverlogs.gg/ / player parses and external fight reviews deferred until release."}
        end
        local imported=FC.ForeverLogsReview
        if not imported then return {metrics="Forever Logs / No imported encounter",goodText="Choose an encounter and player in the local Combat Review, then import the review.",wrongText="No Forever Logs event review is loaded.",improveText="Import a review into the workspace addon, copy it to WoW, and restart the game."} end
        local function section(items)
            local lines={}
            for index,item in ipairs(items or {}) do
                local evidence={}
                for i,event in ipairs(item.evidence or {}) do
                    evidence[#evidence+1]=(event.time or "?")..(event.spellId and " / spell #"..event.spellId or "")
                end
                lines[#lines+1]=(item.title or "Finding")..": "..(item.what or "").."\n"..(item.why or "")..(item.next and "\nNext: "..item.next or "")..(#evidence>0 and "\nEvidence: "..table.concat(evidence,", ") or "")..(item.contextOrigin and "\n"..item.contextOrigin or "")..(item.sourceUrl and "\nSource: "..item.sourceUrl or "")
            end
            return table.concat(lines,"\n\n")
        end
        return {metrics="Forever Logs / "..(imported.metrics or "Imported encounter").." / "..(imported.analyzedAt or ""),
            goodText=section(imported.good),wrongText=section(imported.wrong),improveText=section(imported.improve),
            coverage=imported.coverage,sourceUrl="https://foreverlogs.gg/"}
    end
    local character=characterKey()
    local latest
    if character or filter then
        for _,report in ipairs(ForeverCoachingDB.reviews) do
            if (filter or report.character==character) and self:MatchesFilter(report,filter) then latest=report;break end
        end
    end
    if not latest then
        if filter then return {metrics='No recorded fight for this class/spec',goodText='No matching fight recorded yet.',wrongText='No matching fight to assess.',improveText='Record a fight on this class and specialization.'} end
        return {metrics="Local observations / No fight recorded yet",goodText="Finish a fight to see what you did well, supported by recorded actions.",wrongText="No mistakes can be assessed before a fight is recorded.",improveText="Select an enemy and finish a fight. You can also import a Forever Logs encounter.",observation="Finish a fight to see a review for this character.",
            takeaway="Recorded decisions will appear here after combat.",nextStep="Select a hostile target so the coach can record its recommendations."}
    end
    local failures=latest.failedAttempts or {}
    if latest.encounterCoaching and FC.EncounterCoach then
        local good,investigate,improve=FC.EncounterCoach:Summarize(latest.encounterCoaching)
        local timeline=FC.FightRecorder and FC.FightRecorder:Find(latest.fightTimelineId)
        local recorded=timeline and FC.FightRecorder:Analyze(timeline)
        local scenarios=latest.scenarioCoaching or timeline and timeline.scenarios
        if scenarios and FC.ScenarioTracker then
            local identity=latest.combatContext or latest.encounterCoaching.build or {class=latest.class,role=latest.specRole}
            local sg,sw,sn=FC.ScenarioTracker:Summarize(scenarios,identity)
            if sg~='' then good=sg..'\n\n'..good;investigate=sw..'\n\n'..investigate;improve=sn..'\n\n'..improve end
        end
        if recorded then good=recorded.good..(good~='' and '\n\n'..good or '');investigate=recorded.investigate..(investigate~='' and '\n\n'..investigate or '') end
        local build=latest.encounterCoaching.build or {}
        return {metrics="Local encounter decisions / "..(build.title or "Build unavailable").." / "..tostring(latest.casts or 0).." casts",
            goodText=good~="" and good or "No matching situational response was confirmed. Damage casts alone do not establish encounter execution.",
            wrongText=investigate~="" and investigate or "No unconfirmed situational response in the observed windows. This does not establish a flawless fight.",
            improveText=improve~="" and improve or "Practice the next assigned mechanic with this build. Review the exact target and timing of each response.",
            coverage=(recorded and recorded.coverage or "Observed ready interrupts, group health, removable debuffs and mana. No complete combat outcome stream was available.")..(scenarios and '\n'..scenarios.coverage or '')}
    end
    local casts=tonumber(latest.casts) or 0
    local observation=casts.." successful casts; "..#failures.." failed or interrupted attempts recorded."
    local nextStep="Focus on one decision at a time during your next fight."
    if #failures>0 then
        local first=failures[1]
        local name=shortText(first.name or "Spell",5)
        if first.clientMessage then
            nextStep="Before retrying "..name..", address the game message: "..shortText(first.clientMessage,10)
        elseif first.interrupted then
            nextStep="Check whether movement or an enemy interrupt stopped "..name.." before changing your rotation."
        else
            nextStep="Watch the game error when "..name.." fails; its cause was not recorded."
        end
    elseif #(latest.recommendations or {})>0 then
        local first=latest.recommendations[1]
        if first.situation=="resource recovery" then nextStep="Watch your resource reserve before starting another cast."
        elseif first.situation=="interrupt" then nextStep="Keep your interrupt ready for an interruptible enemy cast."
        elseif first.situation=="movement" then nextStep="Look for a safe moment to stop and cast."
        else nextStep="Compare the coach's suggestion with your target, range and resources before each cast." end
    else nextStep="Select an enemy so recommendations can be recorded alongside your casts." end
    local takeaway=compactReviewText(latest)
    -- Match percentage describes agreement with a suggestion, not correctness.
    if latest.comparedCasts and latest.comparedCasts>0 and #failures==0 then
        observation=observation.." "..(latest.matchedCasts or 0).."/"..latest.comparedCasts.." compared casts followed the suggestion."
    end
    local goodText=casts>0 and (casts.." successful casts recorded.\nYour abilities reached the successful-cast event. This confirms execution, but does not establish that each spell was the best choice.") or "No successful casts were recorded. This alone does not establish poor play."
    local wrongText=#failures>0 and (#failures.." failed or interrupted attempts recorded.\n"..observation.."\nA failed cast can delay your next action. Check the recorded game message before assigning a cause.") or "No failed attempts were recorded.\nThis is not a complete assessment of your rotation or encounter mechanics."
    if failures[1] then wrongText=wrongText.."\n"..shortText(failures[1].name or "Spell",6)..": "..(failures[1].clientMessage and shortText(failures[1].clientMessage,14) or failures[1].interrupted and "Cast interrupted; cause not established." or "Cause not recorded.") end
    return {goodText=goodText,wrongText=wrongText,improveText=nextStep.."\n"..takeaway,metrics=string.format("Local observations / %.0f sec / %s",tonumber(latest.duration) or 0,
            latest.damageSource and "damage available" or "cast observations only"),
        observation=observation,takeaway=takeaway,nextStep=nextStep}
end

function Review:GetSource()
    ensureSavedData()
    return ForeverCoachingDB.settings.combatReviewSource=="foreverlogs" and "foreverlogs" or "local"
end
function Review:SetSource(value)
    ensureSavedData()
    ForeverCoachingDB.settings.combatReviewSource=value=="foreverlogs" and "foreverlogs" or "local"
end

-- Recent per-cast results let the live coach account for this character's
-- current spell rank, gear, and damage modifiers instead of relying forever
-- on unmodified tooltip estimates. AoE spells are excluded by the caller
-- because these records do not yet track how many targets each cast hit.
local function talentSignature(talents)
    if not talents then return nil end
    local parts = {}
    for spellID, talent in pairs(talents) do
        if type(talent) == "table" and talent.spellID then
            parts[#parts + 1] = tostring(talent.spellID) .. ":" .. tostring(talent.rank or 0)
        elseif type(spellID) == "number" and type(talent) == "table" then
            parts[#parts + 1] = tostring(spellID) .. ":" .. tostring(talent.rank or 0)
        end
    end
    table.sort(parts)
    return table.concat(parts, ",")
end

function Review:GetObservedDamage(spellID, activeTalents, currentLevel)
    if not spellID or isSecret(spellID) then return nil end
    ensureSavedData()
    local totalDamage, totalCasts = 0, 0
    local currentCharacter = characterKey()
    if not currentCharacter or not currentLevel or isSecret(currentLevel) then return nil end
    local wantedTalents = talentSignature(activeTalents)
    local function include(entries, recordedTalents, recordedLevel)
        if recordedLevel ~= currentLevel then return end
        if wantedTalents and talentSignature(recordedTalents) ~= wantedTalents then return end
        for _, entry in pairs(entries or {}) do
            if entry.spellID == spellID and entry.casts and entry.damage and entry.casts > 0 then
                totalDamage = totalDamage + entry.damage
                totalCasts = totalCasts + entry.casts
            end
        end
    end

    for index = 1, math.min(#ForeverCoachingDB.reviews, 5) do
        local review = ForeverCoachingDB.reviews[index]
        if review.character == currentCharacter and review.damageSource == "BlizzardDamageMeter"
            and (not FC.ForeverSpellCatalog or review.tuningRevision==FC.ForeverSpellCatalog.revision) then
            include(review.damageByAbility, review.activeTalents, review.playerLevel)
        end
    end
    if totalCasts < 3 or totalDamage <= 0 then return nil end
    return totalDamage / totalCasts, totalCasts
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
events:RegisterEvent("UNIT_SPELLCAST_SENT")
events:RegisterEvent("UNIT_SPELLCAST_FAILED")
events:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
-- Read the game's own failure messages without accessing raw combat logs.
pcall(events.RegisterEvent, events, "UI_ERROR_MESSAGE")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        characterKey()
    elseif event == "PLAYER_REGEN_DISABLED" then
        beginCombat()
    elseif event == "UI_ERROR_MESSAGE" and session then
        local _, message = ...
        if not isSecret(message) and type(message) == "string" then
            local now = GetTime()
            session.lastUIError = { at = now, message = message }
            local last = session.failedAttempts[#session.failedAttempts]
            if last and now - last.at <= 0.4 then last.clientMessage = message end
        end
    elseif event == "UNIT_SPELLCAST_SENT" then
        local unit, _, _, spellID = ...
        if not isSecret(unit) and not isSecret(spellID) and unit == "player" and spellID then
            local rec = Review.latestRecommendation
            local targetGUID = visibleUnitGUID("target")
            if rec and targetGUID and rec.targetGUID == targetGUID and GetTime() - (rec.shownAt or 0) <= 2 then
                pendingRecommendations[spellID] = rec
            else
                pendingRecommendations[spellID] = false
            end
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if not isSecret(unit) and not isSecret(spellID) and unit == "player" then
            local rec = pendingRecommendations[spellID]
            pendingRecommendations[spellID] = nil
            recordCast(spellID, rec, rec ~= nil)
        end
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_FAILED_QUIET" then
        local unit, _, spellID = ...
        if not isSecret(unit) and not isSecret(spellID) and unit == "player" then
            recordFailedAttempt(spellID, false)
        end
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unit, _, spellID = ...
        if not isSecret(unit) and not isSecret(spellID) and unit == "player" then
            recordFailedAttempt(spellID, true)
        end
    elseif event == "PLAYER_REGEN_ENABLED" and session then
        local finishedSession = session
        finishedSession.ended = GetTime()
        session = nil
        pendingRecommendations = {}

        local function saveFinishedReview()
            local timeline=FC.FightRecorder and FC.FightRecorder.last
            if timeline and math.abs(timeline.started-finishedSession.started)<=1 then finishedSession.fightTimelineId=timeline.id;finishedSession.scenarioCoaching=timeline.scenarios end
            if FC.EncounterCoach and FC.EncounterCoach.last and FC.EncounterCoach.last.started >= finishedSession.started-1 then
                finishedSession.encounterCoaching=FC.EncounterCoach.last
            end
            finishedSession.character = finishedSession.character or characterKey()
            pcall(readDamageMeterSpellDamage, finishedSession)
            local reportOK, report = pcall(buildReport, finishedSession)
            if not reportOK then
                ensureSavedData()
                ForeverCoachingDB.lastReviewError = tostring(report)
                return
            end
            if report then
                ensureSavedData()
                ForeverCoachingDB.lastReviewError = nil
                table.insert(ForeverCoachingDB.reviews, 1, report)
                while #ForeverCoachingDB.reviews > 10 do table.remove(ForeverCoachingDB.reviews) end
                ForeverCoachingDB.combatAnalysisReady = true
                if FC.RefreshCombatReview then FC:RefreshCombatReview() end
                if Review:GetReadyNoticeEnabled() and FC.NotifyCombatAnalysisReady then
                    FC:NotifyCombatAnalysisReady(report)
                end
            end
        end

        if C_Timer and C_Timer.After then
            C_Timer.After(0.5, saveFinishedReview)
        else
            saveFinishedReview()
        end
    end
end)
