local CreateFrame = ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
-- Small native UI motifs; all geometry and animation belongs to this addon.
local FC=ForeverCoaching
function FC:IsTalentVFXEnabled()
    return not ForeverCoachingDB or ForeverCoachingDB.talentVFXEnabled~=false
end
function FC:SetTalentVFXEnabled(enabled)
    ForeverCoachingDB=ForeverCoachingDB or {}
    ForeverCoachingDB.talentVFXEnabled=not not enabled
    if self.RefreshTalentVFX then self.RefreshTalentVFX() end
end
function FC:CreateTalentThemeArt(owner)
    local art={pool={},count=0}
    local authored=owner:CreateTexture(nil,"OVERLAY",nil,7)
    authored:SetTexture("Interface\\AddOns\\ForeverCoaching\\Media\\TalentEffects\\Enhancement.tga")
    authored:SetBlendMode("BLEND")
    authored:Hide()
    art.authoredTexture=authored
    local combatSmoke=owner:CreateTexture(nil,"OVERLAY",nil,6)
    combatSmoke:SetTexture("Interface\\AddOns\\ForeverCoaching\\Media\\TalentEffects\\CombatSmoke.tga")
    combatSmoke:SetBlendMode("BLEND");combatSmoke:Hide()
    art.combatSmoke=combatSmoke
    local combatBlood=owner:CreateTexture(nil,"OVERLAY",nil,7)
    combatBlood:SetTexture("Interface\\AddOns\\ForeverCoaching\\Media\\TalentEffects\\CombatBlood.tga")
    combatBlood:SetBlendMode("BLEND");combatBlood:Hide()
    art.combatBlood=combatBlood
    local behind=CreateFrame("Frame",nil,owner)
    behind:EnableMouse(false);behind:SetAllPoints(owner)
    local totem=behind:CreateTexture(nil,"ARTWORK")
    local rear=owner:CreateTexture(nil,"OVERLAY",nil,5)
    rear:SetTexture("Interface\\AddOns\\ForeverCoaching\\Media\\TalentEffects\\EnhancementRear.tga")
    rear:SetBlendMode("BLEND")
    totem:SetBlendMode("BLEND");totem:Hide();behind:Hide()
    art.totemBackdrop=behind
    local totemPieces={}
    for i=1,4 do
        local texture=behind:CreateTexture(nil,'ARTWORK')
        texture:SetTexture('Interface\\AddOns\\ForeverCoaching\\Media\\TalentEffects\\Enhancement.tga')
        texture:SetBlendMode('BLEND');texture:Hide();totemPieces[i]=texture
    end
    art.totemPieces=totemPieces;art.enhancementRear=rear
    local simpleBorder=owner:CreateTexture(nil,"OVERLAY",nil,7)
    simpleBorder:SetTexture("Interface\\AddOns\\ForeverCoaching\\Media\\TalentEffects\\ArmsBorder.tga")
    simpleBorder:SetTexCoord(.5/1024,127.5/1024,.5/1024,127.5/1024)
    simpleBorder:SetBlendMode("BLEND");simpleBorder:Hide()
    function art:ShowSimpleBorder(width,height,keepAnimation)
        if not keepAnimation then
            self.started=nil;self.lastFrame=nil
            authored:Hide();combatSmoke:Hide();combatBlood:Hide();behind:Hide();rear:Hide()
            for _,texture in ipairs(totemPieces) do texture:Hide() end
            for _,p in ipairs(self.pool) do p.texture:Hide() end
        end
        local style=FC.TalentSimpleBorders and FC.TalentSimpleBorders[self.kind]
        if not style then simpleBorder:Hide();return false end
        if self.simpleBorderKind~=self.kind then
            simpleBorder:SetTexture("Interface\\AddOns\\ForeverCoaching\\Media\\TalentEffects\\"..style.file..".tga")
            local col,row=style.frame%8,math.floor(style.frame/8)
            simpleBorder:SetTexCoord((col*128+.5)/1024,((col+1)*128-.5)/1024,(row*128+.5)/1024,((row+1)*128-.5)/1024)
            self.simpleBorderKind=self.kind
        end
        local scale=(width-6)/width*1024/406
        if self.kind=='affliction' or self.kind=='fel' or self.kind=='destruction' then scale=scale*1.10 end
        if self.kind=='water' then scale=scale*1.08 end
        simpleBorder:SetSize(width*scale,height*scale)
        simpleBorder:ClearAllPoints();simpleBorder:SetPoint("CENTER",owner,"CENTER",0,0)
        simpleBorder:Show();return true
    end
    local WHITE={1,1,1};local GOLD={1,.85,.4};local RED={.9,.08,.04}
    local function piece(x,y,w,h,color,texture,alpha,movement,rotation)
        art.count=art.count+1
        local p=art.pool[art.count]
        if not p then
            p={texture=owner:CreateTexture(nil,"OVERLAY")};art.pool[art.count]=p
        end
        p.x=x;p.y=y;p.w=w;p.h=h;p.alpha=alpha or .65;p.movement=movement;p.rotation=rotation or 0
        p.texture:SetTexture(texture or "Interface\\Buttons\\WHITE8X8")
        p.texture:SetTexCoord(0,1,0,1);p.texture:SetBlendMode("ADD")
        p.texture:SetVertexColor(color[1],color[2],color[3]);p.texture:Show()
        return p
    end
    local function icon(name,x,y,size,color,alpha,movement)
        local p=piece(x,y,size,size,color,"Interface\\Icons\\"..name,alpha,movement)
        p.texture:SetTexCoord(.08,.92,.08,.92)
    end
    local function sword(x,color,tip,dagger)
        piece(x,.04,.065,dagger and .32 or .53,color,nil,.85,"weapon")
        piece(x,dagger and .22 or .33,.07,.07,color,nil,.85,"weapon",math.pi/4)
        piece(x,dagger and -.12 or -.22,.25,.045,GOLD,nil,.75,"weapon")
        piece(x,dagger and -.23 or -.33,.055,.18,{.58,.34,.16},nil,.85,"weapon")
        if tip then piece(x,dagger and .17 or .25,.075,.10,tip,nil,.85,"weapon") end
    end
    local function shield(x,color)
        piece(x,0,.32,.40,color,nil,.48,"steady")
        piece(x,-.17,.23,.23,color,nil,.48,"steady",math.pi/4)
        piece(x,.03,.045,.32,WHITE,nil,.7,"steady")
        piece(x,.05,.25,.035,WHITE,nil,.7,"steady")
    end
    local function rays(color,wings)
        for index=-1,1 do
            piece(index*.16,.68,.025,.40,color,nil,.55,"ray",index*-.2)
        end
        if wings then
            for side=-1,1,2 do
                for feather=1,4 do
                    piece(side*(.5+feather*.075),.28-feather*.08,.055,.32,color,nil,.52,"wing",side*(.35+feather*.16))
                end
            end
        end
    end
    function art:SetTheme(kind,theme)
        simpleBorder:Hide()
        self.authored=kind=="enhancement" or kind=="elemental" or kind=="water" or kind=="holy-paladin" or kind=="retribution" or kind=="protection-paladin" or kind=="beast-mastery" or kind=="marksmanship" or kind=="survival" or kind=="balance" or kind=="feral-dps" or kind=="feral-tank" or kind=="restoration-druid" or kind=="arcane" or kind=="fire" or kind=="frost" or kind=="frostfire" or kind=="discipline" or kind=="holy-priest" or kind=="shadow-priest" or kind=="assassination" or kind=="combat" or kind=="subtlety" or kind=="affliction" or kind=="fel" or kind=="destruction" or kind=="arms" or kind=="fury" or kind=="protection-warrior"
        self.lastFrame=nil
        self.playingFile=nil
        self.started=nil
        self.kind=kind
        authored:Hide()
        combatSmoke:Hide()
        combatBlood:Hide()
        authored:SetRotation(0)
        totem:Hide();behind:Hide();rear:Hide()
        for _,texture in ipairs(totemPieces) do texture:Hide() end
        for _,p in ipairs(self.pool) do p.texture:Hide() end
        self.count=0
        if self.authored then
            if kind=="enhancement" then
                self.authoredTexture:SetTexture("Interface\\AddOns\\ForeverCoaching\\Media\\TalentEffects\\EnhancementElements.tga")
                self.authoredTexture:Show()
            end
            local authored=kind=="enhancement" and totem or authored
            local filename=kind=="protection-warrior" and "ProtectionWarrior" or kind=="fury" and "Fury" or kind=="arms" and "Arms" or kind=="destruction" and "Destruction" or kind=="fel" and "Demonology" or kind=="affliction" and "Affliction" or kind=="subtlety" and "Subtlety" or kind=="combat" and "Combat" or kind=="assassination" and "Assassination" or kind=="shadow-priest" and "ShadowPriest" or kind=="holy-priest" and "HolyPriest" or kind=="discipline" and "Discipline" or kind=="frostfire" and "Frostfire" or kind=="frost" and "Frost" or kind=="fire" and "Fire" or kind=="arcane" and "Arcane" or kind=="restoration-druid" and "RestorationDruid" or kind=="feral-tank" and "Bear" or kind=="feral-dps" and "Feral" or kind=="balance" and "Balance" or kind=="survival" and "Survival" or kind=="marksmanship" and "Marksmanship" or kind=="beast-mastery" and "BeastMastery" or kind=="protection-paladin" and "ProtectionPaladin" or kind=="retribution" and "Retribution" or kind=="holy-paladin" and "HolyPaladin" or kind=="water" and "Restoration" or kind=="elemental" and "Elemental" or "Enhancement"
            authored:SetTexture("Interface\\AddOns\\ForeverCoaching\\Media\\TalentEffects\\"..filename..".tga")
            if kind=="combat" then combatSmoke:Show() end
            authored:Show();return
        end
        local color,accent=theme.color,theme.accent
        if kind=="elemental" or kind=="enhancement" then
            for side=-1,1,2 do
                -- A short zigzag on each side, alternating magma/earth and lightning.
                for segment=1,3 do
                    piece(side*(.60+(segment%2)*.055),.28-segment*.14,.04,.19,accent,nil,.8,"flash",side*(segment%2==0 and -.6 or .6))
                end
                piece(side*.52,-.52,.18,.13,color,nil,.65,"rock",.3*side)
            end
        elseif kind=="water" then
            for index=1,4 do piece((index-2.5)*.23,-.55,.19,.045,accent,nil,.65,"water") end
        elseif kind=="frost" or kind=="frostfire" then
            for index=1,5 do
                local x=(index-3)*.22
                piece(x,-.53,.12,.23+(index%2)*.12,accent,nil,.65,"ice")
                piece(x,-.36-(index%2)*.06,.09,.09,color,nil,.7,"ice",math.pi/4)
            end
        elseif kind=="fire" or kind=="destruction" or kind=="fel" then
            icon(kind=="fire" and "Spell_Fire_FlameBolt" or "Spell_Fire_FelFlameRing",-.64,0,.3,color,.55,"flame")
            icon(kind=="fire" and "Spell_Arcane_Arcane01" or "Spell_Shadow_ShadowBolt",.64,0,.3,accent,.55,"wisp")
        elseif kind=="arcane" then
            for side=-1,1,2 do piece(side*.63,0,.07,.6,accent,nil,.7,"surge") end
        elseif kind=="affliction" then
            for index=1,3 do
                icon("Spell_Shadow_CurseOfSargeras",(index-2)*.27,-.62,.19,color,.55,"dot")
            end
        elseif kind=="holy-paladin" then rays(GOLD,false)
        elseif kind=="retribution" then
            -- Blizzard's golden hand icon supplies the Silver Hand motif.
            icon("Spell_Holy_SealOfValor",0,.67,.4,GOLD,.75,"justice")
            rays(accent,false)
        elseif kind=="protection-paladin" then
            shield(-.65,color);rays(GOLD,false)
        elseif kind=="arms" then sword(-.65,WHITE,RED)
        elseif kind=="fury" then sword(-.65,WHITE,RED);sword(.65,WHITE,RED)
        elseif kind=="protection-warrior" then
            shield(-.66,color);sword(.66,WHITE)
            piece(0,.62,.7,.035,WHITE,nil,.35,"shout")
        elseif kind=="balance" then
            icon("Spell_Nature_StarFall",-.65,0,.32,color,.65,"lunar")
            icon("Spell_Holy_SearingLight",.65,0,.32,accent,.65,"solar")
        elseif kind=="feral-tank" then
            for side=-1,1,2 do
                for claw=1,3 do piece(side*(.5+claw*.09),0,.045,.55,accent,nil,.8,"claw",side*.3) end
            end
        elseif kind=="feral-dps" then
            icon("Ability_Ambush",0,.65,.29,color,.4,"stealth")
            for claw=1,3 do piece((claw-2)*.12,-.6,.035,.2,RED,nil,.7,"bleed",-.3) end
        elseif kind=="restoration-druid" then
            -- The leaves are small paired diamonds, drifting down either edge.
            for index=1,6 do piece(index%2==0 and -.61 or .61,.4-index*.12,.075,.13,index%2==0 and color or accent,nil,.7,"leaf",index*.7) end
        elseif kind=="assassination" then sword(-.65,WHITE,accent,true)
        elseif kind=="combat" then sword(-.65,WHITE,RED,true);sword(.65,WHITE,RED,true)
        elseif kind=="subtlety" then
            icon("Ability_Stealth",0,.65,.34,color,.35,"stealth")
            piece(-.07,.65,.055,.025,RED,nil,.95,"eyes");piece(.07,.65,.055,.025,RED,nil,.95,"eyes")
        elseif kind=="discipline" then
            icon("Spell_Holy_PowerWordShield",0,0,1.1,color,.18,"ward");rays(accent,false)
        elseif kind=="holy-priest" then rays(GOLD,true)
        elseif kind=="shadow-priest" then rays(accent,false)
        elseif kind=="beast-mastery" then
            for index=1,3 do icon("Ability_Hunter_Pet_Wolf",(index-2)*.3,-.65,.26,color,.65,"hunt") end
        elseif kind=="marksmanship" then
            for ring=1,2 do
                for index=1,20 do
                    local angle=index*math.pi/10;local radius=ring==1 and .62 or .76
                    piece(math.cos(angle)*radius,math.sin(angle)*radius,.035,.12,accent,nil,.55,"steady",angle-math.pi/2)
                end
            end
            for side=-1,1,2 do
                piece(side*.67,0,.25,.035,color,nil,.85,"steady")
                piece(0,side*.67,.035,.25,color,nil,.85,"steady")
            end
        elseif kind=="survival" then
            icon("Spell_Frost_ChainsOfIce",-.65,0,.28,color,.7,"steady")
            icon("Spell_Fire_SelfDestruct",.65,0,.28,accent,.65,"explosive")
        end
    end
    function art:Animate(time,width,height)
        if not width or not height or width<=6 or height<=6 then return end
        simpleBorder:Hide()
        if self.kind=="feral-dps" then
            simpleBorder:SetTexture("Interface\\AddOns\\ForeverCoaching\\Media\\TalentEffects\\FeralFangs.tga")
            simpleBorder:SetTexCoord(.5/1024,127.5/1024,.5/1024,127.5/1024)
            simpleBorder:SetSize((width-6)*1024/406,(height-6)*1024/406)
            simpleBorder:ClearAllPoints();simpleBorder:SetPoint("CENTER",owner,"CENTER",0,0)
            simpleBorder:Show();self.simpleBorderKind=nil
        end
        if self.authored then authored:Show() end
        if self.authored then
            local authored=self.kind=="enhancement" and totem or authored
            if self.kind=="enhancement" then
                behind:SetFrameStrata(owner:GetFrameStrata())
                behind:SetFrameLevel(owner:GetFrameLevel()+1)
                behind:Show();totem:Show()
            end
            self.started=self.started or time
            local age=time-self.started
            local frame=math.floor(age*(self.kind=="arcane" and 18 or 12))%36
            if self.kind=="combat" then frame=math.min(35,math.floor(age*10)) end
            if self.kind=="affliction" or self.kind=="arms" then frame=math.min(107,math.floor(age*12)) end
            if self.kind=="fel" then frame=math.floor(age*12)%108 end
            -- Play the ritual and impacts once, then loop only the burning aftermath.
            if self.kind=="destruction" then local tick=math.floor(age*12);frame=tick<108 and tick or 72+(tick-108)%36 end
            if self.kind=="protection-warrior" then local tick=math.floor(age*12);frame=tick<36 and tick or 18+(tick-36)%18 end
            if frame~=self.lastFrame then
                local col,row=frame%8,math.floor(frame/8)
                local atlasWidth=1024
                if self.kind=="affliction" or self.kind=="fel" or self.kind=="destruction" or self.kind=="arms" then col,row=frame%16,math.floor(frame/16);atlasWidth=2048 end
                -- Half-pixel inset prevents adjacent atlas cells bleeding in.
                authored:SetTexCoord((col*128+.5)/atlasWidth,((col+1)*128-.5)/atlasWidth,
                    (row*128+.5)/1024,((row+1)*128-.5)/1024)
                self.lastFrame=frame
            end
            local scale=self.kind=="enhancement" and 1.7 or 2.4
            if self.kind=="frost" then scale=(width-6)/width*650/406 end
            if self.kind=="frostfire" or self.kind=="arms" or self.kind=="fury" or self.kind=="protection-warrior" then scale=(width-6)/width*1024/406 end
            if self.kind=="shadow-priest" or self.kind=="combat" or self.kind=="subtlety" then scale=(width-6)/width*1024/406 end
            authored:SetSize(width*scale,height*scale)
            if self.kind=="combat" then
                combatSmoke:Show()
                local smokeFrame=math.floor(age*12)%36
                local sx,sy=smokeFrame%8,math.floor(smokeFrame/8)
                combatSmoke:SetTexCoord((sx*128+.5)/1024,((sx+1)*128-.5)/1024,(sy*128+.5)/1024,((sy+1)*128-.5)/1024)
                combatSmoke:SetSize(width*scale,height*scale)
                combatSmoke:ClearAllPoints();combatSmoke:SetPoint("CENTER",owner,"CENTER",0,0)
                if age>=35/10 then
                    combatBlood:SetTexCoord(combatSmoke:GetTexCoord())
                    combatBlood:SetSize(width*scale,height*scale)
                    combatBlood:ClearAllPoints();combatBlood:SetPoint("CENTER",owner,"CENTER",0,0)
                    combatBlood:Show()
                else combatBlood:Hide() end
            end
            authored:SetPoint("CENTER",owner,"CENTER",0,0)
            if self.kind=="enhancement" then
                local front=self.authoredTexture
                front:SetTexCoord(authored:GetTexCoord())
                front:SetSize(width*2.4,height*2.4)
                front:SetPoint("CENTER",owner,"CENTER",0,0)
                front:SetAlpha(1);front:Show()
                rear:SetTexCoord(authored:GetTexCoord())
                rear:SetSize(width*2.4,height*2.4)
                rear:SetPoint("CENTER",owner,"CENTER",0,0)
                rear:Show()
                -- Draw only the parts of the totem outside the icon. Keeping
                -- these above the native talent panel avoids hiding the totem
                -- behind its background, without painting over the icon.
                local sw,sh=width*scale,height*scale
                local ix,iy=(width-6)/2,(height-6)/2
                local regions={{-sw/2,-ix,-sh/2,sh/2},{ix,sw/2,-sh/2,sh/2},
                    {-ix,ix,iy,sh/2},{-ix,ix,-sh/2,-iy}}
                local col,row=frame%8,math.floor(frame/8)
                for i,region in ipairs(regions) do
                    local x1,x2,y1,y2=(unpack or table.unpack)(region)
                    local texture=totemPieces[i]
                    texture:SetSize(x2-x1,y2-y1)
                    texture:ClearAllPoints();texture:SetPoint('CENTER',owner,'CENTER',(x1+x2)/2,(y1+y2)/2)
                    texture:SetTexCoord((col*128+.5+(x1/sw+.5)*127)/1024,(col*128+.5+(x2/sw+.5)*127)/1024,
                        (row*128+.5+(.5-y2/sh)*127)/1024,(row*128+.5+(.5-y1/sh)*127)/1024)
                    texture:Show()
                end
                totem:Hide()
            end
            authored:SetAlpha(1)
            return
        end
        for index=1,self.count do
            local p=self.pool[index]
            local x,y=p.x,p.y
            local phase=time*1.6+index*.63
            local alpha=p.alpha*(.75+.25*math.sin(phase))
            local rotation=p.rotation
            local m=p.movement
            if m=="leaf" then
                y=.6-((time*.22+index/6)%1)*1.2;x=x+math.sin(phase)*.06;rotation=rotation+math.sin(phase)*.4
            elseif m=="water" then y=y+math.sin(phase)*.06
            elseif m=="flash" then alpha=p.alpha*(.25+.75*math.max(0,math.sin(time*6))^6)
            elseif m=="ray" or m=="surge" then alpha=p.alpha*(.35+.65*(.5+.5*math.sin(time*2.3)))
            elseif m=="wing" then y=y+math.sin(time*1.5)*.035
            elseif m=="flame" then y=y+math.sin(phase)*.06
            elseif m=="wisp" or m=="lunar" or m=="solar" then y=y+math.sin(phase)*.04
            elseif m=="justice" or m=="ward" then alpha=p.alpha*(.4+.6*(.5+.5*math.sin(time*1.5)))
            elseif m=="bleed" then y=y-((time*.3+index*.2)%1)*.12
            elseif m=="hunt" then x=x+math.sin(time*2)*.025
            elseif m=="explosive" then alpha=p.alpha*(.3+.7*math.max(0,math.sin(time*3))^4)
            elseif m=="dot" then alpha=p.alpha*(.25+.75*(.5+.5*math.sin(time*3+index*2)))
            elseif m=="shout" then y=y+((time*.3)%1)*.08;alpha=alpha*(1-(time*.3)%1)
            end
            p.texture:SetSize(width*p.w,height*p.h)
            p.texture:SetPoint("CENTER",owner,"CENTER",width*x,height*y)
            p.texture:SetRotation(rotation);p.texture:SetAlpha(alpha)
        end
    end
    return art
end

-- An addon-owned overlay. Blizzard talent buttons and their scripts are untouched.
local FC=ForeverCoaching
local overlay=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
overlay:EnableMouse(false);overlay:SetFrameStrata("TOOLTIP")
overlay:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
overlay:SetBackdropBorderColor(1,.8,.15,1);overlay:Hide()
local glow=overlay:CreateTexture(nil,"OVERLAY")
glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border");glow:SetBlendMode("ADD")
glow:SetVertexColor(1,.75,.1);glow:SetAllPoints()
local CLASS_COLORS={
    SHAMAN={0,.32,.85},PALADIN={.96,.55,.73},MAGE={.25,.78,.92},
    WARRIOR={.78,.61,.43},DRUID={1,.49,.04},HUNTER={.67,.83,.45},
    PRIEST={1,1,1},ROGUE={1,.96,.41},WARLOCK={.53,.53,.93},
}
-- Small overlapping halos give the edge a soft, drifting appearance while
-- keeping the talent icon readable. Each class has its own motion profile.
local MOTION={
    SHAMAN={speed=2.8,x=2.6,y=1.3,breath=.12,turn=.45},
    PALADIN={speed=1.7,x=1.1,y=2.0,breath=.09,turn=.18},
    MAGE={speed=2.1,x=2.2,y=2.2,breath=.11,turn=-.35},
    WARRIOR={speed=1.5,x=1.3,y=.6,breath=.07,turn=.08},
    DRUID={speed=1.4,x=2.0,y=1.4,breath=.13,turn=.22},
    HUNTER={speed=1.9,x=2.7,y=.9,breath=.08,turn=-.16},
    PRIEST={speed=1.3,x=.7,y=2.5,breath=.10,turn=.12},
    ROGUE={speed=2.5,x=2.3,y=.7,breath=.07,turn=-.28},
    WARLOCK={speed=1.6,x=2.4,y=1.8,breath=.14,turn=-.40},
}
local motion=MOTION.SHAMAN
-- Theme follows the selected allocation, even while buying off-tree talents.
local THEMES={
    arcane={kind="arcane",mode="surge",color={.64,.32,1},accent={.35,.7,1}},
    fire={kind="fire",mode="embers",color={1,.28,.035},accent={.75,.38,1}},
    frost={kind="frost",mode="shards",color={.22,.72,1},accent={.75,.96,1}},
    frostfire={kind="frostfire",mode="shards",color={.25,.65,1},accent={1,.38,.08}},
    fel={kind="fel",mode="felshadow",color={.3,1,.12},accent={.55,.15,.8}},
    shadow={kind="affliction",mode="dots",color={.44,.15,.76},accent={.72,.3,.92}},
    destruction={kind="destruction",mode="embers",color={1,.32,.05},accent={.35,1,.12}},
    holy={kind="holy-paladin",mode="surge",color={1,.78,.34},accent={1,.96,.72}},
    holyPriest={kind="holy-priest",mode="surge",color={1,.85,.4},accent={1,1,.9}},
    shadowPriest={kind="shadow-priest",mode="wisps",color={.44,.15,.76},accent={1,.9,.65}},
    discipline={kind="discipline",mode="wisps",color={.85,.82,1},accent={1,.91,.57}},
    water={kind="water",mode="water",color={.1,.53,.95},accent={.3,.95,.82}},
    storm={mode="surge",color={.04,.32,.95},accent={.4,.78,1}},
    elemental={kind="elemental",mode="magma",color={1,.32,.05},accent={.3,.65,1}},
    enhancement={kind="enhancement",mode="earthstorm",color={.62,.43,.23},accent={.15,.48,1}},
    earth={kind="feral-tank",mode="shards",color={.72,.35,.12},accent={1,.63,.2}},
    nature={kind="restoration-druid",mode="leaves",color={.28,.85,.35},accent={.75,1,.4}},
    lunar={kind="balance",mode="surge",color={.45,.48,1},accent={1,.65,.12}},
    feral={kind="feral-dps",mode="bleed",color={.34,.23,.42},accent={.9,.12,.06}},
    blood={kind="fury",mode="berserk",color={.85,.17,.08},accent={1,.3,.13}},
    steel={kind="arms",mode="bleed",color={.78,.61,.43},accent={.9,.1,.05}},
    shield={kind="protection-warrior",mode="surge",color={.7,.57,.4},accent={1,1,1}},
    venom={kind="assassination",mode="poison",color={.35,.7,.1},accent={.6,1,.15}},
    combat={kind="combat",mode="bleed",color={.85,.78,.55},accent={.9,.08,.04}},
    stealth={kind="subtlety",mode="wisps",color={.25,.2,.37},accent={.85,.08,.04}},
    beast={kind="beast-mastery",mode="slashes",color={.63,.82,.31},accent={.9,1,.53}},
    marksman={kind="marksmanship",mode="surge",color={.85,.17,.1},accent={1,.55,.22}},
    survival={kind="survival",mode="explosives",color={.42,.64,.21},accent={1,.45,.12}},
    paladin={kind="protection-paladin",mode="surge",color={.96,.55,.73},accent={1,.95,.65}},
    retribution={kind="retribution",mode="surge",color={.96,.55,.73},accent={1,.85,.4}},
}
local SPEC_THEMES={
    MAGE={"arcane","fire","frost"},WARLOCK={"shadow","fel","destruction"},
    SHAMAN={"elemental","enhancement","water"},DRUID={"lunar","feral","nature"},
    PALADIN={"holy","paladin","retribution"},PRIEST={"discipline","holyPriest","shadowPriest"},
    WARRIOR={"steel","blood","shield"},ROGUE={"venom","combat","stealth"},
    HUNTER={"beast","marksman","survival"},
}
local theme
local artOK,themeArt=pcall(FC.CreateTalentThemeArt,FC,overlay)
if not artOK then themeArt=nil end
local function disableThemeArt(message)
    if themeArt then
        if themeArt.authoredTexture then themeArt.authoredTexture:Hide() end
        if themeArt.totemBackdrop then themeArt.totemBackdrop:Hide() end
        if themeArt.enhancementRear then themeArt.enhancementRear:Hide() end
        for _,piece in ipairs(themeArt.pool or {}) do piece.texture:Hide() end
    end
    themeArt=nil
    FC.talentThemeError=tostring(message)
    if ForeverCoachingDB then ForeverCoachingDB.talentThemeError=FC.talentThemeError end
end
local function buildTheme(build,class)
    if class=="MAGE" and (build.id or ""):find("frostfire",1,true) then return THEMES.frostfire end
    if class=="DRUID" and build.role=="tank" then return THEMES.earth end
    local totals={0,0,0}
    for _,talent in ipairs(build.talents or {}) do totals[talent.treeIndex]=totals[talent.treeIndex]+talent.rank end
    local primary=1
    for index=2,3 do if totals[index]>totals[primary] then primary=index end end
    local specs=SPEC_THEMES[class]
    return THEMES[specs and specs[primary]] or {mode="wisps",color=CLASS_COLORS[class] or {1,1,1},accent={1,1,1}}
end
local particles={}
for index=1,8 do
    local particle=overlay:CreateTexture(nil,"OVERLAY")
    particle:SetBlendMode("ADD");particle:SetPoint("CENTER")
    particles[index]=particle
end
local clouds={}
for index=1,3 do
    local cloud=overlay:CreateTexture(nil,"OVERLAY")
    cloud:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    cloud:SetBlendMode("ADD");cloud:SetPoint("CENTER")
    clouds[index]=cloud
end
local function call(fn,...)
    if type(fn)~="function" then return end
    local ok,value=pcall(fn,...)
    if ok and not (issecretvalue and issecretvalue(value)) then return value end
end
local function selectedBuild()
    local guid=UnitGUID("player")
    local _,class=UnitClass("player")
    local db=ForeverCoachingDB
    if not db or not guid then return end
    local id=db.activeTalentBuilds and db.activeTalentBuilds[guid]
    -- Preserve selections made before this integration was installed.
    local saved=db.selectedTalentBuilds and db.selectedTalentBuilds[guid]
    if not id and saved then
        id=saved[class..":leveling"] or saved[class..":dungeons"] or saved[class..":raids"] or saved[class..":pvp"]
    end
    for _,build in ipairs(FC.BuildPlanner:GetBuilds(class)) do
        if build.id==id then return build,class end
    end
end
local function nextPoint(build,class)
    local layout=build.treeLayout or FC.TalentTrees[class]
    local ranks,spent,points,available,checks=FC:ReadLiveTalentState(layout)
    if not ranks then return end
    if available==nil then available=FC:ReadUnspentTalentPoints() end
    if not available or available<=0 then return end
    local order=FC.BuildPlanner:GetTalentProgression(class,build)
    for _,step in ipairs(order or {}) do
        local key=step.treeIndex..":"..step.talentIndex
        if ranks[key]==nil then return end
        if ranks[key]<step.rank then
            if checks and checks[key]==false then return end
            if points[step.treeIndex]<layout[step.treeIndex].nodes[step.talentIndex].row*5 then return end
            return step
        end
    end
end
local function matches(button,step)
    if call(button.IsInspecting,button) then return false end
    -- Forever can expose the current rank's spell ID rather than the base ID
    -- stored in the route. Use the same name fallback as the live rank reader.
    local function sameTalent(spellID,overrideName)
        if spellID and step.spellId and spellID==step.spellId then return true end
        local actualName=overrideName or call(C_Spell and C_Spell.GetSpellName,spellID) or call(GetSpellInfo,spellID)
        if type(actualName)~="string" then return false end
        local expectedName=call(C_Spell and C_Spell.GetSpellName,step.spellId) or call(GetSpellInfo,step.spellId)
        return actualName==step.name or (type(expectedName)=="string" and actualName==expectedName)
    end
    local spell=call(button.GetSpellID,button)
    if spell and sameTalent(spell) then return true end
    local name=call(button.GetName,button)
    if type(name)=='string' and (name:match('^PlayerTalentFrameTalent%d+$') or name:match('^TalentFrameTalent%d+$')) and GetTalentInfo then
        local root=PlayerTalentFrame or TalentFrame
        local tab=call(PanelTemplates_GetSelectedTab,root) or (root and root.selectedTab)
        local index=call(button.GetID,button)
        if tab==step.treeIndex and type(index)=='number' then
            local ok,_,_,row,col=pcall(GetTalentInfo,tab,index)
            local _,class=UnitClass('player');local talent=FC.TalentTrees[class][step.treeIndex].nodes[step.talentIndex]
            if ok and talent and row==talent.row+1 and col==talent.col+1 then return true end
        end
    end
    local node=call(button.GetNodeInfo,button)
    local config=call(button.GetConfigID,button)
        or call(C_ClassTalents and C_ClassTalents.GetActiveConfigID)
    if type(node)=="table" and config and C_Traits then
        for _,entryID in ipairs(node.entryIDs or {}) do
            local entry=call(C_Traits.GetEntryInfo,config,entryID)
            local definition=entry and entry.definitionID and call(C_Traits.GetDefinitionInfo,entry.definitionID)
            if definition and sameTalent(definition.spellID,definition.overrideName) then return true end
        end
    end
    return false
end
function FC:GetSelectedTalentGuidance()
    local build,class=selectedBuild()
    if not build then return end
    return build,nextPoint(build,class),buildTheme(build,class)
end
local function findButton(root,step,depth)
    if depth>14 or not root or not root:IsShown() then return end
    if matches(root,step) then return root end
    for _,child in ipairs({root:GetChildren()}) do
        local found=findButton(child,step,depth+1)
        if found then return found end
    end
end
local target
local function refresh()
    if InCombatLockdown and InCombatLockdown() then target=nil;overlay:Hide();return end
    local roots={}
    for _,name in ipairs({"PlayerSpellsFrame","ClassTalentFrame","PlayerTalentFrame","TalentFrame"}) do
        local root=_G[name]
        if root and root:IsShown() then roots[#roots+1]=root end
    end
    if #roots==0 then target=nil;overlay:Hide();return end
    local build,class=selectedBuild()
    local step=build and nextPoint(build,class)
    if not step then target=nil;overlay:Hide();return end
    target=nil
    for _,root in ipairs(roots) do
        target=findButton(root,step,0)
        if target then break end
    end
    if not target then overlay:Hide();return end
    if themeArt and themeArt.target~=target then themeArt.target=target;themeArt.started=nil;themeArt.playingFile=nil end
    local selectedTheme=buildTheme(build,class)
    if theme~=selectedTheme then
        theme=selectedTheme
        if themeArt then
            local ok,message=pcall(themeArt.SetTheme,themeArt,theme.kind or "frostfire",theme)
            if not ok then disableThemeArt(message) end
        end
        for index,particle in ipairs(particles) do
            local soft=theme.mode=="wisps" or theme.mode=="water" or theme.mode=="dots" or (theme.mode=="felshadow" and index%2==0)
            particle:SetTexture(soft and "Interface\\Buttons\\UI-ActionButton-Border" or "Interface\\Buttons\\WHITE8X8")
            local tint=index%2==0 and theme.accent or theme.color
            particle:SetVertexColor(tint[1],tint[2],tint[3])
        end
    end
    local color=theme.color
    if not FC:IsTalentVFXEnabled() then
        glow:SetAlpha(0);overlay:SetAlpha(1);overlay:SetBackdropBorderColor(0,0,0,0)
        for _,cloud in ipairs(clouds) do cloud:SetAlpha(0) end
        for _,particle in ipairs(particles) do particle:SetAlpha(0) end
        overlay:ClearAllPoints();overlay:SetPoint("TOPLEFT",target,"TOPLEFT",-3,3);overlay:SetPoint("BOTTOMRIGHT",target,"BOTTOMRIGHT",3,-3)
        if themeArt and themeArt:ShowSimpleBorder(overlay:GetWidth(),overlay:GetHeight()) then overlay:Show() else overlay:Hide() end
        return
    end
    motion=MOTION[class] or MOTION.PRIEST
    overlay:SetBackdropBorderColor(color[1],color[2],color[3],.95)
    if theme.kind=="enhancement" or theme.kind=="elemental" or theme.kind=="water" or theme.kind=="holy-paladin" or theme.kind=="retribution" or theme.kind=="protection-paladin" or theme.kind=="beast-mastery" or theme.kind=="marksmanship" or theme.kind=="survival" or theme.kind=="balance" or theme.kind=="feral-dps" or theme.kind=="feral-tank" or theme.kind=="restoration-druid" or theme.kind=="arcane" or theme.kind=="fire" or theme.kind=="frost" or theme.kind=="frostfire" or theme.kind=="discipline" or theme.kind=="holy-priest" or theme.kind=="shadow-priest" or theme.kind=="assassination" or theme.kind=="combat" or theme.kind=="subtlety" or theme.kind=="affliction" or theme.kind=="fel" or theme.kind=="destruction" or theme.kind=="arms" or theme.kind=="fury" or theme.kind=="protection-warrior" then overlay:SetBackdropBorderColor(0,0,0,0) end
    glow:SetVertexColor(color[1],color[2],color[3],.95)
    for index,cloud in ipairs(clouds) do
        local tint=index==2 and theme.accent or color
        cloud:SetVertexColor(tint[1],tint[2],tint[3])
    end
    overlay:ClearAllPoints()
    overlay:SetPoint("TOPLEFT",target,"TOPLEFT",-3,3)
    overlay:SetPoint("BOTTOMRIGHT",target,"BOTTOMRIGHT",3,-3)
    overlay:Show()
end
FC.RefreshTalentVFX=refresh
local function animateEffect(overlay,themeArt,theme,motion,clouds,particles,pulse,onError)
        if not FC:IsTalentVFXEnabled() then
            if themeArt then themeArt:ShowSimpleBorder(overlay:GetWidth(),overlay:GetHeight()) end
            return
        end
        if themeArt and themeArt.authored then
            overlay:SetAlpha(1)
            glow:SetAlpha(0)
            for _,cloud in ipairs(clouds) do cloud:SetAlpha(0) end
            for _,particle in ipairs(particles) do particle:SetAlpha(0) end
            local ok,message=pcall(themeArt.Animate,themeArt,pulse,overlay:GetWidth(),overlay:GetHeight())
            if not ok and onError then onError(message) end
            return
        end
        glow:SetAlpha(1)
        local wave=.5+.5*math.sin(pulse*motion.speed)
        overlay:SetAlpha(.72+.23*wave)
        local width,height=overlay:GetWidth(),overlay:GetHeight()
        if themeArt then
            local ok,message=pcall(themeArt.Animate,themeArt,pulse,width,height)
            if not ok and onError then onError(message) end
        end
        for index,cloud in ipairs(clouds) do
            local phase=pulse*motion.speed*.65+(index-1)*2.0944
            local size=1.35+motion.breath*math.sin(phase)
            cloud:SetSize(width*size,height*size)
            cloud:SetPoint("CENTER",overlay,"CENTER",math.cos(phase)*motion.x,math.sin(phase)*motion.y)
            cloud:SetRotation(pulse*motion.turn*(index==2 and -1 or 1)+(index-1)*.6)
            cloud:SetAlpha(.18+.16*(.5+.5*math.sin(phase)))
        end
        for index,particle in ipairs(particles) do
            local progress=(pulse*.45+(index-1)/8)%1
            local angle=(index-1)*math.pi/4
            local radius=1.02+progress*.45
            local x,y=math.cos(angle)*width*.5*radius,math.sin(angle)*height*.5*radius
            local fade=math.sin(progress*math.pi)
            local mode=theme.mode
            if mode=="magma" then mode=index%2==0 and "surge" or "embers"
            elseif mode=="earthstorm" then mode=index%2==0 and "surge" or "shards"
            elseif mode=="felshadow" then mode=index%2==0 and "wisps" or "embers" end
            if mode=="embers" then
                -- Sparks drift upward along the rim, never over the icon.
                x=(index%2==0 and 1 or -1)*(width*.52+math.sin(progress*5+index)*3)
                y=-height*.35+progress*height*.95
                particle:SetSize(2+fade*2,3+fade*3);particle:SetRotation(progress*.8)
            elseif mode=="shards" then
                particle:SetSize(2.5,6+fade*4);particle:SetRotation(angle-math.pi/4)
            elseif mode=="surge" then
                fade=fade^4
                particle:SetSize(2,5+fade*7);particle:SetRotation(angle-math.pi/2)
            elseif mode=="slashes" or mode=="berserk" then
                particle:SetSize(2,5+fade*5);particle:SetRotation(angle+.65)
                x=x+math.sin(progress*math.pi)*2
                if mode=="berserk" then x=x+math.sin(pulse*8+index)*1.2 end
            elseif mode=="bleed" or mode=="poison" then
                particle:SetSize(2,3+fade*3);particle:SetRotation(0)
                x=(index%2==0 and 1 or -1)*width*.58;y=height*(.35-progress*.95)
                local tint=theme.accent;particle:SetVertexColor(tint[1],tint[2],tint[3])
            elseif mode=="leaves" then
                particle:SetSize(3,6);particle:SetRotation(math.sin(pulse+index)*.7)
                x=(index%2==0 and 1 or -1)*width*.6+math.sin(pulse+index)*3;y=height*(.6-progress*1.2)
            elseif mode=="water" then
                particle:SetSize(10,10);particle:SetRotation(0);y=y+progress*4;fade=fade*.7
            elseif mode=="dots" then
                particle:SetSize(9+fade*3,9+fade*3);particle:SetRotation(0)
                fade=fade^3
            elseif mode=="explosives" then
                particle:SetSize(2+fade*2,2+fade*2);particle:SetRotation(angle)
                fade=fade^4;x=x*(1+progress*.2);y=y*(1+progress*.2)
            else
                particle:SetSize(14+fade*8,14+fade*8)
                x=x+math.sin(pulse*.7+index)*2;y=y+math.cos(pulse*.6+index)*2
                particle:SetRotation(-pulse*.25+index)
                fade=fade*.55
            end
            particle:SetPoint("CENTER",overlay,"CENTER",x,y);particle:SetAlpha(fade*.8)
        end

end
local driver=CreateFrame("Frame")
local elapsed,pulse=0,0
driver:SetScript("OnUpdate",function(_,delta)
    pulse=pulse+delta;elapsed=elapsed+delta
    if not overlay:IsShown() and themeArt then themeArt.started=nil;themeArt.playingFile=nil;themeArt.lastFrame=nil end
    if target and (not target:IsShown() or (InCombatLockdown and InCombatLockdown())) then overlay:Hide();target=nil end
    if overlay:IsShown() then animateEffect(overlay,themeArt,theme,motion,clouds,particles,pulse,disableThemeArt) end
    if elapsed>=.4 then
        elapsed=0
        local ok=pcall(refresh)
        if not ok then target=nil;overlay:Hide() end
    end
end)
