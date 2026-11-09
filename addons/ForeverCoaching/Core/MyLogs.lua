local FC=ForeverCoaching
local M={};FC.MyLogs=M
local function normal(value)return tostring(value or ''):lower():gsub('[^%w]','')end
local function plain(value)return tostring(value or ''):gsub('|','||')end
local function finite(value)return type(value)=='number' and value==value and value>-math.huge and value<math.huge end
local function state()
 ForeverCoachingDB=ForeverCoachingDB or {};ForeverCoachingDB.myLogs=ForeverCoachingDB.myLogs or {};local guid=UnitGUID('player')
 if not guid then return {},nil end
 ForeverCoachingDB.myLogs[guid]=ForeverCoachingDB.myLogs[guid] or {};return ForeverCoachingDB.myLogs[guid],guid
end
local function role(class,spec)
 local s=normal(spec)
 if s=='restoration' or s=='holy' or class=='PRIEST' and s=='discipline'then return 'healer'end
 if s=='protection' or s=='guardian'then return 'tank'end
 return 'dps'
end
local function amount(value)if value>=1000000 then return string.format('%.1fm',value/1000000)elseif value>=1000 then return string.format('%.1fk',value/1000)end;return string.format('%.0f',value)end
function M:SetFight(key)local s=state();s.fight=key;if FC.myLogsView then FC.myLogsView.refresh()end end
function M:SetSpec(key)local s=state();s.spec=key;s.role=nil;if FC.myLogsView then FC.myLogsView.refresh()end end
function M:SetRole(key)local s=state();if key=='dps' or key=='healer' or key=='tank'then s.role=key end;if FC.myLogsView then FC.myLogsView.refresh()end end
function M:GetModel()
 local saved,guid=state();local _,class=UnitClass('player');local model={fights={},specs={},ready=false}
 local catalog=FC.PersonalCombatLog;local available={}
 if catalog and catalog.schema==1 and type(catalog.fights)=='table'then for _,fight in ipairs(catalog.fights)do
  if fight.guid==guid and type(fight.id)=='string' and finite(fight.duration) and fight.duration>0 and finite(fight.difficulty) and type(fight.damage)=='table' and type(fight.casts)=='table'then
   available[#available+1]=fight
  end
 end end
 table.sort(available,function(a,b)return (a.started or 0)>(b.started or 0)end)
 local selected
 for _,fight in ipairs(available)do
  local dungeon=fight.dungeonKey;for _,d in ipairs(FC.SupportedDungeons or {})do if d.key==dungeon then dungeon=d.name;break end end
  model.fights[#model.fights+1]={value=fight.id,label=plain(dungeon)..' / '..plain(fight.name)..' #'..fight.id..(fight.kill and '' or ' (unfinished)')}
  if fight.id==saved.fight then selected=fight end
 end
 selected=selected or available[1];model.selectedFight=selected and selected.id
 local examples=FC.WarcraftLogs:PublicExamples();local specs={}
 for _,entry in ipairs(examples)do if entry.class==class and not specs[entry.specKey]then specs[entry.specKey]=entry.spec;model.specs[#model.specs+1]={value=entry.specKey,label=entry.spec}end end
 table.sort(model.specs,function(a,b)return a.label<b.label end)
 local live
 if FC.WarcraftLogs.GetLiveSpecKey then live=FC.WarcraftLogs:GetLiveSpecKey()else live=FC.WarcraftLogs:GetPublicReportModel().selectedSpec end
 model.selectedSpec=specs[saved.spec] and saved.spec or specs[live] and live or model.specs[1] and model.specs[1].value
 model.specName=specs[model.selectedSpec]
 model.roles={{value='dps',label='DPS'},{value='healer',label='Healer'},{value='tank',label='Tank'}}
 model.selectedRole=(saved.role=='dps' or saved.role=='healer' or saved.role=='tank') and saved.role or role(class,model.specName)
 if not selected then model.message='No personal log is imported for this character. Select Import logs to get started.';return model end
 model.fight=selected;model.ready=true;model.message='Reference spec: '..plain(model.specName or 'choose a spec')..'. Confirm the spec and role you played; the local log does not verify them.'
 local chosen,chosenRotations
 local ownName=normal((selected.character or ''):gsub('%-Normal%-%u%u$',''))
 -- Warcraft Logs difficulty 10 is a dungeon category, not client difficulty 10.
 -- Only normal client dungeons are supported here; the catalog does not verify
 -- exact client difficulty, so disclose that instead of equating the two IDs.
 for _,entry in ipairs(examples)do if entry.class==class and entry.specKey==model.selectedSpec and entry.dungeonKey==selected.dungeonKey and entry.difficulty==10 and selected.difficulty==1 and entry.role==model.selectedRole and entry.complete and entry.kill and entry.rankingScope=='dungeon' and entry.performance and (ownName=='' or normal(entry.player)~=ownName)then
  local rotations={}
  for _,r in ipairs(entry.rotations)do if r.fullSequence and r.complete and (r.kind=='trash' or r.kill) and r.kind==selected.kind and (r.kind=='trash' or normal(r.name)==normal(selected.name))then rotations[#rotations+1]=r end end
  if #rotations>0 and (not chosen or entry.performance>chosen.performance)then chosen,chosenRotations=entry,rotations end
 end end
 if selected.kind=='boss' and not selected.kill then chosen=nil end
 local yourDamage=0;for _,spell in ipairs(selected.damage)do if finite(spell.amount) and spell.amount>=0 then yourDamage=yourDamage+spell.amount end end
 local healing=model.selectedRole=='healer';local yourTotal=healing and (selected.healing or 0) or yourDamage
 model.outputHeading=healing and 'Healing done' or 'Overall damage and DPS'
 model.yourOutput=amount(yourTotal)..(healing and ' healing - ' or ' dmg - ')..string.format('%.0f %s',yourTotal/selected.duration,healing and 'HPS' or 'DPS')..' / '..string.format('%.1fs',selected.duration)..' / '..tostring(selected.deaths or 0)..' deaths'
 if not chosen then model.missing=selected.kill and 'No complete reference matches this spec, dungeon, encounter and difficulty in the current catalog.' or 'This attempt was unfinished. Choose a completed boss attempt for a full-fight comparison.';return model end
 model.difficultyNotice='The catalog uses a general dungeon category; the reference\'s exact client difficulty cannot be verified.'
 local referenceDamage,referenceTime,last=0,0,0;local referenceCasts={};local healingAvailable=true
 table.sort(chosenRotations,function(a,b)return a.start<b.start end)
 for _,r in ipairs(chosenRotations)do
  referenceTime=referenceTime+math.max(0,r['end']-math.max(r.start,last));last=math.max(last,r['end'])
  if healing and not r.healing then healingAvailable=false end
  for _,spell in ipairs((healing and r.healing or not healing and r.damage) or {})do referenceDamage=referenceDamage+spell.amount end
  for _,step in ipairs(r.steps or {})do local key=normal(step.name);local count=referenceCasts[key] or {name=step.name,count=0};count.count=count.count+step.count;referenceCasts[key]=count end
 end
 if referenceTime<=0 then model.missing='The reference encounter duration is unavailable.';return model end
 model.referenceOutput=healing and not healingAvailable and 'Healing totals are not available for this reference encounter.' or amount(referenceDamage)..(healing and ' healing - ' or ' dmg - ')..string.format('%.0f %s',referenceDamage/referenceTime,healing and 'HPS' or 'DPS')..' / '..string.format('%.1fs',referenceTime)
 local book=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[class];local known={}
 local racial={bloodfury=true,berserking=true,warstomp=true,stoneform=true,devouringplague=true,starshards=true,feedback=true,hexofweakness=true,shadowguard=true,touchofweakness=true,desperateprayer=true,elunesgrace=true,willoftheforsaken=true}
 for name,spell in pairs(book and book.spells or {})do if not spell.passive and not racial[normal(name)]then known[normal(name)]=name end end
 local yours={};for _,spell in ipairs(selected.casts)do if finite(spell.count) and spell.count>=0 then yours[normal(spell.name)]=(yours[normal(spell.name)] or 0)+spell.count end end
 local lines,differences,positive={},{},{}
 for key,spell in pairs(referenceCasts)do if known[key]then
  local count=yours[key] or 0;local yourRate=count*60/selected.duration;local peerRate=spell.count*60/referenceTime
  lines[#lines+1]=plain(spell.name)..string.format(': you %d (%.1f/min) - example %d (%.1f/min)',count,yourRate,spell.count,peerRate)
  if spell.count>=2 and yourRate<peerRate*.75 then differences[#differences+1]={name=spell.name,yourRate=yourRate,peerRate=peerRate,gap=peerRate-yourRate}
  elseif count>0 and yourRate>=peerRate*.9 then positive[#positive+1]='You used '..plain(spell.name)..' at a similar or higher rate than the example.'end
 end end
 for key,count in pairs(yours)do if known[key] and not referenceCasts[key]then lines[#lines+1]=plain(known[key])..string.format(': you %d (%.1f/min) - example 0 (0.0/min)',count,count*60/selected.duration)end end
 table.sort(lines);table.sort(positive);table.sort(differences,function(a,b)return a.gap>b.gap end)
 model.abilityUse=#lines>0 and table.concat(lines,'\n') or 'No reviewed class abilities overlap with the reference.'
 model.good=positive[1] or 'Your fight has been recorded. No specific positive rotation habit can be established from the available counts alone.'
 local review={};for i=1,math.min(3,#differences)do local d=differences[i];review[#review+1]=plain(d.name)..string.format(': %.1f uses/min for you, %.1f in the example. Check whether targets, resources or mechanics explain the gap.',d.yourRate,d.peerRate)end
 model.review=#review>0 and table.concat(review,'\n') or 'No large class-ability frequency gaps were identified. This does not confirm an optimal rotation.'
 model.next=#differences>0 and ('Review '..plain(differences[1].name)..' in Learn, then check its opportunities in your next similar fight. Do not cast it blindly just to match a count.') or 'Review cooldown timing and encounter mechanics next; cast counts alone cannot judge those decisions.'
 model.reference=chosen
 return model
end
