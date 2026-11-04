local FC=ForeverCoaching
local W={};FC.WowheadBuilds=W
local alphabet='abcdefghjkmnpqrstvwzxyilou468-~!'
local capitals='ABCDEFGHJKMNPQRSTVWZXYILOU579_^.'
local function split(value,separator)
 local parts={};for part in (value..separator):gmatch('(.-)'..separator)do parts[#parts+1]=part end;return parts
end
local function mapping(class)
 local source=FC.WowheadTalentLayouts and FC.WowheadTalentLayouts.classes[class]
 local layout=FC.TalentTrees[class];if not source or not layout then return end
 local localNames,byAddress,bySource={},{},{}
 for ti,tree in ipairs(layout)do for ni,node in ipairs(tree.nodes)do localNames[node.name]={ti=ti,ni=ni,node=node}end end
 for ti,tree in ipairs(source)do bySource[ti]={};for wi,talent in ipairs(tree)do
  local target=localNames[talent.name]
  if target and target.ti==ti and target.node.maxRank==talent.maxRank and target.node.row==talent.row then
   local item={ti=ti,ni=target.ni,wi=wi,node=target.node,source=talent}
   bySource[ti][wi]=item;byAddress[ti..':'..target.ni]=item
  end
 end end
 return source,bySource,byAddress
end
local function orderFor(draft)
 local layout=FC.TalentTrees[draft.class];local totals,spent,names={0,0,0},{0,0,0},{}
 local candidates={}
 for ti,tree in ipairs(layout)do for ni,node in ipairs(tree.nodes)do
  local target=draft.ranks[ti..':'..ni] or 0
  if target>0 then totals[ti]=totals[ti]+target;candidates[#candidates+1]={ti=ti,ni=ni,node=node,target=target}end
  names[node.name]={ti=ti,ni=ni,node=node}
 end end
 table.sort(candidates,function(a,b)if a.ti~=b.ti then return totals[a.ti]==totals[b.ti] and a.ti<b.ti or totals[a.ti]>totals[b.ti]end;if a.node.row~=b.node.row then return a.node.row<b.node.row end;return a.ni<b.ni end)
 local taken={};draft.order={}
 for point=1,totals[1]+totals[2]+totals[3]do
  local selected
  for _,pick in ipairs(candidates)do
   local address=pick.ti..':'..pick.ni;local required=pick.node.requires
   local current=FC.ForeverSpellCatalog and FC.ForeverSpellCatalog.classes[draft.class].talents[pick.node.name]
   required=required or (current and current.requires)
   local name=type(required)=='table' and required.name or required;local prereq=name and names[name]
   local amount=type(required)=='table' and required.rank or (prereq and prereq.node.maxRank)
   if (taken[address] or 0)<pick.target and spent[pick.ti]>=pick.node.row*5
    and (not required or (prereq and (taken[prereq.ti..':'..prereq.ni] or 0)>=amount)) then selected=pick;break end
  end
  if not selected then return nil,'This allocation cannot be learned with the current talent requirements.'end
  local address=selected.ti..':'..selected.ni;taken[address]=(taken[address] or 0)+1;spent[selected.ti]=spent[selected.ti]+1
  draft.order[#draft.order+1]={treeIndex=selected.ti,talentIndex=selected.ni}
 end
 return true
end
function W:Import(url)
 if type(url)~='string' or #url>2048 then return nil,'Paste a Wowhead Forever talent calculator link.'end
 url=url:match('^%s*(.-)%s*$')
 local host,path=url:match('^https://([^/]+)/([^?#]+)')
 if not host or (host:lower()~='wowhead.com' and host:lower()~='www.wowhead.com') then return nil,'Use a link from wowhead.com/forever/talent-calc.'end
 path=path:gsub('/$',''):gsub('^forever/%a%a/','forever/')
 local slug,tail=path:match('^forever/talent%-calc/(%a+)/(.*)$')
 if not slug then slug=path:match('^forever/talent%-calc/(%a+)$');tail='' end
 local class=slug and slug:upper();local source,bySource=mapping(class)
 if not source then return nil,'Choose a supported Wowhead Forever class link.'end
 local draft=FC.CustomBuilds:New(class);draft.name='Wowhead '..slug..' build';draft.importSource={url=url,orderSuggested=false}
 if tail=='' then return draft end
 local segments=split(tail,'/');if #segments>2 then return nil,'This Wowhead link format is not supported.'end
 local fields=split(segments[1],'_');local points=table.remove(fields,1)
 if points:sub(1,2)~='v2' then return nil,'Use a current Wowhead Forever v2 talent link.'end
 points=points:sub(3);if points:find('[^0-5%-]') then return nil,'Invalid talent ranks in this Wowhead link.'end
 local seen={}
 for _,field in ipairs(fields)do
  local kind,value=field:match('^([tlr])(%d+)$');value=tonumber(value)
  if not kind or seen[kind] or (kind=='t' and value>5) or (kind=='l' and (value<1 or value>60)) or (kind=='r' and value<1) then return nil,'Unsupported calculator options in this Wowhead link.'end
  seen[kind]=true;draft.importSource[kind]=value
 end
 local codes=split(points,'-');if #codes>3 then return nil,'This link has too many talent trees.'end
 local count=0
 for ti,code in ipairs(codes)do
  if #code>#source[ti] then return nil,'This link uses a different talent layout. Check it in Wowhead.'end
  for wi=1,#code do
   local rank=tonumber(code:sub(wi,wi));local item=bySource[ti][wi]
   if rank>0 then
    if not item or rank>item.node.maxRank then return nil,'This link does not match the current talent data.'end
    draft.ranks[ti..':'..item.ni]=rank;count=count+rank
   end
  end
 end
 if count>51 then return nil,'A level 60 build can use at most 51 talent points.'end
 local totals={0,0,0};for address,rank in pairs(draft.ranks)do local ti=tonumber(address:sub(1,1));totals[ti]=totals[ti]+rank end
 local primary=1;for ti=2,3 do if totals[ti]>totals[primary]then primary=ti end end
 local profile=FC.SpecScenarioProfiles and FC.SpecScenarioProfiles[class] and FC.SpecScenarioProfiles[class][primary]
 if profile then draft.role=profile.role or 'damage' end
 if segments[2] and segments[2]~='' then
  local tree
  for i=1,#segments[2]do
   local char=segments[2]:sub(i,i)
   if char=='0' or char=='1' or char=='2' then tree=tonumber(char)+1
   else
    local index=alphabet:find(char,1,true);local amount=1
    if not index then index=capitals:find(char,1,true);amount=index and source[tree or 0] and source[tree][index] and source[tree][index].maxRank end
    local item=tree and index and bySource[tree][index]
    if not item or not amount then return nil,'Invalid talent order in this Wowhead link.'end
    if #draft.order+amount>51 then return nil,'Invalid talent order in this Wowhead link.'end
    for _=1,amount do draft.order[#draft.order+1]={treeIndex=tree,talentIndex=item.ni}end
   end
  end
 else
  local ok,err=orderFor(draft);if not ok then return nil,err end;draft.importSource.orderSuggested=true
 end
 local valid,err=FC.CustomBuilds:Validate(draft,true);if not valid then return nil,err end
 return draft
end
function W:Export(draft)
 local valid,err=FC.CustomBuilds:Validate(draft,true);if not valid then return nil,err end
 local source,_,addresses=mapping(draft.class);if not source then return nil,'Wowhead calculator data is unavailable for this class.'end
 local base='https://www.wowhead.com/forever/talent-calc/'..draft.class:lower()
 if valid.points==0 then return base end
 local codes={}
 for ti,tree in ipairs(source)do local digits={};for _=1,#tree do digits[#digits+1]='0'end
  for address,item in pairs(addresses)do if item.ti==ti then digits[item.wi]=tostring(draft.ranks[address] or 0)end end
  codes[ti]=table.concat(digits):gsub('0+$','')
 end
 local order,tree={},nil
 for _,pick in ipairs(draft.order)do
  local item=addresses[pick.treeIndex..':'..pick.talentIndex]
  if not item or item.wi>#alphabet then
   local node=FC.TalentTrees[draft.class][pick.treeIndex].nodes[pick.talentIndex]
   return nil,'Wowhead calculator data does not match this talent: '..node.name
  end
  if tree~=pick.treeIndex then tree=pick.treeIndex;order[#order+1]=tostring(tree-1)end
  order[#order+1]=alphabet:sub(item.wi,item.wi)
 end
 local options='';for _,kind in ipairs({'t','l','r'})do local value=draft.importSource and draft.importSource[kind];if value then options=options..'_'..kind..value end end
 return base..'/v2'..table.concat(codes,'-'):gsub('%-+$','')..options..'/'..table.concat(order)
end
