local FC=ForeverCoaching
FC:ToggleWindow()
local function visibleText(fragment)
    for _,f in ipairs(TestFrames) do
        if type(f.text)=='string' and f.text:find(fragment,1,true) and f:IsShown() then return f end
    end
end
local talentButton
for _,f in ipairs(TestFrames) do if f.text=='Talent Builds' then talentButton=f.parent end end
assert(talentButton and talentButton.scripts.OnClick,'Talent tab missing')
talentButton.scripts.OnClick(talentButton)
assert(visibleText('Talents unlock at level 10'),'Low-level talent guidance missing')
assert(visibleText('Enhancement: mana sustain'),'Shaman should see a Shaman route by default')
local full=assert(visibleText('Full route'))
full.scripts.OnClick(full)
assert(visibleText('21 points planned.'),'Full route point count missing')
assert(visibleText('Improved Stormstrike  1/2'),'Sustain route missing its final point')
local selector=assert(visibleText('Enhancement: mana sustain'))
selector.scripts.OnClick(selector)
assert(visibleText('Enhancement: attack speed'),'Build switch failed')
assert(visibleText('Flurry  5/5'),'Attack-speed route must finish Flurry')
local warrior=assert(visibleText('Warrior'))
warrior.scripts.OnClick(warrior)
assert(visibleText('Fury: leveling'),'Warrior browsing failed')
assert(visibleText('https://wow4evernews.com/en/articles/wow-forever-warrior-leveling-build'),'Build source URL missing')
