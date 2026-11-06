local FC=ForeverCoaching
local CreateFrame=FC.CreateLocalizedFrame or CreateFrame
local window
function FC:OpenWarcraftLogs()
 if not self.WarcraftLogs then return end
 if not window then
  window=CreateFrame('Frame','ForeverCoachingWarcraftLogs',UIParent,'BasicFrameTemplateWithInset')
  window:SetSize(680,480);window:SetPoint('CENTER');window:SetFrameStrata('DIALOG')
  if window.TitleText then window.TitleText:SetText('Warcraft Logs / Combat Review') end
  local function label(value,x,y,width)
   local text=window:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');text:SetPoint('TOPLEFT',x,y);text:SetWidth(width);text:SetJustifyH('LEFT');text:SetText(value);return text
  end
  label('1. Start recording before the pull. 2. Upload your log using a method supported by Warcraft Logs. 3. Paste the analyzed review below. Logging alone does not upload your file.',18,-38,640)
  local url=CreateFrame('EditBox',nil,window,'InputBoxTemplate');url:SetSize(620,22);url:SetPoint('TOPLEFT',24,-88);url:SetAutoFocus(false);url:SetText(self.WarcraftLogs.url);url:SetScript('OnEditFocusGained',function(box)box:HighlightText()end);url:SetScript('OnEscapePressed',function(box)box:ClearFocus()end)
  local status=label('',18,-148,640)
  local function button(value,x,y,width,callback)
   local b=CreateFrame('Button',nil,window,'UIPanelButtonTemplate');b:SetSize(width,24);b:SetPoint('TOPLEFT',x,y);b:SetText(value);b:SetScript('OnClick',callback);return b
  end
  button('Start file logging',18,-118,145,function()local ok,message=FC.WarcraftLogs:SetLogging(true);status:SetText(message)end)
  button('Stop file logging',170,-118,145,function()local ok,message=FC.WarcraftLogs:SetLogging(false);status:SetText(message)end)
  label('Paste the FCWCL1 review code produced by the Warcraft Logs analysis tool. A URL or raw combat log is not an analysis report.',18,-180,640)
  local scroll=CreateFrame('ScrollFrame',nil,window,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',22,-220);scroll:SetPoint('BOTTOMRIGHT',-38,104)
  local input=CreateFrame('EditBox',nil,scroll);input:SetMultiLine(true);input:SetFontObject('ChatFontNormal');input:SetWidth(600);input:SetMaxLetters(60000);input:SetAutoFocus(false);scroll:SetScrollChild(input)
  input:SetScript('OnEscapePressed',function(box)box:ClearFocus()end)
  button('Import review',18,-388,118,function()local ok,message=FC.WarcraftLogs:Import(input:GetText());status:SetText(message);if ok then input:SetText('') end end)
  button('Previous fight',142,-388,118,function()FC.WarcraftLogs:Select(1);status:SetText('Selected an imported fight. Close this window to read Combat Review.')end)
  button('Next fight',266,-388,118,function()FC.WarcraftLogs:Select(-1);status:SetText('Selected an imported fight. Close this window to read Combat Review.')end)
  button('Local review',390,-388,118,function()FC.CombatReview:SetSource('local');FC:RefreshCombatReview();window:Hide()end)
  button('Close',514,-388,118,function()window:Hide()end)
  label('Detailed website results arrive only after upload and import. Imported fights stay separate from the latest local fight. API secrets never belong in this window.',18,-428,640)
  window:SetScript('OnShow',function()status:SetText(FC.WarcraftLogs:GetLogging() and 'File logging is enabled.' or 'File logging is disabled.')end)
 end
 window:Show()
end
