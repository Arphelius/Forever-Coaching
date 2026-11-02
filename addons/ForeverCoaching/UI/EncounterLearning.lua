local CreateFrame=ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
local FC=ForeverCoaching
local positions={Learn=1,Scenarios=1,Talents=1}
function FC:BuildEncounterLearningPage(parent,mode)
 local coach=self.EncounterCoach;if not coach then return end
 local document=FC.ClassicTheme:Document(parent,-174)
 local previous,nextButton,counter,picker,draw
 local function paragraph(title,body,tone)
  if body and body~='' then document:Line(title,true,tone);document:Line(body) end
 end
 draw=function()
  document:Reset()
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
   document:Group(item.name,'|cffffcc66What it does:|r '..(item.description or 'Effect unavailable for this ability.')..'\n\n|cffffcc66Why it is used:|r '..item.why..'\n\n|cffffcc66When to use it:|r '..item.when)
  end
  document:Finish()
 end
 self:BuildGuideSelectors(parent,function()positions[mode]=1;draw()end,mode=='Learn' and 214 or nil)
 previous=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');previous:SetSize(90,26);previous:SetPoint('TOPLEFT',18,-134);previous:SetText('Previous')
 counter=parent:CreateFontString(nil,'OVERLAY','GameFontNormal');counter:SetPoint('TOPLEFT',120,-140)
 nextButton=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');nextButton:SetSize(90,26);nextButton:SetPoint('TOPLEFT',184,-134);nextButton:SetText('Next')
 picker=self:GuidePicker(parent,286,-134,224,function(index)positions[mode]=index;draw()end)
 previous:SetScript('OnClick',function()positions[mode]=math.max(1,positions[mode]-1);draw()end)
 nextButton:SetScript('OnClick',function()positions[mode]=positions[mode]+1;draw()end)
 if mode=='Learn' then
  local toggle=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');toggle:SetSize(112,26);toggle:SetPoint('TOPLEFT',406,-96);toggle:SetText('Talent lessons')
  toggle:SetScript('OnClick',function()mode=mode=='Talents' and 'Learn' or 'Talents';toggle:SetText(mode=='Talents' and 'Ability lessons' or 'Talent lessons');draw()end)
 end
 draw()
 local listener=CreateFrame('Frame',nil,parent)
 for _,event in ipairs({'PLAYER_TALENT_UPDATE','TRAIT_CONFIG_UPDATED','ACTIVE_TALENT_GROUP_CHANGED','PLAYER_SPECIALIZATION_CHANGED','SPELLS_CHANGED'}) do pcall(listener.RegisterEvent,listener,event) end
 listener:SetScript('OnEvent',function()if parent:IsShown() then draw()end end)
end
