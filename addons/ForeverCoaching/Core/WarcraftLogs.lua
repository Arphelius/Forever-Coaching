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
local function normalize(value)return tostring(value or ''):lower():gsub('[%s%-%\']','')end
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
 if FC.CombatReview then FC.CombatReview:SetSource('warcraftlogs') end
 if FC.RefreshCombatReview then FC:RefreshCombatReview() end
end
function W:GetSummary()
 local list=self:GetReviews();local db=saved();local selected=list[1]
 for _,r in ipairs(list) do if db.selected==r.code..':'..r.fight then selected=r end end
 if not selected then return {metrics='Warcraft Logs / No imported fight',goodText='Record a fight, upload it to Warcraft Logs, then import its analyzed review.',wrongText='No external report is loaded for this character.',improveText='Use the Warcraft Logs section at the top of Combat Review for recording and imports.',coverage='The addon cannot upload files or query the website. Local recording continues independently.'} end
 local r=selected
 return {metrics='Warcraft Logs / '..r.name..' / '..r.spec..' / fight '..r.fight..' / '..math.floor(r.duration/1000)..'s',headings={'WHAT YOU DID WELL','ROTATION DIFFERENCES TO REVIEW','NEXT PULL: PRACTICE'},goodText=r.good..'\n\nTimeline:\n'..r.timeline,wrongText=r.observations,improveText=r.improve..'\n\nReference players:\n'..(r.references~='' and r.references or 'No compatible verified reference players retrieved.'),coverage=r.coverage..'\nUploaded fight started (Unix ms): '..r.started..'\nSource: '..self.url..'reports/'..r.code..'#fight='..r.fight,sourceUrl=self.url..'reports/'..r.code..'#fight='..r.fight}
end
