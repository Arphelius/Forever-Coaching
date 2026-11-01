local FC=ForeverCoaching
local slideIndex={Learn=1,Scenarios=1,Talents=1}
function FC:BuildEncounterLearningPage(parent,mode)
 local coach=self.EncounterCoach
 if not coach then return end
 local scroll=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate")
 scroll:SetPoint("TOPLEFT",18,-136);scroll:SetPoint("BOTTOMRIGHT",-28,18)
 local content=CreateFrame("Frame",nil,scroll);content:SetSize(490,800);scroll:SetScrollChild(content)
 local offset=0
 local pool,used={},0
 local previous,nextButton,counter
 local function line(text,gold)
  used=used+1
  local fs=pool[used] or content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  pool[used]=fs;fs:Show();fs:SetFontObject(gold and "GameFontNormal" or "GameFontHighlightSmall");fs:ClearAllPoints()
  fs:SetPoint("TOPLEFT",0,-offset);fs:SetWidth(480);fs:SetJustifyH("LEFT");fs:SetText(text)
  offset=offset+math.max(20,fs:GetStringHeight())+12
 end
 local function draw()
 offset=0;used=0
 local build=coach:GetBuildContext()
 local lessons=coach:RefreshLessons()
 local currentScenarios=mode=='Scenarios' and FC.SpecScenarios and FC.SpecScenarios:ForCurrent(build)
 if mode=='Scenarios' then
  if currentScenarios and currentScenarios.available then
   line(currentScenarios.spec.." / "..currentScenarios.role,true)
   line(currentScenarios.contribution)
   line(currentScenarios.basis)
   line("Skip spells on cooldown, unaffordable spells and targets out of range. Use the first matching action, then check from the top again.")
  end
 else
 line(build.title.." / "..build.role,true)
 line("Lessons use your learned abilities and selected build. Selecting a plan does not verify your current talent allocation.")
 line("Talent check: "..build.talentMatch)
 line('Mobalytics: '..(FC.BuildPlanner and FC.BuildPlanner:GetBuildEvidenceUrl(build) or 'https://mobalytics.gg/wow-forever'))
 end
 if mode=="Learn" or mode=="Talents" then
  if mode=="Talents" then
   local selected
   if build.id and FC.BuildPlanner and build.class then for _,candidate in ipairs(FC.BuildPlanner:GetBuilds(build.class)) do if candidate.id==build.id then selected=candidate;break end end end
   local talents=selected and selected.talents or {}
   slideIndex[mode]=math.min(slideIndex[mode],math.max(1,#talents))
   if counter then counter:SetText(slideIndex[mode].." / "..#talents) end
   if nextButton then nextButton:SetEnabled(slideIndex[mode]<#talents) end
   local talent=talents[slideIndex[mode]]
   if talent and FC.TalentLessons then
    local lesson=FC.TalentLessons:GetLesson(build.class,selected,talent)
    line(talent.name.." / rank "..talent.rank,true)
    line("What it does: "..lesson.effect)
    line("Why it matters: "..lesson.why)
    line("How to use it well: "..lesson.optimal)
    line(lesson.provenance)
    if lesson.sourceUrl then line("Source: "..lesson.sourceUrl) end
   else line("Select your build in Talent Builds to see its talent lessons.") end
  else
  slideIndex[mode]=math.min(slideIndex[mode],math.max(1,#lessons))
  if counter then counter:SetText(slideIndex[mode].." / "..#lessons) end
  if nextButton then nextButton:SetEnabled(slideIndex[mode]<#lessons) end
  for index,lesson in ipairs(lessons) do
   if index==slideIndex[mode] then
   line(lesson.name.." (#"..lesson.spellID..")",true)
   if lesson.description then line(lesson.description) end
   line("When: "..lesson.when.."\nHow: "..lesson.how.."\nWhy: "..lesson.why)
   line("Build use: "..(build.role=="healer" and lesson.kind=="heal" and "A healing tool for your selected healer role. Plan mana and cast windows." or lesson.kind=="interrupt" and "A utility responsibility even in a damage build; coordinate the interrupt assignment." or lesson.kind=="dispel" and "Utility depends on the effect type and mechanic, rather than damage rankings." or "Check the selected build reference for talent-specific interactions."))
   end
  end
  if #lessons==0 then line("No readable learned spell data. Enter the world and check the spellbook; restricted APIs are not replaced with guessed abilities.") end
  end
 else
  local scenarios=currentScenarios and currentScenarios.available and currentScenarios.scenarios or {}
  if #scenarios==0 then line(currentScenarios and currentScenarios.notice or "Current specialization data is unavailable. No browsed-build assumptions are substituted.") end
  slideIndex[mode]=math.min(slideIndex[mode],math.max(1,#scenarios))
  if counter then counter:SetText(slideIndex[mode].." / "..#scenarios) end
  if nextButton then nextButton:SetEnabled(slideIndex[mode]<#scenarios) end
  for index,s in ipairs(scenarios) do
   if index==slideIndex[mode] then
   line(s.title,true)
   line("Switch to this when: "..s.trigger)
   line("Before: "..s.prepare)
   line("Action order",true)
   line(s.react)
   line("Avoid: "..s.avoid)
   if #(s.unavailable or {})>0 then line("Not included: "..table.concat(s.unavailable,", ")) end
   line(currentScenarios.confidence)
   end
  end
 end
 if previous then previous:SetEnabled(slideIndex[mode]>1) end
 for index=used+1,#pool do pool[index]:Hide() end
 scroll:SetVerticalScroll(0)
 content:SetHeight(math.max(800,offset+30))
 end
 previous=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");previous:SetSize(100,26);previous:SetPoint("TOPLEFT",18,-96);previous:SetText("Previous")
 nextButton=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");nextButton:SetSize(100,26);nextButton:SetPoint("TOPLEFT",232,-96);nextButton:SetText("Next")
 counter=parent:CreateFontString(nil,"OVERLAY","GameFontNormal");counter:SetPoint("TOPLEFT",144,-102)
 previous:SetScript("OnClick",function() slideIndex[mode]=math.max(1,slideIndex[mode]-1);draw() end)
 nextButton:SetScript("OnClick",function() slideIndex[mode]=slideIndex[mode]+1;draw() end)
 if mode=="Learn" then
  local talentsButton=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");talentsButton:SetSize(170,26);talentsButton:SetPoint("TOPLEFT",340,-96);talentsButton:SetText("Talents in this build")
  talentsButton:SetScript("OnClick",function()
   mode=mode=="Talents" and "Learn" or "Talents"
   talentsButton:SetText(mode=="Talents" and "Class ability lessons" or "Talents in this build");draw()
  end)
 end
 draw()
 if mode=='Scenarios' then
  local listener=CreateFrame("Frame",nil,parent)
  for _,event in ipairs({"PLAYER_TALENT_UPDATE","TRAIT_CONFIG_UPDATED","ACTIVE_TALENT_GROUP_CHANGED","PLAYER_SPECIALIZATION_CHANGED","SPELLS_CHANGED"}) do pcall(listener.RegisterEvent,listener,event) end
  listener:SetScript("OnEvent",function() if parent:IsShown() then draw() end end)
 end
end
