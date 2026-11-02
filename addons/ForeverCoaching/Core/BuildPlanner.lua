ForeverCoaching = ForeverCoaching or {}
local FC = ForeverCoaching
local Planner = {}
FC.BuildPlanner = Planner

function Planner:GetBuildEvidenceUrl(build)
    local url=build and build.source and build.source.url or ''
    if url:match('^https://mobalytics%.gg/') or url:match('^https://www%.mobalytics%.gg/') then return url end
    return 'https://mobalytics.gg/wow-forever'
end

function Planner:GetBuildDisplayName(classToken,build)
    if build.kind=='custom' then return build.title end
    local name=(build.referenceTitle or build.title or ''):match('^([^:]+)') or ''
    if name:find('/ Finals',1,true) then
        local points={0,0,0};for _,talent in ipairs(build.talents or {})do if points[talent.treeIndex] then points[talent.treeIndex]=points[talent.treeIndex]+(talent.rank or 0) end end
        local primary=1;for i=2,3 do if points[i]>points[primary] then primary=i end end
        local tree=FC.TalentTrees and FC.TalentTrees[classToken] and FC.TalentTrees[classToken][primary]
        name=tree and tree.name or 'PvP'
    end
    name=name:gsub('%s*%(Experimental%)',''):gsub('%s*%(weave%)',''):gsub('%s*%(turret%)',''):gsub('%s*%(melee%)',''):gsub('%s+build$','')
    for _,class in ipairs({'Druid','Hunter','Mage','Paladin','Priest','Rogue','Shaman','Warlock','Warrior'})do name=name:gsub('%s+'..class..'$','') end
    name=name:gsub('Holy%-prot','Holy-Prot'):gsub('Ret%-prot','Ret-Prot'):gsub('Fury%-prot','Fury-Prot')
    if classToken=='WARRIOR' and (name=='Arms' or name=='Fury')then name=name..' warr' end
    if classToken=='DRUID' and name=='Feral' then name=build.role=='tank' and 'Feral (Bear)' or 'Feral (Cat)' end
    if classToken=='PRIEST' and name=='Smite' then name='Holy-Smite' end
    return name
end

function Planner:IsPreferredSource(build)
    local url=build.source and build.source.url or ""
    local host=url:lower():match("^https://([^/:?#]+)")
    if not host then return false end
    host=host:gsub("^www%.","")
    return host=="mythicsim.com" or host=="wowhead.com" or host=="mobalytics.gg"
        or host=="raider.io" or host=="foreverlogs.gg" or host=="bytetavern.com"
end

function Planner:MatchesPlaystyle(build, scenario)
    if build.fit==scenario then return true end
    for _,activity in ipairs(build.activities or {}) do if activity==scenario then return true end end
    return false
end

Planner.classes = {"DRUID","HUNTER","MAGE","PALADIN","PRIEST","ROGUE","SHAMAN","WARLOCK","WARRIOR"}
Planner.activities = {
    {id="dungeons",title="Dungeons"}, {id="leveling",title="Leveling"},
    {id="raids",title="Raids"}, {id="pvp",title="PvP"},
}

-- One source-backed starting point per talent specialization. Scores choose
-- relevant evidence, never invent a performance ranking between guide plans.
function Planner:GetSpecRecommendations(classToken, activity, level)
    local specs=(FC.TalentTrees or {})[classToken] or {}
    local builds=self:GetBuilds(classToken)
    local choices={}
    level=tonumber(level) or 1
    for specIndex,spec in ipairs(specs) do
        local choice={spec=spec.name,specIndex=specIndex,badge="NOT AVAILABLE",
            reason="A sourced "..activity.." recommendation for this spec is still missing.",proof="No supporting allocation verified.",options={}}
        local bestScore
        local fallbackIndex,fallbackScore
        for index,build in ipairs(builds) do
            local totals={0,0,0}
            for _,talent in ipairs(build.talents or {}) do totals[talent.treeIndex]=totals[talent.treeIndex]+talent.rank end
            local primary=1
            for tree=2,3 do if totals[tree]>totals[primary] then primary=tree end end
            if self:IsPreferredSource(build) and primary==specIndex and (build.points or 0)>0
                and self:GetPlan(classToken,level,index) then
                choice.options[#choice.options+1]=index
                local score=(build.evidence=="simulation" and 300 or (build.evidence=="guide" and 250 or 0))-math.abs(build.maxLevel-level)
                if build.maxLevel==60 then score=score+2000 end
                if not fallbackScore or score>fallbackScore then fallbackIndex=index;fallbackScore=score end
            end
            if self:IsPreferredSource(build) and primary==specIndex and (build.points or 0)>0 and build.evidence~="guide_conflict" then
                local scenario=activity
                if activity=="raids" then scenario=build.role=="healer" and "raid_healing" or (build.role=="tank" and "tank_threat" or "raid_damage") end
                if activity=="dungeons" then scenario=build.role=="healer" and "dungeon_healing" or (build.role=="tank" and "dungeon_tanking" or "dungeon_damage") end
                local matches=self:MatchesPlaystyle(build,scenario)
                local healingSuggestion=activity=="raids" and build.role=="healer"
                    and build.evidence=="guide" and self:MatchesPlaystyle(build,"dungeon_healing") and not matches
                local dungeonSuggestion=activity=="dungeons" and build.role=="damage"
                    and build.evidence=="guide" and self:MatchesPlaystyle(build,"leveling") and not matches
                local benchmark=activity=="raids" and build.evidence=="simulation" and (build.boardRank or 0)>0
                local duel=activity=="pvp" and build.evidence=="tournament"
                if matches or benchmark or duel or dungeonSuggestion or healingSuggestion then
                    local score=build.evidence=="guide" and 400 or (benchmark and 500 or (duel and 100 or 250))
                    if activity=="leveling" and build.levelingOrder then score=score+50 end
                    if dungeonSuggestion or healingSuggestion then score=150 end
                    if build.maxLevel==60 then score=score+2000 end
                    if duel then score=score+(build.seriesWins or 0)*10-(build.seriesLosses or 0) end
                    -- Prefer a plan for the preview level; never expand its ranks.
                    if build.maxLevel==level then score=score+1000
                    elseif build.maxLevel<level then score=score-400
                    else score=score-build.maxLevel end
                    if benchmark then score=score-(build.boardRank or 0) end
                    local valid=self:GetPlan(classToken,level,index)
                    if valid and (not bestScore or score>bestScore) then
                        bestScore=score
                        choice.index=index;choice.build=build
                        choice.provisional=dungeonSuggestion or healingSuggestion
                        choice.badge=benchmark and "SIM REFERENCE" or (duel and "DUEL EXAMPLE" or (build.evidence=="guide" and "RECOMMENDED" or "EXPERIMENTAL"))
                        choice.reason=benchmark and (build.role=="tank" and "Raid threat reference; survival is not ranked." or "Published single-target raid reference; fixed gear and buffs.") or (build.note~="" and build.note or "Published plan for this activity; combat comparison pending.")
                        if build.evidence=="experimental" then
                            local highlights={}
                            for _,talent in ipairs(build.talents) do
                                if talent.treeIndex==specIndex and talent.maxRank==1 then highlights[#highlights+1]=talent.name end
                            end
                            if #highlights>0 then
                                local last=highlights[#highlights]
                                local previous=highlights[#highlights-1]
                                choice.reason="Takes "..last..(previous and (" and "..previous) or "").." for this published plan. Experimental; combat comparison pending."
                            end
                        end
                        if build.maxLevel>level then choice.reason="Level "..build.maxLevel.." destination. "..choice.reason end
                        if dungeonSuggestion then choice.reason="Dungeon starting point from this leveling guide; dungeon ranking unverified. "..build.note end
                        if healingSuggestion then choice.reason="Healing guide starting point; no raid comparison published. "..(build.note or "") end
                        if duel then
                            choice.reason="Level 30 duel reference; requires 5 extra talent points. Not validated for level 60."
                            if build.seriesWins then choice.reason=build.seriesWins.." finals series won, "..build.seriesLosses.." lost. Level 30 duels; requires 5 extra points." end
                        end
                        choice.proof=(build.source.name or "Source").." / "..(build.source.guideUpdated or "snapshot unknown")
                        choice.proofUrl=(benchmark or duel) and build.source.comparisonUrl or build.source.url
                    end
                end
            end
        end
        choice.recommendedIndex=choice.index
        if not choice.build and fallbackIndex then
            choice=self:SelectSpecBuild(choice,builds,fallbackIndex,activity)
        end
        choices[specIndex]=choice
    end
    return choices
end

-- Keep MythicSim variants (Frostfire, Elehance, hybrid tanks, etc.)
-- visible alongside the activity's guide allocations.
function Planner:GetVisibleSpecBuilds(classToken, activity, level)
    local groups=self:GetSpecRecommendations(classToken,activity,level)
    local builds=self:GetBuilds(classToken)
    local rows={}
    for _,group in ipairs(groups) do
        local seen={}
        local function append(choice)
            if choice.index and seen[choice.index] then return end
            if choice.index then seen[choice.index]=true end
            choice.displayName=choice.build and choice.build.title or choice.spec
            if choice.build and choice.build.evidence=="simulation" then
                local b=choice.build
                if activity=="raids" then
                    choice.reason=b.role=="damage" and ((b.boardRank or 0)>0
                        and ("MythicSim raid damage rank #"..b.boardRank.." for its preset gear and buffs. Best suited to this single-target benchmark.")
                        or "MythicSim raid variant; no comparable damage rank published.")
                        or "MythicSim tank reference for raid threat; survival is not ranked."
                else
                    choice.reason="Level "..b.maxLevel.." MythicSim raid build. No published "..activity.." comparison for this variant."
                end
                choice.proofUrl=b.source.comparisonUrl or b.source.url
            end
            rows[#rows+1]=choice
        end
        append(group)
        for _,index in ipairs(group.options) do
            local b=builds[index]
            local roleScenario=activity=="raids" and (b.role=="healer" and "raid_healing" or (b.role=="tank" and "tank_threat" or "raid_damage"))
                or activity=="dungeons" and (b.role=="healer" and "dungeon_healing" or (b.role=="tank" and "dungeon_tanking" or "dungeon_damage"))
            local matchingGuide=roleScenario and (b.evidence=="guide" or b.evidence=="theorycraft")
                and self:MatchesPlaystyle(b,roleScenario)
            if b.evidence=="simulation" or matchingGuide then
                append(self:SelectSpecBuild(group,builds,index,activity))
            end
        end
    end
    -- Show one supported allocation per named spec/hybrid and role. Preserve
    -- catalog indices so saved character selections remain valid.
    local unique,positions,scores={},{},{}
    for _,choice in ipairs(rows)do
        local b=choice.build
        local key=b and (b.title:lower()..':'..(b.role or 'damage')) or ('missing:'..choice.spec)
        local score=0
        if b then
            if choice.index==choice.recommendedIndex then score=score+10000 end
            if b.maxLevel==60 then score=score+2000 end
            if b.evidence=='simulation' then score=score+500-(b.boardRank or 999)
            elseif b.evidence=='guide' then score=score+400 elseif b.evidence=='guide_conflict' then score=score-2000 end
            score=score-math.abs((b.maxLevel or 60)-(level or 60))
        end
        if not positions[key] then positions[key]=#unique+1;unique[#unique+1]=choice;scores[key]=score
        elseif score>scores[key] then unique[positions[key]]=choice;scores[key]=score end
    end
    rows=unique
    -- Compare only the relevant published evidence, not arbitrary catalog order.
    local winners,bestByRole={},{}
    for index,choice in ipairs(rows) do
        local b=choice.build
        local raidCandidate=b and activity=="raids" and (
            (b.evidence=="simulation" and (b.boardRank or 0)>0)
            or ((b.evidence=="guide" or b.evidence=="theorycraft") and self:MatchesPlaystyle(b,
                b.role=="healer" and "raid_healing" or (b.role=="tank" and "tank_threat" or "raid_damage"))))
        local dungeonTank=b and activity=="dungeons" and b.role=="tank" and b.evidence~="guide_conflict"
            and ((b.evidence=="simulation" and b.maxLevel==60)
                or self:MatchesPlaystyle(b,"dungeon_tanking"))
        if b and (choice.index==choice.recommendedIndex or raidCandidate or dungeonTank) then
            local score
            if dungeonTank then
                local direct=self:MatchesPlaystyle(b,"dungeon_tanking")
                score=(direct and 1000 or 100)+((b.maxLevel or 60)==60 and 2000 or 0)
                -- Prefer the dedicated tank allocation to a raid hybrid. Raid
                -- threat ranks do not establish dungeon AoE or survival value.
                if b.id=="protection-paladin" or b.id=="protection-warrior" or b.id=="feral-bear-druid" then score=score+50 end
                if not direct then choice.provisional=true end
            elseif activity=="raids" and b.evidence=="simulation" and (b.boardRank or 0)>0 then
                score=10000-b.boardRank
            elseif activity=="pvp" and b.evidence=="tournament" then
                score=1000+(b.seriesWins or 0)*10-(b.seriesLosses or 0)
            elseif b.evidence=="guide" or b.evidence=="theorycraft" then
                score=(choice.provisional and 100 or 500)-math.abs((b.maxLevel or 60)-level)
            end
            local role=b.role or "damage"
            if score and (not bestByRole[role] or score>bestByRole[role]) then winners[role]=index;bestByRole[role]=score end
        end
    end
    for index,choice in ipairs(rows) do
        choice.activityRecommended=choice.build~=nil and winners[choice.build.role or "damage"]==index
        if choice.activityRecommended and activity=="raids" and choice.build.evidence~="simulation" then
            choice.reason=choice.build.note or "Published raid build for this role."
        end
    end
    return rows
end

function Planner:GetBuildSummary(choice, activity, choices)
    local b=choice.build
    if not b then return choice.reason end
    if activity=="dungeons" and b.role=="tank" and b.evidence=="simulation" then
        return choice.activityRecommended
            and "Recommended tank starting point: a dedicated level 60 tank allocation. Dungeon AoE threat and survival have not been ranked."
            or "Alternative tank allocation. Its published simulation compares raid threat rather than dungeon pulls."
    end
    if activity=="raids" and b.evidence=="simulation" then
        local purpose=b.role=="tank" and "single-target threat" or "single-target boss damage"
        if choice.activityRecommended then
            return "Recommended for "..purpose..": the highest-ranked listed "..b.role.." reference for this class in MythicSim's preset fight."
        end
        local winner
        for _,other in ipairs(choices or {}) do
            if other.activityRecommended and other.build and other.build.role==b.role then winner=other;break end
        end
        if winner then
            return "Built for "..purpose..". "..(winner.displayName or winner.spec).." ranks higher in MythicSim's preset single-target comparison."
        end
        return "Built for "..purpose.."; this benchmark does not compare AoE, movement or survivability."
    end
    local ranks={}
    for _,talent in ipairs(b.talents or {}) do ranks[talent.name]=talent.rank end
    local strengths={}
    local function add(talent,benefit)
        if ranks[talent] and #strengths<2 then strengths[#strengths+1]=benefit end
    end
    -- Describe only features present in the allocation. These are strengths,
    -- not invented performance scores for an unmeasured encounter type.
    if activity=="leveling" then
        add("Improved Ghost Wolf","faster travel between pulls")
        add("Spirit Tap","mana recovery between kills")
        add("Feral Swiftness","faster Cat Form travel")
        add("Unleashed Fury","stronger pet damage")
        add("Benediction","lower mana costs")
        add("Anger Management","steadier rage generation")
    end
    if activity=="dungeons" or activity=="leveling" then
        add("Blade Flurry","two-target cleave")
        add("Riposte","defensive value while fighting in melee")
        add("Maelstrom Weapon","instant Lightning Bolts at full stacks")
        add("Improved Stormstrike","mana recovery during melee combat")
        add("Ice Block","an emergency defensive cooldown")
        add("Frostbite","additional control while kiting")
    end
    if b.role=="healer" then
        add("Nature's Swiftness","instant emergency healing")
        add("Swiftmend","quick healing recovery")
        add("Divine Fury","faster direct heals")
        add("Illumination","mana efficiency from healing criticals")
        add("Holy Shock","instant healing while moving")
    end
    if b.role=="tank" then
        add("Shield Specialization","shield-based defense")
        add("Last Stand","an emergency survival cooldown")
    end
    if #strengths>0 then
        local prefix=choice.activityRecommended and "Recommended for " or "Offers "
        return prefix..table.concat(strengths," and ").."."..(choice.provisional and " Guide-based starting point for this activity." or "")
    end
    if b.evidence=="tournament" then
        return "Duel reference: "..(b.player or b.title)..", "..(b.seriesWins or 0).." finals series won. This source compares duels, not battlegrounds."
    end
    if b.note and b.note~="" then return b.note end
    return "This allocation has no published comparison for "..activity.."; an AoE or survivability advantage has not been established."
end

function Planner:SelectSpecBuild(choice, builds, index, activity)
    local build=builds[index]
    if not build then return choice end
    local allowed=false
    for _,option in ipairs(choice.options or {}) do if option==index then allowed=true;break end end
    if not allowed then return choice end
    if index==choice.recommendedIndex then return choice end
    local alternative={}
    for key,value in pairs(choice) do alternative[key]=value end
    alternative.index=index;alternative.build=build;alternative.badge=""
    alternative.reason="You can play this spec in "..activity..". This allocation is a level "..build.maxLevel.." reference; its performance here is unverified."
    if build.evidence=="tournament" then alternative.reason="Level 30 duel allocation with 5 extra talent points; not validated for "..activity.."." end
    if build.evidence=="guide_conflict" then alternative.badge="SOURCE CONFLICT";alternative.reason=build.note end
    alternative.proof=(build.source.name or "Source").." / "..(build.source.guideUpdated or "snapshot unknown")
    alternative.proofUrl=build.source.url
    return alternative
end
Planner.scenarios = {
    {id="raid_damage",title="Raid: single-target damage"},
    {id="aoe",title="Dungeon / raid: multiple targets"},
    {id="leveling",title="Solo leveling"},
    {id="dungeon_healing",title="Dungeon healing"},
    {id="raid_healing",title="Raid healing"},
    {id="tank_threat",title="Tank: single-target threat"},
    {id="tank_survival",title="Tank: survival"},
    {id="pvp",title="PvP"},
    {id="pvp_duels",title="PvP: level 30 duels"},
}

-- Board ranks compare fixed reference characters, not the player's equipment.
-- Keep every build visible, including unranked and conflicting guide entries.
function Planner:CompareBuild(build, scenario, level)
    level = tonumber(level) or 1
    if build.evidence == "overview" then
        return {label="Overview only",reason=build.note,eligible=false}
    end
    if level < (build.maxLevel or 60) then
        return {label="Level "..build.maxLevel.." reference",reason="Your level: "..level..". No verified point order for your level.",eligible=false}
    end
    if build.evidence == "guide_conflict" then
        return {label="Source needs clarification",reason=build.note,eligible=false}
    end
    if build.evidence == "tournament" then
        if scenario=="pvp_duels" and level==build.maxLevel then
            return {label="Tournament duel example",reason="Finals submission; needs "..(build.legacyPoints or 0).." extra talent points. No universal winner.",eligible=false}
        end
        return {label="Level 30 duel submission",reason="Event rules and extra talent points apply; not compared for this activity.",eligible=false}
    end
    local group = scenario=="raid_damage" and "DPS" or (scenario=="tank_threat" and "tank" or nil)
    if group and build.evidence=="simulation" and build.boardGroup==group
        and (build.boardRank or 0)>0 and build.targets==1 and build.targetLevel==63
        and build.duration==120 then
        return {label="Reference "..(group=="DPS" and "DPS" or "threat").." rank #"..build.boardRank,
            reason="Level 60 raid benchmark; fixed gear and buffs.",eligible=true,rank=build.boardRank}
    end
    if self:MatchesPlaystyle(build,scenario) and build.evidence=="guide" and level==build.maxLevel then
        return {label="Guide fits this activity",reason=build.note,eligible=true}
    end
    if self:MatchesPlaystyle(build,scenario) and build.evidence=="experimental" and level==build.maxLevel then
        return {label="Experimental option",reason=build.note,eligible=false}
    end
    if self:MatchesPlaystyle(build,scenario) and build.evidence=="theorycraft" then
        return {label="Proposed scenario variant",reason=build.note,eligible=false}
    end
    if build.role=="healer" and (scenario=="dungeon_healing" or scenario=="raid_healing") then
        return {label="Healing comparison unavailable",reason="No matching healing benchmark for this level and activity.",eligible=false}
    end
    return {label="No matching comparison",reason="This source does not establish a winner for this activity.",eligible=false}
end

-- Evaluate every catalog entry for this class without turning missing data into
-- a low score. Only like-for-like benchmark entries can receive a best badge.
function Planner:EvaluateBuilds(classToken, scenario, level)
    local assessments, bestRank, rankedCount = {}, nil, 0
    local builds=self:GetBuilds(classToken)
    for index,build in ipairs(builds) do
        local result=self:CompareBuild(build,scenario,level)
        local assessment={label=result.label,reason=result.reason,rank=result.rank,eligible=result.eligible,badge="UNRATED",tone="muted"}
        local valid=self:GetPlan(classToken,level,index)
        if not valid then
            assessment.reason="Build data needs verification.";assessment.eligible=false;assessment.rank=nil
        elseif result.rank and result.eligible then
            assessment.badge="BENCHMARKED";rankedCount=rankedCount+1
            if not bestRank or result.rank<bestRank then bestRank=result.rank end
        elseif result.eligible and build.evidence=="guide" then
            assessment.badge="RECOMMENDED";assessment.tone="guide"
            assessment.reason="Guide recommendation for this playstyle. "..(build.note or "")
        elseif build.evidence=="guide_conflict" then
            assessment.badge="SOURCE CONFLICT"
        elseif build.evidence=="overview" then
            assessment.badge="OVERVIEW ONLY"
        elseif tonumber(level) and tonumber(level)<build.maxLevel then
            assessment.badge="LEVEL "..build.maxLevel
        elseif build.evidence=="tournament" and scenario=="pvp_duels" and tonumber(level)==build.maxLevel then
            assessment.badge="DUEL EXAMPLE"
        elseif build.evidence=="theorycraft" and self:MatchesPlaystyle(build,scenario) and tonumber(level)==build.maxLevel then
            assessment.badge="PROPOSED FIT"
        elseif build.evidence=="experimental" then
            assessment.badge=self:MatchesPlaystyle(build,scenario) and tonumber(level)==build.maxLevel and "EXPERIMENTAL FIT" or "EXPERIMENTAL"
        end
        assessments[index]=assessment
    end
    for index,assessment in ipairs(assessments) do
        if assessment.eligible and assessment.rank==bestRank and bestRank then
            assessment.badge=rankedCount>1 and "BEST REFERENCE" or "TOP REFERENCE"
            assessment.tone="best"
            assessment.reason="Highest listed "..(scenario=="tank_threat" and "threat" or "DPS").." reference for this class. Fixed raid setup; not a personal gear simulation."
        end
    end
    return assessments
end

function Planner:GetRecommendation(classToken, scenario, level)
    local winner, bestRank, matching, guideIndex = nil, nil, 0, nil
    local assessments=self:EvaluateBuilds(classToken,scenario,level)
    for index, build in ipairs(self:GetBuilds(classToken)) do
        local result=assessments[index]
        if result.eligible then
            matching=matching+1
            guideIndex=index
            if result.rank and (not bestRank or result.rank<bestRank) then
                bestRank=result.rank;winner=index
            end
        end
    end
    if winner then
        return winner,"Highest listed reference: "..self:GetBuilds(classToken)[winner].title..".\nFixed raid setup; your gear and fight may change the result."
    end
    if matching>0 then
        if matching==1 then
            return guideIndex,"Guide option: "..self:GetBuilds(classToken)[guideIndex].title..".\nFits this activity; no measured comparison establishes it as best."
        end
        return nil,matching.." guide option(s) match this activity.\nNo measured winner; compare their strengths below."
    end
    return nil,"No verified winner for this level and activity.\nAll sourced options remain available below."
end

-- A final allocation does not contain the author's leveling order. Offer a
-- separately labelled planning order without adding or replacing its points.
function Planner:GetTalentProgression(classToken, build)
    if build.kind=='custom' and FC.CustomBuilds then
        local valid,err=FC.CustomBuilds:Validate(FC.CustomBuilds:Draft(build))
        if not valid then return nil,err end
        return valid.order,'custom'
    end
    if build.levelingOrder then return build.levelingOrder,"published" end
    local layout=build.treeLayout or (FC.TalentTrees or {})[classToken]
    if not layout then return nil,"Talent layout unavailable." end
    local targets,totals={}, {0,0,0}
    for _,talent in ipairs(build.talents or {}) do
        local node=layout[talent.treeIndex] and layout[talent.treeIndex].nodes[talent.talentIndex]
        if not node or talent.rank>node.maxRank then return nil,"Talent allocation needs updating." end
        targets[#targets+1]={talent=talent,node=node,taken=0}
        totals[talent.treeIndex]=totals[talent.treeIndex]+talent.rank
    end
    local trees={1,2,3}
    table.sort(trees,function(a,b) return totals[a]==totals[b] and a<b or totals[a]>totals[b] end)
    local priority={};for index,tree in ipairs(trees) do priority[tree]=index end
    table.sort(targets,function(a,b)
        local at,bt=a.talent,b.talent
        if at.treeIndex~=bt.treeIndex then return priority[at.treeIndex]<priority[bt.treeIndex] end
        if a.node.row~=b.node.row then return a.node.row<b.node.row end
        return at.talentIndex<bt.talentIndex
    end)
    local order,spent={}, {0,0,0}
    local expected=build.points or 51
    for point=1,expected do
        local picked
        for _,target in ipairs(targets) do
            local talent=target.talent
            if target.taken<talent.rank and spent[talent.treeIndex]>=target.node.row*5 then picked=target;break end
        end
        if not picked then return nil,"This allocation cannot be ordered with the recorded tree requirements." end
        local t=picked.talent
        picked.taken=picked.taken+1;spent[t.treeIndex]=spent[t.treeIndex]+1
        order[#order+1]={level=point+9,name=t.name,rank=picked.taken,maxRank=t.maxRank,
            spellId=picked.node.spellId,treeIndex=t.treeIndex,talentIndex=t.talentIndex,
            why=picked.taken==t.rank and ("Completes this build's investment in "..t.name..".")
                or ("Develops "..t.name.." toward "..t.rank.."/"..t.maxRank.." for this build.")}
    end
    return order,"suggested"
end

function Planner:GetBuilds(classToken)
    local classes = FC.Builds and FC.Builds.classes or {}
    for name, definition in pairs(classes) do
        if name:upper() == tostring(classToken):upper() then
            local builds=definition.variants or {definition}
            for _,build in ipairs(builds)do build.referenceTitle=build.referenceTitle or build.title;build.title=self:GetBuildDisplayName(name:upper(),build) end
            if FC.CustomBuilds then
                local combined={};for _,build in ipairs(builds)do combined[#combined+1]=build end
                for _,build in ipairs(FC.CustomBuilds:List(name:upper()))do combined[#combined+1]=build end
                return combined
            end
            return builds
        end
    end
    return {}
end

-- Validate the sequential baseline route before showing any point advice.
function Planner:Validate(build)
    if type(build) ~= "table" or type(build.talents) ~= "table" then return false, "Build data is missing." end
    local levels, ranks, treePoints = {}, {}, 0
    local maxLevel = build.maxLevel or 30
    for _, step in ipairs(build.talents) do
        if type(step.name) ~= "string" or type(step.rank) ~= "number" or step.rank < 1
            or step.rank % 1 ~= 0 or type(step.maxRank) ~= "number"
            or type(step.firstLevel) ~= "number" or step.firstLevel < 10 or step.firstLevel % 1 ~= 0 then
            return false, "A talent step is invalid."
        end
        for offset = 0, step.rank - 1 do
            local level = step.firstLevel + offset
            if levels[level] or level > maxLevel or level ~= 10 + treePoints then
                return false, "Talent levels overlap or leave a gap."
            end
            if step.tier and treePoints < (step.tier - 1) * 5 then
                return false, "A talent tier is reached too early."
            end
            if step.requires and (ranks[step.requires.name] or 0) < step.requires.rank then
                return false, "A talent prerequisite is missing."
            end
            ranks[step.name] = (ranks[step.name] or 0) + 1
            if ranks[step.name] > step.maxRank then return false, "A talent exceeds its maximum rank." end
            levels[level] = { name=step.name, rank=ranks[step.name], maxRank=step.maxRank, why=step.why, level=level }
            treePoints = treePoints + 1
        end
    end
    if treePoints ~= maxLevel - 9 then return false, "The route does not cover its stated level range." end
    return true, levels
end

function Planner:GetPlan(classToken, level, variantIndex)
    local builds = self:GetBuilds(classToken)
    local build = builds[variantIndex or 1]
    if not build then return nil, "No MythicSim preset is available for this class yet." end
    if build.kind=='custom' and FC.CustomBuilds then
        local valid,err=FC.CustomBuilds:Validate(FC.CustomBuilds:Draft(build))
        if not valid then return nil,err end
        return {build=build,custom=true,reference=true,level=level,maxLevel=60,rows=build.talents,points=valid.points}
    end
    if build.kind == "reference" then
        local rows, points, treeTotals = {}, 0, {0,0,0}
        local codes = {}
        for code in (tostring(build.talentString or "").."-"):gmatch("(.-)-") do codes[#codes+1]=code end
        local seen = {}
        for _, talent in ipairs(build.talents or {}) do
            local tree, index = talent.treeIndex, talent.talentIndex
            local key = tostring(tree)..":"..tostring(index)
            if not tree or not treeTotals[tree] or not index or index < 1 or index % 1 ~= 0
                or seen[key] or type(talent.rank) ~= "number" or talent.rank < 1
                or talent.rank % 1 ~= 0 or type(talent.maxRank) ~= "number" or talent.rank > talent.maxRank
                or tonumber((codes[tree] or ""):sub(index,index)) ~= talent.rank then
                return nil, "MythicSim talent data is inconsistent."
            end
            seen[key] = true
            treeTotals[tree] = treeTotals[tree] + talent.rank
            points = points + talent.rank
            rows[#rows+1] = talent
        end
        local encodedPoints = 0
        for _, code in ipairs(codes) do
            for digit in code:gmatch(".") do
                if not tonumber(digit) then return nil, "MythicSim talent code is invalid." end
                encodedPoints = encodedPoints + tonumber(digit)
            end
        end
        if points ~= (build.points or 51) or encodedPoints ~= points or table.concat(treeTotals," / ") ~= build.distribution then
            return nil, "MythicSim talent totals do not match the preset."
        end
        return {build=build, reference=true, level=level, maxLevel=build.maxLevel or 60, rows=rows, points=points}
    end
    local ok, route = self:Validate(build)
    if not ok then return nil, route end
    level = math.max(1, math.floor(tonumber(level) or 1))
    local endLevel = build.maxLevel or 30
    local rows, spent = {}, 0
    for _, step in ipairs(build.talents) do
        local assigned = math.max(0, math.min(step.rank, level - step.firstLevel + 1))
        spent = spent + assigned
        rows[#rows+1] = {name=step.name,rank=assigned,targetRank=step.rank,maxRank=step.maxRank,firstLevel=step.firstLevel,lastLevel=step.firstLevel+step.rank-1,why=step.why}
    end
    return {
        build=build, level=level, maxLevel=endLevel, rows=rows, points=spent,
        nextPoint=route[math.max(10,level+1)],
        beforeTalents=level<10, beyondCoverage=level>endLevel,
        note="Baseline talent points only; extra Legacy points are not included.",
    }
end
