-- Builds window: the Talent Builds tab lists reference builds for the character's class and, once one is
-- chosen, shows its source and level-by-level talent progression (the fixture is a level 2 Shaman).
unpack=unpack or table.unpack
local FC=ForeverCoaching
FC:ToggleWindow()
local function visible(text)
    for _,f in ipairs(TestFrames) do
        if f.text==text and f:IsShown() then return f end
    end
end
local function visibleText(fragment)
    for _,f in ipairs(TestFrames) do
        if type(f.text)=='string' and f.text:find(fragment,1,true) and f:IsShown() then return f end
    end
end
local function click(text)
    local f=visible(text)
    while f and not (f.scripts and f.scripts.OnClick) do f=f.parent end
    assert(f,'No clickable "'..text..'"')
    f.scripts.OnClick(f)
end
click('Talent Builds')
assert(visibleText('Select a build from the list'),'No build chosen yet: the window asks for one')
assert(visible('Elemental') and visible('Enhancement') and visible('Restoration'),'All three Shaman specs listed')
click('Raids')
assert(visible('Recommended DPS'))
click('Enhancement')
assert(visibleText('MythicSim / Single target / #13 / 946 DPS / no trinkets'))
click('Dungeons')
assert(visible('Recommended DPS'))
click('Elemental')
assert(visibleText('MythicSim / 5 targets / 60 sec / #3 / 1819 DPS / no trinkets'))
click('MythicSim')
assert(visible('MythicSim rankings'))
print('PASS: Talent Builds shows expectation and source for each damage benchmark.')
