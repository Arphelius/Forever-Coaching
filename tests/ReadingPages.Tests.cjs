const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));
run(`ForeverCoaching={};local factory=CreateFrame
CreateFrame=function(...)
 local frame=factory(...)
 frame.GetFrameLevel=function()return 1 end
 frame.HookScript=function(self,event,callback)self.scripts[event]=callback end
 frame.SetSize=function(self,w,h)self.width=w;self.height=h end
 frame.SetWidth=function(self,w)self.width=w end
 frame.SetHeight=function(self,h)self.height=h end
 frame.SetPoint=function(self,...)self.anchor={...}end
 frame.SetScrollChild=function(self,child)self.child=child end
 frame.SetVerticalScroll=function(self,value)self.scrollOffset=value end
 frame.GetVerticalScroll=function(self)return self.scrollOffset or 0 end
 frame.SetWordWrap=function(self,value)self.wrap=value end
 frame.SetClipsChildren=function(self,value)self.clipped=value end
 frame.SetBackdropColor=function(self,...)self.color={...}end
 frame.SetVertexColor=function(self,...)self.vertex={...}end
 frame.GetStringHeight=function(self)return 16*math.ceil(math.max(1,#(self.text or ''))/math.max(1,math.floor((self.width or 100)/7)))end
 return frame
end`);
for(const file of ['UI/ClassicTheme.lua','UI/GuideSelectors.lua','UI/EncounterLearning.lua','UI/GearGuide.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local parent=CreateFrame('Frame');parent:SetSize(730,580)
local doc=fc.ClassicTheme:Document(parent,-136);doc.scroll:SetSize(640,200)
doc:Line(string.rep('Long readable text ',80));doc:Line('Next section',true);doc:Finish()
assert(doc.panel.color[4]>=0.75 and doc.panel.color[4]<1 and doc.scroll.clipped,'Reading surface must stay readable, let the background show through and clip its viewport')
assert(doc.pool[1].width==640 and doc.pool[1].wrap,'Text must wrap at the viewport width')
assert(doc.pool[2].anchor[3]<-doc.pool[1]:GetStringHeight(),'Next section must follow measured wrapped height')
doc.scroll.scripts.OnMouseWheel(doc.scroll,-1000)
assert(doc.scroll:GetVerticalScroll()==doc.content:GetHeight()-200,'Mouse wheel must reach the end and clamp')
doc.scroll:SetWidth(320);doc.scroll.scripts.OnSizeChanged();assert(doc.pool[1].width==320,'Resizing must reflow text')
doc:Reset();doc:Line('Short');doc:Finish();assert(not doc.pool[2]:IsShown() and doc.scroll:GetVerticalScroll()==0,'Slide changes must hide old rows and reset scrolling')
doc:Reset();doc:Group('1. First action',string.rep('When: a safe opportunity. Why: useful damage. ',30));doc:Group('2. Second action','When: ready. Why: useful.');doc:Finish()
local first,second=doc.groups[1],doc.groups[2]
assert(first.heading.width==doc.scroll:GetWidth()-28 and first.body.width==doc.scroll:GetWidth()-28,'Grouped text must fit inside its panel padding')
assert(first:GetHeight()>=first.heading:GetStringHeight()+first.body:GetStringHeight()+40,'Panel height must include all wrapped text and spacing')
assert(-second.anchor[3]>=first:GetHeight()+12,'Actions must have a visible gap and never overlap')
local oldHeight=first:GetHeight();doc.scroll:SetWidth(200);doc.scroll.scripts.OnSizeChanged();assert(first:GetHeight()>oldHeight,'Narrower panels must grow for wrapping')
doc:Reset();doc:Line('Replacement');doc:Finish();assert(not first:IsShown() and not second:IsShown(),'Changing lessons must hide unused action panels')
fc.EncounterCoach={GetBuildContext=function()return {class='ROGUE',id='test',title='Test build',role='damage',talentMatch='Matches'}end,
 RefreshLessons=function()return {{name='Test spell',spellID=1,description=string.rep('Description ',60),when='When',how='How',why='Why',kind='damage'}}end}
fc.SpecScenarios={ForCurrent=function()return {available=true,spec='Test spec',role='damage',contribution='Contribution',basis='Observed',confidence='Confidence',scenarios={{title='Single',trigger='Enemy',prepare='Ready',react=string.rep('Action ',100),avoid='Avoid',steps={{action='Cast test spell',when='Ready',why='Damage'}}}}}end}
fc.BuildPlanner={classes={'ROGUE'},GetBuilds=function()return {{id='test',title='Test build'}}end,GetBuildEvidenceUrl=function()return 'https://example.com' end}
fc.GearGuide={ForBuild=function()return {title='Gear',importance='Important',available=true,plan='Plan',stats={{name='Stat',why=string.rep('Detail ',80)}},talentNotes={},companion='Companion',steps={'Step'},url='https://example.com',limits='Limits'}end}
fc:BuildEncounterLearningPage(parent,'Learn');fc:BuildEncounterLearningPage(parent,'Scenarios');fc:BuildGearGuidePage(parent)
local scrolls=0
for _,frame in ipairs(TestFrames)do if frame.clipped then scrolls=scrolls+1;assert(frame.child and frame.child:GetHeight()>0);frame:SetSize(600,240);frame.scripts.OnSizeChanged();frame.scripts.OnMouseWheel(frame,-1000);assert(frame:GetVerticalScroll()>=0)end end
assert(scrolls==4,'Shared document must serve Learn, Scenarios and Gear')
print('PASS: readable translucent reading panels, viewport clipping, measured wrapping, resize reflow, wheel limits, slide reset and all three real page builders.')`);
run(`local fc=ForeverCoaching
ForeverCoachingDB={activeTalentBuilds={player='keep-active'}}
fc.BuildPlanner.classes={'ROGUE','MAGE'}
fc.BuildPlanner.GetBuilds=function(_,class)return {{id=class..'-guide',title=class..' specialization',talents={}}}end
fc.SpecScenarios.ForPreview=function(_,class,build)return {available=true,scenarios={
 {title='First scenario',trigger='First condition',prepare='Prepare',steps={{action='First action',when='Ready',why='Useful'}},avoid='Avoid first'},
 {title='Second scenario',trigger='Second condition',prepare='Prepare',steps={{action='Second action',when='Ready',why='Useful'}},avoid='Avoid second'}}}end
local page=CreateFrame('Frame');page:SetSize(730,580);fc:BuildEncounterLearningPage(page,'Scenarios')
local pickers={};for _,frame in ipairs(TestFrames)do if frame.parent==page and frame.guideMenu then pickers[#pickers+1]=frame end end
assert(#pickers==3,'Class, specialization and scenario menus are required')
pickers[1].scripts.OnClick(pickers[1]);local selected
for _,frame in ipairs(TestFrames)do if frame.text=='Mage' and frame.scripts.OnClick and frame:IsShown() then
 assert(frame.icon and frame.icon.pickerIcon and frame.icon.texture:find('UI%-CHARACTERCREATE%-CLASSES') and frame.height==24,'Class menu rows show the class icon beside the name')
 frame.scripts.OnClick(frame);selected=true;break end end
assert(selected and fc.GuideBrowser.class=='MAGE' and pickers[1].text=='Mage','Class menu must browse the requested class without a v suffix')
assert(pickers[2].text:find('MAGE specialization') and pickers[3].text:find('First scenario'),'Class changes must refresh spec and scenario selections')
pickers[3].scripts.OnClick(pickers[3]);selected=false
for _,frame in ipairs(TestFrames)do if frame.text=='Second scenario' and frame.scripts.OnClick and frame:IsShown() then frame.scripts.OnClick(frame);selected=true;break end end
assert(selected and pickers[3].text:find('Second scenario'),'Scenario menu must jump directly to its selected scenario')
assert(ForeverCoachingDB.activeTalentBuilds.player=='keep-active','Guide browsing must never change the active talent allocation')
print('PASS: interactive class/spec/scenario menus, direct scenario selection, refreshed content and isolated live build state.')`);
run(`unpack=unpack or table.unpack;ForeverCoaching.IsTalentVFXEnabled=function()return false end`);
for(const file of ['Data/LocaleMessages.lua','Core/Localization.lua','Data/LevelingBuilds.lua','Data/Level60Builds.lua','Core/BuildPlanner.lua','Data/AbilityLessons.lua','Data/ForeverSpellCatalog.lua','Data/TalentLessonEffects.lua','Core/TalentLessons.lua','Data/SpecScenarios.lua','Data/ScenarioActions.lua','Data/CombatSituations.lua','Data/ForeverSpellGuidance.lua','Core/SpecScenarios.lua','Core/GearGuide.lua','UI/BuildsWindow.lua','Core/CombatReview.lua','ForeverCoaching.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`ForeverCoaching:ToggleWindow()
local navigation={};for _,frame in ipairs(TestFrames)do if frame.navigationIndex then navigation[frame.navigationIndex]=frame end end
for index=1,6 do
 local button=navigation[index];assert(button and button.scripts.OnClick);button.scripts.OnClick(button)
 assert(ForeverCoachingFrame.width==820 and ForeverCoachingFrame.height==540,'Every tab must use the one dashboard size')
 assert(button.parent==navigation[1].parent and button.height==22,'Tabs stay in the header row on every tab')
 -- Toolbar rows: shown widgets at the same top offset must not overlap.
 local rows={}
 for _,frame in ipairs(TestFrames)do
  local a=frame.anchor
  local inside=false;local up=frame.parent;while up do if up==ForeverCoachingFrame then inside=true end;up=up.parent end
  if inside and frame:IsShown() and a and a[1]=='TOPLEFT' and type(a[4])=='number' and type(a[5])=='number' and a[5]==-32 and frame.width then
   local row=rows[a[2]] or {};rows[a[2]]=row;row[#row+1]={x=a[4],w=frame.width}
  end
 end
 for _,row in pairs(rows)do
  table.sort(row,function(p,q)return p.x<q.x end)
  for k=2,#row do assert(row[k].x>=row[k-1].x+row[k-1].w,'Toolbar controls must not overlap') end
  assert(row[#row].x+row[#row].w<=804,'Toolbar must fit inside the content panel')
 end
 local menus,icons=0,0
 for _,frame in ipairs(TestFrames)do if frame:IsShown() then
  if frame.guideMenu then menus=menus+1 end
  if type(frame.texture)=='string' and frame.texture:find('UI%-CHARACTERCREATE%-CLASSES') and not frame.pickerIcon then
   icons=icons+1;assert(frame.vertex and frame.vertex[1]==1 and frame.vertex[2]==1 and frame.vertex[3]==1,'Class icons must keep original colors')
  end
 end end
 if button.text=='Talent Builds' then
  talentChecked=true
  assert(icons==9,'Talent Builds must retain nine original Blizzard class icons')
  -- Nothing on Talent Builds may start or end past the 804px content panel.
  for _,frame in ipairs(TestFrames)do
   local an=frame.anchor
   if frame:IsShown() and an and an[1]=='TOPLEFT' and frame.width then
    local x=type(an[2])=='number' and an[2] or (type(an[4])=='number' and an[4])
    if x then assert(x+frame.width<=804,'Talent Builds widget runs past the panel: x '..x..' + '..frame.width) end
   end
  end
  local choices={};for _,frame in ipairs(TestFrames)do if frame:IsShown() and frame.title and frame.detail and frame.badge and frame.scripts.OnClick then choices[#choices+1]=frame end end
  local squares={}
  for _,choice in ipairs(choices)do
   choice.scripts.OnClick(choice);squares={}
   for _,frame in ipairs(TestFrames)do if frame:IsShown() and frame.levelLabel and frame.icon then squares[#squares+1]=frame end end
   if #squares>0 then break end
  end
  assert(#squares==51,'A complete route must show one square for each of 51 points')
  local occupied={}
  for _,square in ipairs(squares)do
   assert(square.width==40 and square.height==40 and not square.scripts.OnClick,'Progression tiles must be small non-clickable squares')
   assert(square.anchor[2]+40<=square.parent.width,'Squares must remain inside the progression panel')
   assert(tonumber(square.levelLabel.text) and #square.levelLabel.text<=2,'Only the level number belongs inside each square')
   local key=square.anchor[2]..':'..square.anchor[3];assert(not occupied[key],'Progression squares must not overlap');occupied[key]=true
  end
  local tooltipLines={};GameTooltip={SetOwner=function()end,SetText=function(_,value)tooltipLines[#tooltipLines+1]=value end,AddLine=function(_,value)tooltipLines[#tooltipLines+1]=value end,Show=function()end,Hide=function()end}
  squares[1].scripts.OnEnter(squares[1]);assert(table.concat(tooltipLines,' '):find('Level 10'),'Hover must show the point level and talent rank')
 else assert(menus>=2,'Every dashboard section needs class/spec selection')end
end
assert(talentChecked,'The Talent Builds tab must be found by its label')
assert(navigation[1].text=='Talent Builds' and navigation[2].text=='Learn' and navigation[3].text=='Combat Review','Tab order: Talent Builds, Learn, Combat Review, Scenarios, Gear, Resources')
-- Tabs are as wide as their labels and laid out left to right without overlap.
local previousRight=0
for index=1,6 do
 local tab=navigation[index];assert(tab.width>=#(tab.text or '')*7+20,'Tab must be wider than its label')
 previousRight=previousRight+tab.width+2
end
assert(previousRight<=820-130,'All six tabs fit on one header row with room for Language')
-- The Language list belongs to the dashboard (it opened behind it as a separate window).
local languageRow
for _,frame in ipairs(TestFrames)do if frame.text=='Romana' then languageRow=frame end end
local inside=false;local up=languageRow and languageRow.parent;while up do if up==ForeverCoachingFrame then inside=true end;up=up.parent end
assert(inside,'Language menu must be part of the dashboard')
print('PASS: all six real dashboard sections expose selectors in non-overlapping toolbars, one window size, fitted tabs; talent class icons retain their original colors.')`);
run(`local browser=ForeverCoaching.GuideBrowser;local planner=ForeverCoaching.BuildPlanner
browser.activity='raids'
for _,class in ipairs(planner.classes)do
 local expected={}
 for _,choice in ipairs(planner:GetVisibleSpecBuilds(class,'raids',60))do if choice.build then expected[planner:GetBuildDisplayName(class,choice.build)]=true end end
 local seen={};local count=0
 for _,option in ipairs(browser:BuildOptions(class))do
  assert(expected[option.label] and not seen[option.label],'Spec menu must match main Talent Builds choices with no duplicate labels')
  seen[option.label]=true;count=count+1
 end
 local expectedCount=0;for _ in pairs(expected)do expectedCount=expectedCount+1 end
 assert(count==expectedCount,'No main specialization may be lost')
 browser.class=class;browser.buildID='obsolete-build';local _,build=browser:GetContext()
 if count>0 then local present=false;for _,option in ipairs(browser:BuildOptions(class))do if option.value==build.id then present=true end end;assert(present,'Old selections must resolve to a visible main spec')end
end
print('PASS: all nine classes use only unique main Talent Builds choices, preserve hybrid specs and resolve old selections.')`);
run(`local fc=ForeverCoaching;local browser=fc.GuideBrowser
local fingerprints={}
for _,label in ipairs({'Arcane','Fire','Frost'})do
 browser.class='MAGE';browser.buildID=nil
 for _,option in ipairs(browser:BuildOptions('MAGE'))do if option.label==label then browser.buildID=option.value end end
 assert(browser.buildID,'Missing expected Mage spec: '..label)
 local class,build=browser:GetContext();local guide=fc.SpecScenarios:ForPreview(class,build)
 local lessons=browser:LessonsFor(class,build);assert(#lessons>0,'Selected spec needs its own ability lessons')
 local signature={};for _,lesson in ipairs(lessons)do assert(type(lesson.description)=='string' and lesson.description~='','Ability lessons need a real effect');signature[#signature+1]=lesson.name..':'..lesson.when..':'..lesson.description end
 signature=table.concat(signature,'|');assert(not fingerprints[signature],'Mage specs must not all use the same ability list');fingerprints[signature]=true
 assert(guide.spec==label,'Scenario guide must belong to the selected spec')
 local gear=fc.GearGuide:ForBuild(class,build,60);assert(gear.buildId==build.id and gear.spec==label,'Gear must retain the selected allocation and specialization')
 local selectedTalents={};for _,talent in ipairs(build.talents)do selectedTalents[talent.name]=true end
 for _,note in ipairs(gear.talentNotes)do assert(selectedTalents[note.name],'Gear interactions must come from the selected talents')end
end
for _,class in ipairs(fc.BuildPlanner.classes)do for _,option in ipairs(browser:BuildOptions(class))do
 browser.class=class;browser.buildID=option.value;local _,build=browser:GetContext()
 local guide=fc.SpecScenarios:ForPreview(class,build)
 if guide.available then assert(#browser:LessonsFor(class,build)>0,class..' / '..option.label..': missing spec lessons')end
end end
print('PASS: real Arcane/Fire/Frost content differs; scenario and gear identity, allocation-specific interactions and all nine class lesson sets remain tied to selection.')`);
const assert=require('assert'),coaching=require('../tools/talent-preview/encounter-coaching.js');
function el(tag,text){return {tag,text,children:[],append(...items){this.children.push(...items)},replaceChildren(){this.children=[]},setAttribute(){}};}
const panel=el('main'),state={build:{id:'guide',title:'Elemental',role:'damage'},level:60,specScenarios:{available:true,spec:'Elemental',contribution:'REMOVE CONTRIBUTION',basis:'REMOVE BASIS',scenarios:[{title:'Single target',trigger:'One target',prepare:'Ready',steps:[{action:'Cast spell',when:'Safe',why:'Damage'}],avoid:'Unsafe casts'}]}};
coaching.render(panel,state,'scenarios',el);
function texts(node){return [node.text,...node.children.flatMap(texts)].filter(Boolean);}
assert(!texts(panel).includes('REMOVE CONTRIBUTION')&&!texts(panel).includes('REMOVE BASIS'));
assert(texts(panel).includes('Single target')&&texts(panel).includes('Why: Damage'));
console.log('PASS: browser scenario picker and action explanations remain, while the two unwanted introductory paragraphs are removed.');
