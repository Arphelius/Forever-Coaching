local CreateFrame = ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
local FC=ForeverCoaching
function FC:OpenRotationSettings()
 if self.rotationSettings then self.rotationSettings:Show();self.rotationSettings.refresh();return end
 local frame=CreateFrame('Frame','ForeverCoachingRotationSettings',UIParent,'BasicFrameTemplateWithInset')
 frame:SetSize(570,470);frame:SetPoint('CENTER');frame:SetFrameStrata('DIALOG');frame.TitleText:SetText('Live rotation')
 self.rotationSettings=frame
 local function label(text,y)
  local font=frame:CreateFontString(nil,'OVERLAY','GameFontHighlight');font:SetPoint('TOPLEFT',20,y);font:SetWidth(530);font:SetJustifyH('LEFT');font:SetText(text);return font
 end
 label('Four slots: current action is brightest; later icons are conditional forecasts. Empty slots mean there is no reliable forecast.',-40)
 label('Area damage: enable only when every enemy in the area may be hit. Burst: enable for your agreed cooldown window; it resets after combat.',-96)
 local function button(text,x,y,width,command)
  local b=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate');b:SetSize(width,26);b:SetPoint('TOPLEFT',x,y);b:SetText(text)
  b:SetScript('OnClick',function()SlashCmdList.FOREVERCOACHINGROTATION(command);frame.refresh()end);return b
 end
 button('Single target',20,-155,150,'single');button('Area damage allowed',180,-155,180,'aoe')
 button('Use burst window',20,-189,150,'burst on');button('Hold burst cooldowns',180,-189,180,'burst off')
 local status=label('',-227)
 label('Optional items: enter an item ID and assign its actual effect for your current spec/allocation. Only owned/equipped, usable, ready items are shown. Health triggers below 30%; Mana below 20%.',-255)
 local input=CreateFrame('EditBox',nil,frame,'InputBoxTemplate');input:SetSize(90,26);input:SetPoint('TOPLEFT',25,-322);input:SetAutoFocus(false);input:SetNumeric(true)
 input:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
 for i,entry in ipairs({{'Health','health'},{'Mana','mana'},{'Burst','burst'},{'Remove','off'}})do
  local b=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate');b:SetSize(90,26);b:SetPoint('TOPLEFT',125+(i-1)*100,-322);b:SetText(entry[1])
  local trigger=entry[2]
  b:SetScript('OnClick',function()local id=tonumber(input:GetText());if id and id>0 and id==math.floor(id) then SlashCmdList.FOREVERCOACHINGROTATION('item '..id..' '..trigger);input:ClearFocus();frame.refresh()end end)
 end
 local items=label('',-365)
 frame.refresh=function()
  local s=ForeverCoachingDB and ForeverCoachingDB.liveRotation or {}
  status:SetText('Area damage: '..(s.mode=='aoe' and 'allowed' or 'off')..' | Burst: '..(s.burst and 'use now' or 'hold'))
  local scope=FC.LiveRotation:GetItemScope()
  local list={};for id,trigger in pairs(s.items or {})do list[#list+1]=id..' ('..trigger..(s.itemScopes and s.itemScopes[id]~=scope and ', other allocation' or '')..')' end;table.sort(list)
  items:SetText('Configured items: '..(#list>0 and table.concat(list,', ') or 'none'))
 end
 frame:SetScript('OnShow',frame.refresh);frame.refresh()
end
