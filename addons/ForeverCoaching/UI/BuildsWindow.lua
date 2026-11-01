ForeverCoaching = ForeverCoaching or {}
local FC=ForeverCoaching
local GOLD={1,.76,.32}
local MUTED={.56,.62,.70}
local ICONS={DRUID="Ability_Druid_Maul",HUNTER="INV_Weapon_Bow_07",MAGE="INV_Staff_13",PALADIN="INV_Hammer_01",PRIEST="INV_Staff_30",ROGUE="INV_ThrowingKnife_04",SHAMAN="Spell_Nature_BloodLust",WARLOCK="Spell_Nature_Drowsy",WARRIOR="INV_Sword_27"}
local function text(owner,value,size,width,color)
    local t=owner:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    t:SetFont("Fonts\\FRIZQT__.TTF",size,"");t:SetWidth(width);t:SetJustifyH("LEFT")
    t:SetWordWrap(true);t:SetTextColor(unpack(color or {.9,.91,.94}));t:SetText(value or "")
    return t
end
local function surface(f,r,g,b,edge)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(r,g,b,1);f:SetBackdropBorderColor(unpack(edge or {.18,.20,.24}))
end
local function icon(id)
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
    if GetSpellTexture then return GetSpellTexture(id) end
end
    local function readTraitState(layout)
        local api=C_Traits
        local diagnostic={reader="traits",status="API unavailable"}
        FC.TalentReadDiagnostics=diagnostic
        if not api or not api.GetConfigInfo or not api.GetTreeNodes or not api.GetNodeInfo
            or not api.GetEntryInfo or not api.GetDefinitionInfo then return end
        local function query(fn,...)
            if type(fn)~="function" then return end
            local ok,result=pcall(fn,...)
            if ok and not (issecretvalue and issecretvalue(result)) then return result end
        end
        local configID=query(C_ClassTalents and C_ClassTalents.GetActiveConfigID)
        if not configID and Enum and Enum.TraitConfigType then
            local configs=query(api.GetConfigsByType,Enum.TraitConfigType.Combat)
            if type(configs)=="table" and #configs==1 then configID=configs[1] end
        end
        diagnostic.configID=configID;diagnostic.status="No active class config"
        if not configID then return end
        local config=query(api.GetConfigInfo,configID)
        if type(config)~="table" or type(config.treeIDs)~="table" then return end
        local bySpell,byName={},{ }
        for ti,tree in ipairs(layout) do
            for index,node in ipairs(tree.nodes) do
                local target={key=ti..":"..index,tree=ti,maxRank=node.maxRank}
                bySpell[node.spellId]=target;byName[node.name]=target
                local localized=query(C_Spell and C_Spell.GetSpellName,node.spellId) or query(GetSpellInfo,node.spellId)
                if type(localized)=="string" then byName[localized]=target end
            end
        end
        local ranks,spent,points,matched={},0,{0,0,0},0
        local currencies,seenCurrencies,usedCurrencies={},{},{}
        local purchaseChecks={}
        for _,treeID in ipairs(config.treeIDs) do
            local nodes=query(api.GetTreeNodes,treeID)
            local treeMatches=false
            if type(nodes)=="table" then
                for _,nodeID in ipairs(nodes) do
                    local node=query(api.GetNodeInfo,configID,nodeID)
                    if type(node)=="table" then
                        local active=node.activeEntry and node.activeEntry.entryID
                        for _,entryID in ipairs(node.entryIDs or {}) do
                            local entry=query(api.GetEntryInfo,configID,entryID)
                            local definition=entry and entry.definitionID and query(api.GetDefinitionInfo,entry.definitionID)
                            local name=definition and (definition.overrideName or query(C_Spell and C_Spell.GetSpellName,definition.spellID))
                            local target=definition and (bySpell[definition.spellID] or byName[name])
                            if target and (node.maxRanks==target.maxRank or entry.maxRanks==target.maxRank) then
                                local rank=0
                                if active==entryID or (#(node.entryIDs or {})==1) then
                                    rank=node.ranksPurchased or node.currentRank or node.activeRank
                                end
                                if type(rank)=="number" and not (issecretvalue and issecretvalue(rank)) then
                                    if ranks[target.key]==nil then
                                        matched=matched+1;spent=spent+rank;points[target.tree]=points[target.tree]+rank
                                    end
                                    ranks[target.key]=rank;treeMatches=true
                                    purchaseChecks[target.key]=node.canPurchaseRank
                                    for _,cost in ipairs(query(api.GetNodeCost,configID,nodeID) or {}) do
                                        local currencyID=cost.ID or cost.traitCurrencyID
                                        if currencyID then usedCurrencies[currencyID]=true end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if treeMatches then
                for _,currency in ipairs(query(api.GetTreeCurrencyInfo,configID,treeID,false) or {}) do
                    currencies[#currencies+1]=currency
                end
            end
        end
        local available
        for _,currency in ipairs(currencies) do
            local id=currency.traitCurrencyID
            if usedCurrencies[id] and not seenCurrencies[id] and type(currency.quantity)=="number" then
                seenCurrencies[id]=true;available=(available or 0)+currency.quantity
            end
        end
        diagnostic.matchedTalents=matched;diagnostic.spent=spent;diagnostic.unspent=available
        diagnostic.status=matched>0 and "Class nodes read" or "No matching class nodes"
        if ForeverCoachingDB then ForeverCoachingDB.talentReadDiagnostics=diagnostic end
        if matched>0 then return ranks,spent,points,available,purchaseChecks end
    end
    local function readTalentState(layout)
        local ok,ranks,spent,points,unspent,checks=pcall(readTraitState,layout)
        if ok and ranks then return ranks,spent,points,unspent,checks end
        if not ok then FC.TalentReadDiagnostics={reader="traits",status="Trait scan failed"} end
        -- Newer Classic clients expose the same tree through a query/table API.
        if C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo then
            local ranks,spent,treePoints={},0,{0,0,0}
            local complete=true
            for ti,tree in ipairs(layout) do
                for index,node in ipairs(tree.nodes) do
                    local ok,info=pcall(C_SpecializationInfo.GetTalentInfo,{
                        specializationIndex=ti,tier=node.row+1,column=node.col+1,isInspect=false,isPet=false})
                    if not ok or type(info)~="table" or type(info.rank)~="number" or info.maxRank~=node.maxRank then
                        complete=false;break
                    end
                    ranks[ti..":"..index]=info.rank
                    spent=spent+info.rank;treePoints[ti]=treePoints[ti]+info.rank
                end
                if not complete then break end
            end
            if complete then return ranks,spent,treePoints end
        end
        if not GetTalentInfo or not GetNumTalents then return end
        local ranks,spent,treePoints={ },0,{0,0,0}
        for ti,tree in ipairs(layout) do
            local ok,count=pcall(GetNumTalents,ti)
            if not ok or type(count)~="number" or count==0 then return end
            local positions={}
            for index,node in ipairs(tree.nodes) do positions[(node.row+1)..":"..(node.col+1)]=index end
            for index=1,count do
                local success,name,texture,row,col,rank,maxRank=pcall(GetTalentInfo,ti,index)
                if not success or type(rank)~="number" then return end
                spent=spent+rank;treePoints[ti]=treePoints[ti]+rank
                local target=positions[tostring(row)..":"..tostring(col)]
                if target and tree.nodes[target].maxRank==maxRank then ranks[ti..":"..target]=rank end
            end
        end
        return ranks,spent,treePoints
    end
    local function readUnspentPoints()
        local result
        local function consider(fn,...)
            if type(fn)~="function" then return end
            local ok,value=pcall(fn,...)
            if ok and type(value)=="number" and value>=0 and value<=51 and value%1==0 then
                result=math.max(result or 0,value)
            end
        end
        consider(GetUnspentTalentPoints)
        consider(GetNumUnspentTalents)
        consider(C_SpecializationInfo and C_SpecializationInfo.GetNumUnspentTalents)
        consider(C_SpecializationInfo and C_SpecializationInfo.GetUnspentTalentPoints)
        consider(UnitCharacterPoints,"player")
        return result
    end

function FC:ReadLiveTalentState(layout) return readTalentState(layout) end
function FC:ReadUnspentTalentPoints() return readUnspentPoints() end
function FC:BuildTalentPage(parent)
    local planner=FC.BuildPlanner
    local _,class=UnitClass("player")
    local playerClass=class
    local level=UnitLevel("player") or 1
    local preview,selected,activity=60,nil,level<60 and 2 or 3
    local selectedSpec
    local selectedBuilds={}
    local choices={}
    local levels={60};if level~=60 then levels[#levels+1]=level end
    local previewIndex=1
    local previousClass
    local refresh
    local accent=GOLD
    local cards,classButtons,panels,activityButtons={},{},{},{}
    local function button(owner,title,x,y,width,click)
        local b=CreateFrame("Button",nil,owner,"BackdropTemplate")
        b:SetSize(width,28);b:SetPoint("TOPLEFT",owner,"TOPLEFT",x,y);surface(b,.07,.08,.10)
        if FC.ClassicTheme then FC.ClassicTheme:Button(b) end
        b.caption=text(b,title,11,width-12);b.caption:SetPoint("CENTER");b.caption:SetJustifyH("CENTER")
        b:SetScript("OnClick",click)
        b:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(unpack(accent)) end)
        b:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(.18,.20,.24) end)
        return b
    end
    text(parent,"Talent Builds",16,600,GOLD):SetPoint("TOPLEFT",18,-12)
    local vfxButton
    local function syncVFX() vfxButton.caption:SetText(FC:IsTalentVFXEnabled() and "VFX: On" or "VFX: Off") end
    vfxButton=button(parent,"",780,-8,116,function()
        FC:SetTalentVFXEnabled(not FC:IsTalentVFXEnabled());syncVFX()
    end)
    vfxButton:SetScript("OnShow",syncVFX);syncVFX()
    local recommendation=text(parent,"Choose any spec; recommendations never lock your selection.",11,878,MUTED)
    recommendation:SetPoint("TOPLEFT",18,-36);recommendation:SetMaxLines(1)
    for index,token in ipairs(planner.classes) do
        local classToken=token
        local b=button(parent,"",18+(index-1)*46,-58,38,function() class=classToken;selectedSpec=nil;refresh() end)
        b:SetHeight(32)
        local image=b:CreateTexture(nil,"ARTWORK");image:SetTexture("Interface\\Icons\\"..ICONS[token])
        image:SetPoint("TOPLEFT",4,-4);image:SetPoint("BOTTOMRIGHT",-4,4);image:SetTexCoord(.08,.92,.08,.92)
        b:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(classToken:sub(1,1)..classToken:sub(2):lower());GameTooltip:Show() end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
        classButtons[token]=b
    end
    for index,entry in ipairs(planner.activities) do
        local activityIndex=index
        activityButtons[index]=button(parent,entry.title,444+(index-1)*114,-60,108,function() activity=activityIndex;refresh() end)
    end
    local library=text(parent,"SPECIALIZATIONS",10,210,MUTED);library:SetPoint("TOPLEFT",18,-110)
    local scroll=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",18,-132);scroll:SetPoint("BOTTOMLEFT",18,70);scroll:SetWidth(200)
    local list=CreateFrame("Frame",nil,scroll);list:SetSize(198,500);scroll:SetScrollChild(list)
    local hero=text(parent,"",17,478);hero:SetPoint("TOPLEFT",246,-107);hero:SetMaxLines(1)
    local selectedBadge=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    selectedBadge:SetSize(160,24);selectedBadge:SetPoint("TOPLEFT",736,-106)
    surface(selectedBadge,.10,.085,.045,GOLD)
    selectedBadge.text=text(selectedBadge,"",10,150,GOLD)
    selectedBadge.text:SetPoint("CENTER");selectedBadge.text:SetJustifyH("CENTER")
    local meta=text(parent,"",10,650,MUTED);meta:SetPoint("TOPLEFT",246,-137)
    local status=text(parent,"",11,650,GOLD);status:SetPoint("TOPLEFT",246,-159);status:SetHeight(30);status:SetMaxLines(2)
    local detailScroll=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
    detailScroll:SetPoint("TOPLEFT",246,-201);detailScroll:SetPoint("BOTTOMLEFT",246,83);detailScroll:SetWidth(650)
    local detail=CreateFrame("Frame",nil,detailScroll);detail:SetSize(650,540);detailScroll:SetScrollChild(detail)
    local liveLevel=text(detail,"",12,640,GOLD);liveLevel:SetPoint("TOPLEFT",0,-3);liveLevel:SetMaxLines(1)
    local liveHint=text(detail,"",11,640);liveHint:SetPoint("TOPLEFT",0,-24);liveHint:SetMaxLines(1)
    local activeStep
    local focusPoint=false
    local talentLevelShift=0
    local characterKey=UnitGUID and UnitGUID("player")
    if characterKey and ForeverCoachingDB and ForeverCoachingDB.selectedTalentBuilds then
        selectedBuilds=ForeverCoachingDB.selectedTalentBuilds[characterKey] or {}
    end
    local function selectionKey() return class..":"..planner.activities[activity].id end
    if characterKey and ForeverCoachingDB and ForeverCoachingDB.talentLevelShifts then
        talentLevelShift=tonumber(ForeverCoachingDB.talentLevelShifts[characterKey]) or 0
    end
    local function updateLiveHint(build)
        activeStep=nil
        focusPoint=false
        liveLevel:SetText("YOUR LEVEL  "..level)
        if class~=playerClass then liveHint:SetText("Select your class to see your next talent.");return end
        local order=planner:GetTalentProgression(class,build)
        if not order then liveHint:SetText("No point order available for this build.");return end
        local layout=build.treeLayout or FC.TalentTrees[class]
        local ranks,spent,treePoints,traitUnspent,purchaseChecks=readTalentState(layout)
        local unspent=traitUnspent
        if unspent==nil then unspent=readUnspentPoints() end
        local diagnostics=FC.TalentReadDiagnostics or {}
        diagnostics.level=level;diagnostics.pointReaderResult=unspent
        diagnostics.hasClassicTalents=type(GetTalentInfo)=="function"
        diagnostics.hasSpecializationQuery=C_SpecializationInfo and type(C_SpecializationInfo.GetTalentInfo)=="function" or false
        if ForeverCoachingDB then ForeverCoachingDB.talentReadDiagnostics=diagnostics end
        if spent and unspent then
            local earned=spent+unspent
            if earned>0 and earned<=51 then
                local inferred=math.max(0,math.min(5,earned-(level-9)))
                talentLevelShift=earned<51 and inferred or math.max(talentLevelShift,inferred)
                if characterKey and ForeverCoachingDB then
                    ForeverCoachingDB.talentLevelShifts=ForeverCoachingDB.talentLevelShifts or {}
                    ForeverCoachingDB.talentLevelShifts[characterKey]=talentLevelShift
                end
            end
        elseif level==5 and unspent and unspent>0 then
            talentLevelShift=5
        end
        local budget=math.max(0,math.min(51,level-9+talentLevelShift))
        if not ranks then
            if budget==0 and not (unspent and unspent>0) then
                liveHint:SetText("Talent data unavailable: "..(diagnostics.status or "No character data returned")..".");return
            end
            activeStep=order[math.max(1,budget)]
            liveLevel:SetText("YOUR LEVEL  "..level..(unspent and ("   /   "..unspent.." unspent talent points") or ""))
            liveHint:SetText(activeStep and ("Route target: "..activeStep.name.." (learned ranks unavailable)") or "This allocation does not cover your current level.")
            return
        end
        if unspent==nil and budget==0 and spent==0 then
            liveHint:SetText("Talent ranks loaded; available point count has not been provided by the client.");return
        end
        unspent=unspent or math.max(0,budget-spent)
        liveLevel:SetText("YOUR LEVEL  "..level.."   /   "..unspent.." unspent talent points")
        if spent+unspent==0 then
            liveHint:SetText("No talent point available yet. Talented can unlock your first point before level 10.");return
        end
        for _,step in ipairs(order) do
            local rank=ranks[step.treeIndex..":"..step.talentIndex]
            if rank==nil then liveHint:SetText("This build's layout differs from your current talent trees.");return end
            if rank<step.rank then
                local node=layout[step.treeIndex].nodes[step.talentIndex]
                if treePoints[step.treeIndex]<node.row*5 then
                    liveHint:SetText("Your talents differ from this route; review the point order below.");return
                end
                activeStep=step
                if unspent>0 and purchaseChecks and purchaseChecks[step.treeIndex..":"..step.talentIndex]==false then
                    activeStep=nil;liveHint:SetText("The next route talent is locked in your current tree; review the points below.");return
                end
                focusPoint=unspent>0
                liveHint:SetText((unspent>0 and "Spend your next point: " or "Next route talent: ")..step.name.." "..step.rank.."/"..step.maxRank)
                return
            end
        end
        liveHint:SetText("All points in this build's published allocation are learned.")
    end
    for treeIndex=1,3 do
        local p=CreateFrame("Frame",nil,detail,"BackdropTemplate")
        p:SetPoint("TOPLEFT",(treeIndex-1)*220,-54);p:SetHeight(400)
        p:SetWidth(210);surface(p,.035,.043,.055)
        p.emblem=p:CreateTexture(nil,"BACKGROUND")
        p.emblem:SetPoint("CENTER",0,-12);p.emblem:SetSize(180,180)
        p.emblem:SetAlpha(.045)
        p.wash=p:CreateTexture(nil,"BACKGROUND");p.wash:SetTexture("Interface\\Buttons\\WHITE8X8")
        p.wash:SetPoint("TOPLEFT",1,-1);p.wash:SetPoint("TOPRIGHT",-1,-1);p.wash:SetHeight(43)
        p.title=text(p,"",12,150);p.title:SetPoint("TOPLEFT",12,-13)
        p.total=text(p,"",12,38,GOLD);p.total:SetPoint("TOPRIGHT",-10,-13);p.total:SetJustifyH("RIGHT")
        p.nodes={};panels[treeIndex]=p
    end
    local footnote=text(parent,"",10,650,MUTED);footnote:SetPoint("BOTTOMLEFT",246,60)
    local popup=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    popup:SetSize(650,94);popup:SetPoint("BOTTOMRIGHT",-18,48);popup:SetFrameLevel(parent:GetFrameLevel()+30)
    surface(popup,.045,.05,.065,{.7,.5,.2});popup:Hide()
    popup.title=text(popup,"",12,580,GOLD);popup.title:SetPoint("TOPLEFT",14,-12)
    popup.box=CreateFrame("EditBox",nil,popup,"InputBoxTemplate")
    popup.box:SetPoint("TOPLEFT",18,-38);popup.box:SetSize(604,24);popup.box:SetAutoFocus(false)
    popup.box:SetScript("OnEscapePressed",function(self) self:ClearFocus();popup:Hide() end)
    popup.box:SetScript("OnEditFocusGained",function(self) self:HighlightText() end)
    text(popup,"Ctrl+C to copy",10,280,MUTED):SetPoint("BOTTOMLEFT",14,9)
    button(popup,"x",610,-6,28,function() popup.box:ClearFocus();popup:Hide() end)
    local function copy(title,value) popup.title:SetText(title);popup.box:SetText(value or "");popup:Show();popup.box:SetFocus();popup.box:HighlightText() end
    local function current() return choices[selectedSpec] and choices[selectedSpec].build end
    local function footer(title,x,width,click)
        local b=button(parent,title,0,0,width,click);b:ClearAllPoints();b:SetPoint("BOTTOMLEFT",x,12)
    end
    local routeWindow=CreateFrame("Frame",nil,detail,"BackdropTemplate")
    routeWindow:SetSize(650,100);routeWindow:SetPoint("TOPLEFT",0,-474)
    surface(routeWindow,.035,.043,.055,GOLD)
    local routeTitle=text(routeWindow,"",15,575,GOLD);routeTitle:SetPoint("TOPLEFT",14,-14);routeTitle:SetMaxLines(1)
    local routeNote=text(routeWindow,"Published point order. Levels 31–60 are untested; baseline points, without Legacy bonuses.",11,590,MUTED)
    routeNote:SetPoint("TOPLEFT",14,-42);routeNote:SetHeight(34);routeNote:SetMaxLines(2)
    local routeList=CreateFrame("Frame",nil,routeWindow);routeList:SetPoint("TOPLEFT",14,-84);routeList:SetSize(598,1)
    local routeRows={}
    local function showRoute()
        local build=current();if not build then return end
        for _,row in ipairs(routeRows) do row:Hide() end
        local order,orderType=planner:GetTalentProgression(class,build)
        local shift=class==playerClass and talentLevelShift or 0
        local endLevel=(order and #order+9 or build.maxLevel)-shift
        routeTitle:SetText("LEVEL "..(10-shift).."-"..endLevel.." / TALENT PROGRESSION")
        if not order then
            routeNote:SetText(orderType or "Talent progression unavailable for this allocation.")
            routeList:SetHeight(1);routeWindow:SetHeight(110);detail:SetHeight(594)
        else
            routeNote:SetText(orderType=="published"
                and "Guide's point order. Hover each talent for its effect; levels 31-60 are untested."
                or "Suggested point order for this allocation. Talent links need in-game confirmation.")
            if shift>0 then routeNote:SetText("Talented detected: route levels moved "..shift.." earlier. The build still uses at most 51 talent points.") end
            for index,step in ipairs(order) do
                local row=routeRows[index]
                if not row then
                    row=button(routeList,"",0,-(index-1)*54,590,function() end);row:SetHeight(50);row.caption:Hide()
                    row.title=text(row,"",11,570,GOLD);row.title:SetPoint("TOPLEFT",8,-7);row.title:SetMaxLines(1)
                    row.benefit=text(row,"",10,570,MUTED);row.benefit:SetPoint("TOPLEFT",8,-26);row.benefit:SetMaxLines(1)
                    routeRows[index]=row
                end
                row.title:SetText("Level "..(step.level-shift).." / "..step.name.." "..step.rank.."/"..step.maxRank)
                local nextPoint=activeStep and activeStep.treeIndex==step.treeIndex
                    and activeStep.talentIndex==step.talentIndex and activeStep.rank==step.rank
                surface(row,.07,.08,.10,nextPoint and GOLD or {.18,.20,.24})
                if nextPoint then row.title:SetText("NEXT POINT / "..step.name.." "..step.rank.."/"..step.maxRank) end
                local description=C_Spell and C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(step.spellId)
                if description then description=description:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("[\r\n]+"," ") end
                row.benefit:SetText(description and description~="" and description or step.why)
                local spell=step.spellId
                row:SetScript("OnEnter",function(self)
                    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                    if GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(spell) else GameTooltip:SetText(step.name) end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave",function() GameTooltip:Hide() end);row:Show()
            end
            routeList:SetHeight(#order*54);routeWindow:SetHeight(94+#order*54);detail:SetHeight(578+#order*54)
        end
        routeWindow:Show()
    end
    local levelButton=button(parent,"",0,0,198,function() previewIndex=previewIndex % #levels+1;preview=levels[previewIndex];refresh() end)
    levelButton:ClearAllPoints();levelButton:SetPoint("BOTTOMLEFT",18,12)
    footer("Talent code",246,122,function() local b=current();if b and (b.points or 0)>0 then local original=b.source.calculatorUrl and b.source.calculatorUrl~="";copy(original and "Original calculator / "..b.title or "Talent code / "..b.title,original and b.source.calculatorUrl or b.talentString) end end)
    footer("Mobalytics",378,282,function() local choice=choices[selectedSpec];if choice and choice.build then copy('Mobalytics build guides',FC.BuildPlanner:GetBuildEvidenceUrl(choice.build)) end end)
    refresh=function()
        detailScroll:SetVerticalScroll(0)
        popup.box:ClearFocus();popup:Hide()
        local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        accent=color and {color.r,color.g,color.b} or GOLD
        for token,b in pairs(classButtons) do b:SetBackdropBorderColor(unpack(token==class and accent or {.18,.20,.24}));b:SetAlpha(token==class and 1 or .55) end
        for _,card in ipairs(cards) do card:Hide() end
        choices=planner:GetVisibleSpecBuilds(class,planner.activities[activity].id,preview)
        local builds=planner:GetBuilds(class)
        local pick
        for index,choice in ipairs(choices) do
            if choice.activityRecommended then pick=index;break end
        end
        recommendation:SetText(pick and ("Recommended for "..planner.activities[activity].title..": "..choices[pick].displayName) or "Select a spec to see its build and source.")
        local function isRecommended(index,choice)
            return choice.activityRecommended==true
        end
        selectedSpec=nil
        local chosenID=selectedBuilds[selectionKey()]
        if chosenID then
            for index,choice in ipairs(choices) do
                if choice.build and choice.build.id==chosenID then selectedSpec=index;break end
            end
        end
        for index,b in ipairs(activityButtons) do
            surface(b,index==activity and .13 or .07,.08,.10,index==activity and GOLD or {.18,.20,.24})
        end
        if previousClass~=class then scroll:SetVerticalScroll(0);previousClass=class end
        levelButton.caption:SetText("Level "..preview..(preview==level and " / You" or " / Preview"))
        library:SetText("SPECIALIZATIONS / "..planner.activities[activity].title)
        local visibleCount=0
        for index,choice in ipairs(choices) do
            visibleCount=visibleCount+1
            local card=cards[index]
            if not card then
                card=button(list,"",0,0,196,function() end);card:SetHeight(80);card.caption:Hide()
                card.title=text(card,"",11,174);card.title:SetPoint("TOPLEFT",10,-9);card.title:SetMaxLines(2)
                card.detail=text(card,"",10,174,MUTED);card.detail:SetPoint("BOTTOMLEFT",10,27)
                card.badge=text(card,"",10,174,GOLD);card.badge:SetPoint("BOTTOMLEFT",10,9)
                cards[index]=card
            end
            local build=choice.build
            card:ClearAllPoints();card:SetPoint("TOPLEFT",list,"TOPLEFT",0,-(visibleCount-1)*86)
            card.title:SetText(choice.displayName or choice.spec)
            card.detail:SetText(build and ("Level "..build.maxLevel.." / "..build.role) or "Source needed")
            card.badge:SetText(isRecommended(index,choice) and "Recommended" or "")
            card.badge:SetTextColor(unpack(build and GOLD or MUTED))
            local active=index==selectedSpec
            surface(card,active and .11 or .045,active and .105 or .05,active and .085 or .065,active and accent or {.16,.18,.22})
            local buildIndex=index
            card:SetScript("OnClick",function()
                if not build then return end
                selectedBuilds[selectionKey()]=build.id
                if characterKey and ForeverCoachingDB then
                    ForeverCoachingDB.selectedTalentBuilds=ForeverCoachingDB.selectedTalentBuilds or {}
                    ForeverCoachingDB.selectedTalentBuilds[characterKey]=selectedBuilds
                    if class==playerClass then
                        ForeverCoachingDB.activeTalentBuilds=ForeverCoachingDB.activeTalentBuilds or {}
                        ForeverCoachingDB.activeTalentBuilds[characterKey]=build.id
                    end
                end
                refresh()
            end)
            card:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(unpack(buildIndex==selectedSpec and accent or {.16,.18,.22})) end)
            card:Show()
        end
        list:SetHeight(math.max(1,visibleCount*86))
        local choice=choices[selectedSpec]
        selected=choice and choice.index
        if not selected then routeWindow:Hide();detail:SetHeight(400) end
        local plan,err
        if selected then plan,err=planner:GetPlan(class,preview,selected) end
        for _,panel in ipairs(panels) do for _,node in ipairs(panel.nodes) do node:Hide() end end
        if not plan then
            routeWindow:Hide()
            liveLevel:SetText("YOUR LEVEL  "..level);liveHint:SetText("");activeStep=nil;focusPoint=false
            hero:SetText("Select a build")
            meta:SetText(planner.activities[activity].title.." / CHOOSE YOUR BUILD")
            selectedBadge:Hide();status:SetText(err or "Select a build from the list to activate talent guidance.")
            footnote:SetText("Your choice is remembered for this character and activity.")
            for _,panel in ipairs(panels) do panel:Hide() end
            return
        end
        for _,panel in ipairs(panels) do panel:Show() end
        local build=plan.build
        updateLiveHint(build)
        showRoute()
        hero:SetText(build.title)
        local evidence={simulation="SIM REFERENCE",guide="GUIDE",guide_conflict="SOURCE CONFLICT",overview="OVERVIEW",theorycraft="PROPOSED BUILD",tournament="TOURNAMENT / FINALS",experimental="EXPERIMENTAL"}
        meta:SetText((choice.provisional and "PROVISIONAL ACTIVITY PICK" or evidence[build.evidence] or "UNVERIFIED").."  /  LEVEL "..build.maxLevel.."  /  "..build.distribution.."  /  "..build.source.name)
        selectedBadge.text:SetText("Recommended")
        if isRecommended(selectedSpec,choice) then selectedBadge:Show() else selectedBadge:Hide() end
        local badgeColor=GOLD
        selectedBadge:SetBackdropBorderColor(unpack(badgeColor));selectedBadge.text:SetTextColor(unpack(badgeColor))
        status:SetText(planner:GetBuildSummary(choice,planner.activities[activity].id,choices))
        local ranks={};for _,talent in ipairs(plan.rows) do ranks[talent.treeIndex..":"..talent.talentIndex]=talent.rank end
        for treeIndex,tree in ipairs(build.treeLayout or (FC.TalentTrees or {})[class] or {}) do
            local panel=panels[treeIndex];panel.title:SetText(tree.name);panel.wash:SetVertexColor(accent[1],accent[2],accent[3],.12)
            panel.emblem:SetTexture("Interface\\Icons\\"..ICONS[class])
            if FC.ClassicTheme then FC.ClassicTheme:Talent(panel,class,treeIndex) end
            local total=0
            for index,talent in ipairs(tree.nodes) do
                local node=panel.nodes[index]
                if not node then
                    node=CreateFrame("Button",nil,panel,"BackdropTemplate");node:SetSize(36,36);surface(node,.02,.02,.025)
                    node.icon=node:CreateTexture(nil,"ARTWORK");node.icon:SetPoint("TOPLEFT",3,-3);node.icon:SetPoint("BOTTOMRIGHT",-3,3);node.icon:SetTexCoord(.08,.92,.08,.92)
                    local badge=CreateFrame("Frame",nil,node,"BackdropTemplate");badge:SetSize(30,14);badge:SetPoint("BOTTOMRIGHT",4,-6);surface(badge,.018,.02,.026)
                    node.rank=text(badge,"",10,28);node.rank:SetPoint("CENTER");node.rank:SetJustifyH("CENTER");panel.nodes[index]=node
                    node.pointer=CreateFrame("Frame",nil,node,"BackdropTemplate")
                    node.pointer:SetPoint("TOPLEFT",-5,5);node.pointer:SetPoint("BOTTOMRIGHT",5,-5)
                    node.pointer:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=3})
                    node.pointer:SetBackdropBorderColor(1,.8,.15,1);node.pointer:EnableMouse(false)
                    node.pointer:SetScript("OnUpdate",function(self,elapsed)
                        self.elapsed=(self.elapsed or 0)+elapsed
                        self:SetAlpha(.55+.45*(.5+.5*math.sin(self.elapsed*5)))
                    end)
                    node.pointer:Hide()
                end
                local rank=ranks[treeIndex..":"..index] or 0;total=total+rank
                node:ClearAllPoints();node:SetPoint("TOPLEFT",17+talent.col*47,-54-talent.row*42)
                node.icon:SetTexture(icon(talent.spellId) or "Interface\\Icons\\INV_Misc_QuestionMark")
                local highlighted=focusPoint and activeStep and activeStep.treeIndex==treeIndex and activeStep.talentIndex==index
                local dimmed=focusPoint and not highlighted
                node.icon:SetDesaturated(dimmed or (not highlighted and rank==0))
                node.icon:SetAlpha(highlighted and 1 or (dimmed and .15 or (rank>0 and 1 or .28)))
                node:SetBackdropBorderColor(unpack(highlighted and GOLD or (dimmed and {.12,.13,.15} or (rank>0 and GOLD or {.20,.22,.25}))))
                node.rank:SetText(highlighted and (activeStep.rank.."/"..talent.maxRank) or (rank.."/"..talent.maxRank))
                node.rank:SetTextColor(unpack(highlighted and GOLD or (dimmed and {.28,.29,.31} or (rank>0 and GOLD or MUTED))))
                if highlighted then node.pointer:Show() else node.pointer:Hide() end
                node:SetScript("OnEnter",function(self)
                    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                    if GameTooltip.SetSpellByID and icon(talent.spellId) then GameTooltip:SetSpellByID(talent.spellId) else GameTooltip:SetText(talent.name) end
                    GameTooltip:AddLine("Build allocation: "..rank.."/"..talent.maxRank,1,.76,.32);GameTooltip:Show()
                end)
                node:SetScript("OnLeave",function() GameTooltip:Hide() end);node:Show()
            end
            panel.total:SetText(total)
        end
        footnote:SetText("SOURCE: "..choice.proof.." / Scroll down for talent progression")
    end
    local events=CreateFrame("Frame",nil,parent)
    for _,event in ipairs({"PLAYER_LEVEL_UP","PLAYER_TALENT_UPDATE","CHARACTER_POINTS_CHANGED","PLAYER_ENTERING_WORLD","TRAIT_CONFIG_UPDATED","SPECIALIZATION_DATA_INITIALIZED","ACTIVE_TALENT_GROUP_CHANGED","TRAIT_TREE_CURRENCY_INFO_UPDATED","TRAIT_NODE_CHANGED"}) do
        pcall(events.RegisterEvent,events,event)
    end
    events:SetScript("OnEvent",function(_,event,newLevel)
        local currentLevel=event=="PLAYER_LEVEL_UP" and tonumber(newLevel) or UnitLevel("player")
        level=currentLevel or level
        levels={60};if level~=60 then levels[#levels+1]=level end
        previewIndex=math.min(previewIndex,#levels);preview=levels[previewIndex]
        if parent:IsShown() then
            local savedScroll=detailScroll:GetVerticalScroll()
            refresh()
            if event~="PLAYER_LEVEL_UP" then detailScroll:SetVerticalScroll(math.min(savedScroll,detailScroll:GetVerticalScrollRange())) end
        end
    end)
    parent:HookScript("OnShow",function() level=UnitLevel("player") or level;refresh() end)
    refresh()
end
