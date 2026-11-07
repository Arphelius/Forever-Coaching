local FC=ForeverCoaching
local CreateFrame=FC.CreateLocalizedFrame or CreateFrame
-- Warcraft Logs is the analysis destination. In-game controls provide copyable
-- links and display already supplied snapshots; they do not embed the website.
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
 label('Your reports and 100-parse references, with Warcraft Logs handling the report analysis.',16,-42,width-32)
 label('Save your report link once. Select a link below and press Ctrl+C to view it in your browser.',16,-62,width-32)
 local url=CreateFrame('EditBox',nil,panel,'InputBoxTemplate')
 url:SetSize(width-44,20);url:SetPoint('TOPLEFT',22,-96);url:SetAutoFocus(false);url:SetText(self.WarcraftLogs:GetReportURL())
 url:SetScript('OnEditFocusGained',function(box)box:HighlightText()end)
 url:SetScript('OnEscapePressed',function(box)box:ClearFocus()end)
 local status=label('',16,-196,width-32);status:SetHeight(30)
 local function button(value,x,y,w,callback,owner)
  local b=CreateFrame('Button',nil,owner or panel,'UIPanelButtonTemplate')
  b:SetSize(w,24);b:SetPoint('TOPLEFT',x,y);b:SetText(value);b:SetScript('OnClick',callback);return b
 end
 local logging=label('',width-198,-17,182);logging:SetJustifyH('RIGHT')
 local function refresh()
  logging:SetText(FC.WarcraftLogs:GetLogging() and 'File logging: On' or 'File logging: Off')
  if not url.HasFocus or not url:HasFocus()then url:SetText(FC.WarcraftLogs:GetReportURL())end
 end
 local function selectLink(link,message)url:SetText(link);url:HighlightText();url:SetFocus();status:SetText(message)end
 local save=button('Save report',16,-126,116,function()
  local ok,message=FC.WarcraftLogs:SaveReportURL(url:GetText());status:SetText(message)
  if ok then url:SetText(FC.WarcraftLogs:GetReportURL());if FC.RefreshCombatReview then FC:RefreshCombatReview()end end
 end)
 local report=button('Your report',140,-126,116,function()selectLink(FC.WarcraftLogs:GetReportURL(),'Press Ctrl+C, then paste the link into your browser.')end)
 local references=button('100-parse references',264,-126,156,function()
  local link=FC.WarcraftLogs:GetReferenceURL()
  selectLink(link or FC.WarcraftLogs.url,link and 'This reference is labeled 100 percentile in the supplied snapshot. Verify its context on Warcraft Logs.' or 'Choose a verified 100 parse on Warcraft Logs for the same spec, encounter and difficulty.')
 end)
 button('Warcraft Logs',428,-126,132,function()selectLink(FC.WarcraftLogs.url,'Press Ctrl+C, then paste the website address into your browser.')end)
 button('Start file logging',16,-160,140,function()local ok,message=FC.WarcraftLogs:SetLogging(true);status:SetText(message);refresh()end)
 button('Stop file logging',164,-160,140,function()local ok,message=FC.WarcraftLogs:SetLogging(false);status:SetText(message);refresh()end)
 button('Previous review',312,-160,116,function()FC.WarcraftLogs:Select(1);status:SetText('Showing the selected supplied snapshot below.');refresh()end)
 button('Next review',436,-160,108,function()FC.WarcraftLogs:Select(-1);status:SetText('Showing the selected supplied snapshot below.');refresh()end)
 local result={frame=panel,height=240,refresh=refresh,url=url,saveButton=save,reportButton=report,referencesButton=references,status=status}
 panel:SetScript('OnShow',refresh);refresh()
 return result
end
