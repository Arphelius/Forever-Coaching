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
assert(visibleText('Recommended for Leveling: Enhancement'),'Shaman should get its leveling recommendation')
assert(visibleText('Select a build from the list'),'No build chosen yet: the window asks for one')
assert(visible('Elemental') and visible('Enhancement') and visible('Restoration'),'All three Shaman specs listed')
click('Enhancement')
assert(visibleText('GUIDE  /  LEVEL 20'),'Chosen build shows its guide header')
assert(visibleText('SOURCE: Mobalytics'),'Chosen build credits its source')
assert(visibleText('Level 10 / Thundering Strikes 1/5'),'Progression starts at level 10')
assert(visibleText('Level 20 / Shamanistic Focus 1/1'),'Progression reaches the build level')
print('PASS: Talent Builds tab lists the class builds and shows the chosen build progression.')
