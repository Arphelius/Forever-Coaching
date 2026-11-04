local CreateFrame = ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
ForeverCoaching = ForeverCoaching or {}
local FC=ForeverCoaching
local GOLD={1,.76,.32}
local MUTED={.56,.62,.70}
local ICONS={DRUID="Ability_Druid_Maul",HUNTER="INV_Weapon_Bow_07",MAGE="INV_Staff_13",PALADIN="INV_Hammer_01",PRIEST="INV_Staff_30",ROGUE="INV_ThrowingKnife_04",SHAMAN="Spell_Nature_BloodLust",WARLOCK="Spell_Nature_Drowsy",WARRIOR="INV_Sword_27"}
local CLASS_COORDS={WARRIOR={0,.25,0,.25},MAGE={.25,.5,0,.25},ROGUE={.5,.75,0,.25},DRUID={.75,1,0,.25},HUNTER={0,.25,.25,.5},SHAMAN={.25,.5,.25,.5},PRIEST={.5,.75,.25,.5},WARLOCK={.75,1,.25,.5},PALADIN={0,.25,.5,.75}}
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
    if not id then return end
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
                if node.spellId then bySpell[node.spellId]=target end;byName[node.name]=target
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
function FC:BuildPresetTalentPage(parent)
    local planner=FC.BuildPlanner
    local _,class=UnitClass("player")
    local playerClass=class
    if FC.GuideBrowser and FC.GuideBrowser.class then class=FC.GuideBrowser.class end
    local level=UnitLevel("player") or 1
    local preview,selected,activity=60,nil,level<60 and 2 or 3
    if FC.GuideBrowser and FC.GuideBrowser.activity then for i,entry in ipairs(planner.activities) do if entry.id==FC.GuideBrowser.activity then activity=i;break end end end
    local selectedSpec
    local selectedBuilds={}
    local choices={}
    local levels={60};if level~=60 then levels[#levels+1]=level end
    local previewIndex=1
    local previousClass
    local refresh
    local accent=GOLD
    local cards,classButtons,panels,activityButtons={},{},{},{}
    local Theme=FC.ClassicTheme
    -- Layout (fits the 804px content panel): row 1 class icons, activity and VFX; then a
    -- 168px spec column on the left and the build on the right (title, meta, status, trees).
    local PAD,LEFT_W,GAP=14,168,18
    local RIGHT_X=PAD+LEFT_W+GAP
    local RIGHT_W=804-RIGHT_X-PAD
    local TREE_W,TREE_STEP,NODE_X,NODE_Y=186,191,43,46
    local TREE_H,ROUTE_TOP,SQUARE,PITCH=392,-440,28,32 -- trees get the room; progression squares stay small
    local DETAIL_W=RIGHT_W-22 -- the scroll bar sits inside the column
    local function button(owner,title,x,y,width,click)
        local b=CreateFrame("Button",nil,owner,"BackdropTemplate")
        b:SetSize(width,20);b:SetPoint("TOPLEFT",owner,"TOPLEFT",x,y)
        if Theme then Theme:Button(b) else surface(b,.07,.08,.10) end
        b.caption=text(b,title,11,width-12);b.caption:SetPoint("CENTER");b.caption:SetJustifyH("CENTER");b.caption:SetWordWrap(false)
        b:SetScript("OnClick",click)
        return b
    end
    local function fit(b,minimum)
        local width=b.caption:GetStringWidth()
        if type(width)~="number" or width<=0 then width=#(b.caption:GetText() or "")*7 end
        b:SetWidth(math.max(minimum or 48,math.ceil(width)+18));b.caption:SetWidth(b:GetWidth()-8)
    end
    local vfxButton
    local function syncVFX() vfxButton.caption:SetText(FC:IsTalentVFXEnabled() and "VFX: On" or "VFX: Off");fit(vfxButton,64) end
    vfxButton=button(parent,"",0,0,64,function()
        FC:SetTalentVFXEnabled(not FC:IsTalentVFXEnabled());syncVFX()
    end)
    vfxButton:ClearAllPoints();vfxButton:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-PAD,-8)
    vfxButton:SetScript("OnShow",syncVFX);syncVFX()
    -- The spec rows carry "Recommended"; this line stays hidden (kept for refresh).
    local recommendation=text(parent,"",11,10,MUTED);recommendation:Hide()
    for index,token in ipairs(planner.classes) do
        local classToken=token
        local b=CreateFrame('Button',nil,parent,'BackdropTemplate')
        b:SetSize(34,34);b:SetPoint('TOPLEFT',parent,'TOPLEFT',PAD+(index-1)*36,-1)
        b:SetScript('OnClick',function()
            class=classToken;selectedSpec=nil
            if FC.GuideBrowser then FC.GuideBrowser.class=classToken;FC.GuideBrowser.buildID=nil end
            refresh()
        end)
        local image=b:CreateTexture(nil,"OVERLAY",nil,1);image:SetTexture('Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES');image:SetVertexColor(1,1,1,1)
        image:SetPoint("CENTER");image:SetSize(26,26);image:SetTexCoord(unpack(CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token] or CLASS_COORDS[token]))
        b.classIcon=image
        b:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(classToken:sub(1,1)..classToken:sub(2):lower());GameTooltip:Show() end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
        classButtons[token]=b
    end
    -- Activity: joined choices, right of the class icons and left of VFX.
    local activityLabels={};for index,entry in ipairs(planner.activities) do activityLabels[index]=entry.title end
    local function chooseActivity(activityIndex)
        activity=activityIndex
        if FC.GuideBrowser then FC.GuideBrowser.activity=planner.activities[activityIndex].id end
        refresh()
    end
    local activityGroup
    if Theme then
        activityGroup=Theme:Segmented(parent,activityLabels,chooseActivity)
        activityGroup:SetPoint("TOPRIGHT",vfxButton,"TOPLEFT",-10,0)
        activityButtons=activityGroup.buttons
    else
        for index,label in ipairs(activityLabels) do
            local activityIndex=index
            activityButtons[index]=button(parent,label,360+(index-1)*82,-8,80,function() chooseActivity(activityIndex) end)
        end
    end
    local library=text(parent,"SPECIALIZATIONS",10,LEFT_W,MUTED);library:SetPoint("TOPLEFT",PAD,-44)
    local scroll=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",PAD,-60);scroll:SetPoint("BOTTOMLEFT",PAD,34);scroll:SetWidth(LEFT_W-20)
    local list=CreateFrame("Frame",nil,scroll);list:SetSize(LEFT_W-22,400);scroll:SetScrollChild(list)
    local hero=text(parent,"",14,RIGHT_W-120);hero:SetPoint("TOPLEFT",RIGHT_X,-42);hero:SetMaxLines(1);hero:SetWordWrap(false)
    local selectedBadge=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    selectedBadge:SetSize(100,18);selectedBadge:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-PAD,-41)
    surface(selectedBadge,.10,.085,.045,GOLD)
    selectedBadge.text=text(selectedBadge,"",10,94,GOLD)
    selectedBadge.text:SetPoint("CENTER");selectedBadge.text:SetJustifyH("CENTER")
    local meta=text(parent,"",10,RIGHT_W,MUTED);meta:SetPoint("TOPLEFT",RIGHT_X,-62);meta:SetMaxLines(1);meta:SetWordWrap(false)
    local status=text(parent,"",10,RIGHT_W,MUTED);status:SetPoint("TOPLEFT",RIGHT_X,-76);status:SetHeight(14);status:SetMaxLines(1);status:SetWordWrap(false)
    local detailScroll=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
    detailScroll:SetPoint("TOPLEFT",RIGHT_X,-94);detailScroll:SetPoint("BOTTOMLEFT",RIGHT_X,34);detailScroll:SetWidth(DETAIL_W)
    local detail=CreateFrame("Frame",nil,detailScroll);detail:SetSize(DETAIL_W,480);detailScroll:SetScrollChild(detail)
    local liveLevel=text(detail,"",11,DETAIL_W,GOLD);liveLevel:SetPoint("TOPLEFT",0,-2);liveLevel:SetMaxLines(1)
    local liveHint=text(detail,"",11,DETAIL_W);liveHint:SetPoint("TOPLEFT",0,-18);liveHint:SetMaxLines(1)
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
        p:SetPoint("TOPLEFT",(treeIndex-1)*TREE_STEP,-38);p:SetHeight(TREE_H)
        p:SetWidth(TREE_W);surface(p,.035,.043,.055)
        p.emblem=p:CreateTexture(nil,"BACKGROUND")
        p.emblem:SetPoint("CENTER",0,-12);p.emblem:SetSize(160,160)
        p.emblem:SetAlpha(.045)
        p.wash=p:CreateTexture(nil,"BACKGROUND");p.wash:SetTexture("Interface\\Buttons\\WHITE8X8")
        p.wash:SetPoint("TOPLEFT",1,-1);p.wash:SetPoint("TOPRIGHT",-1,-1);p.wash:SetHeight(34)
        p.title=text(p,"",12,TREE_W-56);p.title:SetPoint("TOPLEFT",10,-10);p.title:SetWordWrap(false)
        p.total=text(p,"",12,38,GOLD);p.total:SetPoint("TOPRIGHT",-8,-10);p.total:SetJustifyH("RIGHT")
        p.nodes={};panels[treeIndex]=p
    end
    local footnote=text(parent,"",10,RIGHT_W-230,MUTED);footnote:SetPoint("BOTTOMLEFT",RIGHT_X,13);footnote:SetMaxLines(1);footnote:SetWordWrap(false)
    local popup=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    popup:SetSize(RIGHT_W,86);popup:SetPoint("BOTTOMRIGHT",-PAD,32);popup:SetFrameLevel(parent:GetFrameLevel()+30)
    surface(popup,.045,.05,.065,{.7,.5,.2});popup:Hide()
    popup.title=text(popup,"",12,RIGHT_W-50,GOLD);popup.title:SetPoint("TOPLEFT",12,-10)
    popup.box=CreateFrame("EditBox",nil,popup,"InputBoxTemplate")
    popup.box:SetPoint("TOPLEFT",16,-32);popup.box:SetSize(RIGHT_W-32,22);popup.box:SetAutoFocus(false)
    popup.box:SetScript("OnEscapePressed",function(self) self:ClearFocus();popup:Hide() end)
    popup.box:SetScript("OnEditFocusGained",function(self) self:HighlightText() end)
    text(popup,"Ctrl+C to copy",10,280,MUTED):SetPoint("BOTTOMLEFT",12,8)
    button(popup,"x",RIGHT_W-28,-6,22,function() popup.box:ClearFocus();popup:Hide() end)
    local function copy(title,value) popup.title:SetText(title);popup.box:SetText(value or "");popup:Show();popup.box:SetFocus();popup.box:HighlightText() end
    local function current() return choices[selectedSpec] and choices[selectedSpec].build end
    local footerRight
    local function footer(title,click)
        local b=button(parent,title,0,0,80,click);fit(b,80);b:ClearAllPoints()
        if footerRight then b:SetPoint("BOTTOMRIGHT",footerRight,"BOTTOMLEFT",-6,0) else b:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-PAD,8) end
        footerRight=b
    end
    local routeWindow=CreateFrame("Frame",nil,detail,"BackdropTemplate")
    routeWindow:SetSize(DETAIL_W,60);routeWindow:SetPoint("TOPLEFT",0,ROUTE_TOP)
    surface(routeWindow,.035,.043,.055,GOLD)
    local routeTitle=text(routeWindow,"",11,(DETAIL_W-28)*.45,GOLD);routeTitle:SetPoint("TOPLEFT",14,-9);routeTitle:SetMaxLines(1);routeTitle:SetWordWrap(false)
    local routeNote=text(routeWindow,"Hover a square for the talent and rank.",10,(DETAIL_W-28)*.55,MUTED)
    routeNote:SetPoint("TOPRIGHT",-14,-10);routeNote:SetHeight(14);routeNote:SetMaxLines(1);routeNote:SetWordWrap(false);routeNote:SetJustifyH("RIGHT")
    local routeList=CreateFrame("Frame",nil,routeWindow);routeList:SetPoint("TOPLEFT",14,-30);routeList:SetSize(DETAIL_W-28,1)
    local routeRows={}
    local function showRoute()
        local build=current();if not build then return end
        for _,row in ipairs(routeRows) do row:Hide() end
        local order=planner:GetTalentProgression(class,build)
        local shift=class==playerClass and talentLevelShift or 0
        local endLevel=(order and #order+9 or build.maxLevel)-shift
        routeTitle:SetText("LEVEL "..(10-shift).."-"..endLevel.."  PROGRESSION")
        if not order then
            routeNote:SetText("Point order unavailable for this build.")
            routeList:SetHeight(1);routeWindow:SetHeight(40);detail:SetHeight(-ROUTE_TOP+44)
        else
            routeNote:SetText("Hover for the talent; gold is your next point.")
            for index,step in ipairs(order) do
                local row=routeRows[index]
                if not row then
                    row=CreateFrame('Frame',nil,routeList,'BackdropTemplate');row:SetSize(SQUARE,SQUARE);row:EnableMouse(true)
                    row.icon=row:CreateTexture(nil,'ARTWORK');row.icon:SetPoint('TOPLEFT',2,-2);row.icon:SetPoint('BOTTOMRIGHT',-2,2);row.icon:SetTexCoord(.08,.92,.08,.92)
                    local badge=CreateFrame('Frame',nil,row,'BackdropTemplate');badge:SetSize(16,11);badge:SetPoint('BOTTOMRIGHT',-1,1);surface(badge,.015,.015,.02)
                    row.levelLabel=text(badge,'',8,16);row.levelLabel:SetPoint('CENTER');row.levelLabel:SetJustifyH('CENTER');row.levelLabel:SetWordWrap(false);row.levelLabel:SetMaxLines(1)
                    routeRows[index]=row
                end
                local perRow=math.max(1,math.floor((DETAIL_W-28+PITCH-SQUARE)/PITCH))
                row:ClearAllPoints();row:SetPoint('TOPLEFT',(index-1)%perRow*PITCH,-math.floor((index-1)/perRow)*PITCH)
                row.icon:SetTexture(step.icon or icon(step.spellId) or 'Interface\\Icons\\INV_Misc_QuestionMark')
                row.levelLabel:SetText(tostring(step.level-shift))
                local nextPoint=activeStep and activeStep.treeIndex==step.treeIndex
                    and activeStep.talentIndex==step.talentIndex and activeStep.rank==step.rank
                surface(row,.07,.08,.10,nextPoint and GOLD or {.18,.20,.24})
                row.levelLabel:SetTextColor(unpack(nextPoint and GOLD or {.9,.91,.94}))
                local spell,name,rank,maxRank,pointLevel,why=step.spellId,step.name,step.rank,step.maxRank,step.level-shift,step.why
                row:SetScript("OnEnter",function(self)
                    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                    if spell and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(spell) else GameTooltip:SetText(name) end
                    local reviewed=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[class].talents[name]
                    if reviewed and reviewed.effects[tostring(rank)] then GameTooltip:AddLine(reviewed.effects[tostring(rank)],.85,.88,.92,true) end
                    GameTooltip:AddLine('Level '..pointLevel..' / '..name..' '..rank..'/'..maxRank,1,.76,.32,true)
                    if why then GameTooltip:AddLine(why,.85,.88,.92,true) end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave",function() GameTooltip:Hide() end);row:Show()
            end
            local gridHeight=math.max(1,math.ceil(#order/math.max(1,math.floor((DETAIL_W-28+PITCH-SQUARE)/PITCH)))*PITCH-(PITCH-SQUARE))
            routeList:SetHeight(gridHeight);routeWindow:SetHeight(40+gridHeight);detail:SetHeight(-ROUTE_TOP+44+gridHeight)
        end
        routeWindow:Show()
    end
    local levelButton=button(parent,"",0,0,LEFT_W-20,function() previewIndex=previewIndex % #levels+1;preview=levels[previewIndex];refresh() end)
    levelButton:ClearAllPoints();levelButton:SetPoint("BOTTOMLEFT",PAD,8)
    footer("Talent code",function() local b=current();if b and (b.points or 0)>0 then local original=b.source.calculatorUrl and b.source.calculatorUrl~="";copy(original and "Original calculator / "..b.title or "Talent code / "..b.title,original and b.source.calculatorUrl or b.talentString) end end)
    footer("Wowhead",function() local choice=choices[selectedSpec];if choice and choice.build then copy('Wowhead Forever guide',FC.BuildPlanner:GetBuildEvidenceUrl(choice.build,class)) end end)
    refresh=function()
        detailScroll:SetVerticalScroll(0)
        popup.box:ClearFocus();popup:Hide()
        local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        accent=color and {color.r,color.g,color.b} or GOLD
        for token,b in pairs(classButtons) do
            local on=token==class;local size=on and 30 or 26;b.classIcon:SetSize(size,size);b.classIcon:SetAlpha(on and 1 or .7)
            if on then surface(b,.10,.085,.045,GOLD) elseif b.SetBackdrop then b:SetBackdrop(nil) end
        end
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
        local chosenID=FC.GuideBrowser and FC.GuideBrowser.class==class and FC.GuideBrowser.buildID or selectedBuilds[selectionKey()]
        if chosenID then
            for index,choice in ipairs(choices) do
                if choice.build and choice.build.id==chosenID then selectedSpec=index;break end
            end
        end
        if activityGroup then activityGroup:Select(activity) else
            for index,b in ipairs(activityButtons) do surface(b,index==activity and .13 or .07,.08,.10,index==activity and GOLD or {.18,.20,.24}) end
        end
        if previousClass~=class then scroll:SetVerticalScroll(0);previousClass=class end
        levelButton.caption:SetText("Level "..preview..(preview==level and " / You" or " / Preview"))
        library:SetText("SPECIALIZATIONS / "..planner.activities[activity].title)
        local visibleCount=0
        for index,choice in ipairs(choices) do
            visibleCount=visibleCount+1
            local card=cards[index]
            if not card then
                card=button(list,"",0,0,LEFT_W-24,function() end);card:SetHeight(36);card.caption:Hide()
                card.title=text(card,"",12,LEFT_W-40);card.title:SetPoint("TOPLEFT",8,-5);card.title:SetHeight(14);card.title:SetMaxLines(1);card.title:SetWordWrap(false)
                card.detail=text(card,"",10,LEFT_W-100,MUTED);card.detail:SetPoint("TOPLEFT",8,-21);card.detail:SetWordWrap(false)
                card.badge=text(card,"",10,70,GOLD);card.badge:SetPoint("TOPRIGHT",-6,-21);card.badge:SetJustifyH("RIGHT")
                cards[index]=card
            end
            local build=choice.build
            card:ClearAllPoints();card:SetPoint("TOPLEFT",list,"TOPLEFT",0,-(visibleCount-1)*40)
            card.title:SetText(choice.displayName or choice.spec)
            card.detail:SetText(build and build.role or "Source needed")
            card.badge:SetText(isRecommended(index,choice) and "Recommended" or "")
            card.badge:SetTextColor(unpack(build and GOLD or MUTED))
            local active=index==selectedSpec
            local normal=card.GetNormalTexture and card:GetNormalTexture()
            if normal then normal:SetAlpha(active and .5 or .22) end
            card.title:SetTextColor(unpack(active and GOLD or {.9,.91,.94}))
            surface(card,active and .11 or .045,active and .105 or .05,active and .085 or .065,active and accent or {.16,.18,.22})
            local buildIndex=index
            card:SetScript("OnClick",function()
                if not build then return end
                selectedBuilds[selectionKey()]=build.id
                if FC.GuideBrowser then FC.GuideBrowser.class=class;FC.GuideBrowser.buildID=build.id end
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
        list:SetHeight(math.max(1,visibleCount*40))
        local choice=choices[selectedSpec]
        selected=choice and choice.index
        if not selected then routeWindow:Hide();detail:SetHeight(TREE_H+42) end
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
        meta:SetText("Level "..build.maxLevel.."  ·  "..build.distribution.."  ·  "..build.role)
        selectedBadge.text:SetText("Recommended")
        if isRecommended(selectedSpec,choice) then selectedBadge:Show() else selectedBadge:Hide() end
        local badgeColor=GOLD
        selectedBadge:SetBackdropBorderColor(unpack(badgeColor));selectedBadge.text:SetTextColor(unpack(badgeColor))
        status:SetText(planner.activities[activity].title..'  ·  '..(build.kind=='custom' and 'Custom build' or 'Published build')..'  ·  Source: '..build.source.name)
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
                node:ClearAllPoints();node:SetPoint("TOPLEFT",12+talent.col*NODE_X,-44-talent.row*NODE_Y)
                node.icon:SetTexture(talent.icon or icon(talent.spellId) or "Interface\\Icons\\INV_Misc_QuestionMark")
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
                    local reviewed=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[class].talents[talent.name]
                    if reviewed and reviewed.effects[tostring(math.max(1,rank))] then GameTooltip:AddLine(reviewed.effects[tostring(math.max(1,rank))],.85,.88,.92,true) end
                    GameTooltip:AddLine("Build allocation: "..rank.."/"..talent.maxRank,1,.76,.32);GameTooltip:Show()
                end)
                node:SetScript("OnLeave",function() GameTooltip:Hide() end);node:Show()
            end
            panel.total:SetText(total)
        end
        footnote:SetText("Talent progression is below the trees")
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
function FC:BuildTalentPage(parent)
    if not FC.BuildCustomTalentPage then return self:BuildPresetTalentPage(parent) end
    local preset=CreateFrame('Frame',nil,parent);preset:SetPoint('TOPLEFT',0,-32);preset:SetPoint('BOTTOMRIGHT')
    local custom=CreateFrame('Frame',nil,parent);custom:SetPoint('TOPLEFT',0,-32);custom:SetPoint('BOTTOMRIGHT');custom:Hide()
    local initialized=false
    local function showMode(index)
        if index==1 then custom:Hide();preset:Show();return end
        preset:Hide();custom:Show()
        if not initialized then self:BuildCustomTalentPage(custom);initialized=true end
    end
    -- Published / Custom as one joined choice at the top of the page.
    local mode
    if FC.ClassicTheme then
        mode=FC.ClassicTheme:Segmented(parent,{'Published builds','Custom Builds'},showMode)
        mode:SetPoint('TOPLEFT',parent,'TOPLEFT',14,-8)
    end
    self:BuildPresetTalentPage(preset)
    local active=ForeverCoachingDB and ForeverCoachingDB.activeTalentBuilds and ForeverCoachingDB.activeTalentBuilds[UnitGUID('player')]
    local start=type(active)=='string' and active:match('^custom%-') and 2 or 1
    if mode then mode:Select(start) end
    showMode(start)
end
