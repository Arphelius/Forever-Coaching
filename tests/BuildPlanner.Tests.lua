local planner=ForeverCoaching.BuildPlanner
-- Every preset is now a MythicSim/guide reference build (kind="reference"): GetPlan checks it against its
-- talent string and point total instead of the old sequential level-by-level route (Validate).
local classes={'DRUID','HUNTER','MAGE','PALADIN','PRIEST','ROGUE','SHAMAN','WARLOCK','WARRIOR'}
local total=0
for _,class in ipairs(classes) do
    local builds=planner:GetBuilds(class)
    assert(#builds>0,class..' has no builds')
    for index,build in ipairs(builds) do
        assert(build.kind=='reference',class..' '..tostring(build.id)..' is not a reference build')
        for _,level in ipairs({1,10,20,30,40,50,60}) do
            local plan,err=planner:GetPlan(class,level,index)
            assert(plan,class..' '..tostring(build.id)..' at '..level..': '..tostring(err))
            assert(plan.reference and plan.points==(build.points or 51),'Wrong point total for '..tostring(build.id))
            assert(plan.maxLevel==(build.maxLevel or 60),'Wrong level cap for '..tostring(build.id))
        end
        total=total+1
    end
end
assert(total>0,'No builds checked')
assert(planner:GetPlan('DEATHKNIGHT',20)==nil,'A class without presets gets no plan')
assert(planner:GetPlan('SHAMAN',20,999)==nil,'A missing variant gets no plan')
-- A reference build whose rows disagree with its talent string is rejected, not shown.
local shaman=planner:GetBuilds('SHAMAN')[1]
local saved=shaman.talents[1].rank
shaman.talents[1].rank=saved+1
assert(planner:GetPlan('SHAMAN',60,1)==nil,'Inconsistent MythicSim rows must be rejected')
shaman.talents[1].rank=saved
assert(planner:GetPlan('SHAMAN',60,1),'Restored build plans again')
-- The sequential-route validator still guards hand-written routes.
assert(not planner:Validate({maxLevel=10,talents={{name='Bad',rank=2,maxRank=1,firstLevel=10}}}),'Reject excessive ranks')
assert(not planner:Validate({maxLevel=10,talents={{name='Bad',rank=1,maxRank=1,firstLevel=10,tier=2}}}),'Reject early talent tier')
assert(not planner:Validate({maxLevel=10,talents={{name='Bad',rank=1,maxRank=1,firstLevel=10,requires={name='Missing',rank=1}}}}),'Reject missing prerequisite')
assert(not planner:Validate({maxLevel=10,talents={{name='NoLevel',rank=1,maxRank=1}}}),'Reject a step without its level')
print('PASS: '..total..' reference builds plan at every level; inconsistent rows rejected; route validator guards.')
