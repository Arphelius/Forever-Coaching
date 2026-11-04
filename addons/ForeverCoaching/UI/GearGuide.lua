local CreateFrame=ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
local FC=ForeverCoaching
function FC:BuildGearGuidePage(parent)
 local document=FC.ClassicTheme:Document(parent,FC.ClassicTheme.METRICS.documentTop)
 local draw
 local professions=false;local goal='leveling';local sourceLinks={}
 local goalPicker,craftedToggle
 for i=1,4 do local box=CreateFrame('EditBox',nil,document.content,'InputBoxTemplate');box:SetSize(710,24);box:SetAutoFocus(false);box:SetScript('OnEditFocusGained',function(self)self:HighlightText()end);box:SetScript('OnEscapePressed',function(self)self:ClearFocus()end);box:Hide();sourceLinks[i]=box end
 local link=CreateFrame('EditBox',nil,document.content,'InputBoxTemplate');link:SetSize(480,24);link:SetAutoFocus(false)
 local referenceLink=CreateFrame('EditBox',nil,document.content,'InputBoxTemplate');referenceLink:SetSize(680,24);referenceLink:SetAutoFocus(false);referenceLink:SetScript('OnEditFocusGained',function(self)self:HighlightText()end);referenceLink:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
 link:SetScript('OnEditFocusGained',function(self)self:HighlightText()end);link:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
 draw=function()
  document:Reset()
  link:Hide();referenceLink:Hide();for _,box in ipairs(sourceLinks)do box:Hide()end
  if goalPicker then goalPicker:SetShown(professions);craftedToggle:SetShown(professions)end
  local class,build=FC.GuideBrowser:GetContext()
  if professions and FC.ProfessionGuide then
   local guide=FC.ProfessionGuide:ForBuild(class,build,goal)
   document:Line('Professions / '..(guide.spec or class)..' / '..(guide.role or ''),true)
   document:Group(guide.pair,guide.why)
   document:Group('How to use it for this build',guide.use)
   document:Group('Secondary professions',guide.secondary)
   document:Group('Crafted items in your rotation',guide.items)
   document:Group('Before combat',guide.preparation)
   document:Line(guide.approach,false,'muted')
   for i,url in ipairs(guide.sources or {})do sourceLinks[i]:SetText(url);sourceLinks[i]:Show();document:AddWidget(sourceLinks[i],32)end
   document:Line('Select the link and press Ctrl+C to copy it.');document:Finish();return
  end
  local guide=FC.GearGuide:ForBuild(class,build,UnitLevel and UnitLevel('player'))
  if not guide.available then document:Line(guide.notice or 'Choose a build.') else
   document:Line((guide.spec or guide.title or class)..(guide.role and ' / '..guide.role or ''),true)
   for _,stat in ipairs(guide.stats or {}) do document:Group(stat.name,stat.why) end
  end
  document:Group('Compare upgrades with SimGearForever',guide.companion)
  local steps={};for i,text in ipairs(guide.steps or {}) do steps[#steps+1]=i..'. '..text end
  if #steps>0 then document:Group('How to use SimGearForever',table.concat(steps,'\n\n')) end
  link:SetText(guide.url);link:Show();document:AddWidget(link,32)
  document:Line('Select the link and press Ctrl+C to copy it.')
  if guide.guideReference then document:Line('Wowhead Forever guide',true);referenceLink:SetText(guide.guideReference.url);referenceLink:Show();document:AddWidget(referenceLink,32)end
  document:Finish()
 end
 local _,toolbar=self:BuildGuideSelectors(parent,function()draw()end)
 if FC.ProfessionGuide then
  goalPicker=self:GuidePicker(parent,0,0,110,function(value)goal=value;goalPicker:SetOptions(FC.ProfessionGuide.goals,goal,'Goal');draw()end)
  goalPicker:SetOptions(FC.ProfessionGuide.goals,goal,'Goal')
  local mode
  mode=FC.ClassicTheme:NewButton(parent,'Professions',100);mode:SetScript('OnClick',function()professions=not professions;mode:SetText(professions and 'Gear stats' or 'Professions');draw()end)
  toolbar:Add(mode);toolbar:Add(goalPicker)
  craftedToggle=FC.ClassicTheme:NewButton(parent,'Crafted items: On',130);local toggle=craftedToggle
  local function refreshToggle()toggle:SetText(FC.CraftedItems and FC.CraftedItems:IsEnabled() and 'Crafted items: On' or 'Crafted items: Off')end
  toggle:SetScript('OnClick',function()if FC.CraftedItems then FC.CraftedItems:SetEnabled(not FC.CraftedItems:IsEnabled())end;refreshToggle()end);refreshToggle();toolbar:Add(toggle)
 end
 draw()
end
