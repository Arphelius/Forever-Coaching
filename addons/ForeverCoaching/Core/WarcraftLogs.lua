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
   local ok=self:Import(entry.code)
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
function W:Import(text)
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
 local db=saved();for i=#db.reviews,1,-1 do local old=db.reviews[i];if old.character==guid and old.code==code and old.fight==fight then table.remove(db.reviews,i) end end
 table.insert(db.reviews,1,review);while #db.reviews>30 do table.remove(db.reviews) end;db.selected=code..':'..fight
 db.reportLinks=db.reportLinks or {};db.reportLinks[guid]=self.url..'reports/'..code..'#fight='..fight
 ForeverCoachingDB.combatAnalysisReady=true
 if FC.CombatReview then FC.CombatReview:SetSource('warcraftlogs') end
 if FC.RefreshCombatReview then FC:RefreshCombatReview() end
 return true,'Review imported. This is the identified uploaded fight, not an automatic match to your latest local combat.'
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
