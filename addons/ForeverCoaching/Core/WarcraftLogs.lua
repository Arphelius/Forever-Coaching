ForeverCoaching=ForeverCoaching or {}
local FC=ForeverCoaching
local W={url='https://forever.warcraftlogs.com/'};FC.WarcraftLogs=W
local function safe(fn,...)
 if not fn then return end
 local ok,value=pcall(fn,...)
 if ok and not (issecretvalue and issecretvalue(value)) then return value end
end
local function saved()
 ForeverCoachingDB=ForeverCoachingDB or {};ForeverCoachingDB.warcraftLogs=ForeverCoachingDB.warcraftLogs or {reviews={}}
 local db=ForeverCoachingDB.warcraftLogs;db.reviews=db.reviews or {};return db
end
function W:LoadCompanionReviews()
 if FC.PublicReportCatalog then return 0 end -- Personal comparisons are paused in public-example mode.
 if safe(UnitAffectingCombat,'player')==true then return end
 local db=saved();db.companionReceipts=db.companionReceipts or {ids={},order={}}
 local receipts=db.companionReceipts
 local imported=0
 -- Files are written oldest to newest; the last successful import is selected.
 for _,entry in ipairs(FC.CompanionReviews or {}) do
  if type(entry)=='table' and type(entry.id)=='string' and #entry.id<=100 and type(entry.code)=='string' and not receipts.ids[entry.id] then
   local ok=self:Import(entry.code,entry.comparison)
   if ok then
    receipts.ids[entry.id]=true;receipts.order[#receipts.order+1]=entry.id;imported=imported+1
    while #receipts.order>100 do receipts.ids[table.remove(receipts.order,1)]=nil end
   end
  end
 end
 if imported>0 then print('Forever Coaching: '..imported..' comparison loaded. Open Optimization.') end
 return imported
end
local companionEvents=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_REGEN_ENABLED'})do pcall(companionEvents.RegisterEvent,companionEvents,event)end
companionEvents:SetScript('OnEvent',function()
 local function load()
  local ok,err=pcall(W.LoadCompanionReviews,W)
  if not ok then ForeverCoachingDB=ForeverCoachingDB or {};ForeverCoachingDB.lastCompanionError=tostring(err)end
 end
 if C_Timer and C_Timer.After then C_Timer.After(1,load) else load()end
end)
local function normalize(value)return tostring(value or ''):lower():gsub('[%s%-%\']','')end
function W:SaveReportURL(value)
 if type(value)~='string' or #value>2048 then return false,'Paste a Forever Warcraft Logs report link.' end
 value=value:match('^%s*(.-)%s*$')
 local code,suffix=value:match('^https://forever%.warcraftlogs%.com/reports/([%w]+)(.*)$')
 if not code or #code~=16 or (suffix~='' and suffix~='/' and not suffix:match('^#') and not suffix:match('^/#')) or value:find('[%c%s|]') then return false,'Use a report link from https://forever.warcraftlogs.com/.' end
 local guid=safe(UnitGUID,'player');if not guid then return false,'Character identity unavailable.' end
 local db=saved();db.reportLinks=db.reportLinks or {};db.reportLinks[guid]=value
 return true,'Report link saved for this character. Select the link and press Ctrl+C to view it in your browser.'
end
function W:GetReportURL()
 local guid=safe(UnitGUID,'player');local db=saved()
 return guid and db.reportLinks and db.reportLinks[guid] or self.url
end
local function selectedReview(self)
 local db=saved();local list=self:GetReviews();local selected=list[1]
 for _,review in ipairs(list)do if db.selected==review.code..':'..review.fight then selected=review;break end end
 local url=self:GetReportURL();local code=url:match('/reports/([%w]+)')
 if code then
  local fight=url:match('[#&]fight=([^&]+)')
  if fight and not fight:match('^%d+$')then return nil end
  if selected and selected.code==code and (not fight or selected.fight==tonumber(fight))then return selected end
  for _,review in ipairs(list)do if review.code==code and (not fight or review.fight==tonumber(fight))then return review end end
  return nil
 end
 return selected
end
local function referenceLinks(review)
 local links,seen={},{}
 for line in (review.references or ''):gmatch('[^\n]+') do
  if not line:match(' / 100 percentile$') then return {},false end
  local link,code=line:match('^(https://forever%.warcraftlogs%.com/reports/([%w]+)#fight=%d+&source=%d+)%s')
  if not link or #code~=16 then return {},false end
  if not seen[link] then seen[link]=true;links[#links+1]=link end
 end
 return links,#links>=3
end
function W:GetReferenceURL()
 local selected=selectedReview(self)
 if selected then local links,qualified=referenceLinks(selected);if qualified then return links[1] end end
end
local function decode(value)
 if value:find('%%[^%x]') or value:find('%%$') or value:find('%%%x$') or value:find('%%%x[^%x]') then return nil end
 local text=value:gsub('%%(%x%x)',function(hex)return string.char(tonumber(hex,16))end)
 if text:find('[%z\1-\8\11-\31\127]') then return nil end
 -- Prevent imported WoW markup from creating textures, links or font escapes.
 return text:gsub('|','||')
end
function W:GetLogging()return safe(LoggingCombat)==true end
function W:SetLogging(enabled)
 if type(LoggingCombat)~='function' then return false,'File logging is unavailable in this client.' end
 if enabled then
  if C_CVar and C_CVar.SetCVar then pcall(C_CVar.SetCVar,'advancedCombatLogging','1')
  elseif SetCVar then pcall(SetCVar,'advancedCombatLogging','1') end
 end
 local ok=pcall(LoggingCombat,enabled==true)
 if not ok or self:GetLogging()~=(enabled==true) then return false,'Logging state could not be confirmed. Try /combatlog and check the client message.' end
 return true,enabled and 'Combat file logging enabled. Uploading and detailed analysis happen outside WoW.' or 'Combat file logging stopped.'
end
function W:Import(text,comparison)
 if safe(UnitAffectingCombat,'player')==true then return false,'Import reviews after combat.' end
 if type(text)~='string' or #text>60000 then return false,'Review is missing or exceeds the import limit.' end
 text=text:gsub('^%s+',''):gsub('%s+$','')
 local fields={};for field in (text..'|'):gmatch('(.-)|') do local value=decode(field);if value==nil then return false,'Invalid review encoding.' end;fields[#fields+1]=value end
 if #fields~=17 or fields[1]~='FCWCL1' then return false,'Paste a Forever Coaching Warcraft Logs review code, not a report URL or raw log.' end
 local code=fields[2]
 if #code~=16 or not code:match('^%w+$') then return false,'Invalid report code.' end
 local fight,encounter,started,duration=tonumber(fields[3]),tonumber(fields[8]),tonumber(fields[10]),tonumber(fields[11])
 for _,number in ipairs({fight,encounter,started,duration}) do if number~=number or number<=0 or number%1~=0 or number>1e15 then return false,'Invalid fight metadata.' end end
 if not fight or not encounter or not started or not duration or duration>86400000 then return false,'Invalid fight metadata.' end
 local player=safe(UnitName,'player');local realm=safe(GetRealmName);local _,class
 if UnitClass then local ok,a,b=pcall(UnitClass,'player');if ok and not (issecretvalue and issecretvalue(b)) then class=b end end
 if not player or not realm or normalize(fields[4])~=normalize(player) or (fields[5]~='' and normalize(fields[5])~=normalize(realm)) or fields[6]~=class then return false,'This report belongs to a different character, realm or class.' end
 local guid=safe(UnitGUID,'player');if not guid then return false,'Character identity unavailable.' end
 local review={code=code,fight=fight,player=fields[4],realm=fields[5],class=fields[6],spec=fields[7],encounter=encounter,name=fields[9],started=started,duration=duration,good=fields[12],observations=fields[13],improve=fields[14],timeline=fields[15],references=fields[16],coverage=fields[17],character=guid}
 if comparison then
  local prepared,err=self:PrepareComparison(comparison,review)
  if not prepared then return false,err end
  review.comparison=prepared
 end
 local db=saved();for i=#db.reviews,1,-1 do local old=db.reviews[i];if old.character==guid and old.code==code and old.fight==fight then table.remove(db.reviews,i) end end
 table.insert(db.reviews,1,review);while #db.reviews>30 do table.remove(db.reviews) end;db.selected=code..':'..fight
 db.reportLinks=db.reportLinks or {};db.reportLinks[guid]=self.url..'reports/'..code..'#fight='..fight
 ForeverCoachingDB.combatAnalysisReady=true
 if FC.CombatReview then FC.CombatReview:SetSource('warcraftlogs') end
 if FC.RefreshCombatReview then FC:RefreshCombatReview() end
 return true,'Review imported. This is the identified uploaded fight, not an automatic match to your latest local combat.'
end
local function displayText(value,limit)
 if type(value)~='string' then return nil end
 return value:gsub('[%c]',' '):sub(1,limit or 400):gsub('|','||')
end
local function comparisonKey(class,spec)
 return class..':'..spec:lower():gsub('[^%w]','')
end
local function finite(value)
 return type(value)=='number' and value==value and value~=math.huge and value~=-math.huge
end
function W:PrepareComparison(payload,review)
 if type(review)~='table' or type(review.code)~='string' or #review.code~=16 or not review.code:match('^%w+$') or
  not finite(review.fight) or review.fight<=0 or review.fight%1~=0 or not finite(review.encounter) or review.encounter<=0 or review.encounter%1~=0 or
  not finite(review.started) or review.started<=0 or type(review.player)~='string' or type(review.realm)~='string' then return nil,'Comparison identity is invalid.' end
 if type(payload)~='table' or payload.schema~=1 or payload.source~='Warcraft Logs' or payload.ready~=true then return nil,'Comparison data is incomplete.' end
 local context=payload.context;local report=payload.report
 local observed=type(context)=='table' and context.referenceMode=='observed'
 if observed and (not ({dps=true,healer=true,tank=true})[context.role] or context.metric~=(context.role=='healer' and 'hps' or 'dps') or context.minPercentile~=nil) then return nil,'Invalid observed role or metric.' end
 if type(context)~='table' or type(report)~='table' or type(context.referencePlayers)~='table' or type(payload.findings)~='table' or (not observed and (context.minPercentile~=100 or context.referenceMode~=nil and context.referenceMode~='percentile')) or context.class~=review.class or
  type(context.spec)~='string' or comparisonKey(context.class,context.spec)~=comparisonKey(review.class,review.spec) or
  context.encounterId~=review.encounter or report.code~=review.code or report.fightID~=review.fight or
  normalize(report.player)~=normalize(review.player) or normalize(report.realm)~=normalize(review.realm) or
  not finite(context.instanceId) or context.instanceId<=0 or not finite(context.difficulty) or not finite(context.gameVersion) then
  return nil,'Comparison does not match this player, spec and encounter.'
 end
 local peers,seen={},{}
 for _,peer in ipairs(context.referencePlayers or {})do
  if type(peer)~='table' or type(peer.player)~='string' or type(peer.realm)~='string' or (not observed and peer.percentile~=100) or
   (observed and (peer.percentile~=nil or peer.role~=context.role or peer.metric~=context.metric or not finite(peer.performance) or peer.performance<0)) or
   (observed and peer.recordedDeaths~=nil and (not finite(peer.recordedDeaths) or peer.recordedDeaths<0 or peer.recordedDeaths%1~=0)) or
   peer.class~=context.class or peer.spec~=context.spec or peer.instanceId~=context.instanceId or
   peer.encounterId~=context.encounterId or peer.difficulty~=context.difficulty or peer.gameVersion~=context.gameVersion or
   type(peer.url)~='string' or not peer.url:match('^https://forever%.warcraftlogs%.com/reports/%w+#fight=%d+&source=%d+$') then
   return nil,'Only references with a matching source, spec, role and encounter can be compared.'
  end
  local code=peer.url:match('/reports/(%w+)');if #code~=16 then return nil,'Invalid reference report.' end
  local key=normalize(peer.player)..'@'..normalize(peer.realm)
  if key==normalize(review.player)..'@'..normalize(review.realm) or seen[key] then return nil,'Reference players must be independent.' end
  seen[key]=true;peers[#peers+1]={player=displayText(peer.player,100),percentile=not observed and 100 or nil,url=peer.url,role=observed and context.role or nil,performance=observed and peer.performance or nil,recordedDeaths=observed and peer.recordedDeaths or nil}
 end
 if #peers<(observed and 1 or 3) or observed and #peers~=1 then return nil,'The required matching reference sample is missing.' end
 local rows,nextFight={},nil
 local function valueText(value,unit)
  if unit=='sequence' then return displayText(value,400) end
  if not finite(value) or value<0 or value>100000 then return nil end
  if unit=='percent' then if value>100.000001 then return nil end;return string.format('%.0f%%',math.min(100,value)) end
  if unit=='casts/min' then return string.format('%.1f casts/min',value) end
  if observed and unit==context.metric then return string.format('%.1f %s',value,unit:upper()) end
 end
 local topics={}
 for _,finding in ipairs(payload.findings or {})do
  local item=type(finding)=='table' and finding.comparison
  if type(item)=='table' and (finding.kind=='good' or finding.kind=='change' or observed and finding.kind=='context') then
   local you,reference=valueText(item.you,item.unit),valueText(item.reference,item.unit)
   local action=displayText(item.action,180);local practice=displayText(finding.next,800)
   if not you or not reference or not action or action=='' or not practice or practice=='' then return nil,'Comparison values are invalid.' end
   local topic=finding.topic or 'other';topics[topic]=(topics[topic] or 0)+1
   if topics[topic]<=3 and #rows<9 then rows[#rows+1]={action=action,you=you,reference=reference,kind=finding.kind,practice=practice} end
   if finding.kind=='change' and not nextFight then nextFight=practice end
  end
 end
 if #rows==0 then return nil,'No side-by-side observations are available.' end
 local scenario
 if payload.scenario~=nil then
  local raw=payload.scenario;local source
  if type(raw)~='table' or not finite(raw.duration) or raw.duration<=0 or raw.duration>86400 then return nil,'Invalid reference scenario.' end
  for _,peer in ipairs(peers)do if peer.url==raw.sourceURL then source=peer end end
  if not source then return nil,'Scenario must come from a matching reference.' end
  scenario={player=source.player,url=source.url,duration=raw.duration,basis=observed and ('highest observed '..context.role..' '..context.metric:upper()) or '100 percentile'}
  for _,kind in ipairs({'casts','items','buffs'})do
   local limit=kind=='casts' and 100 or 50
   local countKey=kind=='casts' and 'castCount' or kind=='items' and 'itemCount' or 'buffCount'
   local count=raw[countKey];local list=raw[kind]
   if type(list)~='table' or #list>limit or not finite(count) or count%1~=0 or count<#list then return nil,'Invalid reference action count.' end
   scenario[kind]={};scenario[countKey]=count
   local last=-1
   for _,event in ipairs(list)do
    if type(event)~='table' or not finite(event.at) or event.at<last or event.at<0 or event.at>raw.duration then return nil,'Invalid reference action time.' end
    local spell=finite(event.spellID) and event.spellID>0 and event.spellID%1==0 and event.spellID or nil
    local item=finite(event.itemID) and event.itemID>0 and event.itemID%1==0 and event.itemID or nil
    local name=displayText(event.name,180)
    if not name or name=='' or (kind=='items' and not item) or (kind~='items' and not spell) then return nil,'Reference action identity is missing.' end
    last=event.at;scenario[kind][#scenario[kind]+1]={at=event.at,name=name,spellID=spell,itemID=item}
   end
  end
 end
 return {specKey=comparisonKey(context.class,context.spec),class=context.class,spec=displayText(context.spec,100),
  instanceId=context.instanceId,instance=displayText(context.instance,120) or 'Instance',encounterId=context.encounterId,difficultyName=displayText(context.difficultyName,80),
  encounter=displayText(context.encounter,160) or review.name,difficulty=context.difficulty,
  started=review.started,rows=rows,nextFight=nextFight or rows[1].practice,peerCount=#peers,references=peers,scenario=scenario,
  referenceMode=observed and 'observed' or 'percentile',role=observed and context.role or nil,metric=observed and context.metric or nil}
end
function W:ComparisonSpecs()
 local options,seen={},{}
 for class,profiles in pairs(FC.SpecScenarioProfiles or {})do
  for _,profile in ipairs(profiles)do
   local key=comparisonKey(class,profile.name)
   options[#options+1]={value=key,label=class:sub(1,1)..class:sub(2):lower()..' / '..profile.name,class=class};seen[key]=true
  end
 end
 for _,review in ipairs(saved().reviews)do
  if review.comparison and type(review.class)=='string' and type(review.spec)=='string' then
   local key=comparisonKey(review.class,review.spec)
   if not seen[key]then options[#options+1]={value=key,label=review.class:sub(1,1)..review.class:sub(2):lower()..' / '..review.spec,class=review.class};seen[key]=true end
  end
 end
 table.sort(options,function(a,b)return a.label<b.label end)
 return options
end
local function liveSpec()
 local context
 if FC.EncounterCoach and FC.EncounterCoach.GetCombatContext then local ok,value=pcall(FC.EncounterCoach.GetCombatContext,FC.EncounterCoach);if ok then context=value end end
 local class=context and context.class
 if not class and UnitClass then local ok,_,value=pcall(UnitClass,'player');if ok and not (issecretvalue and issecretvalue(value))then class=value end end
 local profile=context and context.tree and FC.SpecScenarioProfiles and FC.SpecScenarioProfiles[class] and FC.SpecScenarioProfiles[class][context.tree]
 return profile and comparisonKey(class,profile.name) or nil,class
end
function W:GetLiveSpecKey()return liveSpec()end
local function comparisonSelection()
 local guid=safe(UnitGUID,'player');local db=saved();db.comparisonSelections=db.comparisonSelections or {}
 if not guid then W.sessionSelection=W.sessionSelection or {};return W.sessionSelection end
 db.comparisonSelections[guid]=db.comparisonSelections[guid] or {}
 return db.comparisonSelections[guid]
end
function W:SetComparisonSpec(key)
 for _,option in ipairs(self:ComparisonSpecs())do if option.value==key then
  local selection=comparisonSelection();selection.spec=key;selection.encounter=nil
  if FC.RefreshCombatReview then FC:RefreshCombatReview()end;return true
 end end
 return false
end
function W:SetComparisonEncounter(key)
 local model=self:GetComparisonModel()
 for _,option in ipairs(model.encounters)do if option.value==key then
  comparisonSelection().encounter=key;if FC.RefreshCombatReview then FC:RefreshCombatReview()end;return true
 end end
 return false
end
function W:ComparisonCatalog()
 local source=FC.WarcraftLogsCatalog
 if source==self.catalogSource then return self.catalogEntries or {} end
 self.catalogSource=source;self.catalogEntries={}
 if type(source)~='table' or source.schema~=1 or source.source~='Warcraft Logs' or type(source.entries)~='table' then return self.catalogEntries end
 for _,payload in ipairs(source.entries)do
  if type(payload)=='table' and type(payload.context)=='table' and type(payload.report)=='table' then
   local context,report=payload.context,payload.report
   local review={class=context.class,spec=context.spec,encounter=context.encounterId,code=report.code,fight=report.fightID,
    player=report.player,realm=report.realm,started=report.started,name=context.encounter}
   if type(review.class)=='string' and type(review.spec)=='string' and finite(review.started) then
    local ok,entry=pcall(self.PrepareComparison,self,payload,review)
    if ok and entry then self.catalogEntries[#self.catalogEntries+1]=entry end
   end
  end
 end
 return self.catalogEntries
end
function W:GetComparisonModel()
 local options=self:ComparisonSpecs();local selection=comparisonSelection();local current,class=liveSpec()
 if current and selection.liveSpec~=current then selection.spec=current;selection.encounter=nil;selection.liveSpec=current end
 local selected=selection.spec or current or 'current'
 for _,option in ipairs(options)do if option.value==current then option.label=option.label..' (current)'end end
 local known=false;for _,option in ipairs(options)do if option.value==selected then known=true;break end end
 if not known then table.insert(options,1,{value=selected,label=(class or 'Current character')..' / Choose spec'})end
 local guid=safe(UnitGUID,'player');local choices,encounters={},{}
 for _,entry in ipairs(self:ComparisonCatalog())do
  if entry.specKey==selected then
   local key=entry.instanceId..':'..entry.encounterId..':'..entry.difficulty..(entry.role and (':'..entry.role) or '')
   local existing=choices[key]
   if not existing or entry.started>existing.entry.started then choices[key]={entry=entry,mine=false}end
  end
 end
 for _,review in ipairs(saved().reviews)do
  local entry=review.comparison
  if type(entry)=='table' and entry.specKey==selected then
   local key=entry.instanceId..':'..entry.encounterId..':'..entry.difficulty..(entry.role and (':'..entry.role) or '')
   local existing=choices[key]
   local mine=guid and review.character==guid
   if not existing or mine and not existing.mine or mine==existing.mine and entry.started>existing.entry.started then choices[key]={entry=entry,mine=mine}end
  end
 end
 for key,value in pairs(choices)do
  local entry=value.entry;local difficulty=entry.difficultyName or safe(GetDifficultyInfo,entry.difficulty)
  encounters[#encounters+1]={value=key,label=entry.instance..' / '..entry.encounter..(type(difficulty)=='string' and (' / '..difficulty) or '')..(entry.role and (' / '..entry.role) or '')}
 end
 table.sort(encounters,function(a,b)return a.label<b.label end)
 local key=selection.encounter
 if not key or not choices[key]then
  local recent
  for candidate,value in pairs(choices)do if not recent or value.mine and not recent.mine or value.mine==recent.mine and value.entry.started>recent.entry.started then key=candidate;recent=value end end
  selection.encounter=key
 end
 local match=key and choices[key]
 local model={specs=options,selectedSpec=selected,encounters=encounters,selectedEncounter=key,rows={},ready=false,
  status='No Warcraft Logs comparison data is connected for this selection.',metrics='Warcraft Logs / Optimization',referenceHeading='REFERENCE'}
 if match then
  local entry=match.entry;model.ready=true;model.rows={}
  for _,row in ipairs(entry.rows)do model.rows[#model.rows+1]={action=row.action,you=match.mine and row.you or 'No matching fight',reference=row.reference,kind=match.mine and row.kind or 'reference'}end
  model.nextFight=match.mine and entry.nextFight or nil
  model.scenario=entry.scenario
  model.referenceMode=entry.referenceMode;model.role=entry.role;model.metric=entry.metric
  model.referenceHeading=entry.referenceMode=='observed' and (entry.role=='healer' and 'TOP OBSERVED HEALER' or entry.role=='tank' and 'TOP OBSERVED TANK DPS' or 'TOP OBSERVED DPS') or '100-PARSE PLAYERS'
  model.status='Typical values from '..entry.peerCount..' matching 100 parses / saved comparison'
  if entry.referenceMode=='observed' then model.status='Highest observed '..entry.role..' '..entry.metric:upper()..' in the scanned sample / '..entry.references[1].player..'. Not a percentile or global ranking.\nTalents and gear are not compared, but affect output.'..(entry.role=='tank' and ' Threat data is unavailable; this compares tank damage.' or entry.role=='healer' and ' Healing depends on incoming damage and assignments.' or '')end
  if entry.referenceMode=='observed' and (entry.references[1].recordedDeaths or 0)>0 then model.status=model.status..'\nReference: '..entry.references[1].recordedDeaths..' recorded deaths. Sustained-rotation coaching withheld.'end
  model.metrics=entry.spec..' / '..entry.instance..' / '..entry.encounter
 end
 return model
end
function W:GetReviews()
 local guid=safe(UnitGUID,'player');local result={}
 for _,review in ipairs(saved().reviews) do if guid and review.character==guid then result[#result+1]=review end end
 return result
end
W.publicNotice='Fights are still being logged and combat is still being tested. These public-report examples are not guaranteed to be the best possible outcome. Use them at your discretion.'
function W:ResolvePublicDungeon(instance,encounter)
 local function key(value)return tostring(value or ''):lower():gsub('[^%w]','')end
 local names={[key(instance)]=true,[key(encounter)]=true,[key(tostring(instance or '')..': '..tostring(encounter or ''))]=true}
 local match
 for _,dungeon in ipairs(FC.SupportedDungeons or {})do
  local found=names[key(dungeon.name)]
  for _,alias in ipairs(dungeon.aliases or {})do if names[key(alias)]then found=true end end
  if found then if match then return nil end;match=dungeon end
 end
 return match
end
function W:PreparePublicExample(raw)
 if type(raw)~='table' or type(raw.code)~='string' or #raw.code~=16 or not raw.code:match('^%w+$') then return end
 for _,value in ipairs({raw.fightID or false,raw.actorID or false})do if not finite(value) or value<=0 or value%1~=0 then return end end
 if not finite(raw.instanceId) or raw.instanceId<0 or raw.instanceId%1~=0 or raw.instanceId==0 and not FC.SupportedDungeons then return end
 if not finite(raw.encounterId) or raw.encounterId<0 or raw.encounterId%1~=0 then return end
 if type(raw.class)~='string' or not raw.class:match('^[A-Z]+$') or type(raw.spec)~='string' or raw.spec=='' or
  type(raw.player)~='string' or raw.player=='' or not finite(raw.duration) or raw.duration<=0 or raw.duration>86400 or
  not finite(raw.difficulty) or not finite(raw.recordedDeaths) or raw.recordedDeaths<0 or raw.recordedDeaths%1~=0 or
  not ({dps=true,healer=true,tank=true,unknown=true})[raw.role] or type(raw.complete)~='boolean' or type(raw.kill)~='boolean' or
  type(raw.spellCountsComplete)~='boolean' or type(raw.scenario)~='table' or type(raw.spells)~='table' or #raw.spells>20 then return end
 if raw.started~=nil and (not finite(raw.started) or raw.started<=0)then return end
 if raw.metric~=nil and (raw.metric~=(raw.role=='healer' and 'hps' or 'dps') or raw.role=='unknown')then return end
 if raw.performance~=nil and (not raw.metric or not finite(raw.performance) or raw.performance<0)then return end
 if raw.gameVersion~=nil and (not finite(raw.gameVersion) or raw.gameVersion%1~=0)then return end
 if raw.rankingScope~=nil and raw.rankingScope~='dungeon' then return end
 local dungeon=FC.SupportedDungeons and self:ResolvePublicDungeon(raw.instance,raw.encounter)
 if FC.SupportedDungeons and not dungeon or dungeon and raw.dungeonKey~=nil and raw.dungeonKey~=dungeon.key then return end
 local url='https://forever.warcraftlogs.com/reports/'..raw.code..'#fight='..raw.fightID..'&source='..raw.actorID
 if raw.scenario.sourceURL~=url or raw.scenario.duration~=raw.duration then return end
 local scenario={player=displayText(raw.player,100),url=url,duration=raw.duration,basis='public report example'}
 for _,kind in ipairs({'casts','items','buffs'})do
  local countKey=kind=='casts' and 'castCount' or kind=='items' and 'itemCount' or 'buffCount'
  local list,count=raw.scenario[kind],raw.scenario[countKey];local limit=kind=='casts' and 100 or 50
  if type(list)~='table' or #list>limit or not finite(count) or count%1~=0 or count<#list then return end
  scenario[kind]={};scenario[countKey]=count;local last=-1
  for _,event in ipairs(list)do
   if type(event)~='table' or not finite(event.at) or event.at<0 or event.at<last or event.at>raw.duration then return end
   local spell=finite(event.spellID) and event.spellID>0 and event.spellID%1==0 and event.spellID
   local item=finite(event.itemID) and event.itemID>0 and event.itemID%1==0 and event.itemID
   local name=displayText(event.name,180)
   if not name or name=='' or kind=='items' and not item or kind~='items' and not spell then return end
   last=event.at;scenario[kind][#scenario[kind]+1]={at=event.at,name=name,spellID=spell,itemID=item}
  end
 end
 local rows,seen={},{}
 for _,spell in ipairs(raw.spells)do
  if type(spell)~='table' or not finite(spell.spellID) or spell.spellID<=0 or spell.spellID%1~=0 or seen[spell.spellID] or
   not finite(spell.count) or spell.count<1 or spell.count%1~=0 or spell.count>scenario.castCount or type(spell.name)~='string' or spell.name=='' then return end
  seen[spell.spellID]=true
  rows[#rows+1]={action=displayText(spell.name,180),reference=raw.spellCountsComplete and (spell.count..' uses / '..string.format('%.1f casts/min',spell.count*60/raw.duration)) or (spell.count..' uses in recorded excerpt')}
 end
 local rotations={}
 if raw.rotations~=nil then
  if type(raw.rotations)~='table' or #raw.rotations>500 then return end
  for _,rotation in ipairs(raw.rotations)do
   if type(rotation)~='table' or rotation.combatOnly~=true or (rotation.kind~='boss' and rotation.kind~='trash') or
    type(rotation.name)~='string' or rotation.name=='' or not finite(rotation.start) or not finite(rotation['end']) or
    rotation.start<0 or rotation['end']<=rotation.start or rotation['end']>raw.duration or
    not finite(rotation.combatCasts) or rotation.combatCasts<0 or rotation.combatCasts>scenario.castCount or rotation.combatCasts%1~=0 or
    not finite(rotation.repeats) or rotation.repeats<0 or rotation.repeats%1~=0 or
    type(rotation.complete)~='boolean' or type(rotation.kill)~='boolean' then return end
   local sequences={}
   for _,field in ipairs({'opener','repeated'})do
    local sequence=rotation[field];if type(sequence)~='table' or #sequence>(field=='opener' and 6 or 4) or field=='opener' and #sequence==0 and not (rotation.fullSequence==true and rotation.combatCasts==0 or rotation.summaryOnly==true) then return end
    local names={}
    for _,action in ipairs(sequence)do
     if type(action)~='table' or not finite(action.spellID) or action.spellID<=0 or action.spellID%1~=0 or
      ({[1]=true,[75]=true,[5019]=true,[6603]=true})[action.spellID] or type(action.name)~='string' or action.name=='' then return end
     names[#names+1]=displayText(action.name,180)
    end
    sequences[field]=table.concat(names,' > ')
   end
   if #rotation.repeated>0 and (rotation.repeats<2 or #rotation.repeated<2)then return end
   local steps={}
   if rotation.fullSequence==true then
    if type(rotation.steps)~='table' or #rotation.steps==0 and rotation.combatCasts~=0 or #rotation.steps>rotation.combatCasts then return end
    local total,last=0,-1;local duration=rotation['end']-rotation.start
    for _,step in ipairs(rotation.steps)do
     if type(step)~='table' or not finite(step.spellID) or step.spellID<=0 or step.spellID%1~=0 or
      ({[1]=true,[75]=true,[5019]=true,[6603]=true})[step.spellID] or type(step.name)~='string' or step.name=='' or
      not finite(step.at) or not finite(step['end']) or step.at<0 or step.at<last or step['end']<step.at or step['end']>duration+0.000001 or
      not finite(step.count) or step.count<1 or step.count%1~=0 then return end
     last=math.min(step['end'],duration);total=total+step.count;steps[#steps+1]={name=displayText(step.name,180),at=math.min(step.at,duration),['end']=last,count=step.count}
    end
    if total~=rotation.combatCasts then return end
   elseif rotation.fullSequence~=nil then return end
   local output={}
   for _,field in ipairs({'damage','healing'})do if rotation[field]~=nil then
    if type(rotation[field])~='table' then return end
    local values,seenOutput={},{}
    for _,spell in ipairs(rotation[field])do
     if type(spell)~='table' or not finite(spell.spellID) or spell.spellID<=0 or spell.spellID%1~=0 or seenOutput[spell.spellID] or type(spell.name)~='string' or spell.name=='' or not finite(spell.amount) or spell.amount<0 then return end
     seenOutput[spell.spellID]=true;values[#values+1]={spellID=spell.spellID,name=displayText(spell.name,180),amount=spell.amount}
    end
    output[field]=values
   end end
   if rotation.summaryOnly~=nil and rotation.summaryOnly~=true then return end
   rotations[#rotations+1]={kind=rotation.kind,name=rotation.kind=='trash' and 'Trash mobs' or displayText(rotation.name,180),damage=output.damage,healing=output.healing,summaryOnly=rotation.summaryOnly==true,
    opener=sequences.opener,repeated=sequences.repeated,repeats=rotation.repeats,combatCasts=rotation.combatCasts,complete=rotation.complete,kill=rotation.kill,
    steps=steps,fullSequence=rotation.fullSequence==true,start=rotation.start,['end']=rotation['end']}
  end
 end
 return {key=raw.code..':'..raw.fightID..':'..raw.actorID,specKey=comparisonKey(raw.class,raw.spec),class=raw.class,spec=displayText(raw.spec,100),
  instance=dungeon and dungeon.name or displayText(raw.instance,120) or 'Instance',dungeonKey=dungeon and dungeon.key,
  encounter=displayText(raw.encounter,160) or 'Encounter',player=scenario.player,
  role=raw.role,metric=raw.metric,performance=raw.performance,duration=raw.duration,totalDamage=finite(raw.totalDamage) and raw.totalDamage>=0 and raw.totalDamage or nil,totalHealing=finite(raw.totalHealing) and raw.totalHealing>=0 and raw.totalHealing or nil,recordedDeaths=raw.recordedDeaths,complete=raw.complete,kill=raw.kill,
  started=raw.started or 0,rows=rows,scenario=scenario,rotations=rotations,excerpt=not raw.spellCountsComplete,
  difficulty=raw.difficulty,gameVersion=raw.gameVersion,rankingScope=raw.rankingScope}
end
function W:PublicExamples()
 local source=FC.PublicReportCatalog
 if source==self.publicSource then return self.publicExamples or {}end
 self.publicSource=source;self.publicExamples={}
 if type(source)~='table' or source.schema~=1 or source.source~='Warcraft Logs' or type(source.examples)~='table' then return self.publicExamples end
 local seen={}
 for _,raw in ipairs(source.examples)do
  local ok,entry=pcall(self.PreparePublicExample,self,raw)
  if ok and entry and not seen[entry.key] then seen[entry.key]=true;self.publicExamples[#self.publicExamples+1]=entry end
 end
 for _,raw in ipairs(source.additionalExamples or {})do local ok,entry=pcall(self.PreparePublicExample,self,raw);if ok and entry and not seen[entry.key]then seen[entry.key]=true;self.publicExamples[#self.publicExamples+1]=entry end end
 return self.publicExamples
end
function W:PublicRuns()
 local source=FC.PublicReportCatalog
 if self.publicRunsSource==source then return self.publicRuns or {}end
 local runs,seen={},{}
 local details={};for _,entry in ipairs(self:PublicExamples())do details[entry.key]=entry end
 for _,raw in ipairs(source and source.runs or {})do
  if type(raw)=='table' and type(raw.code)=='string' and raw.code:match('^%w+$') and #raw.code==16 and finite(raw.fightID) and raw.fightID>0 and raw.fightID%1==0 and finite(raw.actorID) and raw.actorID>0 and raw.actorID%1==0 and type(raw.class)=='string' and raw.class:match('^[A-Z]+$') and type(raw.spec)=='string' and raw.spec~='' and finite(raw.duration) and raw.duration>0 and finite(raw.performance) and raw.performance>=0 and finite(raw.difficulty) and finite(raw.gameVersion) and raw.complete==true and raw.kill==true and (raw.role=='dps' or raw.role=='healer' or raw.role=='tank') and raw.metric==(raw.role=='healer' and 'hps' or 'dps') then
   local dungeon=self:ResolvePublicDungeon(raw.instance,'');local key=raw.code..':'..raw.fightID..':'..raw.actorID
   if dungeon and dungeon.key==raw.dungeonKey and not seen[key]then
    local entry=details[key] or {key=key,class=raw.class,spec=displayText(raw.spec,100),specKey=comparisonKey(raw.class,raw.spec),dungeonKey=dungeon.key,instance=dungeon.name,role=raw.role,metric=raw.metric,performance=raw.performance,duration=raw.duration,totalDamage=finite(raw.totalDamage) and raw.totalDamage>=0 and raw.totalDamage or nil,totalHealing=finite(raw.totalHealing) and raw.totalHealing>=0 and raw.totalHealing or nil,difficulty=raw.difficulty,gameVersion=raw.gameVersion,rankingScope='dungeon',complete=true,kill=true,started=raw.started or 0,rotations={},encounters=raw.encounters}
    runs[#runs+1]=entry;seen[key]=true
   end
  end
 end
 for key,entry in pairs(details)do if not seen[key]then runs[#runs+1]=entry end end
 self.publicRunsSource=source;self.publicRuns=runs;return runs
end
function W:SetPublicSpec(key)
 local model=self:GetPublicReportModel()
 for _,option in ipairs(model.specs)do if option.value==key then local selection=comparisonSelection();selection.publicSpec=key;selection.publicEncounter=nil;if FC.RefreshCombatReview then FC:RefreshCombatReview()end;return true end end
 return false
end
function W:SetPublicEncounter(key)
 for _,option in ipairs(self:GetPublicReportModel().encounters)do if option.value==key then local selection=comparisonSelection();selection.publicEncounter=key;selection.publicDungeon=option.dungeonKey;if FC.RefreshCombatReview then FC:RefreshCombatReview()end;return true end end
 return false
end
function W:GetPublicReportModel()
 local examples=self:PublicRuns();local specs,seen={},{};local selection=comparisonSelection();local current,class=liveSpec()
 for _,entry in ipairs(examples)do if not seen[entry.specKey]then seen[entry.specKey]=true;specs[#specs+1]={value=entry.specKey,label=entry.class:sub(1,1)..entry.class:sub(2):lower()..' / '..entry.spec..(entry.specKey==current and ' (current)' or '')}end end
 table.sort(specs,function(a,b)return a.label<b.label end)
 if current and not seen[current]then table.insert(specs,1,{value=current,label=(class or 'Current')..' / Current spec (no public example yet)'})end
 if current and selection.publicLiveSpec~=current then selection.publicSpec=current;selection.publicEncounter=nil;selection.publicLiveSpec=current end
 local selected=selection.publicSpec or current or specs[1] and specs[1].value
 if selected~=current and not seen[selected]then selected=specs[1] and specs[1].value;selection.publicSpec=selected end
 local choices,encounters,groups,allDungeons={},{},{},{}
 for _,entry in ipairs(examples)do allDungeons[entry.dungeonKey or entry.instance]=true end
 for _,entry in ipairs(examples)do if entry.specKey==selected then
  local groupKey=entry.dungeonKey or entry.instance;groups[groupKey]=groups[groupKey] or {};groups[groupKey][#groups[groupKey]+1]=entry
 end end
 local function rotationRows(entries)
  local preferHealer=selected and (selected:match(':restoration$') or selected:match(':holy$') or selected=='PRIEST:discipline')
  local hasDPS,hasHPS=false,false;for _,entry in ipairs(entries or {})do if entry.metric=='dps'then hasDPS=true elseif entry.metric=='hps'then hasHPS=true end end
  preferHealer=preferHealer or hasHPS and not hasDPS
  local metric=preferHealer and 'hps' or 'dps'
  local list={};for _,entry in ipairs(entries or {})do if entry.complete and entry.kill and entry.rankingScope=='dungeon' and entry.gameVersion and entry.performance and entry.metric==metric and entry.role~='unknown'then list[#list+1]=entry end end
  table.sort(list,function(a,b)if a.performance~=b.performance then return a.performance>b.performance end;return a.key<b.key end)
  local chosen=list[1]
  list=chosen and {chosen} or {}
  local rows,sections,sectionMap={},{},{}
  for _,entry in ipairs(list)do
   local healing=entry.role=='healer';local outputField=healing and 'healing' or 'damage';local rateLabel=healing and 'HPS' or 'DPS'
   local function optionalSource(name)
    local n=name:lower()
    if n:find('blood fury',1,true) or n:find('berserking',1,true) or n:find('war stomp',1,true) or n:find('stoneform',1,true) or n:find('will of the forsaken',1,true) or n:find('escape artist',1,true) or n:find('cannibalize',1,true) or n:find('shadowmeld',1,true) or n:find('perception',1,true) or n:find('devouring plague',1,true) or n:find('starshards',1,true) or n:find('feedback',1,true) or n:find('hex of weakness',1,true) or n:find('shadowguard',1,true) or n:find('touch of weakness',1,true) or n:find('desperate prayer',1,true) or n:find('elune',1,true) then return 'Racial'end
    if n:find('grenade',1,true) or n:find('dynamite',1,true) or n:find('sapper',1,true) or n:find('bomb',1,true) or n:find('dragonling',1,true) or n:find('battle chicken',1,true) or n:find('potion',1,true) then return 'Profession / item'end
   end
   local book=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes and FC.ForeverSpellCatalog.classes[entry.class]
   local classNames={};for name in pairs(book and book.spells or {})do classNames[name:lower()]=true end
   local otherClassNames={}
   for class,other in pairs(FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes or {})do if class~=entry.class then for name in pairs(other.spells or {})do otherClassNames[name:lower()]=true end end end
   local function shortDamage(amount)if amount>=1000000 then return string.format('%.1fm',amount/1000000)elseif amount>=1000 then return string.format('%.1fk',amount/1000)end;return string.format('%.0f',amount)end
   local function damageRow(spells,total,duration)
    table.sort(spells,function(a,b)return a.amount>b.amount end)
    local lines,meter={},{}
    for _,spell in ipairs(spells)do
     local category=optionalSource(spell.name)
     if not category and not classNames[spell.name:lower()] and otherClassNames[spell.name:lower()]then category='Proc / other effect'end
     local label=spell.name..(category and (' ['..category..']') or '')
     local dps=duration>0 and spell.amount/duration or 0;local share=total>0 and spell.amount*100/total or 0
     local value=string.format('%s %s - %.0f %s (%.1f%%)',shortDamage(spell.amount),healing and 'healing' or 'dmg',dps,rateLabel,share)
     lines[#lines+1]=label..'  '..value;meter[#meter+1]={name=label,value=value,share=share,amount=spell.amount,dps=not healing and dps or nil,hps=healing and dps or nil}
    end
    local row={action=healing and 'Healing by ability' or 'Damage by ability',reference=#lines>0 and table.concat(lines,'\n') or (healing and 'No healing recorded.' or 'No damage recorded.'),meter=meter}
    if healing then row.totalHealing=total;row.totalHPS=duration>0 and total/duration or 0 else row.totalDamage=total;row.totalDPS=duration>0 and total/duration or 0 end
    return row
   end
   local overallSpells,overallMap,overallTotal={},{},0
   for _,r in ipairs(entry.rotations)do for _,spell in ipairs(r[outputField] or {})do local old=overallMap[spell.spellID] or {spellID=spell.spellID,name=spell.name,amount=0};old.amount=old.amount+spell.amount;overallMap[spell.spellID]=old;overallTotal=overallTotal+spell.amount end end
   for _,spell in pairs(overallMap)do overallSpells[#overallSpells+1]=spell end
   local duration=entry.duration or entry.scenario and entry.scenario.duration or 0
   local overall=damageRow(overallSpells,overallTotal,duration)
   local total=healing and (entry.totalHealing or entry.performance*duration) or entry.totalDamage or entry.metric=='dps' and entry.performance*duration
   if total then if healing then overall.totalHealing=total;overall.totalHPS=duration>0 and total/duration or 0 else overall.totalDamage=total;overall.totalDPS=duration>0 and total/duration or 0 end end
   if #entry.rotations==0 then overall.reference='Encounter details are not cached for this log. Overall output comes from the recorded dungeon totals.';overall.meter=nil end
   if healing then for _,r in ipairs(entry.rotations)do if not r.healing then overall.meter=nil;overall.reference='Healing by ability is not cached for this log.';break end end end
   if not total and #entry.rotations==0 then overall.totalDamage=nil;overall.totalDPS=nil;overall.reference='Damage totals are unavailable for this healer log; the recorded ranking metric is HPS.'end
   local overallSection={value='overall',label='Overall',rows={overall},sources={}}
   rows[#rows+1]=overall;sections[#sections+1]=overallSection;sectionMap.overall=overallSection
   local rotations={};for _,r in ipairs(entry.rotations)do rotations[#rotations+1]=r end;table.sort(rotations,function(a,b)return a.start<b.start end)
   local trashDamage,trashTotal,trashAvailable,trashDuration,trashEnd={},0,true,0,0
   for _,r in ipairs(rotations)do if r.kind=='trash' then
    trashDuration=trashDuration+math.max(0,r['end']-math.max(r.start,trashEnd));trashEnd=math.max(trashEnd,r['end'])
    if not r[outputField] then trashAvailable=false end
    for _,spell in ipairs(r[outputField] or {})do local row=trashDamage[spell.spellID] or {name=spell.name,amount=0};row.amount=row.amount+spell.amount;trashDamage[spell.spellID]=row;trashTotal=trashTotal+spell.amount end
   end end
   local trashShown=false
   for _,r in ipairs(rotations)do
    local title=r.kind=='trash' and (healing and 'Overall trash healing' or 'Overall trash damage') or r.name
    local sectionKey=r.kind=='trash' and 'trash' or 'boss:'..r.name:lower()
    local section=sectionMap[sectionKey]
    if not section then section={value=sectionKey,label=r.kind=='trash' and 'Trash mobs' or r.name,rows={},sources={}};sectionMap[sectionKey]=section;sections[#sections+1]=section end
    section.sources[entry.key]=true
    local function addRow(row)rows[#rows+1]=row;section.rows[#section.rows+1]=row end
    if r.kind=='trash' then
     if not trashShown then
      trashShown=true
      if not trashAvailable then addRow({action=title,reference='The '..outputField..' breakdown is not available for this log. Individual pulls are hidden.'})
      else
       local spells={};for _,spell in pairs(trashDamage)do spells[#spells+1]=spell end
       addRow(damageRow(spells,trashTotal,trashDuration))
      end
     end
    else
    if r.kind=='boss' and not r.kill then title=title..' / attempt'end
    if r[outputField] then
     local spells,total={},0
     for _,spell in ipairs(r[outputField])do spells[#spells+1]=spell;total=total+spell.amount end
     addRow(damageRow(spells,total,r['end']-r.start))
    else addRow({action=title..' / '..outputField,reference='The '..outputField..' breakdown is not available for this encounter.'})end
    end
   end
   for _,encounter in ipairs(entry.encounters or {})do if type(encounter)=='table' and (encounter.kind=='boss' or encounter.kind=='trash') and type(encounter.name)=='string'then local key=encounter.kind=='trash' and 'trash' or 'boss:'..encounter.name:lower();if not sectionMap[key]then local section={value=key,label=encounter.kind=='trash' and 'Trash mobs' or displayText(encounter.name,180),rows={{action='Encounter data unavailable',reference='Combat details for this log have not been cached. No other player\'s encounter data is substituted.'}}};sections[#sections+1]=section;sectionMap[key]=section end end end
  end
  if #sections>0 and not sectionMap.trash then sections[#sections+1]={value='trash',label='Trash mobs',rows={{action='Trash mobs',reference='No trash-pull data is available for the selected run.'}}}end
  table.sort(sections,function(a,b)if a.value==b.value then return false end;if a.value=='overall' or b.value=='overall'then return a.value=='overall'end;if a.value=='trash' or b.value=='trash'then return a.value=='trash'end;return a.label<b.label end)
  return rows,sections,nil,chosen and chosen.key
 end
 local roster=FC.SupportedDungeons or {};if not FC.SupportedDungeons then for key,entries in pairs(groups)do roster[#roster+1]={key=key,name=entries[1].instance}end;table.sort(roster,function(a,b)return a.name<b.name end)end
 local firstAvailable,covered=nil,0
 for _,dungeon in ipairs(roster)do
  local rows,sections,runs,run=rotationRows(groups[dungeon.key]);local key='dungeon:'..dungeon.key
  choices[key]={instance=dungeon.name,rows=rows,sections=sections,runs=runs,selectedRun=run,hasReports=groups[dungeon.key]~=nil,otherSpecs=allDungeons[dungeon.key]}
  if #rows>0 then covered=covered+1;firstAvailable=firstAvailable or key end
  encounters[#encounters+1]={value=key,dungeonKey=dungeon.key,label=dungeon.name..(#rows>0 and '' or groups[dungeon.key] and ' / awaiting encounter rotations' or allDungeons[dungeon.key] and ' / other specs available' or ' / no reports loaded')}
 end
 local key=selection.publicEncounter
 if not key or not choices[key]then key=selection.publicDungeon and ('dungeon:'..selection.publicDungeon);if not key or not choices[key]then key=firstAvailable or encounters[1] and encounters[1].value end;selection.publicEncounter=key end
 local model={referenceOnly=true,notice=self.publicNotice,specs=specs,selectedSpec=selected,encounters=encounters,selectedEncounter=key,
  rows={},sections={},ready=false,rotationView=true,supportedDungeonCount=#roster,coveredDungeonCount=covered,
  metrics='Recorded dungeon output',status='No public-report example is loaded for this spec yet. Coverage is still expanding.'}
 local entry=key and choices[key]
 if entry and #entry.rows==0 then
  model.metrics=entry.instance..' / awaiting public reports'
  model.status=entry.hasReports and 'Public logs are loaded, but complete ranked dungeon rotations are not available yet. Refresh the public catalog to collect full sequences and output scores.' or
   entry.otherSpecs and (entry.instance..' has public reports for other specs. Choose another spec to see its recorded examples. No example is loaded for the selected spec.') or
   entry.instance..' is supported. No public-report example is loaded for this dungeon yet. The current scan did not retrieve usable runs; public reports may still exist on the website.'
 elseif entry then
  model.ready=true;model.rows=entry.rows;model.sections=entry.sections;model.runs=entry.runs;model.selectedRun=entry.selectedRun;model.metrics=entry.instance..(entry.rows[1] and entry.rows[1].totalHealing~=nil and ' / healing overview' or ' / damage overview')
  model.status='This is not a verified ranking across every log on Warcraft Logs.'
 end
 return model
end
function W:SetPublicSection(key)
 local model=self:GetPublicReportModel()
 for _,section in ipairs(model.sections or {})do if section.value==key then local selection=comparisonSelection();selection.publicSection=key;selection.publicSectionContext=(model.selectedSpec or '')..'@'..(model.selectedEncounter or '');if FC.RefreshCombatReview then FC:RefreshCombatReview()end;return true end end
 return false
end
function W:GetOptimizationModel()
 local model=self:GetPublicReportModel();local selection=comparisonSelection()
 local context=(model.selectedSpec or '')..'@'..(model.selectedEncounter or '')
 if selection.publicSectionContext~=context then selection.publicSection=nil;selection.publicSectionContext=context end
 local selected
 for _,section in ipairs(model.sections or {})do if section.value==selection.publicSection then selected=section end end
 selected=selected or model.sections and model.sections[1]
 selection.publicSection=selected and selected.value;model.selectedSection=selection.publicSection
 model.rows=selected and selected.rows or {};model.sectionLabel=selected and selected.label
 return model
end
function W:Select(offset)
 local list=self:GetReviews();if #list==0 then return end
 local db=saved();local index=1
 for i,r in ipairs(list) do if db.selected==r.code..':'..r.fight then index=i end end
 index=math.max(1,math.min(#list,index+offset));local r=list[index];db.selected=r.code..':'..r.fight
 db.reportLinks=db.reportLinks or {};local guid=safe(UnitGUID,'player');if guid then db.reportLinks[guid]=self.url..'reports/'..r.code..'#fight='..r.fight end
 if FC.CombatReview then FC.CombatReview:SetSource('warcraftlogs') end
 if FC.RefreshCombatReview then FC:RefreshCombatReview() end
end
function W:GetSummary()
 local selected=selectedReview(self)
 if not selected then return {metrics='Warcraft Logs / Report access',headings={'YOUR REPORT','100-PARSE REFERENCES','COMPARE ON WARCRAFT LOGS'},goodText=self:GetReportURL()~=self.url and 'Your report link is saved. Select Your report and copy the link to view this fight on Warcraft Logs.' or 'Save your Warcraft Logs report link above to keep it with this character.',wrongText='Choose verified 100-percentile players on the same class, spec, encounter and difficulty in other runs.',improveText='Open your report in a browser and compare casts, buffs and encounter timelines on Warcraft Logs. The addon does not retrieve website results automatically.',coverage='Warcraft Logs remains the source for uploaded reports and rankings. This addon provides links and displays supplied comparison snapshots. Local cast failures are not rotation verdicts.'} end
 local r=selected
 local links,qualified=referenceLinks(r)
 if not qualified then return {metrics='Warcraft Logs / '..r.name..' / 100-parse comparison unavailable',headings={'YOUR REPORT','100-PARSE REFERENCES','COMPARE ON WARCRAFT LOGS'},goodText='Your imported report identifies '..r.name..' / '..r.spec..' / fight '..r.fight..'.',wrongText='This saved snapshot does not identify three distinct 100-percentile reference parses. Lower-percentile comparisons are withheld.',improveText='Use your report link to compare with verified 100 parses on Warcraft Logs. Match the spec, encounter, difficulty and tuning period.',coverage='Reference labels in an imported snapshot cannot be independently verified by the in-game addon. The addon does not turn a percentile difference into a confirmed mistake.'} end
 return {metrics='Imported Warcraft Logs comparison / '..r.name..' / '..r.spec..' / fight '..r.fight..' / '..math.floor(r.duration/1000)..'s',headings={'IMPORTED FIGHT SUMMARY','DIFFERENCES FROM 100 PARSES','POINTS TO REVIEW'},goodText=r.good,wrongText=r.observations,improveText=r.improve..'\n\n100-percentile reference parses:\n'..r.references,coverage='Imported comparison findings are supplied by the import tool; they are not official Warcraft Logs mistake verdicts.\n'..r.coverage..'\nUploaded fight started (Unix ms): '..r.started..'\nSource: '..self.url..'reports/'..r.code..'#fight='..r.fight,sourceUrl=self.url..'reports/'..r.code..'#fight='..r.fight}
end
