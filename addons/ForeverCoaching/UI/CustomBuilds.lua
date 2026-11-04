local FC=ForeverCoaching
local CreateFrame=FC.CreateLocalizedFrame or CreateFrame
local GOLD={1,.76,.32}
local function text(parent,value,width,size)
 local label=parent:CreateFontString(nil,'OVERLAY','GameFontHighlight');label:SetWidth(width);label:SetJustifyH('LEFT');label:SetWordWrap(true);label:SetText(value);if size then label:SetFont('Fonts\\FRIZQT__.TTF',size,'')end;return label
end
local function surface(frame,active)
 frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
 frame:SetBackdropColor(.035,.043,.055,.98);frame:SetBackdropBorderColor(active and 1 or .22,active and .76 or .24,active and .32 or .27,1)
end
local function button(parent,title,width,click)
 local Theme=FC.ClassicTheme
 local b
 if Theme then b=Theme:NewButton(parent,title,width or 64) else b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetSize(width or 100,22);b:SetText(title) end
 b:SetScript('OnClick',click);return b
end
-- Layout (fits the 804px content panel): class dropdown, build name, role and points on one
-- row; saved builds on the left; the three trees on the right; actions in one footer row.
local PAD,LEFT_W,GAP=14,168,18
local RIGHT_X=PAD+LEFT_W+GAP
local RIGHT_W=804-RIGHT_X-PAD
local TREE_W,TREE_STEP,NODE_X,NODE_Y=186,191,43,42
function FC:BuildCustomTalentPage(parent)
 local model=FC.CustomBuilds;local _,class=UnitClass('player');local drafts={}
 if FC.GuideBrowser and FC.GuideBrowser.class then class=FC.GuideBrowser.class end
 local activeID=ForeverCoachingDB and ForeverCoachingDB.activeTalentBuilds and ForeverCoachingDB.activeTalentBuilds[UnitGUID('player')]
 local activeBuild=activeID and model:Find(class,activeID);local draft=activeBuild and model:Draft(activeBuild) or model:New(class)
 local savedButtons,nodes={},{ };local selectedTalent;local deleteArmed=false;local refresh
 local hint=text(parent,'Left-click to add a point; right-click to remove it. Your click order becomes the leveling order.',776,10);hint:SetPoint('TOPLEFT',PAD,-2);hint:SetWordWrap(false)
 hint:SetTextColor(.85,.83,.78)
 local function chooseClass(selectedClass)
  drafts[class]=draft;class=selectedClass;draft=drafts[class] or model:New(class);selectedTalent=nil;deleteArmed=false;refresh()
  if FC.GuideBrowser then FC.GuideBrowser.class=class;FC.GuideBrowser.buildID=nil end
 end
 local classPicker
 if FC.GuidePicker and FC.ClassicTheme then
  classPicker=self:GuidePicker(parent,PAD,-20,LEFT_W-20,chooseClass)
 else
  for index,token in ipairs(FC.BuildPlanner.classes)do
   local selectedClass=token
   local b=button(parent,token:sub(1,1)..token:sub(2):lower(),60,function()chooseClass(selectedClass)end)
   b:SetPoint('TOPLEFT',PAD+(index-1)*64,-20)
  end
 end
 local nameLabel=text(parent,'Build name',80,11);nameLabel:SetPoint('TOPLEFT',RIGHT_X,-24);nameLabel:SetWordWrap(false)
 local input=CreateFrame('EditBox',nil,parent,'InputBoxTemplate');input:SetSize(220,20);input:SetPoint('TOPLEFT',RIGHT_X+84,-20);input:SetAutoFocus(false);input:SetMaxLetters(60)
 input:SetScript('OnTextChanged',function(self)draft.name=self:GetText()end);input:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
 local roleButton=button(parent,'Role: damage',96,function()
  local roles=model:GetRoles(class);local index=1;for i,role in ipairs(roles)do if role==draft.role then index=i end end;draft.role=roles[index%#roles+1];refresh()
 end);roleButton:SetPoint('TOPLEFT',RIGHT_X+316,-20)
 local points=text(parent,'',110,11);points:SetPoint('TOPRIGHT',parent,'TOPRIGHT',-PAD,-24);points:SetJustifyH('RIGHT')
 local library=text(parent,'Saved custom builds',LEFT_W,10);library:SetPoint('TOPLEFT',PAD,-50);library:SetTextColor(.85,.83,.78)
 local savedScroll=CreateFrame('ScrollFrame',nil,parent,'UIPanelScrollFrameTemplate');savedScroll:SetPoint('TOPLEFT',PAD,-66);savedScroll:SetPoint('BOTTOMLEFT',PAD,34);savedScroll:SetWidth(LEFT_W-20)
 local savedList=CreateFrame('Frame',nil,savedScroll);savedList:SetSize(LEFT_W-22,1);savedScroll:SetScrollChild(savedList)
 local status=text(parent,'',RIGHT_W,11);status:SetPoint('TOPLEFT',RIGHT_X,-48);status:SetHeight(14);status:SetWordWrap(false)
 local selected=text(parent,'',RIGHT_W,10);selected:SetPoint('TOPLEFT',RIGHT_X,-63);selected:SetHeight(13);selected:SetWordWrap(false);selected:SetTextColor(.85,.83,.78)
 local treeScroll=CreateFrame('ScrollFrame',nil,parent,'UIPanelScrollFrameTemplate');treeScroll:SetPoint('TOPLEFT',RIGHT_X,-82);treeScroll:SetPoint('BOTTOMLEFT',RIGHT_X,34);treeScroll:SetWidth(RIGHT_W-22)
 local trees=CreateFrame('Frame',nil,treeScroll);trees:SetSize(RIGHT_W-22,400);treeScroll:SetScrollChild(trees)
 local panels={}
 for ti=1,3 do
  local panel=CreateFrame('Frame',nil,trees,'BackdropTemplate');panel:SetPoint('TOPLEFT',(ti-1)*TREE_STEP,0);panel:SetWidth(TREE_W);panel:SetHeight(400);surface(panel)
  panel.title=text(panel,'',TREE_W-20,12);panel.title:SetPoint('TOPLEFT',10,-10);panel.title:SetWordWrap(false);panels[ti]=panel
 end
 -- Footer: Delete apart on the left; New, Reset, Save and Use (the primary) on the right.
 local delete=button(parent,'Delete build',80,function()
  if not draft.id then return end
  if not deleteArmed then deleteArmed=true;status:SetText('Press Delete build again to confirm.');return end
  model:Delete(class,draft.id);draft=model:New(class);drafts[class]=draft;deleteArmed=false;refresh();status:SetText('Custom build deleted.')
 end);delete:SetPoint('BOTTOMLEFT',PAD,8)
 if FC.WowheadBuilds then
  local dialog=CreateFrame('Frame',nil,parent,'BackdropTemplate');dialog:SetSize(530,152);dialog:SetPoint('CENTER');dialog:SetFrameStrata('FULLSCREEN_DIALOG');surface(dialog);dialog:Hide()
  local title=text(dialog,'',490,12);title:SetPoint('TOPLEFT',16,-14)
  local field=CreateFrame('EditBox',nil,dialog,'InputBoxTemplate');field:SetSize(490,24);field:SetPoint('TOPLEFT',20,-44);field:SetAutoFocus(false);field:SetMaxLetters(2048)
  local message=text(dialog,'',490,10);message:SetPoint('TOPLEFT',16,-78);message:SetHeight(28)
  local confirm
  local close=button(dialog,'Close',70,function()dialog:Hide()end);close:SetPoint('BOTTOMRIGHT',-14,10)
  field:SetScript('OnEscapePressed',function()dialog:Hide()end)
  confirm=button(dialog,'Import link',90,function()
   local imported,err=FC.WowheadBuilds:Import(field:GetText());if not imported then message:SetText(err);return end
   drafts[class]=draft;class=imported.class;draft=imported;drafts[class]=draft;selectedTalent=nil;deleteArmed=false
   if FC.GuideBrowser then FC.GuideBrowser.class=class;FC.GuideBrowser.buildID=nil end
   dialog:Hide();refresh();status:SetText(imported.importSource.orderSuggested and 'Imported allocation. Review the suggested point order, then save.' or 'Imported point order. Review the build, then save.')
  end);confirm:SetPoint('BOTTOMRIGHT',close,'BOTTOMLEFT',-8,0)
  local function currentLink()
   local url,err=FC.WowheadBuilds:Export(draft);if not url then status:SetText(err);message:SetText(err);return end
   field:SetText(url);field:SetFocus();field:HighlightText();return true
  end
  local current=button(dialog,'Wowhead link',110,function()if currentLink()then message:SetText('Press Ctrl+C to copy, then open it in your browser.')end end);current:SetPoint('BOTTOMLEFT',14,10)
  local exchange=button(parent,'Wowhead link',96,function()
   title:SetText('Wowhead Forever calculator');message:SetText('Paste the calculator link. Import creates an editable draft.');confirm:Show();dialog:Show()
   if not currentLink()then field:SetText('');field:SetFocus()end
  end);exchange:SetPoint('LEFT',delete,'RIGHT',8,0)
 end
 local use=button(parent,'Use this build',90,function()
  if not draft.id then status:SetText('Save this build before selecting it.');return end
  local saved=model:Find(class,draft.id)
  local candidate,err=model:Validate(draft)
  if not candidate or not saved or saved.title~=input:GetText() or #saved.levelingOrder~=#draft.order then status:SetText(err or 'Save your changes before selecting this build.');return end
  for index,pick in ipairs(draft.order)do local step=saved.levelingOrder[index];if pick.treeIndex~=step.treeIndex or pick.talentIndex~=step.talentIndex then status:SetText('Save your changes before selecting this build.');return end end
  if saved.role~=draft.role then status:SetText('Save your changes before selecting this build.');return end
  local build,error=model:Select(class,draft.id)
  if build then refresh();status:SetText('Selected for in-game talent guidance. Open your talent window when a point is available.')else status:SetText(error)end
 end);use:SetPoint('BOTTOMRIGHT',parent,'BOTTOMRIGHT',-PAD,8)
 if FC.ClassicTheme then FC.ClassicTheme:SetSelected(use,true) end
 local save=button(parent,'Save custom build',100,function()
  draft.name=input:GetText();local build,err=model:Save(draft)
  if build then refresh();status:SetText('Custom build saved. Select it to enable in-game guidance.')else status:SetText(err)end
 end);save:SetPoint('BOTTOMRIGHT',use,'BOTTOMLEFT',-6,0)
 local reset=button(parent,'Reset points',80,function()draft.ranks={};draft.order={};draft.layoutIssue=nil;selectedTalent=nil;deleteArmed=false;refresh()end);reset:SetPoint('BOTTOMRIGHT',save,'BOTTOMLEFT',-6,0)
 local new=button(parent,'New build',70,function()draft=model:New(class);drafts[class]=draft;selectedTalent=nil;deleteArmed=false;refresh()end);new:SetPoint('BOTTOMRIGHT',reset,'BOTTOMLEFT',-6,0)
 refresh=function()
  for _,b in ipairs(savedButtons)do b:Hide()end
  for index,build in ipairs(model:List(class))do
   local b=savedButtons[index]
   if not b then b=button(savedList,'',LEFT_W-24,function()end);b:SetWidth(LEFT_W-24);b:SetHeight(24);savedButtons[index]=b end
   local savedBuild=build;b:ClearAllPoints();b:SetPoint('TOPLEFT',0,-(index-1)*28);b:SetText(build.title)
   b:SetScript('OnClick',function()draft=model:Draft(savedBuild);drafts[class]=draft;selectedTalent=nil;deleteArmed=false;refresh()end);b:Show()
  end
  savedList:SetHeight(math.max(1,#model:List(class)*28));input:SetText(draft.name);roleButton:SetText('Role: '..draft.role)
  if FC.ClassicTheme then FC.ClassicTheme:FitButton(roleButton,96,18) end
  if classPicker and FC.GuideBrowser then classPicker:SetOptions(FC.GuideBrowser:ClassOptions(),class,'Class') end
  local valid,err=model:Validate(draft,true);points:SetText((valid and valid.points or #draft.order)..' / 51 points')
  status:SetText(err or 'Add points in the order you want to learn them. Saving does not spend in-game points.')
  local guid=UnitGUID('player');local active=ForeverCoachingDB and ForeverCoachingDB.activeTalentBuilds and ForeverCoachingDB.activeTalentBuilds[guid]
  selected:SetText(active==draft.id and draft.id and ('Active custom build: '..draft.name) or 'No changes are applied to your character by this calculator.')
  delete:SetEnabled(draft.id~=nil)
  for _,n in ipairs(nodes)do n:Hide()end
  local nodeIndex,height=0,0
  for ti,tree in ipairs(FC.TalentTrees[class])do
   local panel=panels[ti];panel.title:SetText(tree.name);if FC.ClassicTheme then FC.ClassicTheme:Talent(panel,class,ti)end
   for ni,node in ipairs(tree.nodes)do
    nodeIndex=nodeIndex+1;local b=nodes[nodeIndex]
    if not b then
     b=CreateFrame('Button',nil,panel,'BackdropTemplate');b:SetSize(36,36);b:RegisterForClicks('LeftButtonUp','RightButtonUp')
     b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('TOPLEFT',3,-3);b.icon:SetPoint('BOTTOMRIGHT',-3,3)
     b.rank=text(b,'',46,10);b.rank:SetPoint('BOTTOMRIGHT',7,-7);b.rank:SetJustifyH('RIGHT');nodes[nodeIndex]=b
    end
    local treeIndex,talentIndex,talent=ti,ni,node;local rank=draft.ranks[ti..':'..ni] or 0
    b:SetParent(panel);b:ClearAllPoints();b:SetPoint('TOPLEFT',12+node.col*NODE_X,-40-node.row*NODE_Y);surface(b,rank>0)
    local texture=node.icon or (node.spellId and ((C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(node.spellId)) or (GetSpellTexture and GetSpellTexture(node.spellId))))
    b.icon:SetTexture(texture or 'Interface\\Icons\\INV_Misc_QuestionMark');b.icon:SetDesaturated(rank==0);b.rank:SetText(rank..'/'..node.maxRank)
    b:SetScript('OnClick',function(_,mouse)
     local result,error=model:Change(draft,treeIndex,talentIndex,mouse=='RightButton' and -1 or 1)
     if result then selectedTalent={treeIndex=treeIndex,talentIndex=talentIndex};deleteArmed=false;refresh()else status:SetText(error)end
    end)
    b:SetScript('OnEnter',function(self)
     GameTooltip:SetOwner(self,'ANCHOR_RIGHT');if talent.spellId and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(talent.spellId)else GameTooltip:SetText(talent.name)end
     local reviewed=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[class].talents[talent.name]
     local rank=math.max(1,draft.ranks[treeIndex..':'..talentIndex] or 0)
     if reviewed and reviewed.effects[tostring(rank)] then GameTooltip:AddLine(reviewed.effects[tostring(rank)],.85,.88,.92,true) end
     GameTooltip:AddLine((FC.Text and FC:Text('Build allocation:') or 'Build allocation:')..' '..(draft.ranks[treeIndex..':'..talentIndex] or 0)..'/'..talent.maxRank,1,.76,.32)
     GameTooltip:AddLine(FC.Text and FC:Text('Left-click: add. Right-click: remove.') or 'Left-click: add. Right-click: remove.',.8,.8,.8);GameTooltip:Show()
    end);b:SetScript('OnLeave',function()GameTooltip:Hide()end);b:Show()
    height=math.max(height,92+node.row*NODE_Y)
   end
  end
  trees:SetHeight(height);for _,p in ipairs(panels)do p:SetHeight(height)end
 end
 parent:HookScript('OnShow',refresh);refresh()
end
