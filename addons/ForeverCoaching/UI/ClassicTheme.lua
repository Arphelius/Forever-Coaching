local CreateFrame = ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
local FC=ForeverCoaching
local Theme={};FC.ClassicTheme=Theme
local root='Interface\\AddOns\\ForeverCoaching\\Media\\ClassicTheme\\'
-- One set of sizes for the dashboard, following SimGear Forever's panel: a slim two-row
-- header (title row, then tabs sized to their text), one toolbar row per page, and
-- translucent panels so the background shows while text sits on darker strips.
Theme.METRICS={
 width=940,height=620,gutter=8,headerHeight=62,tabHeight=22,buttonHeight=22,
 pageTop=-10,toolbarTop=-34,documentTop=-66,pagePadding=14,
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
function Theme:Button(button)
 button:SetNormalTexture('Interface\\Buttons\\UI-Panel-Button-Up')
 button:SetPushedTexture('Interface\\Buttons\\UI-Panel-Button-Down')
 button:SetHighlightTexture('Interface\\Buttons\\UI-Panel-Button-Highlight','ADD')
 for _,method in ipairs({'GetNormalTexture','GetPushedTexture','GetHighlightTexture'})do
  local texture=button[method] and button[method](button)
  if texture then texture:SetTexCoord(0,.625,0,.6875) end
 end
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
