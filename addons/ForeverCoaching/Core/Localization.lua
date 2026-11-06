ForeverCoaching=ForeverCoaching or {}
local FC=ForeverCoaching
-- The game font has no ă, ș or ț (they render as boxes), so Romanian is named and shown
-- without diacritics; the translation file keeps the proper spelling (as SimGear does).
local L={languages={{code='en',name='English'},{code='ro',name='Romana'},{code='es',name='Español'},{code='fr',name='Français'},{code='de',name='Deutsch'},{code='pt',name='Português'}},bindings=setmetatable({},{__mode='k'})}
FC.Localization=L
function L:GetLanguage()
 local code=ForeverCoachingDB and ForeverCoachingDB.settings and ForeverCoachingDB.settings.language
 for _,language in ipairs(self.languages)do if language.code==code then return code end end
 return 'en'
end
local function boundary(text,start,finish)
 return (start==1 or not text:sub(start-1,start-1):match('[%w_]')) and (finish==#text or not text:sub(finish+1,finish+1):match('[%w_]'))
end
function L:GetProtectedNames()
 local names={['Forever Coaching']=true,['Forever Logs']=true,['MythicSim']=true,['Mobalytics']=true}
 for _,name in ipairs({'Druid','Hunter','Mage','Paladin','Priest','Rogue','Shaman','Warlock','Warrior','DRUID','HUNTER','MAGE','PALADIN','PRIEST','ROGUE','SHAMAN','WARLOCK','WARRIOR'})do names[name]=true end
 for _,class in pairs(FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes or {})do for name in pairs(class.spells)do names[name]=true end;for name in pairs(class.talents or {})do names[name]=true end end
 for _,trees in pairs(FC.TalentTrees or {})do for _,tree in ipairs(trees)do names[tree.name]=true;for _,node in ipairs(tree.nodes)do names[node.name]=true end end end
 for _,builds in pairs(ForeverCoachingDB and ForeverCoachingDB.customTalentBuilds or {})do for _,build in ipairs(builds)do if type(build.title)=='string' then names[build.title]=true end end end
 local result={};for name in pairs(names)do result[#result+1]=name end
 table.sort(result,function(a,b)return #a>#b end);return result
end
local PLAIN={['\196\131']='a',['\196\130']='A',['\195\162']='a',['\195\130']='A',['\195\174']='i',['\195\142']='I',
 ['\200\153']='s',['\200\152']='S',['\200\155']='t',['\200\154']='T',['\197\159']='s',['\197\158']='S',['\197\163']='t',['\197\162']='T'}
local PLAIN_CODES={ro=true}
function L:Plain(text)
 return (text:gsub('[\195\196\197\200][\128-\191]',function(c)return PLAIN[c] or c end))
end
local function replaceLiteral(text,key,callback)
 local from,out=1,{}
 while true do
  local first,last=text:find(key,from,true)
  if not first then out[#out+1]=text:sub(from);break end
  out[#out+1]=text:sub(from,first-1)
  out[#out+1]=boundary(text,first,last) and callback(key) or key
  from=last+1
 end
 return table.concat(out)
end
function L:Text(value,code)
 if type(value)~='string' or value=='' then return value end
 code=code or self:GetLanguage();if code=='en' then return value end
 self.cache=self.cache or {};self.cache[code]=self.cache[code] or {}
 if self.cache[code][value] then return self.cache[code][value] end
 local dictionary=FC.LocaleMessages and FC.LocaleMessages[code];if not dictionary then return value end
 if not self.protected then self.protected=self:GetProtectedNames() end
 local function maskNames(input)
  for index,name in ipairs(self.protected)do if input:find(name,1,true)then input=replaceLiteral(input,name,function()return '\003'..index..'\004'end)end end
  return input
 end
 local tokens={};local function hold(text)tokens[#tokens+1]=text;return '\001'..#tokens..'\002' end
 local text=value:gsub('https?://[^%s]+',hold):gsub('|c%x%x%x%x%x%x%x%x',hold):gsub('|r',hold)
 text=maskNames(text)
 self.keys=self.keys or {};local keys=self.keys[code]
 if not keys then keys={};for key,translation in pairs(dictionary)do local masked=maskNames(key);if not masked:match('^\003%d+\004$')then keys[#keys+1]={key=masked,target=translation}end end;table.sort(keys,function(a,b)return #a.key>#b.key end);self.keys[code]=keys end
 for _,entry in ipairs(keys)do if text:find(entry.key,1,true)then text=replaceLiteral(text,entry.key,function()return hold(entry.target)end)end end
 local result=text:gsub('\001(%d+)\002',function(index)return tokens[tonumber(index)]end)
 result=result:gsub('\003(%d+)\004',function(index)return self.protected[tonumber(index)]end)
 if PLAIN_CODES[code] then result=self:Plain(result) end
 self.cacheCount=(self.cacheCount or 0)+1;if self.cacheCount>2000 then self.cache={};self.cache[code]={};self.cacheCount=0 end
 self.cache[code][value]=result
 return result
end
function FC:Text(value)return L:Text(value)end
function L:Bind(widget)
 if not widget or self.bindings[widget] or type(widget.SetText)~='function' then return widget end
 -- Edit boxes hold user input, links, talent codes and exported JSON.
 if widget.IsObjectType and widget:IsObjectType('EditBox') then return widget end
 local original=widget.SetText;local record={set=original};self.bindings[widget]=record
 widget.SetText=function(target,value)record.source=value;return original(target,L:Text(value))end
 if widget.SetFormattedText then widget.SetFormattedText=function(target,format,...)target:SetText(string.format(format,...))end end
 return widget
end
local rawCreateFrame=CreateFrame
function FC.CreateLocalizedFrame(...)
 local frame=rawCreateFrame(...);L:Bind(frame)
 local createFont=frame.CreateFontString
 if createFont then frame.CreateFontString=function(owner,...)return L:Bind(createFont(owner,...))end end
 if frame.TitleText then L:Bind(frame.TitleText)end
 return frame
end
function L:SetLanguage(code)
 local valid=false;for _,language in ipairs(self.languages)do if language.code==code then valid=true end end
 if not valid then return false end
 ForeverCoachingDB=ForeverCoachingDB or {};ForeverCoachingDB.settings=ForeverCoachingDB.settings or {};ForeverCoachingDB.settings.language=code
 self.protected=nil;self.keys=nil;self.cache=nil
 for widget,record in pairs(self.bindings)do if record.source~=nil then record.set(widget,self:Text(record.source,code))end end
 -- Re-translated labels change width; let open windows re-fit and re-lay out.
 for _,listener in ipairs(FC.languageListeners or {})do pcall(listener,code)end
 return true
end
function FC:OpenLanguageSettings()
 -- The dashboard's Language dropdown is the one place to choose; this window is only a fallback.
 if self.OpenLanguageMenu then return self:OpenLanguageMenu() end
 if self.languageSettings then self.languageSettings:Show();return end
 local frame=FC.CreateLocalizedFrame('Frame','ForeverCoachingLanguageSettings',UIParent,'BasicFrameTemplateWithInset')
 frame:SetSize(320,292);frame:SetPoint('CENTER');frame:SetFrameStrata('FULLSCREEN_DIALOG');frame.TitleText:SetText('Language')
 self.languageSettings=frame
 for index,language in ipairs(L.languages)do
  local button=FC.CreateLocalizedFrame('Button',nil,frame,'UIPanelButtonTemplate');button:SetSize(270,28);button:SetPoint('TOPLEFT',25,-35-(index-1)*37)
  -- Native language labels are deliberately independent of the chosen language.
  button:SetText(language.name);button:SetScript('OnClick',function()L:SetLanguage(language.code);frame:Hide()end)
 end
end
if not SlashCmdList then SlashCmdList={} end;SLASH_FOREVERCOACHINGLANGUAGE1='/fclanguage'
SlashCmdList.FOREVERCOACHINGLANGUAGE=function(message)
 local code=(message or ''):lower():match('^%s*(%S*)')
 if code=='' then FC:OpenLanguageSettings()elseif not L:SetLanguage(code)then print('/fclanguage en | ro | es | fr | de | pt')end
end
local events=rawCreateFrame('Frame');events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent',function(_,_,addon)if addon=='ForeverCoaching' then L:SetLanguage(L:GetLanguage())end end)
