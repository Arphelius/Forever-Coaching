local FC=ForeverCoaching
local Theme={};FC.ClassicTheme=Theme
local root='Interface\\AddOns\\ForeverCoaching\\Media\\ClassicTheme\\'
function Theme:Artwork(frame,alpha)
 if not frame.classicArtwork then
  local texture=frame:CreateTexture(nil,'BACKGROUND',nil,-6)
  texture:SetPoint('TOPLEFT',5,-5);texture:SetPoint('BOTTOMRIGHT',-5,5)
  texture:SetTexture(root..'ClassicBackdrop.tga');frame.classicArtwork=texture
 end
 frame.classicArtwork:SetAlpha(alpha or .10)
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
function Theme:Talent(panel,class,index)
 if not panel.classicTalentArt then
  local texture=panel:CreateTexture(nil,'BACKGROUND',nil,-6)
  texture:SetPoint('TOPLEFT',1,-42);texture:SetPoint('BOTTOMRIGHT',-1,1)
  texture:SetAlpha(.65);panel.classicTalentArt=texture
 end
 panel.classicTalentArt:SetTexture(root..class..'-'..index..'.tga')
 if panel.emblem then panel.emblem:Hide() end
end
