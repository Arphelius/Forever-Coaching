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
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetSize(width,26);b:SetText(title);b:SetScript('OnClick',click);return b
end
function FC:BuildCustomTalentPage(parent)
 local model=FC.CustomBuilds;local _,class=UnitClass('player');local drafts={}
 local activeID=ForeverCoachingDB and ForeverCoachingDB.activeTalentBuilds and ForeverCoachingDB.activeTalentBuilds[UnitGUID('player')]
 local activeBuild=activeID and model:Find(class,activeID);local draft=activeBuild and model:Draft(activeBuild) or model:New(class)
 local savedButtons,nodes={},{ };local selectedTalent;local deleteArmed=false;local refresh
 local title=text(parent,'Custom Builds',860,16);title:SetPoint('TOPLEFT',14,-10)
 local hint=text(parent,'Left-click to add a point; right-click to remove it. Your click order becomes the leveling order.',860,11);hint:SetPoint('TOPLEFT',14,-34)
 for index,token in ipairs(FC.BuildPlanner.classes)do
  local selectedClass=token
  local b=button(parent,token:sub(1,1)..token:sub(2):lower(),94,function()
   drafts[class]=draft;class=selectedClass;draft=drafts[class] or model:New(class);selectedTalent=nil;deleteArmed=false;refresh()
  end)
  b:SetPoint('TOPLEFT',14+(index-1)*97,-58)
 end
 local library=text(parent,'Saved custom builds',178,12);library:SetPoint('TOPLEFT',14,-98)
 local savedScroll=CreateFrame('ScrollFrame',nil,parent,'UIPanelScrollFrameTemplate');savedScroll:SetPoint('TOPLEFT',14,-124);savedScroll:SetPoint('BOTTOMLEFT',14,82);savedScroll:SetWidth(169)
 local savedList=CreateFrame('Frame',nil,savedScroll);savedList:SetSize(163,1);savedScroll:SetScrollChild(savedList)
 local nameLabel=text(parent,'Build name',90,11);nameLabel:SetPoint('TOPLEFT',207,-98)
 local input=CreateFrame('EditBox',nil,parent,'InputBoxTemplate');input:SetSize(280,24);input:SetPoint('TOPLEFT',282,-94);input:SetAutoFocus(false);input:SetMaxLetters(60)
 input:SetScript('OnTextChanged',function(self)draft.name=self:GetText()end);input:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
 local roleButton=button(parent,'',130,function()
  local roles=model:GetRoles(class);local index=1;for i,role in ipairs(roles)do if role==draft.role then index=i end end;draft.role=roles[index%#roles+1];refresh()
 end);roleButton:SetPoint('TOPLEFT',579,-94)
 local points=text(parent,'',170,12);points:SetPoint('TOPLEFT',723,-100)
 local status=text(parent,'',674,11);status:SetPoint('TOPLEFT',207,-128);status:SetHeight(32)
 local treeScroll=CreateFrame('ScrollFrame',nil,parent,'UIPanelScrollFrameTemplate');treeScroll:SetPoint('TOPLEFT',207,-168);treeScroll:SetPoint('BOTTOMLEFT',207,84);treeScroll:SetWidth(668)
 local trees=CreateFrame('Frame',nil,treeScroll);trees:SetSize(650,500);treeScroll:SetScrollChild(trees)
 local panels={}
 for ti=1,3 do
  local panel=CreateFrame('Frame',nil,trees,'BackdropTemplate');panel:SetPoint('TOPLEFT',(ti-1)*219,0);panel:SetWidth(211);panel:SetHeight(500);surface(panel)
  panel.title=text(panel,'',190,12);panel.title:SetPoint('TOPLEFT',10,-12);panels[ti]=panel
 end
 local selected=text(parent,'',860,10);selected:SetPoint('BOTTOMLEFT',14,49);selected:SetHeight(25)
 local new=button(parent,'New build',163,function()draft=model:New(class);drafts[class]=draft;selectedTalent=nil;deleteArmed=false;refresh()end);new:SetPoint('BOTTOMLEFT',14,12)
 local save=button(parent,'Save custom build',166,function()
  draft.name=input:GetText();local build,err=model:Save(draft)
  if build then refresh();status:SetText('Custom build saved. Select it to enable in-game guidance.')else status:SetText(err)end
 end);save:SetPoint('BOTTOMLEFT',207,12)
 local use=button(parent,'Use this build',154,function()
  if not draft.id then status:SetText('Save this build before selecting it.');return end
  local saved=model:Find(class,draft.id)
  local candidate,err=model:Validate(draft)
  if not candidate or not saved or saved.title~=input:GetText() or #saved.levelingOrder~=#draft.order then status:SetText(err or 'Save your changes before selecting this build.');return end
  for index,pick in ipairs(draft.order)do local step=saved.levelingOrder[index];if pick.treeIndex~=step.treeIndex or pick.talentIndex~=step.talentIndex then status:SetText('Save your changes before selecting this build.');return end end
  if saved.role~=draft.role then status:SetText('Save your changes before selecting this build.');return end
  local build,error=model:Select(class,draft.id)
  if build then refresh();status:SetText('Selected for in-game talent guidance. Open your talent window when a point is available.')else status:SetText(error)end
 end);use:SetPoint('BOTTOMLEFT',386,12)
 local reset=button(parent,'Reset points',137,function()draft.ranks={};draft.order={};selectedTalent=nil;deleteArmed=false;refresh()end);reset:SetPoint('BOTTOMLEFT',553,12)
 local delete=button(parent,'Delete build',169,function()
  if not draft.id then return end
  if not deleteArmed then deleteArmed=true;status:SetText('Press Delete build again to confirm.');return end
  model:Delete(class,draft.id);draft=model:New(class);drafts[class]=draft;deleteArmed=false;refresh();status:SetText('Custom build deleted.')
 end);delete:SetPoint('BOTTOMLEFT',703,12)
 refresh=function()
  for _,b in ipairs(savedButtons)do b:Hide()end
  for index,build in ipairs(model:List(class))do
   local b=savedButtons[index]
   if not b then b=button(savedList,'',161,function()end);b:SetHeight(42);savedButtons[index]=b end
   local savedBuild=build;b:ClearAllPoints();b:SetPoint('TOPLEFT',0,-(index-1)*48);b:SetText(build.title)
   b:SetScript('OnClick',function()draft=model:Draft(savedBuild);drafts[class]=draft;selectedTalent=nil;deleteArmed=false;refresh()end);b:Show()
  end
  savedList:SetHeight(math.max(1,#model:List(class)*48));input:SetText(draft.name);roleButton:SetText('Role: '..draft.role)
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
     b=CreateFrame('Button',nil,panel,'BackdropTemplate');b:SetSize(37,37);b:RegisterForClicks('LeftButtonUp','RightButtonUp')
     b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('TOPLEFT',3,-3);b.icon:SetPoint('BOTTOMRIGHT',-3,3)
     b.rank=text(b,'',46,10);b.rank:SetPoint('BOTTOMRIGHT',7,-7);b.rank:SetJustifyH('RIGHT');nodes[nodeIndex]=b
    end
    local treeIndex,talentIndex,talent=ti,ni,node;local rank=draft.ranks[ti..':'..ni] or 0
    b:SetParent(panel);b:ClearAllPoints();b:SetPoint('TOPLEFT',12+node.col*47,-44-node.row*47);surface(b,rank>0)
    local texture=C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(node.spellId) or (GetSpellTexture and GetSpellTexture(node.spellId))
    b.icon:SetTexture(texture or 'Interface\\Icons\\INV_Misc_QuestionMark');b.icon:SetDesaturated(rank==0);b.rank:SetText(rank..'/'..node.maxRank)
    b:SetScript('OnClick',function(_,mouse)
     local result,error=model:Change(draft,treeIndex,talentIndex,mouse=='RightButton' and -1 or 1)
     if result then selectedTalent={treeIndex=treeIndex,talentIndex=talentIndex};deleteArmed=false;refresh()else status:SetText(error)end
    end)
    b:SetScript('OnEnter',function(self)
     GameTooltip:SetOwner(self,'ANCHOR_RIGHT');if GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(talent.spellId)else GameTooltip:SetText(talent.name)end
     GameTooltip:AddLine((FC.Text and FC:Text('Build allocation:') or 'Build allocation:')..' '..(draft.ranks[treeIndex..':'..talentIndex] or 0)..'/'..talent.maxRank,1,.76,.32)
     GameTooltip:AddLine(FC.Text and FC:Text('Left-click: add. Right-click: remove.') or 'Left-click: add. Right-click: remove.',.8,.8,.8);GameTooltip:Show()
    end);b:SetScript('OnLeave',function()GameTooltip:Hide()end);b:Show()
    height=math.max(height,100+node.row*47)
   end
  end
  trees:SetHeight(height);for _,p in ipairs(panels)do p:SetHeight(height)end
 end
 parent:HookScript('OnShow',refresh);refresh()
end
