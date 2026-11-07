local FC=ForeverCoaching
local CreateFrame=FC.CreateLocalizedFrame or CreateFrame

function FC:BuildWarcraftLogsPanel(parent,width)
 if not self.WarcraftLogs then return end
 local panel=CreateFrame('Frame',nil,parent)
 panel:SetSize(width,160);panel:SetPoint('TOPLEFT',parent,'TOPLEFT',18,0)
 local function text(value,x,y,w,font)
  local label=panel:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall')
  label:SetPoint('TOPLEFT',x,y);label:SetWidth(w);label:SetJustifyH('LEFT');label:SetText(value);return label
 end
 text('Spec',0,-8,math.floor(width*.44),'GameFontNormal')
 text('Instance / encounter',math.floor(width*.46),-8,math.floor(width*.54),'GameFontNormal')
 local result={frame=panel,height=160,comparisonView=true,rows={}}
 local spec=FC:GuidePicker(panel,0,-30,math.floor(width*.44),function(key)FC.WarcraftLogs:SetComparisonSpec(key)end)
 local encounter=FC:GuidePicker(panel,math.floor(width*.46),-30,math.floor(width*.54),function(key)FC.WarcraftLogs:SetComparisonEncounter(key)end)
 local status=text('',0,-72,width)
 local headers={text('ACTION',0,-112,math.floor(width*.34),'GameFontNormal'),text('YOU',math.floor(width*.36),-112,math.floor(width*.28),'GameFontNormal'),text('100-PARSE PLAYERS',math.floor(width*.67),-112,math.floor(width*.33),'GameFontNormal')}
 local nextHeading=text('NEXT FIGHT',0,-160,width,'GameFontNormal')
 local nextStep=text('',0,-184,width)
 function result.refresh()
  local model=FC.WarcraftLogs:GetComparisonModel();result.model=model;result.metrics=model.metrics
  spec:SetOptions(model.specs,model.selectedSpec,'Choose spec')
  encounter:SetOptions(model.encounters,model.selectedEncounter,'No encounter data')
  status:SetText(model.status)
  for _,header in ipairs(headers)do header:SetShown(model.ready)end
  local offset=142
  for index,row in ipairs(model.rows)do
   local labels=result.rows[index]
   if not labels then labels={text('',0,0,math.floor(width*.34)),text('',math.floor(width*.36),0,math.floor(width*.28)),text('',math.floor(width*.67),0,math.floor(width*.33))};result.rows[index]=labels end
   local height=0
   for column,value in ipairs({row.action,row.you,row.reference})do
    local label=labels[column];label:SetText(value);label:ClearAllPoints()
    label:SetPoint('TOPLEFT',column==1 and 0 or column==2 and math.floor(width*.36) or math.floor(width*.67),-offset)
    label:Show();height=math.max(height,label:GetStringHeight())
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
  result.height=model.ready and offset+20 or 120;panel:SetHeight(result.height)
 end
 result.specPicker=spec;result.encounterPicker=encounter
 result.status=status;result.nextStep=nextStep;result.refresh();return result
end
