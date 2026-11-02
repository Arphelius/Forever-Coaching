local CreateFrame=ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
local FC=ForeverCoaching
function FC:BuildGearGuidePage(parent)
 local document=FC.ClassicTheme:Document(parent,FC.ClassicTheme.METRICS.documentTop)
 local draw
 local link=CreateFrame('EditBox',nil,document.content,'InputBoxTemplate');link:SetSize(480,24);link:SetAutoFocus(false)
 link:SetScript('OnEditFocusGained',function(self)self:HighlightText()end);link:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
 draw=function()
  document:Reset()
  local class,build=FC.GuideBrowser:GetContext()
  local guide=FC.GearGuide:ForBuild(class,build,UnitLevel and UnitLevel('player'))
  if not guide.available then document:Line(guide.notice or 'Choose a build.') else
   document:Line((guide.spec or guide.title or class)..(guide.role and ' / '..guide.role or ''),true)
   for _,stat in ipairs(guide.stats or {}) do document:Group(stat.name,stat.why) end
  end
  document:Group('Compare upgrades with SimGearForever',guide.companion)
  local steps={};for i,text in ipairs(guide.steps or {}) do steps[#steps+1]=i..'. '..text end
  if #steps>0 then document:Group('How to use SimGearForever',table.concat(steps,'\n\n')) end
  link:SetText(guide.url);document:AddWidget(link,32)
  document:Line('Select the link and press Ctrl+C to copy it.')
  document:Finish()
 end
 self:BuildGuideSelectors(parent,function()draw()end)
 draw()
end
