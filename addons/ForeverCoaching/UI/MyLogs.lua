local FC=ForeverCoaching
local CreateFrame=FC.CreateLocalizedFrame or CreateFrame
function FC:BuildMyLogsPage(parent)
 local Theme=self.ClassicTheme;local M=Theme.METRICS
 local document=Theme:Document(parent,M.documentTop);local toolbar=Theme:Toolbar(parent,M.toolbarTop,M.pagePadding)
 local fight=self:GuidePicker(parent,0,0,240,function(key)FC.MyLogs:SetFight(key)end)
 local spec=self:GuidePicker(parent,0,0,135,function(key)FC.MyLogs:SetSpec(key)end)
 local role=self:GuidePicker(parent,0,0,90,function(key)FC.MyLogs:SetRole(key)end)
 local logging=Theme:NewButton(parent,'Start logging',100);local import=Theme:NewButton(parent,'Import logs',90)
 toolbar:Add(fight,0);toolbar:Add(spec,8);toolbar:Add(role,8);toolbar:Add(logging,8);toolbar:Add(import,8);toolbar:SetFlexible(fight,180)
 local view={parent=parent,document=document,fightPicker=fight,specPicker=spec,rolePicker=role,loggingButton=logging,importButton=import};FC.myLogsView=view
 local function copyBox(value)
  local box=CreateFrame('EditBox',nil,document.content,'InputBoxTemplate');box:SetAutoFocus(false);box:SetHeight(24);box:SetText(value)
  box:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
  box:SetScript('OnEditFocusGained',function(self)self:HighlightText()end)
  return box
 end
 local archon=copyBox('https://www.archon.gg/download')
 local helper=copyBox('Interface\\AddOns\\ForeverCoaching\\Helpers\\Import-MyLogs.cmd')
 function view.refresh()
  local model=FC.MyLogs:GetModel();view.model=model;document:Reset();archon:Hide();helper:Hide()
  fight:SetOptions(model.fights,model.selectedFight,'Choose your recorded fight');spec:SetOptions(model.specs,model.selectedSpec,'Reference spec')
  role:SetOptions(model.roles,model.selectedRole,'Role')
  logging:SetText(FC.WarcraftLogs:GetLogging() and 'Stop logging' or 'Start logging');toolbar:Layout()
  if view.notice then document:Line(view.notice,false,'caution')end
  document:Line(model.message,false,'muted')
  if view.importGuide or not model.ready then
   document:Group('Record and import','1. Select Start logging before your dungeon.\n2. After the run, open your game folder, then Interface > AddOns > ForeverCoaching > Helpers. Double-click Import-MyLogs.cmd.\n3. Type /reload in WoW, then choose your fight and the spec you played here.')
   helper:Show();document:AddWidget(helper,28)
   document:Group('Archon recommended','Install Archon to upload or live-log your runs to Warcraft Logs. Configure combat logging and select the Forever service in Archon. Importing the local file here works separately and needs no Warcraft Logs API credentials. The local helper requires Node.js.')
   archon:Show();document:AddWidget(archon,28)
  else document:Line('Recommended: Archon for logging and uploading your runs. Select Import logs for setup.',false,'muted')end
  if model.ready then
   document:Group('Your fight',model.yourOutput,true)
   if model.missing then document:Line(model.missing,false,'caution')else
    document:Group('Catalog example',model.referenceOutput,true)
    document:Line(model.difficultyNotice,false,'caution')
    document:Line('This is not a verified ranking across every log on Warcraft Logs. Level, gear, talents, group composition and fight conditions affect results. Only recorded direct damage and class-ability counts are compared; pet damage, buff uptime and mechanic decisions are not graded. Trash covers the recorded portion, with pulls separated by 15-second gaps in combat activity.',false,'muted')
    document:Group('What you did well',model.good,true);document:Group('What to review',model.review,true);document:Group('Try next fight',model.next,true)
    document:Group('Class ability use',model.abilityUse,true)
   end
  end
  document:Finish()
 end
 import:SetScript('OnClick',function()view.importGuide=not view.importGuide;view.refresh()end)
 logging:SetScript('OnClick',function()local ok,message=FC.WarcraftLogs:SetLogging(not FC.WarcraftLogs:GetLogging());view.notice=not ok and message or nil;view.refresh()end)
 view.refresh();return view
end
