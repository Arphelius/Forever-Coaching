local FC=ForeverCoaching
local CreateFrame=FC.CreateLocalizedFrame or CreateFrame
-- Logging and imports belong to the review page, inside its scrolling content.
function FC:BuildWarcraftLogsPanel(parent,width)
 if not self.WarcraftLogs then return end
 local panel=CreateFrame('Frame',nil,parent,'BackdropTemplate')
 panel:SetSize(width,340);panel:SetPoint('TOPLEFT',parent,'TOPLEFT',18,0)
 panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
 panel:SetBackdropColor(.07,.09,.13,.94);panel:SetBackdropBorderColor(.65,.48,.19,.9)
 local function label(value,x,y,w,font)
  local text=panel:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall')
  text:SetPoint('TOPLEFT',x,y);text:SetWidth(w);text:SetJustifyH('LEFT');text:SetText(value);return text
 end
 local title=label('WARCRAFT LOGS',16,-14,width-32,'GameFontNormalLarge')
 title:SetTextColor(1,.78,.3)
 label('Compare your rotation with strong players on the same spec and encounter.',16,-42,width-32)
 label('Upload and peer analysis happen outside WoW. Import the analyzed review for strengths, rotation differences and next-pull practice.',16,-62,width-32)
 local url=CreateFrame('EditBox',nil,panel,'InputBoxTemplate')
 url:SetSize(width-44,20);url:SetPoint('TOPLEFT',22,-96);url:SetAutoFocus(false);url:SetText(self.WarcraftLogs.url)
 url:SetScript('OnEditFocusGained',function(box)box:HighlightText()end)
 url:SetScript('OnEscapePressed',function(box)box:ClearFocus()end)
 local status=label('',16,-164,width-32);status:SetHeight(30)
 local function button(value,x,y,w,callback)
  local b=CreateFrame('Button',nil,panel,'UIPanelButtonTemplate')
  b:SetSize(w,24);b:SetPoint('TOPLEFT',x,y);b:SetText(value);b:SetScript('OnClick',callback);return b
 end
 local logging=label('',width-198,-17,182);logging:SetJustifyH('RIGHT')
 local function refresh()logging:SetText(FC.WarcraftLogs:GetLogging() and 'File logging: On' or 'File logging: Off')end
 button('Start file logging',16,-126,140,function()local ok,message=FC.WarcraftLogs:SetLogging(true);status:SetText(message);refresh()end)
 button('Stop file logging',164,-126,140,function()local ok,message=FC.WarcraftLogs:SetLogging(false);status:SetText(message);refresh()end)
 button('Previous fight',312,-126,116,function()FC.WarcraftLogs:Select(1);status:SetText('Showing the selected imported fight below.')end)
 button('Next fight',436,-126,108,function()FC.WarcraftLogs:Select(-1);status:SetText('Showing the selected imported fight below.')end)
 button('Local review',552,-126,108,function()FC.CombatReview:SetSource('local');FC:RefreshCombatReview();status:SetText('Showing your local fight observations below.')end)
 label('Paste analyzed review',16,-202,width-32)
 local scroll=CreateFrame('ScrollFrame',nil,panel,'UIPanelScrollFrameTemplate')
 scroll:SetPoint('TOPLEFT',22,-224);scroll:SetSize(width-62,58)
 local input=CreateFrame('EditBox',nil,scroll)
 input:SetMultiLine(true);input:SetFontObject('ChatFontNormal');input:SetWidth(width-84);input:SetHeight(58);input:SetMaxLetters(60000);input:SetAutoFocus(false)
 scroll:SetScrollChild(input);input:SetScript('OnEscapePressed',function(box)box:ClearFocus()end)
 local import=button('Import review',16,-300,140,function()
  local ok,message=FC.WarcraftLogs:Import(input:GetText());status:SetText(message)
  if ok then input:SetText('') end
 end)
 label('Imported fights are separate from the latest local fight.',170,-307,width-190)
 panel:SetScript('OnShow',refresh);refresh()
 return {frame=panel,height=340,refresh=refresh,input=input,importButton=import,status=status}
end
