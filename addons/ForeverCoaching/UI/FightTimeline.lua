local FC=ForeverCoaching
local window,body,heading,coverage,previous,nextButton,counter
local labels={};local page=1;local follow=true
local function draw()
 local fight=FC.FightRecorder:GetLatest();local events=fight and fight.events or {}
 local pages=math.max(1,math.ceil(#events/40));if follow then page=pages end;page=math.min(page,pages)
 heading:SetText(fight and ((FC.FightRecorder.active and 'Recording live' or 'Recorded fight')..' / '..#events..' events') or 'No recorded fight yet')
 coverage:SetText(fight and (fight.coverage..(fight.truncated and ' Storage limit reached; partial timeline.' or '')) or 'Recording starts automatically in combat. Finish a fight, then open this timeline to inspect it.')
 for i=1,40 do
  local event=events[(page-1)*40+i];local label=labels[i]
  if event then
   if not label then label=body:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');label:SetWidth(630);label:SetJustifyH('LEFT');labels[i]=label end
   label:SetText(FC.FightRecorder:Describe(event));label:Show()
  elseif label then label:Hide() end
 end
 local offset=0;for _,label in ipairs(labels) do if label:IsShown() then label:ClearAllPoints();label:SetPoint('TOPLEFT',0,-offset);offset=offset+math.max(22,label:GetStringHeight())+6 end end
 body:SetHeight(math.max(400,offset+20));counter:SetText(page..' / '..pages);previous:SetEnabled(page>1);nextButton:SetEnabled(page<pages)
end
local function export()
 local text=FC.FightRecorder:Export();if not text then return end
 local panel=CreateFrame('Frame',nil,window,'BasicFrameTemplateWithInset');panel:SetSize(650,300);panel:SetPoint('CENTER');panel:SetFrameStrata('TOOLTIP')
 local intro=panel:CreateFontString(nil,'OVERLAY','GameFontNormal');intro:SetPoint('TOPLEFT',16,-30);intro:SetText('Copy this fight JSON into the local preview. Contains character/fight data; no API key.')
 local scroll=CreateFrame('ScrollFrame',nil,panel,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',16,-60);scroll:SetPoint('BOTTOMRIGHT',-32,16)
 local box=CreateFrame('EditBox',nil,scroll);box:SetMultiLine(true);box:SetFontObject('ChatFontNormal');box:SetWidth(590);box:SetMaxLetters(0);box:SetAutoFocus(false);box:SetText(text);box:SetScript('OnEscapePressed',function()panel:Hide()end);scroll:SetScrollChild(box);box:HighlightText();box:SetFocus()
end
function FC:OpenFightTimeline()
 if not self.FightRecorder then return end
 if not window then
  window=CreateFrame('Frame','ForeverCoachingFightTimeline',UIParent,'BasicFrameTemplateWithInset');window:SetSize(700,560);window:SetPoint('CENTER');window:SetMovable(true);window:EnableMouse(true);window:RegisterForDrag('LeftButton');window:SetScript('OnDragStart',window.StartMoving);window:SetScript('OnDragStop',window.StopMovingOrSizing)
  heading=window:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');heading:SetPoint('TOPLEFT',18,-32)
  coverage=window:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');coverage:SetPoint('TOPLEFT',18,-62);coverage:SetWidth(650);coverage:SetJustifyH('LEFT')
  local scroll=CreateFrame('ScrollFrame',nil,window,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',18,-116);scroll:SetPoint('BOTTOMRIGHT',-32,60)
  body=CreateFrame('Frame',nil,scroll);body:SetSize(640,400);scroll:SetScrollChild(body)
  local function button(text,x,callback)local b=CreateFrame('Button',nil,window,'UIPanelButtonTemplate');b:SetSize(110,26);b:SetPoint('BOTTOMLEFT',x,18);b:SetText(text);b:SetScript('OnClick',callback);return b end
  previous=button('Previous',18,function()follow=false;page=math.max(1,page-1);draw();scroll:SetVerticalScroll(0)end)
  nextButton=button('Next',138,function()follow=false;page=page+1;draw();scroll:SetVerticalScroll(0)end)
  button('Latest',258,function()follow=true;draw();scroll:SetVerticalScroll(0)end);button('Export fight',528,export)
  counter=window:CreateFontString(nil,'OVERLAY','GameFontNormal');counter:SetPoint('BOTTOMLEFT',398,24)
  local elapsed=0;window:SetScript('OnUpdate',function(_,delta)elapsed=elapsed+delta;if elapsed>=1 then elapsed=0;draw()end end)
 end
 window:Show();draw()
end
