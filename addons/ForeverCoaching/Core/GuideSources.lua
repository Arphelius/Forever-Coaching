local FC=ForeverCoaching
local Sources={provider='Wowhead',checked='2026-11-04'};FC.GuideSources=Sources
-- Overview URLs are published in Wowhead's Forever calculator guide index.
-- Keep allocation evidence separate: a reference link does not make a custom
-- or adapted build an author-published Wowhead allocation.
local specs={
 WARRIOR={{'arms','dps'},{'fury','dps'},{'protection','tank'}},
 PALADIN={{'holy','healer'},{'protection','tank'},{'retribution','dps'}},
 HUNTER={{'beast-mastery','dps'},{'marksmanship','dps'},{'survival','dps'}},
 ROGUE={{'assassination','dps'},{'combat','dps'},{'subtlety','dps'}},
 PRIEST={{'discipline','healer'},{'holy','healer'},{'shadow','dps'}},
 SHAMAN={{'elemental','dps'},{'enhancement','dps'},{'restoration','healer'}},
 MAGE={{'arcane','dps'},{'fire','dps'},{'frost','dps'}},
 WARLOCK={{'affliction','dps'},{'demonology','dps'},{'destruction','dps'}},
 DRUID={{'balance','dps'},{'feral','dps'},{'restoration','healer'}},
}
Sources.specs=specs
function Sources:ForSpec(class,tree,role)
 local entry=specs[class] and specs[class][tree];if not entry then return end
 local suffix=class=='DRUID' and tree==2 and role=='tank' and 'tank' or entry[2]
 local base='https://www.wowhead.com/forever/guide/classes/'..class:lower()..'/'..entry[1]..'/'
 return {provider='Wowhead',url=base..'overview-pve-'..suffix,class=class,tree=tree,role=role,checked=self.checked,
  scope='Primary specialization reference; compare hybrid and custom allocations with their actual talents.'}
end
function Sources:ForBuild(class,build)
 if not build then return end
 class=class or build.class
 if not class then
  for token,data in pairs(FC.Builds and FC.Builds.classes or {})do for _,candidate in ipairs(data.variants or {})do
   if candidate==build then class=token:upper();break end
  end;if class then break end end
 end
 if not class then return end
 local totals={0,0,0};for _,talent in ipairs(build.talents or {})do if totals[talent.treeIndex]then totals[talent.treeIndex]=totals[talent.treeIndex]+(talent.rank or 0)end end
 local tree=1;for i=2,3 do if totals[i]>totals[tree]then tree=i end end
 return self:ForSpec(class,tree,build.role)
end
function Sources:SpellUrl(id)
 if type(id)=='number' and id>0 and id%1==0 then return 'https://www.wowhead.com/forever/spell='..id end
end
