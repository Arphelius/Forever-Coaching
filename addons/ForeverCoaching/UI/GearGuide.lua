local CreateFrame = ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
local FC=ForeverCoaching
function FC:BuildGearGuidePage(parent)
 local document=FC.ClassicTheme:Document(parent,-96)
 local content=document.content
 local function line(text,title)
  document:Line(text,title)
 end
 local context=FC.EncounterCoach:GetBuildContext();local selected
 if context.class and context.id then for _,build in ipairs(FC.BuildPlanner:GetBuilds(context.class)) do if build.id==context.id then selected=build;break end end end
 local guide=FC.GearGuide:ForBuild(context.class,selected,UnitLevel and UnitLevel('player'))
 line(guide.title or 'Gear for your selected build',true);line(guide.importance)
 if not guide.available then line(guide.notice) else
  line(guide.plan)
  line('Stats to look for',true)
  for _,stat in ipairs(guide.stats) do line(stat.name,true);line(stat.why) end
  if #guide.talentNotes>0 then line('Interactions in this allocation',true);for _,talent in ipairs(guide.talentNotes) do line(talent.name..': '..talent.effect) end end
 end
 line('Compare upgrades with SimGearForever',true);line(guide.companion)
 for i,text in ipairs(guide.steps) do line(i..'. '..text) end
 local link=CreateFrame('EditBox',nil,content,'InputBoxTemplate');link:SetSize(480,30);link:SetAutoFocus(false);link:SetText(guide.url);link:SetScript('OnEditFocusGained',function(self)self:HighlightText()end);link:SetScript('OnEscapePressed',function(self)self:ClearFocus()end);document:AddWidget(link,32)
 line('Select the link and press Ctrl+C to copy it.');line(guide.limits)
 document:Finish()
end
