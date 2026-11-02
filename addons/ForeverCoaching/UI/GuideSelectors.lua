local FC=ForeverCoaching
local CreateFrame=FC.CreateLocalizedFrame or CreateFrame
local browser={};FC.GuideBrowser=browser
-- Browsing a guide must never select a live talent build or change combat advice.
function browser:GetContext()
 local live=FC.EncounterCoach:GetBuildContext()
 local class=self.class or live.class
 local builds=FC.BuildPlanner:GetBuilds(class)
 local build
 for _,candidate in ipairs(builds) do if candidate.id==(self.buildID or live.id) then build=candidate;break end end
 local options=self:BuildOptions(class)
 local label=build and (FC.BuildPlanner.GetBuildDisplayName and FC.BuildPlanner:GetBuildDisplayName(class,build) or build.title)
 local chosen
 for _,option in ipairs(options) do if option.value==(build and build.id) or option.label==label then chosen=option;break end end
 chosen=chosen or options[1]
 if chosen then for _,candidate in ipairs(builds) do if candidate.id==chosen.value then build=candidate;break end end else build=nil end
 return class,build,live,self.class~=nil
end
function browser:ClassOptions()
 local options={}
 for _,class in ipairs(FC.BuildPlanner.classes or {}) do options[#options+1]={value=class,label=class:sub(1,1)..class:sub(2):lower()} end
 return options
end
function browser:BuildOptions(class)
 local options,seen={},{}
 local level=UnitLevel and UnitLevel('player') or 60
 local activity=self.activity or (level<60 and 'leveling' or 'raids')
 local choices=FC.BuildPlanner.GetVisibleSpecBuilds and FC.BuildPlanner:GetVisibleSpecBuilds(class,activity,60)
 if not choices then choices={};for _,build in ipairs(FC.BuildPlanner:GetBuilds(class)) do choices[#choices+1]={build=build} end end
 for _,choice in ipairs(choices) do
  local build=choice.build
  if build then
   local label=FC.BuildPlanner.GetBuildDisplayName and FC.BuildPlanner:GetBuildDisplayName(class,build) or build.title
   if not seen[label] then seen[label]=true;options[#options+1]={value=build.id,label=label} end
  end
 end
 return options
end
function browser:GetReviewFilter()
 if not self.class then return end
 local class,build=self:GetContext();local points={0,0,0}
 for _,talent in ipairs(build and build.talents or {}) do if points[talent.treeIndex] then points[talent.treeIndex]=points[talent.treeIndex]+(talent.rank or 0) end end
 local tree;local highest=0;local tied=false
 for i,value in ipairs(points) do if value>highest then tree=i;highest=value;tied=false elseif value==highest and value>0 then tied=true end end
 return {class=class,tree=not tied and tree or nil,role=build and build.role}
end
function browser:LessonsFor(class,build)
 local guide=FC.SpecScenarios and FC.SpecScenarios.ForPreview and FC.SpecScenarios:ForPreview(class,build)
 local catalog={};for _,lesson in ipairs(FC.AbilityLessons and FC.AbilityLessons[class] or {}) do catalog[lesson.name]=lesson end
 local lessons,seen={},{}
 for _,scenario in ipairs(guide and guide.scenarios or {}) do
  for _,step in ipairs(scenario.steps or {}) do
   local source=step.spell and catalog[step.spell]
   if source and not seen[step.spell] then
    seen[step.spell]=true
    local spell=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[class] and FC.ForeverSpellCatalog.classes[class].spells[step.spell]
    local effect=spell and spell.description
    local level=UnitLevel and UnitLevel('player') or 60
    local selectedLevel=-1
    for _,id in ipairs(source.ids) do
     local rank=spell and spell.effects and spell.effects[tostring(id)]
     if rank and type(rank.text)=='string' and rank.text~='' and rank.level<=level and rank.level>=selectedLevel then effect=rank.text;selectedLevel=rank.level end
    end
    lessons[#lessons+1]={name=step.spell,spellID=source.ids[#source.ids],description=effect or 'Effect unavailable in the reviewed spellbook.',when=step.when,how=step.action,why=step.why,sourceUrl=source.sourceUrl,sourceBuild=source.sourceBuild}
   end
  end
 end
 return lessons
end
-- A dropdown: the field shows the choice (cut with "..."), the list opens under it and
-- above every panel. Up to ten rows show at once; longer lists scroll.
local ROW_H,VISIBLE=20,10
function FC:GuidePicker(parent,x,y,width,choose)
 local Theme=FC.ClassicTheme
 local button=Theme:Dropdown(parent,width);button:SetPoint('TOPLEFT',x,y)
 local menu=Theme:Menu(button,width)
 local scroll=CreateFrame('ScrollFrame',nil,menu,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',4,-4);scroll:SetPoint('BOTTOMRIGHT',-4,4)
 local list=CreateFrame('Frame',nil,scroll);list:SetSize(math.max(90,width-8),1);scroll:SetScrollChild(list)
 scroll:EnableMouseWheel(true)
 scroll:SetScript('OnMouseWheel',function(self,delta)
  local maximum=math.max(0,(list:GetHeight() or 0)-(self:GetHeight() or 0))
  self:SetVerticalScroll(math.max(0,math.min(maximum,(self:GetVerticalScroll() or 0)-delta*ROW_H*3)))
 end)
 local rows={};local entries={};local current
 function button:SetOptions(options,selected,placeholder)
  entries=options or {};current=selected;local caption=placeholder or 'Select'
  for _,entry in ipairs(entries) do if entry.value==selected then caption=entry.label end end
  self:SetText(caption);self:SetEnabled(#entries>0);menu:Hide();Theme:SetOpen(self,false)
 end
 button:SetScript('OnClick',function()
  if menu:IsShown() then menu:Hide();Theme:SetOpen(button,false);return end
  if FC.openGuidePicker and FC.openGuidePicker~=menu then FC.openGuidePicker:Hide() end;FC.openGuidePicker=menu
  local w=button:GetWidth() or width
  local scrolls=#entries>VISIBLE
  local inner=math.max(90,w-8-(scrolls and 20 or 0))
  menu:SetWidth(math.max(w,120));list:SetWidth(inner)
  scroll:ClearAllPoints();scroll:SetPoint('TOPLEFT',4,-4);scroll:SetPoint('BOTTOMRIGHT',scrolls and -24 or -4,4)
  for i,entry in ipairs(entries) do
   local row=rows[i]
   if not row then
    row=CreateFrame('Button',nil,list);row:SetHeight(ROW_H)
    row:SetNormalFontObject('GameFontHighlightSmall');row:SetHighlightFontObject('GameFontNormalSmall')
    row:SetText(' ')
    local label=row:GetFontString()
    if label and label.ClearAllPoints then label:ClearAllPoints();label:SetPoint('LEFT',6,0);label:SetPoint('RIGHT',-6,0);label:SetJustifyH('LEFT');label:SetWordWrap(false) end
    local glow=row:CreateTexture(nil,'HIGHLIGHT');glow:SetAllPoints(row);glow:SetTexture('Interface\\Buttons\\WHITE8X8');glow:SetVertexColor(1,.85,.5,.10)
    rows[i]=row
   end
   row:ClearAllPoints();row:SetPoint('TOPLEFT',0,-(i-1)*ROW_H);row:SetWidth(inner)
   local value=entry.value;row:SetText(entry.label)
   local label=row:GetFontString();if label and label.SetTextColor then if value==current then label:SetTextColor(1,.76,.32) else label:SetTextColor(.9,.89,.85) end end
   row:SetScript('OnClick',function()menu:Hide();Theme:SetOpen(button,false);choose(value)end);row:Show()
  end
  for i=#entries+1,#rows do rows[i]:Hide() end
  list:SetHeight(math.max(1,#entries*ROW_H))
  menu:SetHeight(math.min(#entries,VISIBLE)*ROW_H+8)
  scroll:SetVerticalScroll(0);menu:Show();Theme:SetOpen(button,true)
 end)
 button:HookScript('OnHide',function()menu:Hide();Theme:SetOpen(button,false)end)
 button.guideMenu=menu
 return button
end
-- Class and specialization pickers open the page's toolbar row; pages add their own
-- controls after them. Returns refresh and that toolbar.
function FC:BuildGuideSelectors(parent,changed,specWidth,toolbar)
 local Theme=FC.ClassicTheme
 toolbar=toolbar or Theme:Toolbar(parent,Theme.METRICS.toolbarTop)
 local classPicker,specPicker
 local function refresh()
  local class,build=browser:GetContext()
  classPicker:SetOptions(browser:ClassOptions(),class,'Class')
  specPicker:SetOptions(browser:BuildOptions(class),build and build.id,'Specialization')
 end
 classPicker=self:GuidePicker(parent,0,0,120,function(class)browser.class=class;browser.buildID=nil;refresh();changed()end)
 specPicker=self:GuidePicker(parent,0,0,specWidth or 200,function(id)browser.buildID=id;local class=browser:GetContext();browser.class=class;refresh();changed()end)
 toolbar:Add(classPicker);toolbar:Add(specPicker)
 refresh()
 return refresh,toolbar
end
