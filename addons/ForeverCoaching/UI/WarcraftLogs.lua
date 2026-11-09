local FC=ForeverCoaching
local CreateFrame=FC.CreateLocalizedFrame or CreateFrame

function FC:BuildOptimizationPage(parent)
 local W=self.WarcraftLogs;local Theme=self.ClassicTheme;local M=Theme.METRICS
 local document=Theme:Document(parent,M.documentTop)
 local toolbar=Theme:Toolbar(parent,M.toolbarTop,M.pagePadding)
 local spec=self:GuidePicker(parent,0,0,220,function(key)W:SetPublicSpec(key)end)
 local dungeon=self:GuidePicker(parent,0,0,235,function(key)W:SetPublicEncounter(key)end)
 local encounter=self:GuidePicker(parent,0,0,235,function(key)W:SetPublicSection(key)end)
 toolbar:Add(spec,0);toolbar:Add(dungeon,8);toolbar:Add(encounter,8);toolbar:SetFlexible(encounter,150)
 local view={parent=parent,document=document,specPicker=spec,dungeonPicker=dungeon,sectionPicker=encounter,toolbar=toolbar}
 function view.refresh()
  local model=W:GetOptimizationModel();view.model=model;document:Reset()
  spec:SetOptions(model.specs,model.selectedSpec,'Choose spec')
  dungeon:SetOptions(model.encounters,model.selectedEncounter,'Choose dungeon')
  encounter:SetOptions(model.sections,model.selectedSection,'Choose encounter')
  document:Line(model.notice,false,'caution')
  document:Line(model.metrics,true)
  document:Line(model.status,false,'muted')
  if model.sectionLabel then document:Line(model.sectionLabel,true)end
  for _,row in ipairs(model.rows)do
   if row.totalDamage then
    local total=row.totalDamage;local value=total>=1000000 and string.format('%.1fm',total/1000000) or total>=1000 and string.format('%.1fk',total/1000) or string.format('%.0f',total)
    document:Group('Overall damage and DPS',value..string.format(' dmg - %.0f DPS',row.totalDPS),true)
   end
   if row.meter and #row.meter>0 then document:Meter(row.action,row.meter)else document:Group(row.action,row.reference,true)end
  end
  document:Finish()
 end
 self.optimizationView=view;view.refresh()
 local listener=CreateFrame('Frame',nil,parent)
 for _,event in ipairs({'PLAYER_TALENT_UPDATE','TRAIT_CONFIG_UPDATED','ACTIVE_TALENT_GROUP_CHANGED','PLAYER_SPECIALIZATION_CHANGED'})do pcall(listener.RegisterEvent,listener,event)end
 listener:SetScript('OnEvent',function()if parent:IsShown()then view.refresh()end end)
 return view
end

function FC:BuildWarcraftLogsPanel(parent,width)
 if not self.WarcraftLogs then return end
 local panel=CreateFrame('Frame',nil,parent)
 panel:SetSize(width,160);panel:SetPoint('TOPLEFT',parent,'TOPLEFT',18,0)
 local function text(value,x,y,w,font)
  local label=panel:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall')
  label:SetPoint('TOPLEFT',x,y);label:SetWidth(w);label:SetJustifyH('LEFT');label:SetWordWrap(true);label:SetText(value);return label
 end
 text('Spec',0,-8,math.floor(width*.44),'GameFontNormal')
 local encounterLabel=text('Dungeon',math.floor(width*.46),-8,math.floor(width*.54),'GameFontNormal')
 local result={frame=panel,height=160,comparisonView=true,rows={}}
 local spec=FC:GuidePicker(panel,0,-30,math.floor(width*.44),function(key)local w=FC.WarcraftLogs;if w.GetPublicReportModel then w:SetPublicSpec(key)else w:SetComparisonSpec(key)end end)
 local encounter=FC:GuidePicker(panel,math.floor(width*.46),-30,math.floor(width*.54),function(key)local w=FC.WarcraftLogs;if w.GetPublicReportModel then w:SetPublicEncounter(key)else w:SetComparisonEncounter(key)end end)
 local status=text('',0,-72,width)
 local headers={text('ACTION',0,-112,math.floor(width*.34),'GameFontNormal'),text('YOU',math.floor(width*.36),-112,math.floor(width*.28),'GameFontNormal'),text('100-PARSE PLAYERS',math.floor(width*.67),-112,math.floor(width*.33),'GameFontNormal')}
 local nextHeading=text('NEXT FIGHT',0,-160,width,'GameFontNormal')
 local nextStep=text('',0,-184,width)
 function result.refresh()
  local w=FC.WarcraftLogs;local model=w.GetPublicReportModel and w:GetPublicReportModel() or w:GetComparisonModel();result.model=model;result.metrics=model.metrics
  encounterLabel:SetText(model.rotationView and 'Dungeon' or 'Instance / encounter')
  spec:SetOptions(model.specs,model.selectedSpec,'Choose spec')
  encounter:SetOptions(model.encounters,model.selectedEncounter,'No encounter data')
  status:SetText((model.notice and (model.notice..'\n\n') or '')..model.status)
  headers[1]:SetText(model.rotationView and 'ENCOUNTER' or model.referenceOnly and 'RECORDED SPELL' or 'ACTION')
  headers[1]:SetWidth(math.floor(width*(model.rotationView and .28 or model.referenceOnly and .64 or .34)))
  headers[3]:SetText(model.rotationView and 'OBSERVED ROTATION' or model.referenceOnly and 'RECORDED USES' or model.referenceHeading or 'REFERENCE')
  headers[3]:SetWidth(math.floor(width*(model.rotationView and .68 or .33)))
  for _,header in ipairs(headers)do header:SetShown(model.ready)end
  headers[2]:SetShown(model.ready and not model.referenceOnly)
  local headerTop=92+math.max(20,status:GetStringHeight())
  for column,header in ipairs(headers)do header:ClearAllPoints();header:SetPoint('TOPLEFT',column==1 and 0 or column==2 and math.floor(width*.36) or math.floor(width*(model.rotationView and .32 or .67)),-headerTop)end
  local offset=headerTop+30
  for index,row in ipairs(model.rows)do
   local labels=result.rows[index]
   if not labels then labels={text('',0,0,math.floor(width*.34)),text('',math.floor(width*.36),0,math.floor(width*.28)),text('',math.floor(width*.67),0,math.floor(width*.33))};result.rows[index]=labels end
   local height=0
   for column,value in ipairs({row.action,row.you or '',row.reference})do
    local label=labels[column];label:SetText(value);label:ClearAllPoints()
    if column==1 then label:SetWidth(math.floor(width*(model.rotationView and .28 or model.referenceOnly and .64 or .34)))end
    if column==3 then label:SetWidth(math.floor(width*(model.rotationView and .68 or .33)))end
    label:SetPoint('TOPLEFT',column==1 and 0 or column==2 and math.floor(width*.36) or math.floor(width*(model.rotationView and .32 or .67)),-offset)
    label:SetShown(column~=2 or not model.referenceOnly);height=math.max(height,label:GetStringHeight())
   end
   offset=offset+math.max(28,height)+18
  end
  for index=#model.rows+1,#result.rows do for _,label in ipairs(result.rows[index])do label:Hide()end end
  nextHeading:SetShown(model.ready and model.nextFight~=nil);nextStep:SetShown(model.ready and model.nextFight~=nil)
  if model.nextFight then
   nextHeading:ClearAllPoints();nextHeading:SetPoint('TOPLEFT',0,-offset-12)
   nextStep:SetText(model.nextFight);nextStep:ClearAllPoints();nextStep:SetPoint('TOPLEFT',0,-offset-38)
   offset=offset+58+nextStep:GetStringHeight()
  end
  result.height=model.ready and offset+20 or model.notice and headerTop+20 or 120;panel:SetHeight(result.height)
 end
 result.specPicker=spec;result.encounterPicker=encounter
 result.status=status;result.nextStep=nextStep;result.refresh();return result
end
