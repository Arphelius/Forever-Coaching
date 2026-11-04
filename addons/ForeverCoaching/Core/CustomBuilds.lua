local FC=ForeverCoaching
local C={limit=50,maxPoints=51};FC.CustomBuilds=C
local function database()
 ForeverCoachingDB=ForeverCoachingDB or {};ForeverCoachingDB.customTalentBuilds=ForeverCoachingDB.customTalentBuilds or {}
 return ForeverCoachingDB.customTalentBuilds
end
local function integer(v)return type(v)=='number' and v%1==0 end
local function key(tree,index)return tree..':'..index end
local function copy(value)if type(value)~='table' then return value end;local result={};for k,v in pairs(value)do result[k]=copy(v)end;return result end
local roles={WARRIOR={'damage','tank'},PALADIN={'damage','tank','healer'},DRUID={'damage','tank','healer'},PRIEST={'damage','healer'},SHAMAN={'damage','healer'}}
function C:GetRoles(class)return roles[class] or {'damage'}end
function C:New(class)return {class=class,name='My custom build',role='damage',ranks={},order={}}end
function C:List(class)
 local list=database()[class];if type(list)~='table' then return {}end;return list
end
function C:Find(class,id)for _,build in ipairs(self:List(class))do if build.id==id then return build end end end
function C:Draft(build)
 local draft=self:New(build.class);draft.id=build.id;draft.name=build.title;draft.role=build.role
 draft.importSource=copy(build.importSource)
 -- Saved indices belong to the old layout. Resolve names first so a moved
 -- talent can never turn into an unrelated purchase after a class rework.
 local lookup={};for ti,tree in ipairs(FC.TalentTrees[build.class] or {})do for ni,node in ipairs(tree.nodes)do lookup[node.name]={ti=ti,ni=ni,node=node}end end
 for _,talent in ipairs(build.talents or {})do
  local current=lookup[talent.name]
  if not current or talent.rank>current.node.maxRank then draft.layoutIssue='This saved build contains changed talents. Reset the calculator and save an updated allocation.'
  else draft.ranks[key(current.ti,current.ni)]=talent.rank end
 end
 for _,step in ipairs(build.levelingOrder or {})do
  local current=lookup[step.name]
  if current then draft.order[#draft.order+1]={treeIndex=current.ti,talentIndex=current.ni}
  else draft.layoutIssue='This saved build contains changed talents. Reset the calculator and save an updated allocation.' end
 end
 return draft
end
local function prerequisite(class,node)
 local current=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[class]
 return node.requires or (current and current.talents[node.name] and current.talents[node.name].requires)
end
function C:Validate(draft,allowEmpty)
 if draft and draft.layoutIssue then return nil,draft.layoutIssue end
 if type(draft)~='table' or not FC.TalentTrees[draft.class] then return nil,'Choose a valid class.'end
 if type(draft.ranks)~='table' or type(draft.order)~='table' then return nil,'Invalid custom build data.'end
 local layout=FC.TalentTrees[draft.class];local lookup={};local totals={0,0,0};local expected=0
 for ti,tree in ipairs(layout)do for ni,node in ipairs(tree.nodes)do lookup[node.name]={treeIndex=ti,talentIndex=ni,node=node}end end
 for address,rank in pairs(draft.ranks)do
  if type(address)~='string' then return nil,'Invalid talent address.'end
  local ti,ni=address:match('^([1-3]):(%d+)$');ti,ni=tonumber(ti),tonumber(ni)
  local node=ti and ni and layout[ti] and layout[ti].nodes[ni]
  if not node or not integer(rank) or rank<0 or rank>node.maxRank then return nil,'Talent rank is outside its allowed range.'end
  expected=expected+rank
 end
 if expected>self.maxPoints then return nil,'A level 60 build can use at most 51 talent points.'end
 if expected==0 and not allowEmpty then return nil,'Add at least one talent point before saving.'end
 if #draft.order~=expected then return nil,'Point order does not match the allocation.'end
 local ranks,order={},{}
 for point,pick in ipairs(draft.order)do
  if type(pick)~='table' or not integer(pick.treeIndex) or not integer(pick.talentIndex) then return nil,'Invalid point order.'end
  local ti,ni=pick.treeIndex,pick.talentIndex;local node=layout[ti] and layout[ti].nodes[ni]
  if not node then return nil,'This talent is not in the current layout.'end
  local address=key(ti,ni);local rank=(ranks[address] or 0)+1
  if rank>node.maxRank or rank>(draft.ranks[address] or 0) then return nil,'Point order exceeds the chosen ranks.'end
  if totals[ti]<node.row*5 then return nil,'Spend more points in earlier tiers of this tree first.'end
  local required=prerequisite(draft.class,node)
  if required then
   local name=type(required)=='table' and required.name or required
   local target=lookup[name];local amount=type(required)=='table' and required.rank or (target and target.node.maxRank)
   if not target or (ranks[key(target.treeIndex,target.talentIndex)] or 0)<amount then return nil,'Required talent: '..tostring(name)end
  end
  ranks[address]=rank;totals[ti]=totals[ti]+1
  order[#order+1]={level=point+9,name=node.name,rank=rank,maxRank=node.maxRank,spellId=node.spellId,icon=node.icon,treeIndex=ti,talentIndex=ni,row=node.row,col=node.col,why=draft.importSource and (draft.importSource.orderSuggested and 'Suggested order for your imported allocation.' or 'Your imported Wowhead point order.') or 'Your saved custom point order.'}
 end
 return {points=expected,totals=totals,order=order,ranks=ranks}
end
function C:Change(draft,ti,ni,delta)
 if delta~=1 and delta~=-1 then return nil,'Change one point at a time.'end
 local candidate=copy(draft);local address=key(ti,ni);local rank=(candidate.ranks[address] or 0)+delta
 candidate.ranks[address]=rank
 if delta==1 then candidate.order[#candidate.order+1]={treeIndex=ti,talentIndex=ni}
 else
  for index=#candidate.order,1,-1 do local pick=candidate.order[index];if pick.treeIndex==ti and pick.talentIndex==ni then table.remove(candidate.order,index);break end end
 end
 local valid,err=self:Validate(candidate,true);if not valid then return nil,err end
 draft.ranks=candidate.ranks;draft.order=candidate.order
 return valid
end
function C:Save(draft)
 local valid,err=self:Validate(draft);if not valid then return nil,err end
 local name=type(draft.name)=='string' and draft.name:gsub('[%c|]',''):match('^%s*(.-)%s*$') or ''
 local _,characters=name:gsub('[%z\1-\127\194-\244]','')
 if name=='' or characters>60 then return nil,'Enter a build name of 1 to 60 characters.'end
 draft.name=name
 local roleOK=false;for _,role in ipairs(self:GetRoles(draft.class))do if draft.role==role then roleOK=true end end
 if not roleOK then return nil,'Choose a valid role for this class.'end
 local list=self:List(draft.class);local position
 for index,build in ipairs(list)do if build.id==draft.id then position=index end end
 if draft.id and not position then return nil,'This custom build no longer exists. Create a new build.'end
 if not position and #list>=self.limit then return nil,'Custom build limit reached for this class.'end
 if not position then
  repeat
   ForeverCoachingDB.customBuildSerial=math.max(0,math.floor(tonumber(ForeverCoachingDB.customBuildSerial) or 0))+1
   draft.id='custom-'..draft.class:lower()..'-'..ForeverCoachingDB.customBuildSerial
  until not self:Find(draft.class,draft.id)
 end
 local talents,codes={},{}
 for ti,tree in ipairs(FC.TalentTrees[draft.class])do
  local digits={}
  for ni,node in ipairs(tree.nodes)do
   local rank=valid.ranks[key(ti,ni)] or 0;digits[#digits+1]=tostring(rank)
   if rank>0 then talents[#talents+1]={name=node.name,tree=tree.name,treeIndex=ti,talentIndex=ni,rank=rank,maxRank=node.maxRank,tier=node.row+1}end
  end
  codes[#codes+1]=table.concat(digits):gsub('0+$','')
 end
 local build={kind='custom',class=draft.class,id=draft.id,title=name,specialization=name,role=draft.role,evidence='custom',maxLevel=60,points=valid.points,
  talents=talents,talentString=table.concat(codes,'-'),distribution=table.concat(valid.totals,' / '),levelingOrder=valid.order,
  importSource=copy(draft.importSource),source={name=draft.importSource and 'Wowhead custom build' or 'Custom build',url=draft.importSource and draft.importSource.url or '',talentSnapshot=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.build},note='Player-created experiment; not a published or ranked recommendation.'}
 list[position or #list+1]=build;database()[draft.class]=list
 if FC.Localization then FC.Localization.protected=nil;FC.Localization.keys=nil;FC.Localization.cache=nil end
 return build
end
function C:Select(class,id,guid)
 local build=self:Find(class,id);if not build then return nil,'Custom build not found.'end
 local valid,err=self:Validate(self:Draft(build));if not valid then return nil,err end
 guid=guid or (UnitGUID and UnitGUID('player'));local _,playerClass=UnitClass('player')
 if not guid or playerClass~=class then return nil,'Only your current class can be selected for in-game guidance.'end
 ForeverCoachingDB.activeTalentBuilds=ForeverCoachingDB.activeTalentBuilds or {};ForeverCoachingDB.activeTalentBuilds[guid]=id
 ForeverCoachingDB.selectedTalentBuilds=ForeverCoachingDB.selectedTalentBuilds or {};local selected=ForeverCoachingDB.selectedTalentBuilds[guid] or {}
 for _,activity in ipairs({'leveling','dungeons','raids','pvp'})do selected[class..':'..activity]=id end
 ForeverCoachingDB.selectedTalentBuilds[guid]=selected
 return build
end
function C:Delete(class,id)
 local list=self:List(class);local removed
 for index,build in ipairs(list)do if build.id==id then table.remove(list,index);removed=true;break end end
 if not removed then return false end
 for guid,active in pairs(ForeverCoachingDB.activeTalentBuilds or {})do if active==id then ForeverCoachingDB.activeTalentBuilds[guid]=nil end end
 for _,selections in pairs(ForeverCoachingDB.selectedTalentBuilds or {})do for activity,active in pairs(selections)do if active==id then selections[activity]=nil end end end
 return true
end
