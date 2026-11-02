local CreateFrame = ForeverCoaching and ForeverCoaching.CreateLocalizedFrame or CreateFrame
local FC=ForeverCoaching
local Theme={};FC.ClassicTheme=Theme
local root='Interface\\AddOns\\ForeverCoaching\\Media\\ClassicTheme\\'
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
 panel:SetBackdropColor(.035,.028,.02,1);panel:SetBackdropBorderColor(.24,.19,.12,1)
 local scroll=CreateFrame('ScrollFrame',nil,panel,'UIPanelScrollFrameTemplate')
 scroll:SetPoint('TOPLEFT',16,-16);scroll:SetPoint('BOTTOMRIGHT',-30,16)
 if scroll.SetClipsChildren then scroll:SetClipsChildren(true) end
 local content=CreateFrame('Frame',nil,scroll);content:SetSize(480,1);scroll:SetScrollChild(content)
 local doc={panel=panel,scroll=scroll,content=content,rows={},pool={},used=0,dividers={}}
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
   offset=offset+(row.height or math.max(20,widget:GetStringHeight()))+(row.title and 8 or 12)
  end
  for i=dividerCount+1,#self.dividers do self.dividers[i]:Hide() end
  self.content:SetHeight(math.max(1,offset))
 end
 function doc:Reset()self.rows={};self.used=0 end
 function doc:Line(value,title)
  self.used=self.used+1
  local fs=self.pool[self.used] or self.content:CreateFontString(nil,'OVERLAY','GameFontHighlight')
  self.pool[self.used]=fs;fs:Show();fs:SetFontObject(title and 'GameFontNormal' or 'GameFontHighlight')
  if fs.SetSpacing then fs:SetSpacing(2) end
  fs:SetWordWrap(true);if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(true) end
  fs:SetJustifyH('LEFT');fs:SetJustifyV('TOP');fs:SetText(value or '')
  self.rows[#self.rows+1]={widget=fs,title=title}
 end
 function doc:AddWidget(widget,height)self.rows[#self.rows+1]={widget=widget,height=height} end
 function doc:Finish()
  for i=self.used+1,#self.pool do self.pool[i]:Hide() end
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
