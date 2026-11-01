local FC=ForeverCoaching
function FC:BuildGearGuidePage(parent)
 local scroll=CreateFrame('ScrollFrame',nil,parent,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',18,-96);scroll:SetPoint('BOTTOMRIGHT',-28,18)
 local content=CreateFrame('Frame',nil,scroll);content:SetSize(490,900);scroll:SetScrollChild(content)
 local offset=0
 local function line(text,title)
  local label=content:CreateFontString(nil,'OVERLAY',title and 'GameFontNormal' or 'GameFontHighlightSmall');label:SetPoint('TOPLEFT',0,-offset);label:SetWidth(480);label:SetJustifyH('LEFT');label:SetText(text);offset=offset+math.max(20,label:GetStringHeight())+12
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
 local link=CreateFrame('EditBox',nil,content,'InputBoxTemplate');link:SetPoint('TOPLEFT',0,-offset);link:SetSize(480,30);link:SetAutoFocus(false);link:SetText(guide.url);link:SetScript('OnEditFocusGained',function(self)self:HighlightText()end);link:SetScript('OnEscapePressed',function(self)self:ClearFocus()end);offset=offset+44
 line('Select the link and press Ctrl+C to copy it.');line(guide.limits)
 content:SetHeight(math.max(900,offset+20))
end
