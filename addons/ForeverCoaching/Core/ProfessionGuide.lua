local FC=ForeverCoaching
local G={};FC.ProfessionGuide=G
local root='https://www.wowhead.com/forever/guide/'
G.sources={overview=root..'professions/overview',alchemy=root..'professions/alchemy-overview-trainer-locations-recipes',engineering=root..'professions/engineering-overview-trainer-locations-recipes',firstAid=root..'professions/first-aid/overview'}
G.goals={{id='leveling',label='Leveling'},{id='dungeons',label='Dungeons'},{id='raids',label='Raids'},{id='pvp',label='PvP'},{id='gold',label='Gold'}}
for _,entry in ipairs(G.goals)do entry.value=entry.id end
local leveling={
 WARRIOR={'Blacksmithing + Mining','Forge weapons and armor; weapon upgrades support Arms/Fury damage, while Protection also needs a suitable shield and defensive gear.'},
 PALADIN={'Blacksmithing + Mining','Craft armor for your role: Holy needs healing and Mana stats, Protection needs a shield and survival, and Retribution values its weapon and damage stats.'},
 HUNTER={'Leatherworking + Skinning','Craft leather and later mail with useful offensive stats. Feed your recipes with hides from beasts you already kill.'},
 ROGUE={'Leatherworking + Skinning','Make leather upgrades for attack power and safe melee uptime. Keep the weapon requirements of your chosen attacks in mind.'},
 DRUID={'Leatherworking + Skinning','Craft leather for your form or spell role. Cat damage, Bear survival and caster/healer stats need different pieces.'},
 SHAMAN={'Leatherworking + Skinning','Choose melee gear for Enhancement or spell/healing gear for Elemental and Restoration; Leatherworking supports leather and later mail.'},
 MAGE={'Tailoring + Enchanting','Turn looted cloth into caster gear and bags; disenchant spare crafted pieces for enchants and early wands.'},
 PRIEST={'Tailoring + Enchanting','Craft cloth and early wands. Wands help conserve Mana while leveling; choose healing or damage stats for your allocation.'},
 WARLOCK={'Tailoring + Enchanting','Craft cloth with useful spell stats and bags, then disenchant spare gear. Choose school bonuses that support the spells in your build.'},
}
function G:ForBuild(class,build,goal)
 local base=leveling[class];if not base then return {available=false,notice='Choose a class and specialization.'}end
 local spec=build and FC.SpecScenarios and FC.SpecScenarios.ForPreview and FC.SpecScenarios:ForPreview(class,build)
 local tree=spec and spec.treeIndex or 1;local role=build and build.role or 'damage';goal=goal or 'leveling'
 local out={available=true,class=class,spec=spec and spec.spec or class,role=role,goal=goal,reviewed='2026-11-04',pair=base[1],why=base[2],sources={G.sources.overview},
  approach='Recommended for this goal; costs, available recipes and your group can change the best choice.',
  secondary='Learn First Aid, Cooking and Fishing alongside your two primary professions. In Forever, First Aid crafts standard healing potions. Food and bandages support recovery between fights.'}
 if goal=='gold' then out.pair='Herbalism + Mining';out.why='Gather materials for other crafters while questing. Compare local prices; Skinning is an alternative when your route already includes many beasts.'
 elseif goal=='pvp' then out.pair='Engineering + Mining';out.why='Engineering adds grenades and situational gadgets for control and pressure. Mining supplies the materials. Damage can break control, so coordinate before throwing explosives.'
 elseif goal~='leveling' then
  if role=='healer' or (class=='SHAMAN' and tree==1) or (class=='DRUID' and tree==1) then
   out.pair='Alchemy + Herbalism';out.why='Supply Mana potions and role-appropriate consumables for longer encounters. Herbalism feeds the recipes; carry healing potions from First Aid as separate emergency recovery.'
  elseif class=='MAGE' or class=='PRIEST' or class=='WARLOCK' then
   out.pair='Tailoring + Enchanting';out.why=base[2]..' Alchemy is an alternative for self-supplied consumables; Engineering is an alternative when gadget utility matters more.'
  elseif class=='DRUID' and role=='tank' then
   out.pair='Alchemy + Herbalism';out.why='Supply consumables for Bear survival and sustained encounters. Engineering is an alternative for permitted area pressure; crafted leather remains an equipment option.'
  else out.pair='Engineering + Mining';out.why='Add crafted grenades and utility to your existing attacks. Use explosives only when the group permits area damage; Mining helps fund the material cost.' end
 end
 if role=='healer' then
  out.use='Carry Mana potions for low Mana and healing potions for your own emergency. Mender\'s Potions support a planned healing window; keep direct heals and assigned dispels ahead of optional items.'
 elseif class=='WARRIOR' then
  out.use='Healing potions cover emergencies. Rage potions help when Rage is low. Frenzy Potions support melee burst; grenades can add permitted area pressure without replacing threat or defensive duties.'
 elseif class=='ROGUE' then
  out.use='Thistle Tea restores Energy, so leave room for its return. Frenzy Potions support attack-power windows. Use grenades without breaking Sap, Gouge or other assigned control.'
 elseif class=='HUNTER' then
  out.use=tree==3 and 'Survival uses its melee attack plan: Frenzy Potions support attack power, Mana potions preserve utility, and grenades add permitted area damage.' or 'Engineering can supply guns, ammunition and scopes as equipment. Frenzy Potions support ranged attack power; Mana potions preserve shot and utility uptime.'
 elseif class=='DRUID' and tree==2 then
  out.use=role=='tank' and 'Bear can use healing potions for survival and suitable Rage potions for low Rage. Keep the correct form and required defenses ahead of optional damage items.' or 'Cat can use Thistle Tea when Energy is low and Frenzy Potions during burst. Choose form-specific equipment; ordinary weapon DPS is not the whole comparison.'
 elseif class=='PALADIN' and tree==2 then
  out.use='Mana potions sustain threat tools. Spellblasting Potions support Holy damage during a planned window. Crafted shields and armor are equipment upgrades, rather than buttons in the combat sequence.'
 elseif (class=='PALADIN' and tree==3) or (class=='SHAMAN' and tree==2) then
  out.use='Frenzy Potions support your physical attack window; Mana potions preserve spells and utility. Compare the whole hybrid setup before replacing gear with purely physical or caster items.'
 else out.use='Spellblasting Potions support a planned spell-damage window. Mana potions preserve casting and utility. Apply oils, long-duration elixirs, food and equipment upgrades before combat.' end
 out.preparation='Crafted armor, weapons, enchants, oils and food belong in preparation. Combat suggestions cover verified usable consumables in your bags; owning a recipe or having an item in the bank is insufficient.'
 out.items='Automatic crafted items: healing below 30% Health; Mana below 20%; Thistle Tea at low Energy; Rage potions at low Rage. Damage/healing buffs require your burst window, and grenades require area damage allowed.'
 out.sources[#out.sources+1]=G.sources.firstAid;out.sources[#out.sources+1]=G.sources.alchemy;out.sources[#out.sources+1]=G.sources.engineering
 return out
end
