// Local-only preview. Executes the bundled catalog and planner in Lua.
const fs=require('fs'),path=require('path'),os=require('os'),http=require('http');
const root=path.resolve(__dirname,'..');
const foreverLogs=require('./foreverlogs-bridge.cjs').createBridge(root);
const startedAt=new Date().toISOString();
let fengari;
for(const location of [path.join(__dirname,'preview-runtime/node_modules/fengari'),path.join(os.tmpdir(),'fc-lua-test-runtime/node_modules/fengari')]){
  try{fengari=require(location);break;}catch{}
}
if(!fengari)throw Error('Lua runtime missing. Run npm install --prefix tools/preview-runtime fengari@0.1.4');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=fengari;
function luaValue(value,depth=0){
 if(depth>12)throw Error('Custom build data is too deeply nested');
 if(value===null||value===undefined)return 'nil';
 if(typeof value==='number'){if(!Number.isFinite(value))throw Error('Invalid number');return String(value);}
 if(typeof value==='boolean')return String(value);
 if(typeof value==='string')return '"'+value.replace(/[\\"\x00-\x1f\x7f]/g,c=>c==='\\'?'\\\\':c==='"'?'\\"':'\\'+c.charCodeAt(0).toString().padStart(3,'0'))+'"';
 if(Array.isArray(value))return '{'+value.map(v=>luaValue(v,depth+1)).join(',')+'}';
 if(typeof value==='object')return '{'+Object.entries(value).map(([k,v])=>'['+luaValue(k)+']='+luaValue(v,depth+1)).join(',')+'}';
 throw Error('Invalid custom build data');
}
function state(params){
  const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
  function run(code){if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));}
  try{
    for(const file of ['Data/LevelingBuilds.lua','Data/Level60Builds.lua','Data/AbilityLessons.lua','Data/ForeverSpellCatalog.lua','Data/TalentLessonEffects.lua','Core/TalentLessons.lua','Data/SpecScenarios.lua','Data/ScenarioActions.lua','Data/CombatSituations.lua','Data/ForeverSpellGuidance.lua','Core/SpecScenarios.lua','Core/GearGuide.lua','Core/BuildPlanner.lua'])run(fs.readFileSync(path.join(root,'addons/ForeverCoaching',file),'utf8'));
    run(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Core/CustomBuilds.lua'),'utf8'));
    run(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Core/GuideSources.lua'),'utf8'));
    run(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Data/WowheadGuideNotes.lua'),'utf8'));
    for(const file of ['Data/WowheadTalentLayouts.lua','Core/WowheadBuilds.lua','Core/ProfessionGuide.lua'])run(fs.readFileSync(path.join(root,'addons/ForeverCoaching',file),'utf8'));
    const effects=fs.readFileSync(path.join(root,'addons/ForeverCoaching/UI/BlizzardTalentGuide.lua'),'utf8');
    // Read the actual effect palettes and spec mapping, without creating WoW frames.
    const themeStart=effects.indexOf('local THEMES={'),themeEnd=effects.indexOf('local theme',themeStart);
    if(themeStart>=0&&themeEnd>themeStart)run(effects.slice(themeStart,themeEnd)+'\nPreviewThemes=THEMES;PreviewSpecThemes=SPEC_THEMES');
    const cls=params.get('class')||'SHAMAN',activity=params.get('activity')||'leveling';
    if(!['DRUID','HUNTER','MAGE','PALADIN','PRIEST','ROGUE','SHAMAN','WARLOCK','WARRIOR'].includes(cls))throw Error('Unknown class');
    if(!['dungeons','leveling','raids','pvp'].includes(activity))throw Error('Unknown activity');
    const integer=(key,fallback,min,max)=>Math.max(min,Math.min(max,Math.floor(Number(params.get(key)||fallback))||fallback));
    const level=integer('level',10,1,60),legacy=integer('legacy',0,0,5),selected=integer('build',0,0,1000);
    const learned=JSON.parse(params.get('learned')||'{}');
    const customText=params.get('custom');
    if(customText){
      if(customText.length>20000)throw Error('Custom build request is too large');
      const draft=JSON.parse(customText);draft.class=cls;delete draft.id;
      if(!draft||typeof draft!=='object'||!Array.isArray(draft.order)||draft.order.length>51)throw Error('Invalid custom point order');
      const change=params.get('customChange')?JSON.parse(params.get('customChange')):null;
      run('PreviewCustom='+luaValue(draft)+';PreviewCustomChange='+luaValue(change));
      const imported=params.get('customImport');if(imported&&imported.length>2048)throw Error('Wowhead link is too long');
      if(imported)run('PreviewWowheadImport='+luaValue(imported));
    }
    const entries=Object.entries(learned).filter(([k,v])=>/^[1-3]:\d+$/.test(k)&&Number.isInteger(v)&&v>=0&&v<=5);
    run(`PreviewClass="${cls}";PreviewActivity="${activity}";PreviewLevel=${level};PreviewLegacy=${legacy};PreviewBuild=${selected};PreviewRanks={${entries.map(([k,v])=>`["${k}"]=${v}`).join(',')}}`);
    const reviewCase=['empty','failed','interrupted','clean'].includes(params.get('reviewCase'))?params.get('reviewCase'):'failed';
    run(`PreviewReviewCase="${reviewCase}"`);
    run(String.raw`
UnitName=function() return "Preview" end
GetRealmName=function() return "Local" end
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
ForeverCoachingDB={reviews={}}
if PreviewReviewCase~='empty' then
 local failures={}
 if PreviewReviewCase=='failed' then failures={{name='Lightning Bolt',clientMessage='Target is out of range.'}}
 elseif PreviewReviewCase=='interrupted' then failures={{name='Lightning Bolt',interrupted=true}} end
 ForeverCoachingDB.reviews[1]={character='Preview-Local',duration=24,casts=6,
  comparedCasts=4,matchedCasts=3,failedAttempts=failures,
  recommendations={{spellID=403,name='Lightning Bolt',situation='damage choice',shortReason='Lightning Bolt was suggested for ranged damage against this target.'}}}
end
`);
    run(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Core/FightRecorder.lua'),'utf8'));
    run(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Core/CombatReview.lua'),'utf8'));
    const demoCase=['responded','missed','wrong-target','hidden'].includes(params.get('coachingCase'))?params.get('coachingCase'):'responded';
    run(`PreviewDemoCase="${demoCase}"`);
    run(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Core/EncounterCoach.lua'),'utf8'));
    run(fs.readFileSync(path.join(__dirname,'preview-encounter.lua'),'utf8'));
    run(fs.readFileSync(path.join(root,'addons/ForeverCoaching/UI/GuideSelectors.lua'),'utf8'));
    run(String.raw`
local fc=ForeverCoaching;local p=fc.BuildPlanner
local choices=p:GetVisibleSpecBuilds(PreviewClass,PreviewActivity,PreviewLevel)
local list={}
for _,c in ipairs(choices) do
 if c.build then list[#list+1]={index=c.index,id=c.build.id,title=c.build.title,spec=c.displayName or c.spec,role=c.build.role,recommended=c.activityRecommended or false,summary=p:GetBuildSummary(c,PreviewActivity,choices),source=p:GetBuildEvidenceUrl(c.build,PreviewClass),allocationSource=c.proofUrl or c.build.source.url} end
end
local build=p:GetBuilds(PreviewClass)[PreviewBuild]
local customResult
if PreviewCustom then
 local model=fc.CustomBuilds;local changeOK,changeError
 if PreviewWowheadImport then
  local imported,err=fc.WowheadBuilds:Import(PreviewWowheadImport)
  if imported and imported.class==PreviewClass then PreviewCustom=imported else changeError=err or 'Choose the same class as the imported Wowhead link.'end
 end
 if PreviewCustomChange then changeOK,changeError=model:Change(PreviewCustom,PreviewCustomChange.treeIndex,PreviewCustomChange.talentIndex,PreviewCustomChange.delta)end
 local valid,validationError=model:Validate(PreviewCustom,true)
 build=nil;local saveError
 if valid and valid.points>0 then build,saveError=model:Save(PreviewCustom)end
 PreviewCustom.id=nil
 customResult={draft=PreviewCustom,points=valid and valid.points or 0,error=changeError or validationError or saveError,valid=build~=nil,roles=model:GetRoles(PreviewClass),wowheadUrl=fc.WowheadBuilds:Export(PreviewCustom)}
end
local specScenarios=fc.SpecScenarios:ForPreview(PreviewClass,build)
local talentLessons={}
if build then for _,talent in ipairs(build.talents or {}) do talentLessons[#talentLessons+1]=fc.TalentLessons:GetLesson(PreviewClass,build,talent) end end
local layout=build and (build.treeLayout or fc.TalentTrees[PreviewClass]) or fc.TalentTrees[PreviewClass]
local ranks,spent,treeSpent={},0,{0,0,0}
for ti,tree in ipairs(layout) do for ni,node in ipairs(tree.nodes) do
 local key=ti..":"..ni;local rank=math.min(node.maxRank,PreviewRanks[key] or 0)
 ranks[key]=rank;spent=spent+rank;treeSpent[ti]=treeSpent[ti]+rank
end end
local budget=math.min(51,math.max(0,PreviewLevel-9+PreviewLegacy))
local order,kind,nextPoint,locked
if build then
 order,kind=p:GetTalentProgression(PreviewClass,build)
 for _,step in ipairs(order or {}) do
  if ranks[step.treeIndex..":"..step.talentIndex]<step.rank then
   nextPoint=step
   locked=treeSpent[step.treeIndex]<layout[step.treeIndex].nodes[step.talentIndex].row*5
   break
  end
 end
end
local totals={0,0,0};local primary=1
for _,talent in ipairs(build and build.talents or {}) do totals[talent.treeIndex]=totals[talent.treeIndex]+talent.rank end
for index=2,3 do if totals[index]>totals[primary] then primary=index end end
local themeName=PreviewSpecThemes and PreviewSpecThemes[PreviewClass] and PreviewSpecThemes[PreviewClass][primary]
local designPreviewPoint
if build and not nextPoint then
 for _,talent in ipairs(build.talents or {}) do
  local tree=layout[talent.treeIndex]
  if talent.treeIndex==primary and tree and tree.nodes[talent.talentIndex] then
   designPreviewPoint={treeIndex=talent.treeIndex,talentIndex=talent.talentIndex}
   break
  end
 end
end
if build and PreviewClass=='DRUID' and build.role=='tank' then themeName='earth' end
if build and PreviewClass=='MAGE' and (build.id or ''):find('frostfire',1,true) then themeName='frostfire' end
local result={custom=customResult,gearGuide=fc.GearGuide:ForBuild(PreviewClass,build,PreviewLevel),specScenarios=specScenarios,talentLessons=talentLessons,coachingReplay=fc.PreviewCoachingReplay,abilityLessons=build and fc.GuideBrowser:LessonsFor(PreviewClass,build) or fc.AbilityLessons[PreviewClass],choices=list,layout=layout,build=build,ranks=ranks,spent=spent,budget=budget,available=math.max(0,budget-spent),overBudget=spent>budget,order=order,orderType=kind,nextPoint=nextPoint,designPreviewPoint=designPreviewPoint,locked=locked or false,level=PreviewLevel,legacy=PreviewLegacy,effect=PreviewThemes and PreviewThemes[themeName],review=fc.CombatReview:GetLatestSummary()}
result.professionGuides={}
result.buildEvidenceUrl=p:GetBuildEvidenceUrl(build,PreviewClass)
for _,goal in ipairs(fc.ProfessionGuide.goals)do result.professionGuides[goal.value]=fc.ProfessionGuide:ForBuild(PreviewClass,build,goal.value)end
local function quote(s)
 return '"'..s:gsub('[%z\1-\31\\"]',function(c)
  if c=='"' then return '\\"' elseif c=='\\' then return '\\\\' end
  return string.format('\\u%04x',string.byte(c))
 end)..'"'
end
local function encode(v)
 if v==nil then return 'null' end
 if type(v)=='boolean' or type(v)=='number' then return tostring(v) end
 if type(v)=='string' then return quote(v) end
 local parts={};local count=0;local array=true
 for k in pairs(v) do count=count+1;if type(k)~='number' then array=false end end
 if array and count>0 and #v==count then
  for _,value in ipairs(v) do parts[#parts+1]=encode(value) end
  return '['..table.concat(parts,',')..']'
 end
 for key,value in pairs(v) do parts[#parts+1]=quote(tostring(key))..':'..encode(value) end
 return '{'..table.concat(parts,',')..'}'
end
PreviewJSON=encode(result)
`);
    lua.lua_getglobal(L,to_luastring('PreviewJSON'));
    return to_jsstring(lua.lua_tostring(L,-1));
  }finally{lua.lua_close(L);}
}
const assets={'/custom-builds.js':'custom-builds.js','/locale-messages.js':'locale-messages.js','/localization.js':'localization.js','/classic-theme.css':'classic-theme.css','/fight-recording.js':'fight-recording.js','/log-statistics.js':'log-statistics.js','/player-logs.js':'player-logs.js','/':'index.html','/encounter-coaching.js':'encounter-coaching.js','/app.js':'app.js','/combat-review.js':'combat-review.js','/effects.js':'effects.js','/border-styles.js':'border-styles.js','/style.css':'style.css','/addon.css':'addon.css'};
http.createServer((req,res)=>{
  res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');
  try{
    const url=new URL(req.url,'http://127.0.0.1');
    if(/^\/classic-theme\/(ClassicBackdrop|(DRUID|HUNTER|MAGE|PALADIN|PRIEST|ROGUE|SHAMAN|WARLOCK|WARRIOR)-[1-3])\.jpg$/.test(url.pathname)){
      res.setHeader('Content-Type','image/jpeg');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/ClassicTheme',path.basename(url.pathname))));return;
    }
    if(url.pathname==='/foreverlogs'){foreverLogs(req,res).catch(()=>{if(!res.headersSent){res.writeHead(500,{'Content-Type':'application/json'});res.end(JSON.stringify({error:'The local review helper could not complete this request.'}));}});return;}
    if(url.pathname==='/health'){res.setHeader('Content-Type','text/plain');res.end('ForeverCoachingPreview');return;}
    if(url.pathname==='/preview-version'){res.setHeader('Content-Type','application/json');res.end(JSON.stringify({version:'encounter-replay-v1',startedAt,pid:process.pid}));return;}
    if(url.pathname==='/simple-borders.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/SimpleBorders.tga')));return;}
    if(url.pathname==='/protection-warrior.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/ProtectionWarrior.tga')));return;}
    if(url.pathname==='/fury.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Fury.tga')));return;}
    if(url.pathname==='/protection-warrior-border.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/ProtectionWarriorBorder.tga')));return;}
    if(url.pathname==='/fury-border.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/FuryBorder.tga')));return;}
    if(url.pathname==='/arms-border.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/ArmsBorder.tga')));return;}
    if(url.pathname==='/arms.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Arms.tga')));return;}
    if(url.pathname==='/destruction.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Destruction.tga')));return;}
    if(url.pathname==='/fel.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Demonology.tga')));return;}
    if(url.pathname==='/affliction.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Affliction.tga')));return;}
    if(url.pathname==='/subtlety.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Subtlety.tga')));return;}
    if(url.pathname==='/combat-blood.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/CombatBlood.tga')));return;}
    if(url.pathname==='/combat-smoke.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/CombatSmoke.tga')));return;}
    if(url.pathname==='/combat.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Combat.tga')));return;}
    if(url.pathname==='/assassination.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Assassination.tga')));return;}
    if(url.pathname==='/shadow-priest.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/ShadowPriest.tga')));return;}
    if(url.pathname==='/holy-priest.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Discipline.tga')));return;}
    if(url.pathname==='/discipline.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/HolyPriest.tga')));return;}
    if(url.pathname==='/frostfire.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Frostfire.tga')));return;}
    if(url.pathname==='/frost.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Frost.tga')));return;}
    if(url.pathname==='/fire.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Fire.tga')));return;}
    if(url.pathname==='/arcane-collapse.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/ArcaneCollapse.tga')));return;}
    if(url.pathname==='/arcane.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Arcane.tga')));return;}
    if(url.pathname==='/restoration-druid.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/RestorationDruid.tga')));return;}
    if(url.pathname==='/feral-tank.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Bear.tga')));return;}
    if(url.pathname==='/feral-fangs.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/FeralFangs.tga')));return;}
    if(url.pathname==='/feral-dps.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Feral.tga')));return;}
    if(url.pathname==='/balance.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Balance.tga')));return;}
    if(url.pathname==='/survival.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Survival.tga')));return;}
    if(url.pathname==='/marksmanship.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/Marksmanship.tga')));return;}
    if(url.pathname==='/beast-mastery.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/BeastMastery.tga')));return;}
    if(url.pathname==='/enhancement-rear.tga'){res.setHeader('Content-Type','application/octet-stream');res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects/EnhancementRear.tga')));return;}
    if(url.pathname==='/enhancement-elements.tga'||url.pathname==='/protection-paladin.tga'||url.pathname==='/retribution.tga'||url.pathname==='/holy-paladin.tga'||url.pathname==='/enhancement.tga'||url.pathname==='/enhancement-intro.tga'||url.pathname==='/elemental.tga'||url.pathname==='/elemental-intro.tga'||url.pathname==='/water.tga'){
      res.setHeader('Content-Type','application/octet-stream');
      const texture={'/enhancement-elements.tga':'EnhancementElements.tga','/protection-paladin.tga':'ProtectionPaladin.tga','/retribution.tga':'Retribution.tga','/holy-paladin.tga':'HolyPaladin.tga','/water.tga':'Restoration.tga','/elemental.tga':'Elemental.tga','/elemental-intro.tga':'ElementalIntro.tga','/enhancement.tga':'Enhancement.tga','/enhancement-intro.tga':'EnhancementIntro.tga'}[url.pathname];
      res.end(fs.readFileSync(path.join(root,'addons/ForeverCoaching/Media/TalentEffects',texture)));return;
    }
    if(url.pathname==='/state'){res.setHeader('Content-Type','application/json; charset=utf-8');res.end(state(url.searchParams));return;}
    const file=assets[url.pathname];if(!file){res.writeHead(404);res.end('Not found');return;}
    res.setHeader('Content-Type',file.endsWith('.js')?'text/javascript':file.endsWith('.css')?'text/css':'text/html; charset=utf-8');
    res.end(fs.readFileSync(path.join(__dirname,'talent-preview',file)));
  }catch(error){res.writeHead(400,{'Content-Type':'application/json'});res.end(JSON.stringify({error:error.message}));}
}).listen(Number(process.env.FC_PREVIEW_PORT||4317),'127.0.0.1',()=>process.stdout.write('Talent preview: http://127.0.0.1:'+Number(process.env.FC_PREVIEW_PORT||4317)+'\n'));
