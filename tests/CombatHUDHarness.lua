HUDRecommendation={spellID=6603,icon=6603,targetHostile=true,pressRequired=false,spellRanks={6603},rotation={}}
ForeverCoaching={RotationCoach={GetRecommendation=function() return HUDRecommendation end}}
ActionButton1=CreateFrame('Button',nil,UIParent)
ActionButton1.action=1
GetActionInfo=function() return 'spell',6603 end
