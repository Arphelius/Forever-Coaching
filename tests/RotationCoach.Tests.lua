local coach=ForeverCoaching.RotationCoach
ResetRotationState()
assert(coach:GetRecommendation().spellID==403,'Learned Lightning Bolt should be recommended while standing')
RotationState.speed=7
assert(coach:GetRecommendation().situation=='movement','Do not recommend a hard cast while moving')
RotationState.known[8042]=true
assert(coach:GetRecommendation().spellID==8042,'Prefer a ready instant shock while moving')
RotationState.speed=0
RotationState.mana=20
RotationState.costs={[8042]=5}
assert(coach:GetRecommendation().spellID==8042,'Choose affordable attack instead of one that consumes the reserve')
ResetRotationState()
RotationState.mana=5
assert(coach:GetRecommendation().situation=='resource recovery','Stop suggesting unaffordable casts')
RotationState.hiddenMana=true
assert(coach:GetRecommendation().situation=='resource recovery','Use insufficient-power result even when exact mana is secret')
ResetRotationState()
RotationState.mana=0
RotationState.costs={[403]=0}
assert(coach:GetRecommendation().spellID==403,'A genuinely free cast must not be blocked by the mana reserve')
ResetRotationState()
RotationState.speed=7
RotationState.rank=5
RotationState.stacks=5
RotationState.costs={[403]=0}
assert(coach:GetRecommendation().spellID==403,'Instant Maelstrom Bolt remains available while moving')
ResetRotationState()
RotationState.rank=5
RotationState.stacks=2
RotationState.costs={[403]=9}
local rec=coach:GetRecommendation()
assert(rec.reason:find('91 mana remains',1,true),'Do not apply Maelstrom discount twice to the effective engine cost')

ResetRotationState()
RotationState.combat=true
RotationState.mana=5
RotationState.meleeRange=true
RotationState.attacking=false
InstallAttackButton()
local startAttack=coach:GetRecommendation()
assert(startAttack.spellID==6603 and startAttack.pressRequired==true,'Low mana in confirmed melee should offer starting weapon attacks')
RotationState.attacking=true
local keepAttacking=coach:GetRecommendation()
assert(keepAttacking.spellID==6603 and keepAttacking.pressRequired==false,'Never prompt an attack toggle that would stop existing swings')
RotationState.meleeRange=nil
assert(coach:GetRecommendation().spellID==nil,'Unknown melee range must not produce an Attack cue')
RotationState.meleeRange=false
assert(coach:GetRecommendation().spellID==nil,'Out-of-melee target must not produce an Attack cue')
RotationState.meleeRange=true
RotationState.attacking=nil
assert(coach:GetRecommendation().spellID==nil,'Unknown toggle state must not ask the player to toggle Attack')
RotationState.attacking=false
RotationState.mana=100
assert(coach:GetRecommendation().spellID==403,'Weapon fallback must not displace an affordable damage spell')
RotationState.mana=5
RotationState.combat=false
assert(coach:GetRecommendation().spellID==nil,'Do not recommend pulling with a weapon when mana is low outside combat')
ResetRotationState()
local projected=coach:GetRecommendation()
assert(projected.forecast and #projected.forecast==3,'Known affordable repeated filler projects all three follow-ups')
for _,spell in ipairs(projected.forecast)do assert(spell.id==403,'Forecast uses the actual selected filler')end
C_ClassTalents=nil
local rank=3
GetNumTalents=function(tree)return tree==2 and 1 or 0 end
GetTalentInfo=function()return 'Flurry',nil,1,1,rank,5 end
for _,frame in ipairs(TestFrames)do if frame.events.PLAYER_TALENT_UPDATE then frame.scripts.OnEvent(frame,'PLAYER_TALENT_UPDATE') end end
assert(coach:GetActiveTalentSnapshot().Flurry.rank==3,'Read actual talents on the legacy client')
rank=4
for _,frame in ipairs(TestFrames)do if frame.events.PLAYER_TALENT_UPDATE then frame.scripts.OnEvent(frame,'PLAYER_TALENT_UPDATE') end end
assert(coach:GetActiveTalentSnapshot().Flurry.rank==4,'Talent updates invalidate the legacy cache')
