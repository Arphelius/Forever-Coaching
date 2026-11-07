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
 if imported>0 then print('Forever Coaching: '..imported..' coaching review loaded from your companion. Open Combat Review.') end
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
 if not player or not realm or normalize(fields[4])~=normalize(player) or normalize(fields[5])~=normalize(realm) or fields[6]~=class then return false,'This report belongs to a different character, realm or class.' end
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
 if type(context)~='table' or type(report)~='table' or type(context.referencePlayers)~='table' or type(payload.findings)~='table' or context.minPercentile~=100 or context.class~=review.class or
  type(context.spec)~='string' or comparisonKey(context.class,context.spec)~=comparisonKey(review.class,review.spec) or
  context.encounterId~=review.encounter or report.code~=review.code or report.fightID~=review.fight or
  normalize(report.player)~=normalize(review.player) or normalize(report.realm)~=normalize(review.realm) or
  not finite(context.instanceId) or context.instanceId<=0 or not finite(context.difficulty) or not finite(context.gameVersion) then
  return nil,'Comparison does not match this player, spec and encounter.'
 end
 local peers,seen={},{}
 for _,peer in ipairs(context.referencePlayers or {})do
  if type(peer)~='table' or type(peer.player)~='string' or type(peer.realm)~='string' or peer.percentile~=100 or
   peer.class~=context.class or peer.spec~=context.spec or peer.instanceId~=context.instanceId or
   peer.encounterId~=context.encounterId or peer.difficulty~=context.difficulty or peer.gameVersion~=context.gameVersion or
   type(peer.url)~='string' or not peer.url:match('^https://forever%.warcraftlogs%.com/reports/%w+#fight=%d+&source=%d+$') then
   return nil,'Only matching 100-percentile reference players can be compared.'
  end
  local code=peer.url:match('/reports/(%w+)');if #code~=16 then return nil,'Invalid reference report.' end
  local key=normalize(peer.player)..'@'..normalize(peer.realm)
  if key==normalize(review.player)..'@'..normalize(review.realm) or seen[key] then return nil,'Reference players must be independent.' end
  seen[key]=true;peers[#peers+1]={player=displayText(peer.player,100),percentile=100,url=peer.url}
 end
 if #peers<3 then return nil,'At least three matching 100-percentile reference players are required.' end
 local rows,nextFight={},nil
 local function valueText(value,unit)
  if unit=='sequence' then return displayText(value,400) end
  if not finite(value) or value<0 or value>100000 then return nil end
  if unit=='percent' then if value>100.000001 then return nil end;return string.format('%.0f%%',math.min(100,value)) end
  if unit=='casts/min' then return string.format('%.1f casts/min',value) end
 end
 local topics={}
 for _,finding in ipairs(payload.findings or {})do
  local item=type(finding)=='table' and finding.comparison
  if type(item)=='table' and (finding.kind=='good' or finding.kind=='change') then
   local you,reference=valueText(item.you,item.unit),valueText(item.reference,item.unit)
   local action=displayText(item.action,180);local practice=displayText(finding.next,800)
   if not you or not reference or not action or action=='' or not practice or practice=='' then return nil,'Comparison values are invalid.' end
   local topic=finding.topic or 'other';topics[topic]=(topics[topic] or 0)+1
   if topics[topic]<=3 and #rows<9 then rows[#rows+1]={action=action,you=you,reference=reference,kind=finding.kind,practice=practice} end
   if finding.kind=='change' and not nextFight then nextFight=practice end
  end
 end
 if #rows==0 then return nil,'No side-by-side observations are available.' end
 return {specKey=comparisonKey(context.class,context.spec),class=context.class,spec=displayText(context.spec,100),
  instanceId=context.instanceId,instance=displayText(context.instance,120) or 'Instance',encounterId=context.encounterId,difficultyName=displayText(context.difficultyName,80),
  encounter=displayText(context.encounter,160) or review.name,difficulty=context.difficulty,
  started=review.started,rows=rows,nextFight=nextFight or rows[1].practice,peerCount=#peers,references=peers}
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
   local key=entry.instanceId..':'..entry.encounterId..':'..entry.difficulty
   local existing=choices[key]
   if not existing or entry.started>existing.entry.started then choices[key]={entry=entry,mine=false}end
  end
 end
 for _,review in ipairs(saved().reviews)do
  local entry=review.comparison
  if type(entry)=='table' and entry.specKey==selected then
   local key=entry.instanceId..':'..entry.encounterId..':'..entry.difficulty
   local existing=choices[key]
   local mine=guid and review.character==guid
   if not existing or mine and not existing.mine or mine==existing.mine and entry.started>existing.entry.started then choices[key]={entry=entry,mine=mine}end
  end
 end
 for key,value in pairs(choices)do
  local entry=value.entry;local difficulty=entry.difficultyName or safe(GetDifficultyInfo,entry.difficulty)
  encounters[#encounters+1]={value=key,label=entry.instance..' / '..entry.encounter..(type(difficulty)=='string' and (' / '..difficulty) or '')}
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
  status='No Warcraft Logs comparison data is connected for this selection.',metrics='Warcraft Logs / 100-parse comparison'}
 if match then
  local entry=match.entry;model.ready=true;model.rows={}
  for _,row in ipairs(entry.rows)do model.rows[#model.rows+1]={action=row.action,you=match.mine and row.you or 'No matching fight',reference=row.reference,kind=match.mine and row.kind or 'reference'}end
  model.nextFight=match.mine and entry.nextFight or nil
  model.status='Typical values from '..entry.peerCount..' matching 100 parses / saved comparison'
  model.metrics=entry.spec..' / '..entry.instance..' / '..entry.encounter
 end
 return model
end
function W:GetReviews()
 local guid=safe(UnitGUID,'player');local result={}
 for _,review in ipairs(saved().reviews) do if guid and review.character==guid then result[#result+1]=review end end
 return result
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
