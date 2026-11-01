local planner=ForeverCoaching.BuildPlanner
for _,class in ipairs({'SHAMAN','WARRIOR'}) do
    for index,build in ipairs(planner:GetBuilds(class)) do
        local valid,err=planner:Validate(build)
        assert(valid,tostring(err))
        for level=1,60 do
            local plan=assert(planner:GetPlan(class,level,index))
            assert(plan.points==math.max(0,math.min(level,30)-9),'Wrong baseline point budget')
            if plan.nextPoint then assert(plan.nextPoint.level==math.max(10,level+1),'Wrong next point') end
        end
    end
end
local function rank(plan,name)
    for _,row in ipairs(plan.rows) do if row.name==name then return row.rank end end
    return 0
end
assert(planner:GetPlan('SHAMAN',2).nextPoint.level==10,'Talent advice must wait until level 10')
assert(rank(planner:GetPlan('SHAMAN',20),'Shamanistic Focus')==1,'Focus milestone missing')
assert(rank(planner:GetPlan('SHAMAN',25),'Stormstrike')==1,'Stormstrike milestone missing')
local sustain=planner:GetPlan('SHAMAN',30,1)
assert(rank(sustain,'Flurry')==4 and rank(sustain,'Improved Stormstrike')==1,'Wrong sustain variant')
local speed=planner:GetPlan('SHAMAN',30,2)
assert(rank(speed,'Flurry')==5 and rank(speed,'Improved Stormstrike')==0,'Wrong speed variant')
assert(planner:GetPlan('SHAMAN',60).beyondCoverage,'Do not invent a 31-60 route')
assert(planner:GetPlan('PALADIN',20)==nil,'Do not give another class a Shaman build')
assert(not planner:Validate({maxLevel=10,talents={{name='Bad',rank=2,maxRank=1,firstLevel=10}}}),'Reject excessive ranks')
assert(not planner:Validate({maxLevel=10,talents={{name='Bad',rank=1,maxRank=1,firstLevel=10,tier=2}}}),'Reject early talent tier')
assert(not planner:Validate({maxLevel=10,talents={{name='Bad',rank=1,maxRank=1,firstLevel=10,requires={name='Missing',rank=1}}}}),'Reject missing prerequisite')
