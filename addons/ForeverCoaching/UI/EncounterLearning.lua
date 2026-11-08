local CreateFrame=ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
local FC=ForeverCoaching
local positions={Learn=1,Scenarios=1,Talents=1}
function FC:BuildParserScenarioPage(parent)
 local W=self.WarcraftLogs;local Theme=self.ClassicTheme
 local document=Theme:Document(parent,Theme.METRICS.documentTop)
 local toolbar=Theme:Toolbar(parent,Theme.METRICS.toolbarTop,14)
 local spec=self:GuidePicker(parent,0,0,240,function(key)if W.GetPublicReportModel then W:SetPublicSpec(key)else W:SetComparisonSpec(key)end end)
 local encounter=self:GuidePicker(parent,0,0,360,function(key)if W.GetPublicReportModel then W:SetPublicEncounter(key)else W:SetComparisonEncounter(key)end end)
 toolbar:Add(spec,0);toolbar:Add(encounter,12);toolbar:SetFlexible(encounter,160)
 local function draw()
  local model=W.GetPublicReportModel and W:GetPublicReportModel() or W:GetComparisonModel();document:Reset()
  spec:SetOptions(model.specs,model.selectedSpec,'Choose spec')
  encounter:SetOptions(model.encounters,model.selectedEncounter,'Choose instance / encounter')
  local replay=model.scenario
  if model.notice then document:Line(model.notice,false,'caution')end
  if not replay then
   document:Line(model.referenceOnly and model.status or model.ready and 'This comparison has no recorded reference sequence yet.' or 'No matching reference scenario data is connected for this selection.')
  else
   document:Line(model.metrics,true)
   document:Line(replay.player..' / '..(replay.basis or '100 percentile')..' / '..string.format('%.1fs',replay.duration))
   document:Line(model.status)
   document:Line('This is one recorded sequence, not a guaranteed optimal rotation. Adapt to your assignments and available abilities.')
   local function actions(title,kind,countKey)
    document:Line(title..' ('..#replay[kind]..' / '..replay[countKey]..' recorded)',true)
    if #replay[kind]==0 then
     document:Line(kind=='items' and 'Item-use details were not exposed in this reference.' or 'No matching actions were recorded.')
    else
     for i,event in ipairs(replay[kind])do
      document:Line(string.format('%d.  %.1fs — %s%s',i,event.at,event.name,event.itemID and (' / item #'..event.itemID) or ''))
     end
    end
   end
   actions('Recorded rotation','casts','castCount')
   actions('Items used','items','itemCount')
   actions('Self-applied buffs','buffs','buffCount')
   if model.nextFight then document:Line('Your next fight',true);document:Line(model.nextFight)end
  end
  document:Finish()
 end
 self.parserScenarioView={parent=parent,refresh=draw,document=document,specPicker=spec,encounterPicker=encounter}
 draw()
 local listener=CreateFrame('Frame',nil,parent)
 for _,event in ipairs({'PLAYER_TALENT_UPDATE','TRAIT_CONFIG_UPDATED','ACTIVE_TALENT_GROUP_CHANGED','PLAYER_SPECIALIZATION_CHANGED'})do pcall(listener.RegisterEvent,listener,event)end
 listener:SetScript('OnEvent',function()if parent:IsShown()then draw()end end)
end
function FC:RefreshParserScenarios()
 local view=self.parserScenarioView
 if view and view.parent:IsShown() then view.refresh()end
end
function FC:BuildEncounterLearningPage(parent,mode)
 if mode=='Scenarios' and self.WarcraftLogs then return self:BuildParserScenarioPage(parent)end
 local coach=self.EncounterCoach;if not coach then return end
 local Theme=FC.ClassicTheme
 local document=Theme:Document(parent,Theme.METRICS.documentTop)
 local guideLink=CreateFrame('EditBox',nil,document.content,'InputBoxTemplate');guideLink:SetSize(680,24);guideLink:SetAutoFocus(false)
 guideLink:SetScript('OnEditFocusGained',function(self)self:HighlightText()end);guideLink:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
 local previous,nextButton,counter,picker,draw
 local function paragraph(title,body,tone)
  if body and body~='' then document:Line(title,true,tone);document:Line(body) end
 end
 draw=function()
  document:Reset()
  guideLink:Hide()
  local class,build,live=FC.GuideBrowser:GetContext()
  local scenarios
  if mode=='Scenarios' and FC.SpecScenarios then
   scenarios=build and FC.SpecScenarios.ForPreview and FC.SpecScenarios:ForPreview(class,build) or FC.SpecScenarios:ForCurrent(live)
  end
  local items=mode=='Scenarios' and scenarios and scenarios.scenarios or mode=='Talents' and build and build.talents or mode=='Learn' and FC.GuideBrowser:LessonsFor(class,build) or {}
  positions[mode]=math.max(1,math.min(positions[mode],math.max(1,#items)))
  local index=positions[mode];local item=items[index]
  local options={}
  for i,value in ipairs(items) do options[#options+1]={value=i,label=value.title or value.name} end
  picker:SetOptions(options,index,mode=='Scenarios' and 'Choose a scenario' or 'Choose a lesson')
  counter:SetText(index..' / '..#items);previous:SetEnabled(index>1);nextButton:SetEnabled(index<#items)
  if not item then document:Line(mode=='Scenarios' and 'Choose a specialization to see its scenarios.' or 'No lessons available for this selection.')
  elseif mode=='Scenarios' then
   document:Line((scenarios.spec or class)..' / '..item.title,true)
   paragraph('When',item.trigger)
   if #(item.steps or {})>0 then
    for i,step in ipairs(item.steps) do
     document:Group(i..'. '..step.action,'|cffffcc66When:|r '..step.when..'\n\n|cffffcc66Why:|r '..step.why)
    end
   else paragraph('What to do',item.react) end
   paragraph('Before',item.prepare)
   paragraph('Avoid',item.avoid,'caution')
   if #(item.unavailable or {})>0 then paragraph('Not included',table.concat(item.unavailable,', '),'muted') end
  elseif mode=='Talents' then
   local lesson=FC.TalentLessons and FC.TalentLessons:GetLesson(class,build,item)
   if lesson then document:Group(item.name..' / rank '..item.rank,'|cffffcc66What it does:|r '..lesson.effect..'\n\n|cffffcc66Why it is used:|r '..lesson.why..'\n\n|cffffcc66Good for this build:|r '..(lesson.buildBenefit or lesson.why)) end
  else
   document:Group(item.name,'|cffffcc66What it does:|r '..(item.description or 'Effect unavailable for this ability.')..'\n\n|cffffcc66Why it is used:|r '..item.why..'\n\n|cffffcc66When to use it:|r '..item.when..'\n\n|cffffcc66How to use it:|r '..item.how)
  end
  local reference=FC.GuideSources and FC.GuideSources:ForBuild(class,build)
  if reference then document:Line('Wowhead Forever guide',true);guideLink:SetText(reference.url);guideLink:Show();document:AddWidget(guideLink,32)end
  document:Finish()
 end
 local _,toolbar=self:BuildGuideSelectors(parent,function()positions[mode]=1;draw()end)
 -- One toolbar row: class, spec, then Previous / n of m / Next and the direct picker.
 local height=Theme.METRICS.buttonHeight
 -- Small step buttons around the counter; the tooltip names them for screen readers and translators.
 local function step(label,tip)
  local b=Theme:NewButton(parent,label,false);b:SetWidth(24)
  b:HookScript('OnEnter',function(self)if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:SetText(FC.Text and FC:Text(tip) or tip);GameTooltip:Show()end end)
  b:HookScript('OnLeave',function()if GameTooltip then GameTooltip:Hide()end end)
  return b
 end
 previous=step('<','Previous')
 counter=parent:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');counter:SetSize(44,height);counter:SetJustifyH('CENTER');if counter.SetJustifyV then counter:SetJustifyV('MIDDLE') end
 nextButton=step('>','Next')
 picker=self:GuidePicker(parent,0,0,220,function(index)positions[mode]=index;draw()end)
 toolbar:Add(previous,12);toolbar:Add(counter,2);toolbar:Add(nextButton,2);toolbar:Add(picker,8);toolbar:SetFlexible(picker,110)
 previous:SetScript('OnClick',function()positions[mode]=math.max(1,positions[mode]-1);draw()end)
 nextButton:SetScript('OnClick',function()positions[mode]=positions[mode]+1;draw()end)
 if mode=='Learn' then
  local toggle=Theme:NewButton(parent,'Talent lessons',80)
  toolbar:Add(toggle,8)
  toggle:SetScript('OnClick',function()mode=mode=='Talents' and 'Learn' or 'Talents';toggle:SetText(mode=='Talents' and 'Ability lessons' or 'Talent lessons');Theme:FitButton(toggle,80,18);toolbar:Layout();draw()end)
 end
 draw()
 local listener=CreateFrame('Frame',nil,parent)
 for _,event in ipairs({'PLAYER_TALENT_UPDATE','TRAIT_CONFIG_UPDATED','ACTIVE_TALENT_GROUP_CHANGED','PLAYER_SPECIALIZATION_CHANGED','SPELLS_CHANGED'}) do pcall(listener.RegisterEvent,listener,event) end
 listener:SetScript('OnEvent',function()if parent:IsShown() then draw()end end)
end
