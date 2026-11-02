local CreateFrame = ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
local FC=ForeverCoaching
local Theme={};FC.ClassicTheme=Theme
local root='Interface\\AddOns\\ForeverCoaching\\Media\\ClassicTheme\\'
-- One set of sizes for the dashboard, following SimGear Forever's panel: a slim two-row
-- header (title row, then tabs sized to their text), one toolbar row per page, and
-- translucent panels so the background shows while text sits on darker strips.
Theme.METRICS={
 width=820,height=540,gutter=8,headerHeight=56,tabHeight=22,buttonHeight=20,
 pageTop=-10,toolbarTop=-32,documentTop=-60,pagePadding=14,
 contentAlpha=.55,readingAlpha=.82,
}
Theme.MUTED={.85,.83,.78}
-- Widen a button to its label. GetStringWidth can be 0 before the font is ready
-- (and is absent in tests), so fall back to an estimate from the text length.
function Theme:FitButton(button,minimum,padding)
 local label=button.caption or (button.GetFontString and button:GetFontString())
 local width=label and label.GetStringWidth and label:GetStringWidth()
 if type(width)~='number' or width<=0 then
  local text=(label and label.GetText and label:GetText()) or (button.GetText and button:GetText()) or ''
  width=#tostring(text)*7
 end
 button:SetWidth(math.max(minimum or 64,math.ceil(width)+(padding or 24)))
 return button
end
-- A row of widgets placed left to right from their actual widths, so translated
-- labels never push one control on top of the next.
function Theme:Toolbar(parent,y,x)
 local row={parent=parent,y=y,x=x or self.METRICS.pagePadding,widgets={},
  maxRight=self.METRICS.width-2*self.METRICS.gutter-self.METRICS.pagePadding}
 function row:Add(widget,gap,fit)
  if fit then Theme:FitButton(widget,fit) end
  self.widgets[#self.widgets+1]={widget=widget,gap=gap or 6}
  self:Layout()
  return widget
 end
 -- The flexible widget (a picker that cuts its label with "...") gives up width
 -- when the row would run past the content panel, e.g. with longer translations.
 function row:SetFlexible(widget,minimum)self.flex=widget;self.flexWidth=widget:GetWidth();self.flexMinimum=minimum or 120;self:Layout()end
 function row:Layout()
  if self.flex then self.flex:SetWidth(self.flexWidth) end
  for pass=1,2 do
   local offset=self.x
   for index,entry in ipairs(self.widgets) do
    if index>1 then offset=offset+entry.gap end
    local widget=entry.widget
    widget:ClearAllPoints();widget:SetPoint('TOPLEFT',self.parent,'TOPLEFT',offset,self.y)
    offset=offset+(widget:GetWidth() or 0)
   end
   self.right=offset
   if pass==2 or not self.flex or offset<=self.maxRight then break end
   self.flex:SetWidth(math.max(self.flexMinimum,self.flexWidth-(offset-self.maxRight)))
  end
 end
 return row
end
function Theme:Artwork(frame,alpha)
 if not frame.classicArtwork then
  -- BackdropTemplate paints an opaque background above negative BACKGROUND
  -- sublayers. Keep the art above that fill and below content and text.
  local texture=frame:CreateTexture(nil,'BORDER',nil,-2)
  texture:SetPoint('TOPLEFT',5,-5);texture:SetPoint('BOTTOMRIGHT',-5,5)
  texture:SetTexture(root..'ClassicBackdrop.tga');frame.classicArtwork=texture
 end
 frame.classicArtwork:SetAlpha(alpha or .30)
end
-- Controls. One vocabulary on every tab: tabs read as tabs (text + gold underline),
-- dropdowns as dropdowns (field + arrow), buttons as flat bordered buttons. No red
-- panel-button template, so the controls stay small next to the background art.
local WHITE='Interface\\Buttons\\WHITE8X8'
Theme.COLORS={fill={.06,.05,.035,.88},edge={.42,.33,.20},hover={1,.76,.32},gold={1,.76,.32},text={.9,.89,.85}}
local function flat(frame)
 if not frame.SetBackdrop then return end
 frame:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
 local c=Theme.COLORS;frame:SetBackdropColor(c.fill[1],c.fill[2],c.fill[3],c.fill[4]);frame:SetBackdropBorderColor(c.edge[1],c.edge[2],c.edge[3],1)
end
local function edge(frame)
 if not frame.SetBackdropBorderColor then return end
 local c=frame.themeHover and Theme.COLORS.hover or ((frame.themeSelected or frame.themeArrow and frame.themeOpen) and Theme.COLORS.gold or Theme.COLORS.edge)
 frame:SetBackdropBorderColor(c[1],c[2],c[3],1)
end
local function hover(frame)
 frame:HookScript('OnEnter',function(self)self.themeHover=true;edge(self)end)
 frame:HookScript('OnLeave',function(self)self.themeHover=false;edge(self)end)
end
-- Restyle an existing BackdropTemplate button flat (kept for pages that build their own).
function Theme:Button(button)
 flat(button);hover(button)
 return button
end
function Theme:NewButton(parent,label,minimum)
 local b=CreateFrame('Button',nil,parent,'BackdropTemplate')
 b:SetHeight(self.METRICS.buttonHeight)
 b:SetNormalFontObject('GameFontHighlightSmall');b:SetHighlightFontObject('GameFontHighlightSmall');b:SetDisabledFontObject('GameFontDisableSmall')
 flat(b);hover(b)
 b:SetText(label or '')
 if minimum~=false then self:FitButton(b,minimum or 48,18) end
 return b
end
-- Selected (or primary) buttons get a gold border and gold label.
function Theme:SetSelected(button,selected)
 button.themeSelected=selected and true or false;edge(button)
 local label=button.GetFontString and button:GetFontString()
 if label and label.SetTextColor then local c=selected and self.COLORS.gold or self.COLORS.text;label:SetTextColor(c[1],c[2],c[3]) end
end
function Theme:Tab(parent,label)
 local b=CreateFrame('Button',nil,parent)
 b:SetHeight(self.METRICS.tabHeight)
 b:SetNormalFontObject('GameFontHighlight');b:SetHighlightFontObject('GameFontHighlight')
 b:SetText(label or '')
 local glow=b:CreateTexture(nil,'HIGHLIGHT');glow:SetAllPoints(b);glow:SetTexture(WHITE);glow:SetVertexColor(1,.85,.5,.07)
 b.underline=b:CreateTexture(nil,'ARTWORK');b.underline:SetTexture(WHITE);b.underline:SetVertexColor(1,.76,.32,1)
 b.underline:SetPoint('BOTTOMLEFT',6,0);b.underline:SetPoint('BOTTOMRIGHT',-6,0);b.underline:SetHeight(2);b.underline:Hide()
 self:FitButton(b,40,20)
 return b
end
function Theme:SelectTab(tab,selected)
 if selected then tab.underline:Show() else tab.underline:Hide() end
 local label=tab.GetFontString and tab:GetFontString()
 if label and label.SetTextColor then local c=selected and self.COLORS.gold or self.COLORS.text;label:SetTextColor(c[1],c[2],c[3]) end
end
-- A dropdown field: value left-aligned and cut with "...", arrow at the right.
function Theme:Dropdown(parent,width)
 local b=self:NewButton(parent,' ',false)
 b:SetWidth(width or 160);b.themeArrow=true
 local label=b:GetFontString()
 if label and label.ClearAllPoints then
  label:ClearAllPoints();label:SetPoint('LEFT',b,'LEFT',8,0);label:SetPoint('RIGHT',b,'RIGHT',-22,0)
  label:SetJustifyH('LEFT');label:SetWordWrap(false)
 end
 b.arrow=b:CreateTexture(nil,'OVERLAY');b.arrow:SetTexture('Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up')
 b.arrow:SetSize(16,16);b.arrow:SetPoint('RIGHT',b,'RIGHT',-3,0)
 return b
end
function Theme:SetOpen(dropdown,open)dropdown.themeOpen=open and true or false;edge(dropdown)end
-- A pop-up list under a control, always above the dashboard's panels.
function Theme:Menu(owner,width)
 local menu=CreateFrame('Frame',nil,owner,'BackdropTemplate')
 menu:SetPoint('TOPLEFT',owner,'BOTTOMLEFT',0,-2);menu:SetSize(width or owner:GetWidth() or 160,10)
 menu:SetFrameStrata('FULLSCREEN_DIALOG');menu:EnableMouse(true)
 flat(menu);if menu.SetBackdropColor then menu:SetBackdropColor(.035,.03,.02,.98) end
 menu:Hide()
 return menu
end
-- Joined choices (Published / Custom, Dungeons / Leveling / Raids / PvP); the selected one is gold.
function Theme:Segmented(parent,labels,choose)
 local group=CreateFrame('Frame',nil,parent);group.buttons={}
 local x=0
 for index,label in ipairs(labels) do
  local b=self:NewButton(group,label,56)
  b:SetPoint('TOPLEFT',group,'TOPLEFT',x,0);x=x+(b:GetWidth() or 56)-1
  b:SetScript('OnClick',function()group:Select(index);if choose then choose(index)end end)
  group.buttons[index]=b
 end
 group:SetSize(x+1,self.METRICS.buttonHeight)
 function group:Select(selected)
  self.selected=selected
  for index,b in ipairs(self.buttons) do Theme:SetSelected(b,index==selected);if index==selected and b.SetFrameLevel then b:SetFrameLevel((group:GetFrameLevel() or 1)+2) end end
 end
 return group
end
-- Shared document layout: measure wrapped text at the viewport's actual width,
-- and keep all overflow inside a scrollable, opaque reading panel.
function Theme:Document(parent,top)
 local panel=CreateFrame('Frame',nil,parent,'BackdropTemplate')
 panel:SetPoint('TOPLEFT',14,top);panel:SetPoint('BOTTOMRIGHT',-14,14)
 panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
 panel:SetBackdropColor(.035,.028,.02,self.METRICS.readingAlpha);panel:SetBackdropBorderColor(.24,.19,.12,1)
 local scroll=CreateFrame('ScrollFrame',nil,panel,'UIPanelScrollFrameTemplate')
 scroll:SetPoint('TOPLEFT',16,-16);scroll:SetPoint('BOTTOMRIGHT',-30,16)
 if scroll.SetClipsChildren then scroll:SetClipsChildren(true) end
 local content=CreateFrame('Frame',nil,scroll);content:SetSize(480,1);scroll:SetScrollChild(content)
 local doc={panel=panel,scroll=scroll,content=content,rows={},pool={},used=0,dividers={},groups={},groupCount=0}
 function doc:Layout()
  local width=math.max(180,(self.scroll:GetWidth() or 0)>0 and self.scroll:GetWidth() or (parent:GetWidth() or 560)-76)
  self.content:SetWidth(width)
  local offset,dividerCount=0,0
  for _,row in ipairs(self.rows) do
   if row.title and offset>0 then
    offset=offset+10;dividerCount=dividerCount+1
    local divider=self.dividers[dividerCount]
    if not divider then divider=self.content:CreateTexture(nil,'BACKGROUND');divider:SetTexture('Interface\\Buttons\\WHITE8X8');divider:SetVertexColor(.55,.43,.24,.3);self.dividers[dividerCount]=divider end
    divider:ClearAllPoints();divider:SetPoint('TOPLEFT',0,-offset+6);divider:SetSize(width,1);divider:Show()
   end
   local widget=row.widget;widget:ClearAllPoints();widget:SetPoint('TOPLEFT',0,-offset);widget:SetWidth(width)
   local height=row.height
   if row.group then
    widget.heading:SetWidth(width-28);widget.body:SetWidth(width-28)
    local titleHeight=math.max(20,widget.heading:GetStringHeight())
    widget.body:ClearAllPoints();widget.body:SetPoint('TOPLEFT',14,-12-titleHeight-10)
    height=12+titleHeight+10+math.max(20,widget.body:GetStringHeight())+14
    widget:SetHeight(height)
   end
   offset=offset+(height or math.max(20,widget:GetStringHeight()))+(row.title and 8 or 12)
  end
  for i=dividerCount+1,#self.dividers do self.dividers[i]:Hide() end
  self.content:SetHeight(math.max(1,offset))
 end
 function doc:Reset()self.rows={};self.used=0;self.groupCount=0 end
 function doc:Group(title,body)
  self.groupCount=self.groupCount+1
  local group=self.groups[self.groupCount]
  if not group then
   -- Plain frames and textures avoid extra templates and button states.
   group=CreateFrame('Frame',nil,self.content)
   local fill=group:CreateTexture(nil,'BACKGROUND');fill:SetAllPoints(group);fill:SetTexture('Interface\\Buttons\\WHITE8X8');fill:SetVertexColor(.065,.052,.035,1)
   local edge=group:CreateTexture(nil,'BORDER');edge:SetTexture('Interface\\Buttons\\WHITE8X8');edge:SetPoint('TOPLEFT');edge:SetPoint('BOTTOMLEFT');edge:SetWidth(2);edge:SetVertexColor(.65,.49,.24,1)
   group.heading=group:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');group.heading:SetPoint('TOPLEFT',14,-12);group.heading:SetTextColor(1,.79,.4)
   group.body=group:CreateFontString(nil,'OVERLAY','GameFontHighlight');group.body:SetTextColor(.82,.84,.86)
   for _,label in ipairs({group.heading,group.body}) do
    label:SetWordWrap(true);label:SetJustifyH('LEFT');label:SetJustifyV('TOP');if label.SetNonSpaceWrap then label:SetNonSpaceWrap(true) end
    if label.SetSpacing then label:SetSpacing(2) end
   end
   self.groups[self.groupCount]=group
  end
  group.heading:SetText(title or '');group.body:SetText(body or '');group:Show()
  self.rows[#self.rows+1]={widget=group,group=true}
 end
 function doc:Line(value,title,tone)
  self.used=self.used+1
  local fs=self.pool[self.used] or self.content:CreateFontString(nil,'OVERLAY','GameFontHighlight')
  self.pool[self.used]=fs;fs:Show();fs:SetFontObject(title and 'GameFontNormal' or 'GameFontHighlight')
  if fs.SetSpacing then fs:SetSpacing(2) end
  if tone=='caution' then fs:SetTextColor(1,.55,.3) elseif tone=='muted' then fs:SetTextColor(Theme.MUTED[1],Theme.MUTED[2],Theme.MUTED[3]) elseif title then fs:SetTextColor(1,.76,.32) else fs:SetTextColor(.88,.91,.94) end
  fs:SetWordWrap(true);if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(true) end
  fs:SetJustifyH('LEFT');fs:SetJustifyV('TOP');fs:SetText(value or '')
  self.rows[#self.rows+1]={widget=fs,title=title}
 end
 function doc:AddWidget(widget,height)self.rows[#self.rows+1]={widget=widget,height=height} end
 function doc:Finish()
  for i=self.used+1,#self.pool do self.pool[i]:Hide() end
  for i=self.groupCount+1,#self.groups do self.groups[i]:Hide() end
  self:Layout();self.scroll:SetVerticalScroll(0)
 end
 scroll:SetScript('OnSizeChanged',function()doc:Layout()end)
 scroll:EnableMouseWheel(true)
 scroll:SetScript('OnMouseWheel',function(_,delta)
  local maximum=math.max(0,content:GetHeight()-(scroll:GetHeight() or 0))
  scroll:SetVerticalScroll(math.max(0,math.min(maximum,(scroll:GetVerticalScroll() or 0)-delta*40)))
 end)
 return doc
end
function Theme:Talent(panel,class,index)
 if not panel.classicTalentArt then
  local texture=panel:CreateTexture(nil,'BORDER',nil,-2)
  texture:SetPoint('TOPLEFT',1,-42);texture:SetPoint('BOTTOMRIGHT',-1,1)
  texture:SetAlpha(.65);panel.classicTalentArt=texture
 end
 panel.classicTalentArt:SetTexture(root..class..'-'..index..'.tga')
 if panel.emblem then panel.emblem:Hide() end
end
-- Class icons from the client's character-creation sheet (the same art Talent Builds uses).
local CLASS_SHEET='Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES'
local CLASS_COORDS={WARRIOR={0,.25,0,.25},MAGE={.25,.5,0,.25},ROGUE={.5,.75,0,.25},DRUID={.75,1,0,.25},HUNTER={0,.25,.25,.5},SHAMAN={.25,.5,.25,.5},PRIEST={.5,.75,.25,.5},WARLOCK={.75,1,.25,.5},PALADIN={0,.25,.5,.75}}
Theme.CLASS_SHEET=CLASS_SHEET
function Theme:ClassCoords(token)
 return CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token] or CLASS_COORDS[token]
end
function Theme:SetClassIcon(texture,token)
 local coords=self:ClassCoords(token)
 if not coords then texture:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark');texture:SetTexCoord(0,1,0,1);return false end
 texture:SetTexture(CLASS_SHEET);texture:SetTexCoord((unpack or table.unpack)(coords));texture:SetVertexColor(1,1,1,1)
 return true
end
