const fs=require('fs'),path=require('path'),os=require('os');let f;
for(const p of ['tools/preview-runtime/node_modules/fengari',path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){try{f=require(path.resolve(p));break;}catch{}}
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=f,L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(s){if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));
run(`ForeverCoaching={};local factory=CreateFrame
CreateFrame=function(...)
 local frame=factory(...)
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
 frame.GetStringHeight=function(self)return 16*math.ceil(math.max(1,#(self.text or ''))/math.max(1,math.floor((self.width or 100)/7)))end
 return frame
end`);
for(const file of ['UI/ClassicTheme.lua','UI/EncounterLearning.lua','UI/GearGuide.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`local fc=ForeverCoaching;local parent=CreateFrame('Frame');parent:SetSize(730,580)
local doc=fc.ClassicTheme:Document(parent,-136);doc.scroll:SetSize(640,200)
doc:Line(string.rep('Long readable text ',80));doc:Line('Next section',true);doc:Finish()
assert(doc.panel.color[4]==1 and doc.scroll.clipped,'Reading surface must be opaque and clip its viewport')
assert(doc.pool[1].width==640 and doc.pool[1].wrap,'Text must wrap at the viewport width')
assert(doc.pool[2].anchor[3]<-doc.pool[1]:GetStringHeight(),'Next section must follow measured wrapped height')
doc.scroll.scripts.OnMouseWheel(doc.scroll,-1000)
assert(doc.scroll:GetVerticalScroll()==doc.content:GetHeight()-200,'Mouse wheel must reach the end and clamp')
doc.scroll:SetWidth(320);doc.scroll.scripts.OnSizeChanged();assert(doc.pool[1].width==320,'Resizing must reflow text')
doc:Reset();doc:Line('Short');doc:Finish();assert(not doc.pool[2]:IsShown() and doc.scroll:GetVerticalScroll()==0,'Slide changes must hide old rows and reset scrolling')
fc.EncounterCoach={GetBuildContext=function()return {class='ROGUE',id='test',title='Test build',role='damage',talentMatch='Matches'}end,
 RefreshLessons=function()return {{name='Test spell',spellID=1,description=string.rep('Description ',60),when='When',how='How',why='Why',kind='damage'}}end}
fc.SpecScenarios={ForCurrent=function()return {available=true,spec='Test spec',role='damage',contribution='Contribution',basis='Observed',confidence='Confidence',scenarios={{title='Single',trigger='Enemy',prepare='Ready',react=string.rep('Action ',100),avoid='Avoid',steps={{action='Cast test spell',when='Ready',why='Damage'}}}}}end}
fc.BuildPlanner={GetBuilds=function()return {{id='test'}}end,GetBuildEvidenceUrl=function()return 'https://example.com' end}
fc.GearGuide={ForBuild=function()return {title='Gear',importance='Important',available=true,plan='Plan',stats={{name='Stat',why=string.rep('Detail ',80)}},talentNotes={},companion='Companion',steps={'Step'},url='https://example.com',limits='Limits'}end}
fc:BuildEncounterLearningPage(parent,'Learn');fc:BuildEncounterLearningPage(parent,'Scenarios');fc:BuildGearGuidePage(parent)
local scrolls=0
for _,frame in ipairs(TestFrames)do if frame.clipped then scrolls=scrolls+1;assert(frame.child and frame.child:GetHeight()>0);frame:SetSize(600,240);frame.scripts.OnSizeChanged();frame.scripts.OnMouseWheel(frame,-1000);assert(frame:GetVerticalScroll()>=0)end end
assert(scrolls==4,'Shared document must serve Learn, Scenarios and Gear')
print('PASS: opaque reading panels, viewport clipping, measured wrapping, resize reflow, wheel limits, slide reset and all three real page builders.')`);
