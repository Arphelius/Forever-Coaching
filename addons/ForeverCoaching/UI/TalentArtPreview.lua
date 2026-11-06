local CreateFrame = ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
-- Standalone art research preview. Never reads or spends live talent points.
local FC=ForeverCoaching
local designs={
    {"Shaman: Elemental","elemental","Spell_Nature_Lightning"},
    {"Shaman: Enhancement","enhancement","Spell_Nature_LightningShield"},
    {"Shaman: Restoration","water","Spell_Nature_MagicImmunity"},
    {"Paladin: Holy","holy-paladin","Spell_Holy_HolyBolt"},
    {"Paladin: Protection","protection-paladin","Spell_Holy_DevotionAura"},
    {"Paladin: Retribution","retribution","Spell_Holy_AuraOfLight"},
    {"Hunter: Beast Mastery","beast-mastery","Ability_Hunter_BeastTaming"},
    {"Hunter: Marksmanship","marksmanship","Ability_Marksmanship"},
    {"Hunter: Survival","survival","Ability_Hunter_SwiftStrike"},
    {"Druid: Balance","balance","Spell_Nature_StarFall"},
    {"Druid: Feral","feral-dps","Ability_Druid_CatForm"},
    {"Druid: Guardian","feral-tank","Ability_Racial_BearForm"},
    {"Druid: Restoration","restoration-druid","Spell_Nature_HealingTouch"},
    {"Mage: Arcane","arcane","Spell_Holy_MagicalSentry"},
    {"Mage: Fire","fire","Spell_Fire_FireBolt02"},
    {"Mage: Frost","frost","Spell_Frost_FrostBolt02"},
    {"Mage: Frostfire","frostfire","Ability_Mage_FrostFireBolt"},
    {"Priest: Discipline","discipline","Spell_Holy_PowerWordShield"},
    {"Priest: Holy","holy-priest","Spell_Holy_GuardianSpirit"},
    {"Priest: Shadow","shadow-priest","Spell_Shadow_ShadowWordPain"},
    {"Rogue: Assassination","assassination","Ability_Rogue_DeadlyBrew"},
    {"Rogue: Combat","combat","Ability_BackStab"},
    {"Rogue: Subtlety","subtlety","Ability_Stealth"},
    {"Warlock: Affliction","affliction","Spell_Shadow_DeathCoil"},
    {"Warlock: Demonology","fel","Spell_Shadow_Metamorphosis"},
    {"Warlock: Destruction","destruction","Spell_Shadow_RainOfFire"},
    {"Warrior: Fury - Slayer","fury","Ability_Warrior_InnerRage"},
    {"Warrior: Protection - Mountain Thane","protection-warrior","Ability_Warrior_DefensiveStance"},
    {"Warrior: Arms — Colossus","arms","Ability_Warrior_SavageBlow"},
}
local window,art,overlay,icon,rank,title,status,sizeButton,vfxButton
local selected,sizeIndex=1,2
local sizes={32,48,64}
local buttons={}
local function text(parent,value,font)
    local label=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
    label:SetText(value)
    return label
end
local function choose(index)
    selected=(index-1)%#designs+1
    local design=designs[selected]
    title:SetText(design[1])
    icon:SetTexture("Interface\\Icons\\"..design[3])
    local size=sizes[sizeIndex]
    icon:GetParent():SetSize(size,size)
    overlay:SetSize(size+6,size+6)
    sizeButton:SetText("Icon size: "..size)
    local ok,err=pcall(art.SetTheme,art,design[2],{color={.7,.7,1},accent={1,.9,.6}})
    status:SetText(ok and "Research preview - no level or talent points required" or tostring(err))
    for i,button in ipairs(buttons) do
        button:GetFontString():SetTextColor(i==selected and 1 or .75,i==selected and .82 or .75,i==selected and .3 or .75)
    end
end
local function create()
    window=CreateFrame("Frame","ForeverCoachingTalentArtPreview",UIParent,"BackdropTemplate")
    window:SetSize(820,560);window:SetPoint("CENTER");window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true);window:SetMovable(true);window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart",window.StartMoving);window:SetScript("OnDragStop",window.StopMovingOrSizing)
    window:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=14,insets={left=3,right=3,top=3,bottom=3}})
    window:SetBackdropColor(.025,.035,.055,.98);window:SetBackdropBorderColor(.65,.5,.22,1)
    text(window,"FOREVER COACHING - Talent art preview","GameFontNormalLarge"):SetPoint("TOPLEFT",20,-18)
    local close=CreateFrame("Button",nil,window,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-4,-4)
    if not UISpecialFrames then UISpecialFrames={} end;table.insert(UISpecialFrames,"ForeverCoachingTalentArtPreview")
    local scroll=CreateFrame("ScrollFrame",nil,window,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",18,-56);scroll:SetSize(212,430)
    local list=CreateFrame("Frame",nil,scroll);list:SetSize(210,#designs*27);scroll:SetScrollChild(list)
    for i,design in ipairs(designs) do
        local index=i
        local button=CreateFrame("Button",nil,list,"UIPanelButtonTemplate")
        button:SetSize(208,24);button:SetPoint("TOPLEFT",0,-(i-1)*27);button:SetText(design[1])
        button:SetScript("OnClick",function() choose(index) end);buttons[i]=button
    end
    title=text(window,"","GameFontNormalLarge");title:SetPoint("TOP",window,"TOP",120,-66)
    local target=CreateFrame("Frame",nil,window,"BackdropTemplate")
    target:SetPoint("CENTER",window,"CENTER",120,0)
    target:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});target:SetBackdropBorderColor(.5,.5,.5,1)
    icon=target:CreateTexture(nil,"ARTWORK");icon:SetPoint("TOPLEFT",1,-1);icon:SetPoint("BOTTOMRIGHT",-1,1)
    overlay=CreateFrame("Frame",nil,target);overlay:SetPoint("CENTER");overlay:EnableMouse(false)
    art=FC:CreateTalentThemeArt(overlay);art.target=target
    -- Render a real rank badge above the animation for readability checks.
    local badge=CreateFrame("Frame",nil,target,"BackdropTemplate")
    badge:SetFrameLevel(overlay:GetFrameLevel()+10);badge:SetSize(30,16);badge:SetPoint("BOTTOMRIGHT",5,-7)
    badge:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});badge:SetBackdropColor(.02,.03,.04,1)
    rank=text(badge,"0/5");rank:SetPoint("CENTER");rank:SetTextColor(1,.8,.3)
    status=text(window,"");status:SetPoint("BOTTOM",window,"BOTTOM",110,54)
    local function button(caption,x,action)
        local b=CreateFrame("Button",nil,window,"UIPanelButtonTemplate");b:SetSize(142,25)
        b:SetPoint("BOTTOM",window,"BOTTOM",x,20);b:SetText(caption);b:SetScript("OnClick",action);return b
    end
    button("Previous",-38,function() choose(selected-1) end)
    sizeButton=button("",112,function() sizeIndex=sizeIndex%#sizes+1;choose(selected) end)
    button("Next",262,function() choose(selected+1) end)
    vfxButton=button("",300,function()
        FC:SetTalentVFXEnabled(not FC:IsTalentVFXEnabled())
        art.started=nil;art.lastFrame=nil
    end)
    vfxButton:ClearAllPoints();vfxButton:SetPoint("TOPRIGHT",window,"TOPRIGHT",-24,-100)
    local elapsed=0
    window:SetScript("OnUpdate",function(_,delta)
        local enabled=FC:IsTalentVFXEnabled()
        vfxButton:SetText(enabled and "VFX: On" or "VFX: Off")
        if not enabled then
            if art.ShowSimpleBorder and art:ShowSimpleBorder(overlay:GetWidth(),overlay:GetHeight()) then overlay:Show() else overlay:Hide() end
            return
        end
        overlay:Show()
        elapsed=elapsed+delta;if elapsed<1/30 then return end;elapsed=0
        local ok,err=pcall(art.Animate,art,GetTime(),overlay:GetWidth(),overlay:GetHeight())
        if not ok then status:SetText("Preview error: "..tostring(err));window:SetScript("OnUpdate",nil) end
    end)
    choose(selected)
end
function FC:OpenTalentArtPreview(query)
    if not window then create() end
    if query and query~="" then
        query=query:lower()
        for i,design in ipairs(designs) do
            if design[2]==query or design[1]:lower():find(query,1,true) then choose(i);break end
        end
    end
    window:Show()
end
SLASH_FOREVERCOACHINGARTPREVIEW1="/fcpreview"
SlashCmdList.FOREVERCOACHINGARTPREVIEW=function(query)
    if query and query:lower()=="off" then if window then window:Hide() end;return end
    FC:OpenTalentArtPreview(query)
end
