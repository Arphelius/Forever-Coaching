-- Published point order, not an extrapolation of a level-30 tournament build.
local FC=ForeverCoaching
local url="https://bytetavern.com/wow-forever-leveling-talents/"
local routes={
    WARRIOR={title="Arms: 10–60 leveling",why="Builds rage efficiency and two-handed damage before adding Fury support.",steps={
        {"Improved Rend",3},{"Improved Heroic Strike",2},{"Improved Tactical Mastery",5},{"Anger Management",1},{"Deep Wounds",3},{"Improved Heroic Strike",1},{"Impale",2},{"Two-Handed Weapon Specialization",3},{"Sweeping Strikes",1},{"Bloodthrill",5},{"Weaponmaster",4},{"Mortal Strike",1},{"Weaponmaster",1},{"Improved Overpower",2},{"Cruelty",5},{"Unbridled Wrath",5},{"Blood Craze",3},{"Piercing Howl",1},{"Lingering Rage",3}}},
    PALADIN={title="Retribution: 10–60 leveling",why="Prioritizes melee damage, mana savings and travel speed, then Holy support.",steps={
        {"Benediction",5},{"Conviction",5},{"Seal of Command",1},{"Pursuit of Justice",2},{"Sanctified Judgement",3},{"Sacred Arbiter",1},{"Vindication",3},{"Vengeance",1},{"Vengeance",2},{"Two-Handed Weapon Specialization",3},{"Champion of the Light",3},{"Improved Judgement",1},{"Twist of Light",1},{"Improved Judgement",1},{"Divine Strength",5},{"Improved Seals",3},{"Divine Intellect",5},{"Reverence",3},{"Purifying Power",2},{"Unyielding Faith",1}}},
    HUNTER={title="Beast Mastery: 10–60 leveling",why="Strengthens your pet first, then improves your ranged damage and shot efficiency.",steps={
        {"Deadly Aspects",5},{"Focused Fire",2},{"Endurance Training",3},{"Unleashed Fury",5},{"Summon Hawk",1},{"Ferocity",5},{"Bestial Swiftness",1},{"Intimidation",1},{"Spirit Bond",2},{"Frenzy",5},{"Bestial Wrath",1},{"Endurance Training",2},{"Bestial Discipline",2},{"Lethal Attacks",5},{"Careful Aim",5},{"Rapid Killing",2},{"Efficiency",4}}},
    ROGUE={title="Combat: 10–60 leveling",why="Reduces early energy costs and adds cleave, cooldowns and weapon damage.",steps={
        {"Improved Sinister Strike",2},{"Improved Eviscerate",3},{"Precision",3},{"Deflection",2},{"Endurance",2},{"Deflection",1},{"Riposte",1},{"Lightning Reflexes",1},{"Dual Wield Specialization",5},{"Blade Flurry",1},{"Hack and Slash",5},{"Weapon Expertise",2},{"Flawless Execution",1},{"Aggression",1},{"Adrenaline Rush",1},{"Aggression",2},{"Malice",5},{"Ruthlessness",3},{"Murder",2},{"Relentless Strikes",1},{"Lethality",5},{"Improved Slice and Dice",2}}},
    PRIEST={title="Shadow: 10–60 leveling",why="Combines mana recovery and Shadow damage with defensive Discipline support.",steps={
        {"Spirit Tap",5},{"Improved Shadow Word: Pain",2},{"Shadow Focus",3},{"Mind Flay",1},{"Improved Mind Flay",2},{"Improved Mind Blast",3},{"Shadow Weaving",3},{"Improved Mind Blast",1},{"Vampiric Embrace",1},{"Improved Mind Blast",1},{"Shadow Focus",1},{"Devouring Contagion",2},{"Darkness",5},{"Shadowform",1},{"Shadow Focus",1},{"Twin Disciplines",5},{"Improved Power Word: Shield",3},{"Silent Resolve",2},{"Meditation",3},{"Mental Agility",1},{"Inner Focus",1},{"Soul Warding",1},{"Early Demise",2},{"Silence",1}}},
    SHAMAN={title="Enhancement: 10–60 leveling",why="Builds melee damage and mobility, then instant Lightning Bolts and Elemental support.",steps={
        {"Thundering Strikes",5},{"Mental Dexterity",3},{"Ancestral Knowledge",2},{"Improved Ghost Wolf",2},{"Elemental Weapons",3},{"Stormstrike",1},{"Flurry",5},{"Improved Stormstrike",2},{"Mental Quickness",2},{"Maelstrom Weapon",5},{"Rage of the Farseer",1},{"Shamanistic Focus",1},{"Ancestral Knowledge",3},{"Anticipation",3},{"Spirit Weapons",1},{"Concussion",5},{"Elemental Devastation",3},{"Convection",4}}},
    DRUID={title="Feral: 10–60 leveling",why="Adds cheaper attacks, movement speed and Feral damage before shapeshifting support.",steps={
        {"Ferocity",5},{"Thick Hide",3},{"Heart of the Wild",2},{"Feral Swiftness",2},{"Sharpened Claws",2},{"Savage Fury",2},{"Predatory Strikes",3},{"Blood Frenzy",1},{"Leader of the Pack",1},{"Blood Frenzy",1},{"Natural Instinct",2},{"Heart of the Wild",1},{"Rend and Tear",5},{"Berserk",1},{"Heart of the Wild",2},{"Shredding Attacks",3},{"Shifting Power",1},{"Improved Shifting Power",2},{"Feral Charge",1},{"Natural Reaction",5},{"Primal Bite",1},{"Furor",5}}},
}
FC.LevelingRouteIssues={}
for class,route in pairs(routes) do
    local lookup,counts,totals,rows,order={},{},{0,0,0},{},{}
    for ti,tree in ipairs(FC.TalentTrees[class]) do
        for ni,node in ipairs(tree.nodes) do lookup[node.name]={node=node,tree=tree.name,ti=ti,ni=ni} end
    end
    local problem
    for _,step in ipairs(route.steps) do
        local found=lookup[step[1]]
        if not found then problem="Unknown talent: "..step[1];break end
        local node=found.node
        for rank=1,step[2] do
            local taken=counts[step[1]] or 0
            if taken>=node.maxRank or totals[found.ti]<node.row*5 then
                problem="Published order conflicts with recorded rank/row: "..step[1];break
            end
            counts[step[1]]=taken+1;totals[found.ti]=totals[found.ti]+1
            order[#order+1]={level=9+#order+1,name=step[1],rank=taken+1,maxRank=node.maxRank,spellId=node.spellId,
                why=route.why,treeIndex=found.ti,talentIndex=found.ni}
        end
        if problem then break end
    end
    if not problem and #order~=51 then problem="Published route does not total 51 points." end
    if problem then FC.LevelingRouteIssues[class]=problem else
        local codes={}
        for ti,tree in ipairs(FC.TalentTrees[class]) do
            local code=""
            for ni,node in ipairs(tree.nodes) do
                local rank=counts[node.name] or 0;code=code..rank
                if rank>0 then rows[#rows+1]={name=node.name,tree=tree.name,treeIndex=ti,talentIndex=ni,rank=rank,maxRank=node.maxRank,tier=node.row+1} end
            end
            codes[ti]=code:gsub("0+$","")
        end
        local key=class:sub(1,1)..class:sub(2):lower()
        local variants=FC.Builds.classes[key].variants
        variants[#variants+1]={kind="reference",id="published-60-"..class,maxLevel=60,points=51,title=route.title,
            role="damage",evidence="guide",note=route.why.." Levels 31–60 are an untested published plan.",fit="leveling",
            source={name="ByteTavern / Arez",url=url,guideUpdated="2026-10-21"},
            talents=rows,talentString=table.concat(codes,"-"),distribution=table.concat(totals," / "),levelingOrder=order}
    end
end
