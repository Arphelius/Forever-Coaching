local FC=ForeverCoaching
local CreateFrame=FC.CreateLocalizedFrame or CreateFrame
-- Logging and imports belong to the review page, inside its scrolling content.
function FC:BuildWarcraftLogsPanel(parent,width)
 if not self.WarcraftLogs then return end
 local panel=CreateFrame('Frame',nil,parent,'BackdropTemplate')
 panel:SetSize(width,240);panel:SetPoint('TOPLEFT',parent,'TOPLEFT',18,0)
 panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
 panel:SetBackdropColor(.07,.09,.13,.94);panel:SetBackdropBorderColor(.65,.48,.19,.9)
 local function label(value,x,y,w,font)
  local text=panel:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall')
  text:SetPoint('TOPLEFT',x,y);text:SetWidth(w);text:SetJustifyH('LEFT');text:SetText(value);return text
 end
 local title=label('WARCRAFT LOGS',16,-14,width-32,'GameFontNormalLarge')
 title:SetTextColor(1,.78,.3)
 label('Compare your rotation with strong players on the same spec and encounter.',16,-42,width-32)
 label('Open Review-My-Run.cmd, sign in and choose your run. Click Review my run, then type /reload in WoW.',16,-62,width-32)
 local url=CreateFrame('EditBox',nil,panel,'InputBoxTemplate')
 url:SetSize(width-44,20);url:SetPoint('TOPLEFT',22,-96);url:SetAutoFocus(false);url:SetText('http://127.0.0.1:4318/')
 url:SetScript('OnEditFocusGained',function(box)box:HighlightText()end)
 url:SetScript('OnEscapePressed',function(box)box:ClearFocus()end)
 local status=label('',16,-164,width-32);status:SetHeight(30)
 local function button(value,x,y,w,callback,owner)
  local b=CreateFrame('Button',nil,owner or panel,'UIPanelButtonTemplate')
  b:SetSize(w,24);b:SetPoint('TOPLEFT',x,y);b:SetText(value);b:SetScript('OnClick',callback);return b
 end
 local logging=label('',width-198,-17,182);logging:SetJustifyH('RIGHT')
 local function refresh()logging:SetText(FC.WarcraftLogs:GetLogging() and 'File logging: On' or 'File logging: Off')end
 button('Start file logging',16,-126,140,function()local ok,message=FC.WarcraftLogs:SetLogging(true);status:SetText(message);refresh()end)
 button('Stop file logging',164,-126,140,function()local ok,message=FC.WarcraftLogs:SetLogging(false);status:SetText(message);refresh()end)
 button('Previous fight',312,-126,116,function()FC.WarcraftLogs:Select(1);status:SetText('Showing the selected imported fight below.')end)
 button('Next fight',436,-126,108,function()FC.WarcraftLogs:Select(-1);status:SetText('Showing the selected imported fight below.')end)
 button('Local review',552,-126,108,function()FC.CombatReview:SetSource('local');FC:RefreshCombatReview();status:SetText('Showing your local fight observations below.')end)
 local advanced=CreateFrame('Frame',nil,panel);advanced:SetSize(width,144);advanced:SetPoint('TOPLEFT',0,-238);advanced:Hide()
 local advancedLabel=advanced:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');advancedLabel:SetPoint('TOPLEFT',16,-4);advancedLabel:SetText('Manual review import')
 local scroll=CreateFrame('ScrollFrame',nil,advanced,'UIPanelScrollFrameTemplate')
 scroll:SetPoint('TOPLEFT',22,-24);scroll:SetSize(width-62,58)
 local input=CreateFrame('EditBox',nil,scroll)
 input:SetMultiLine(true);input:SetFontObject('ChatFontNormal');input:SetWidth(width-84);input:SetHeight(58);input:SetMaxLetters(60000);input:SetAutoFocus(false)
 scroll:SetScrollChild(input);input:SetScript('OnEscapePressed',function(box)box:ClearFocus()end)
 local import=button('Import review',16,-100,140,function()
  local ok,message=FC.WarcraftLogs:Import(input:GetText());status:SetText(message)
  if ok then input:SetText('') end
 end,advanced)
 local result={frame=panel,height=240,refresh=refresh,input=input,importButton=import,status=status}
 result.advancedButton=button('Advanced import',16,-202,140,function()
  local show=not advanced:IsShown();advanced:SetShown(show);result.height=show and 384 or 240;panel:SetHeight(result.height)
  if FC.RefreshCombatReview then FC:RefreshCombatReview()end
 end)
 panel:SetScript('OnShow',refresh);refresh()
 return result
end
