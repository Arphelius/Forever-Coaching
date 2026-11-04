local FC=ForeverCoaching
local A={};FC.ScenarioActions=A
local function step(spell,when,action,why,talent)
 return {spell=spell,when=when,action=action,why=why,talent=talent}
end
local function recipe(prepare,steps,avoid)
 return {prepare=prepare,steps=steps,avoid=avoid}
end
local selfActions={}
for _,name in ipairs({'Lightning Mastery','Rage of the Farseer','Nature\'s Swiftness','Arcane Power','Combustion','Icy Veins','Starfall','Berserk','Divine Favor','Holy Shield','Divine Protection','Avenging Wrath','Inner Focus','Cold Blood','Blade Flurry','Adrenaline Rush','Shadow Dance','Sweeping Strikes','Recklessness','Death Wish','Shield Wall','Shield Block','Rapid Fire','Bestial Wrath','Metamorphosis','Sprint','Dash','Blink','Evocation','Life Tap','Bloodrage','Feign Death','Hellfire','Arcane Explosion','Consecration','Thunder Clap','Whirlwind','Divine Storm','Frenzied Regeneration','Barkskin'}) do selfActions[name]=true end
local function basic(spell,when,why,talent)
 local action
 if spell=='Earthbind Totem' then action='Drop Earthbind Totem where the pursuers must cross, then run along the safe route.'
 elseif spell=='Freezing Trap' then action='Place Freezing Trap on the assigned target\'s approach; keep pet and area damage off that target.'
 elseif spell=='Fire Nova' then action='Cast Fire Nova while your active fire totem is beside the intended enemies.'
 elseif spell=='Blizzard' or spell=='Flamestrike' or spell=='Hurricane' or spell=='Rain of Fire' then action='Place '..spell..' over the intended group of enemies.'
 elseif spell=='Dispel Magic' and when:find('friendly or hostile',1,true) then action='Cast Dispel Magic on the player carrying the agreed removable Magic effect.'
 elseif selfActions[spell] then action='Use '..spell..'.'
 elseif when:find('recipient',1,true) then action='Cast '..spell..' on the agreed recipient.'
 elseif when:find('tank',1,true) then action='Cast '..spell..' on the tank.'
 elseif when:find('ally',1,true) then action='Cast '..spell..' on that ally.'
 elseif spell=='Prayer of Healing' then action='Cast Prayer of Healing for the injured group.'
 elseif spell=='Chain Heal' then action='Cast Chain Heal on an injured ally beside the other injured allies.'
 elseif spell=='Earth Shock' and when:find('interruptible',1,true) then action='Cast Earth Shock on the enemy caster before the cast finishes.'
 else action='Cast '..spell..' on your assigned target.' end
 return step(spell,when,action,why,talent)
end
-- These are conditional walkthroughs, not a claim that these spells are ready
-- right now. The current-character view filters actions by learned abilities.
local shared={
 SHAMAN={
  utility=recipe('Target the enemy caster. Keep Earth Shock off cooldown for your assigned interrupt.',{
   basic('Earth Shock','Your assigned enemy starts a dangerous interruptible cast; Earth Shock is ready and in range.','Interrupting prevents the cast effect. Spending Earth Shock for damage can lose this stop.'),
   basic('Cure Poison','Your assigned ally has a removable Poison and this mechanic permits cleansing.','Removes the Poison instead of healing through its remaining effect.'),
   basic('Cure Disease','Your assigned ally has a removable Disease and this mechanic permits cleansing.','Removes the Disease; it is not a Poison or Curse cleanse.'),
   basic('Lesser Healing Wave','An ally will die before Healing Wave can finish, and a heal is your responsibility.','The shorter cast is an emergency response; do not interrupt the assigned enemy cast to do optional healing.')},'Do not use Earth Shock for damage immediately before your assigned interrupt.'),
  movement=recipe('Choose the safe location before the mechanic begins. Keep Earth Shock reserved if you have the next interrupt.',{
   step(nil,'A ground effect or movement mechanic threatens you.','Move out first. Do not start Lightning Bolt or Chain Lightning.','Finishing a hard cast is not worth taking an avoidable mechanic.'),
   basic('Flame Shock','You are moving, the target is in range, and Flame Shock will last long enough to deal useful damage.','Its instant application can contribute while you reposition; do not refresh it just to press a button.')},'Do not stop inside a mechanic to finish a Lightning Bolt.'),
  resources=recipe('Check your mana before the next pull. Tell the tank when you need to drink.',{
   step(nil,'Combat has ended and your mana will not cover the next pull.','Drink before the tank pulls again.','Recovery between pulls prevents losing essential casts during combat.'),
   step(nil,'Mana is low during combat, but no assigned heal, cleanse or interrupt is due.','Stop optional shock and area-spell casts. Preserve mana for Earth Shock and required support.','Optional damage must not consume the mana needed for the next assigned action.')},'Do not spend your last mana on optional Fire Nova before an assigned interrupt.')},
 MAGE={
  utility=recipe('Assign a caster to Counterspell and mark any Polymorph target before the pull.',{
   basic('Counterspell','Your assigned enemy starts an interruptible cast; Counterspell is ready and in range.','Stops that cast. Do not duplicate another assigned interrupt.'),
   basic('Remove Lesser Curse','Your assigned ally has a removable Curse and removal is safe.','Removes a Curse; it does not remove Magic, Poison or Disease.'),
   basic('Polymorph','The assigned eligible enemy needs control and nobody is damaging it.','Keeps that enemy out of the active fight; damage can break the control.')},'Do not hit the Polymorph target with cleave or area damage.'),
  movement=recipe('Face a safe landing position before using Blink.',{
   basic('Blink','The safe destination is in front of you and the path is suitable.','Repositions quickly; the destination must be safe.'),
   basic('Fire Blast','You are moving, Fire Blast is ready, and its target is in range.','An instant cast can deal damage without stopping your movement.')},'Do not Blink into another hazard or stop in one to cast Frostbolt.'),
  resources=recipe('Recover mana before the next pull; save Evocation for a safe channel window.',{
   basic('Evocation','Mana recovery is needed and no immediate damage or movement will interrupt the channel.','A safe channel recovers resources; forced movement wastes the window.'),
   step(nil,'Combat ends and mana is low.','Drink before the next pull.','Avoid beginning the next fight without enough mana for Counterspell and damage casts.')},'Do not start Evocation immediately before a movement mechanic.')},
 PRIEST={
  utility=recipe('Confirm which Magic and Disease effects you must remove.',{
   basic('Dispel Magic','Your assigned ally has a removable harmful Magic effect and dispelling is safe.','Removes Magic effects; choose the affected ally rather than an enemy.'),
   basic('Cure Disease','Your assigned ally has a removable Disease.','Disease removal is a separate action from Dispel Magic.')},'Do not dispel an effect that the encounter requires you to retain.'),
  movement=recipe('Move to a position that keeps injured allies in healing range.',{
   step(nil,'A mechanic requires movement.','Move immediately; cancel the current cast if it prevents reaching safety.','Preventing a death to the mechanic comes before finishing a cast.'),
   basic('Renew','You are moving and an injured ally will benefit from its healing ticks.','An instant heal can contribute while you relocate.'),
   basic('Power Word: Shield','An ally needs immediate protection and can receive your shield.','The absorb can protect before a casted heal would land.')},'Do not refresh Renew on a full-health ally just because you are moving.'),
  resources=recipe('Choose a safe time to recover before the group starts another pull.',{
   step(nil,'Combat has ended and your next pull needs more mana than you have.','Drink and tell the tank to wait.','Mana spent on the next emergency cannot be recovered by optional casts now.'),
   step(nil,'Mana is low and incoming damage is controlled.','Stop optional damage casts and unnecessary Renew refreshes.','Keep mana available for the next assigned heal or Dispel Magic.')},'Do not stop a required lifesaving heal to improve mana efficiency.')},
 DRUID={
  utility=recipe('Confirm Curse and Poison assignments before pulling.',{
   basic('Remove Curse','An assigned ally has a removable Curse and removal is safe.','Removes a Curse; use the matching removal rather than a heal.'),
   basic('Cure Poison','An assigned ally has a removable Poison and removal is safe.','Removes a Poison; account for the mana and form change needed.')},'Do not abandon a dangerous tanking assignment to perform an optional cleanse.'),
  movement=recipe('Mark a safe destination and keep your assigned target in reach.',{
   step(nil,'A ground mechanic requires movement.','Move out before starting another Wrath, Starfire or Healing Touch.','Those casts cannot justify standing in danger.'),
   basic('Dash','You are in the required form and need to reach the safe location faster.','The movement-speed window helps meet the mechanic deadline.'),
   basic('Rejuvenation','You are moving and an injured ally needs sustained healing.','Instant periodic healing can contribute during relocation.')},'Do not shift away from required tanking just to use an optional spell.'),
  resources=recipe('Plan whether the next pull needs Mana, Energy or Rage; account for shifting costs.',{
   basic('Innervate','The agreed recipient needs mana recovery and can benefit from the current effect.','The recipient and timing matter more than using it on cooldown.'),
   step(nil,'Combat has ended and Mana is low.','Drink before the next pull. Do not repeatedly shift while recovering.','Shifting and support spells can consume the same mana you need to recover.')},'Do not spend mana on repeated shifting immediately before an assigned emergency heal.')},
 PALADIN={
  utility=recipe('Confirm cleansing and stun assignments before the pull.',{
   basic('Cleanse','Your assigned ally has removable Magic, Poison or Disease and removal is safe.','Removes supported debuffs; it is not a Curse removal.'),
   basic('Purify','An assigned ally has Poison or Disease and Cleanse is not available.','This is the lower-toolkit fallback; it does not remove Magic.'),
   basic('Hammer of Justice','An assigned stun is needed, the enemy is eligible, and you are in range.','Stops an eligible enemy acting for the stun window.')},'Do not use the assigned stun on an immune target or overlap it without a reason.'),
  movement=recipe('Plan a safe position that maintains access to the tank or your melee target.',{
   step(nil,'A mechanic requires movement.','Move out immediately. Cancel Holy Light if needed to reach safety.','The heal is not useful if completing it kills you.'),
   basic('Cleanse','You can safely remove an assigned debuff while moving.','Instant utility can be completed without stopping to hard cast.')},'Do not keep casting from a dangerous position to avoid losing one global cooldown.'),
  resources=recipe('Check Mana before the tank starts the next pull.',{
   step(nil,'Combat has ended and Mana is insufficient for the next pull.','Drink and tell the group to wait.','You need mana for your next heal, cleanse or threat action.'),
   step(nil,'Mana is low and no emergency is due.','Stop optional damage and unnecessary healing. Keep mana for your assigned role.','Do not spend your last resource on throughput that does not solve an encounter need.')},'Do not begin a larger pull without mana for the opening threat or healing actions.')},
 ROGUE={
  utility=recipe('Assign a caster to Kick and mark the Sap target before combat.',{
   basic('Kick','Your assigned enemy starts an interruptible cast; you have Energy and melee range.','Stops the cast; keeping enough Energy for Kick is part of the assignment.'),
   basic('Sap','You are out of combat, meet the stealth requirements, and the marked target is eligible.','Removes that enemy from the opening pull without spending damage on it.')},'Do not spend the Energy reserved for Kick on Sinister Strike.'),
  movement=recipe('Choose the safe route back to melee range.',{
   basic('Sprint','You need extra speed to reach safety or return to the priority target.','Reduces travel time, but does not make hazards safe.'),
   step(nil,'You cannot attack safely from melee.','Leave melee and complete the mechanic. Return before spending offensive cooldowns.','Melee uptime is useful only while the position is safe.')},'Do not chase a target through a lethal mechanic to preserve a builder cast.'),
  resources=recipe('Keep enough Energy for the assigned Kick; watch combo points before using a builder.',{
   step(nil,'The next assigned interrupt is approaching.','Pool Energy for Kick instead of spending it on another builder.','An empty Energy bar can lose the interrupt.'),
   basic('Eviscerate','A damage finisher is appropriate, you have combo points and Energy, and the target will remain attackable.','Spends combo points rather than wasting another builder into the point cap.')},'Do not waste combo-point generation at the cap or empty Energy before an assigned Kick.')},
 WARRIOR={
  utility=recipe('Check the stance and weapon requirements for your assigned interrupt.',{
   basic('Pummel','Your assigned enemy starts an interruptible cast and Pummel requirements are met.','Stops the cast; reserve its Rage cost.'),
   basic('Shield Bash','You have the required shield/stance and Pummel is not your available interrupt.','Provides the shield-based interrupt instead of attempting an unavailable Pummel.')},'Do not enter the assigned cast window without the resource or equipment for your interrupt.'),
  movement=recipe('Choose a route that does not turn enemies toward allies.',{
   step(nil,'A mechanic requires movement.','Move to the safe position. If tanking, keep enemies positioned away from the group.','The movement must protect the group as well as your own uptime.'),
   basic('Intercept','The destination enemy is safe to reach and the stance, range and Rage requirements are met.','Closes distance; it does not check the safety of the landing position for you.')},'Do not Intercept into an unsafe landing area to regain one melee attack.')},
 HUNTER={
  utility=recipe('Mark the control target and set your pet to the intended attack target.',{
   basic('Freezing Trap','The assigned trap target can be controlled and nobody will damage it.','Stops that enemy temporarily; area damage can break the control.'),
   basic('Feign Death','Threat must be dropped and the mechanic permits it.','Changes your threat situation; check the group before resuming attacks.')},'Do not use Multi-Shot across the trapped enemy.'),
  movement=recipe('Choose a safe firing position and account for pet pathing.',{
   step(nil,'The mechanic forces you out of your firing position.','Move to safety first and keep your pet on the assigned target.','An instant shot does not excuse standing in a hazard.'),
   basic('Arcane Shot','You are moving, the target is in valid range, and the shot is ready.','Deals ranged damage without requiring you to stand for a cast.')},'Do not let the pet take an unsafe route into another pack.')},
 WARLOCK={
  utility=recipe('Assign the curse and control target; keep your pet on the intended enemy.',{
   basic('Fear','Your assigned enemy is eligible and its escape route will not pull another pack.','Control can prevent enemy actions but can also create another pull.'),
   step(nil,'Your pet is attacking the controlled or wrong enemy.','Stop that pet attack and send the pet to the assigned kill target.','Pet damage can break control even while you cast on the correct target.')},'Do not Fear an enemy toward an unpulled group.'),
  movement=recipe('Identify the safe destination before committing another Shadow Bolt.',{
   step(nil,'A mechanic requires movement.','Move out and cancel Shadow Bolt if necessary.','A completed cast does not compensate for taking a lethal mechanic.'),
   basic('Corruption','You are moving, Corruption can be applied instantly in your current setup, and the target needs a fresh application.','A useful instant application can contribute during movement; do not replace useful remaining ticks.')},'Do not assume Corruption is instant without checking your current talents.')}
}
shared.WARRIOR.resources=recipe('Keep Rage available for the next assigned interrupt or defensive action.',{step(nil,'Rage is limited and an interrupt is due.','Stop queuing Heroic Strike. Reserve Rage for Pummel or Shield Bash.','Extra damage must not consume the assigned interrupt.'),basic('Bloodrage','You need Rage, Bloodrage is ready, and its health cost is safe.','Generates Rage at a health cost; do not use it to solve a resource problem that creates a survival problem.')},'Do not spend all Rage on optional damage before a required defensive action.')
shared.HUNTER.resources=recipe('Check Mana and pet readiness before the next pull.',{step(nil,'Combat ends and Mana is low.','Drink before pulling. Check that your pet is alive and ready.','A dead or unavailable pet changes what the next pull can safely support.'),step(nil,'Mana is low during combat.','Stop optional Arcane Shot and Multi-Shot casts; keep the assigned target and pet attacks controlled.','Avoid exhausting the resources required by the next encounter action.')},'Do not pull while the group is still recovering mana.')
shared.WARLOCK.resources=recipe('Check your Health and incoming damage before using Life Tap.',{basic('Life Tap','You need Mana and the Health cost will leave you safe against the next incoming hit.','Converts Health into Mana; the healer must not be forced into an emergency to fund optional damage.'),step(nil,'A large hit is imminent or you are already at unsafe Health.','Do not Life Tap. Survive the hit and recover before converting Health.','Mana recovery is not useful if the exchange kills you.')},'Do not chain Life Tap during dangerous group damage.')
A.shared=shared
A.step=step;A.recipe=recipe;A.basic=basic
A.profiles={}
local function spec(class,index,prepare,single,group,burst)
 A.profiles[class]=A.profiles[class] or {}
 A.profiles[class][index]={
  single=recipe(prepare,single,'Do not continue the damage/healing sequence through a required interrupt or movement mechanic.'),
  group=recipe(prepare,group,'Do not hit a controlled enemy or heal targets that will receive no useful recovery.'),
  burst=recipe(prepare,burst,'Do not activate this sequence immediately before forced movement or target downtime.'),
  movement=shared[class].movement,utility=shared[class].utility,resources=shared[class].resources
 }
end
spec('SHAMAN',1,'Stand where Lightning Bolt can reach the kill target. Reserve Earth Shock for assigned interrupts.',{
 basic('Flame Shock','Flame Shock is missing and the target will survive useful ticks.','Adds Fire damage over time; it is no longer a Lava Burst setup.'),
 basic('Lightning Bolt','No assigned utility is due, you have Mana, and you have a safe stationary cast window.','Your main ranged filler; Call of Thunder and Lightning Overload support lightning casts.')},
 {basic('Chain Lightning','At least two attackable enemies are close enough for the jumps and none is controlled.','Use the additional hits on the intended pack.'),basic('Fire Nova','An active fire totem is positioned to hit the pack and the affected enemies may be damaged.','Fire Nova erupts at the fire totem, not at your ranged target.')},
 {basic('Lightning Mastery','The assigned burst target is attackable and you can remain in a safe cast position.','Shortens Lightning Bolt and removes Chain Lightning cooldown for 15 seconds.','Lightning Mastery'),basic('Chain Lightning','Lightning Mastery is active, Mana permits it, and only intended enemies can be hit.','Use the cooldown-free window; account for the higher Mana cost and 2.5-second base cast.')})
spec('SHAMAN',2,'Reach safe melee range. Check Stormstrike and Maelstrom Weapon; keep Earth Shock ready if you have the next interrupt.',{
 step(nil,'The pull has started, the assigned enemy is in safe melee range, and your auto-attacks are not active.','Start auto-attacking the priority enemy; do not press Attack again if swings are already active.','Weapon swings continue between spell actions. Toggling Attack again can stop them.'),
 basic('Stormstrike','Stormstrike is ready, you are in melee, and the target can be attacked safely.','Sets up its empowered Lightning Bolt, Chain Lightning or Earth Shock follow-up.','Stormstrike'),
 basic('Lightning Bolt','Maelstrom Weapon currently makes Lightning Bolt instant and the priority target is in range.','Spends the observed proc without stopping for a hard cast.','Maelstrom Weapon'),
 basic('Earth Shock','No assigned interrupt is approaching, Earth Shock is ready, and you can afford its Mana cost.','Consumes damage opportunities without sacrificing a required interrupt.')},
 {basic('Stormstrike','You can reach the pack\'s priority target safely and Stormstrike is ready.','Apply the setup to the enemy that needs to die first.','Stormstrike'),basic('Chain Lightning','Maelstrom Weapon makes it instant and its jumps will hit at least two permitted targets.','Spend the instant cast on multiple useful hits.','Maelstrom Weapon'),basic('Fire Nova','Your active fire totem reaches the intended pack and will not hit controlled enemies.','Contributes area damage from the totem position.')},
 {basic('Rage of the Farseer','The burst window has begun and you can remain in melee for its useful duration.','Attack speed needs weapon swings on an attackable target.','Rage of the Farseer'),basic('Stormstrike','Stormstrike is ready during the melee burst window.','Keep its named spell follow-up available instead of wasting the setup.','Stormstrike')})
spec('SHAMAN',3,'Stay in healing range of the tank. Check which allies can share Chain Heal jumps and keep Mana for a cleanse or emergency heal.',{
 basic('Lesser Healing Wave','The injured ally cannot safely wait for Healing Wave to finish.','The shorter cast addresses the immediate danger.'),
 basic('Riptide','An ally needs sustained healing and can survive until its ticks.','Provides periodic healing only; use a direct heal for immediate danger.','Riptide'),
 basic('Healing Wave','No ally needs a faster emergency response, and the injured tank will survive until the cast finishes.','Use the cast window to land direct recovery.')},
 {basic('Chain Heal','At least two injured allies are close enough for useful jumps.','Start on an injured ally near the others so the jumps are useful.'),basic('Lesser Healing Wave','One ally is dying but the other nearby allies are healthy.','Use a focused response instead of spending a group heal on healthy targets.')},
 {basic('Nature\'s Swiftness','An assigned ally needs an immediate Nature heal and the cooldown is ready.','Makes the next qualifying cast instant.','Nature\'s Swiftness'),basic('Healing Wave','Nature\'s Swiftness is active and the endangered ally is in range.','Spend the instant cast on the emergency target rather than another action.')})
spec('MAGE',1,'Stand in a safe casting position. Check Arcane Blast stacks, Mana and the next Counterspell assignment.',{
 basic('Arcane Blast','You can afford the current stack-adjusted cost and can finish the cast safely.','Builds Arcane pressure at a cost you must actually be able to sustain.','Arcane Blast'),
 basic('Arcane Missiles','Your Missile Barrage proc is active and you can complete a safe channel.','Uses the proc window on its named channel.','Missile Barrage')},
 {basic('Arcane Explosion','The assigned pack is within its area, entering that range is safe, and no controlled target will be hit.','Hits the intended nearby enemies; do not stand in danger to reach them.')},
 {basic('Arcane Power','The burst target will remain attackable and you have Mana for the window.','Aligns the damage cooldown with actual casts.','Arcane Power'),basic('Arcane Blast','Arcane Power is active and the current cast cost is affordable.','Converts the cooldown window into useful damage.','Arcane Blast')})
spec('MAGE',2,'Keep the target in range. Watch Hot Streak stacks and reserve Counterspell for your assigned caster.',{
 basic('Pyroblast','Hot Streak currently makes Pyroblast instant and the target is attackable.','Consumes the actual instant-cast proc.','Heating Up'),
 basic('Fireball','No required action interrupts the cast window and the target will remain attackable.','Provides a direct fire cast while you wait for the conditional proc.')},
 {basic('Flamestrike','The intended enemies are grouped, no control target will be hit, and you can finish its cast safely.','Places area damage where the enemies will actually remain.'),basic('Fire Blast','The priority enemy is in range, Fire Blast is ready, and you must move.','Keeps one named instant attack available during relocation.')},
 {basic('Combustion','The damage window has begun and you can follow it with fire casts.','Use the cooldown while its fire interactions can contribute.','Combustion'),basic('Fireball','Combustion is active and no instant Pyroblast proc or mechanic takes priority.','Keep damaging the burst target during the window.')})
spec('MAGE',3,'Check whether the target can be slowed or frozen. Stay where Frostbolt can finish safely.',{
 basic('Frostbolt','The target is in range and you have a safe stationary cast window.','Deals ranged frost damage without moving into melee.'),basic('Ice Lance','The target satisfies Ice Lance\'s current bonus condition, or you must move and it is your available instant attack.','Use the named instant spell only when its condition or movement need justifies it.','Ice Lance')},
 {basic('Blizzard','The pack will stay in its area and you can channel safely without breaking control.','A channel loses value if targets leave or you must immediately cancel it.')},
 {basic('Icy Veins','The target is attackable and the upcoming window permits sustained casts.','Casting-speed benefit needs casts that can finish.','Icy Veins'),basic('Frostbolt','Icy Veins is active and no movement or utility action is required.','Uses the actual safe cast window.')})
spec('DRUID',1,'Choose a safe ranged position. Check Moonfire and your observed Eclipse state.',{
 basic('Moonfire','The target lacks your useful periodic effect and will live for its ticks.','Do not refresh away remaining useful periodic damage.'),basic('Starfire','Your observed Eclipse effect benefits Starfire and you can finish the cast safely.','Use the cast named by the active effect.','Eclipse'),basic('Wrath','The active Eclipse state does not favor Starfire and a Wrath cast is safe.','Use a named filler instead of an unspecified Nature spell.')},
 {basic('Hurricane','The pack will remain in its area, no control target will be hit, and the channel is safe.','Spend the channel on enemies that stay inside its damage area.')},
 {basic('Starfall','The burst window is active and its possible extra targets are safe to hit.','Do not activate a wide-area effect next to unpulled or controlled enemies.','Starfall'),basic('Starfire','The observed Eclipse effect favors Starfire during the burst window.','Follow the active cast modifier rather than assuming every bolt is equivalent.','Eclipse')})
spec('DRUID',2,'Use Cat Form for damage. Track Energy and combo points before choosing a builder or finisher.',{
 basic('Rake','Your Rake effect is missing and the target will survive useful bleed ticks.','Applies periodic damage before spending another builder.'),basic('Shred','You are in its required position, have Energy, and are below the combo-point cap.','Builds combo points without wasting generation.'),basic('Rip','You have combo points, the target will survive the bleed, and a bleed finisher fits the current situation.','Uses accumulated points on sustained damage.')},
 {basic('Swipe','You are in the form required by your learned Swipe and its area contains only permitted targets.','Use the form-specific area attack without breaking control.')},
 {basic('Shifting Power','Energy is low enough to use the gain and the Mana cost is affordable.','Adds Energy without a powershift.','Shifting Power'),basic('Shred','Its position requirement is met and a builder will not waste combo points.','Build combo points during safe melee uptime.')})
spec('DRUID',3,'Keep the tank in range. Identify who needs immediate healing versus healing over time.',{
 basic('Rejuvenation','The ally needs sustained recovery and will survive until useful ticks land.','Use periodic healing for sustained pressure, not an imminent lethal hit.'),basic('Healing Touch','The ally needs direct healing and can survive until the cast completes.','Land the direct heal before the next dangerous hit.')},
 {basic('Wild Growth','Several injured allies are grouped in its effective area.','Apply group recovery where more than one injured ally can benefit.','Wild Growth'),basic('Rejuvenation','A specific injured ally needs continued recovery after the group response.','Target useful periodic healing rather than refreshing everyone blindly.')},
 {basic('Nature\'s Swiftness','An endangered ally needs an immediate qualifying Nature heal.','Prepare the instant-heal response.','Nature\'s Swiftness'),basic('Healing Touch','Nature\'s Swiftness is active and the endangered ally is in range.','Spend the instant cast on the lifesaving heal.')})
spec('PALADIN',1,'Keep the tank in healing range. Decide whether Flash of Light will land before the next hit.',{
 basic('Flash of Light','This heal will arrive in time and restore enough Health for the ally to survive the next hit.','Use the shorter direct heal when it solves the actual deficit.'),basic('Holy Light','A larger direct heal is needed and the target will survive its longer cast.','Choose the larger recovery only when its cast can land in time.')},
 {basic('Holy Light','Your priority ally needs a large heal and can survive the cast.','Stabilize the assigned endangered target before spreading optional healing.'),basic('Flash of Light','Another injured ally needs a shorter direct response.','Move to the next useful direct heal instead of assuming you have a group-heal button.')},
 {basic('Divine Favor','A critical direct heal is planned and the cooldown is ready.','Prepare the guaranteed-heal interaction described by the live effect.','Divine Favor'),basic('Holy Light','Divine Favor is active and the selected ally needs this large heal.','Spend the effect on useful recovery rather than overhealing.')})
spec('PALADIN',2,'Equip the required tank gear. Position the pack away from allies and identify the kill target.',{
 basic('Holy Shield','Holy Shield is ready and the next incoming attacks can benefit from its effect.','Prepare the defensive/threat effect before the attacks arrive.','Holy Shield'),basic('Judgement','The required seal is active and the assigned enemy is in range.','Apply the seal/judgement interaction to the enemy you need to hold.')},
 {basic('Consecration','The assigned pack is inside its area and no controlled enemy will be hit.','Places area threat where the pack is actually standing.','Consecration'),basic('Holy Shield','Several assigned enemies are attacking you and the effect is ready.','Maintain the named defensive/threat tool during the pack.','Holy Shield')},
 {basic('Divine Protection','A dangerous incoming hit is approaching and the current effect is appropriate for the tank assignment.','Use the protection before the hit rather than after losing the Health.')})
spec('PALADIN',3,'Reach safe melee range. Check the current seal before Judgement and keep Mana for assigned cleansing.',{
 basic('Judgement','Your intended seal is active, the enemy is in range, and no required utility takes priority.','Use the actual seal interaction rather than an unspecified holy spell.'),basic('Crusader Strike','The priority enemy is in safe melee range and the strike is ready.','Use the named melee attack on the kill target.','Crusader Strike')},
 {basic('Divine Storm','Its area contains only permitted enemies and you are in safe melee range.','Apply the multi-target melee attack without breaking control.','Divine Storm'),basic('Consecration','The pack will remain in its area and the Mana cost will not prevent required utility.','Do not spend Mana on an area the enemies are leaving.','Consecration')},
 {basic('Avenging Wrath','The burst target is attackable and the effect\'s current restrictions do not conflict with required protection.','Align its benefit with useful melee attacks.','Avenging Wrath'),basic('Crusader Strike','The burst effect is active and the strike is ready.','Spend the window on attacks that can reach the assigned target.','Crusader Strike')})
spec('PRIEST',1,'Confirm whether you are assigned to healing or damage. Keep the tank in range for protection.',{
 basic('Power Word: Shield','The assigned ally is about to take damage and can receive your shield.','Protect before the hit rather than after it.'),basic('Flash Heal','An injured ally needs direct recovery before a slower heal could land.','A named short cast handles the immediate healing need.')},
 {basic('Prayer of Healing','Several eligible group members are injured, in range, and can survive its cast.','Use the group heal only when its recipients need recovery.'),basic('Power Word: Shield','One ally needs immediate protection while others can wait.','Stabilize the urgent target rather than finishing an unnecessary group cast.')},
 {basic('Power Infusion','The agreed recipient is ready to cast throughout the burst window.','The recipient must be able to use the effect.','Power Infusion'),basic('Penance','An assigned ally needs healing and Penance can be used safely under the current spell rules.','Deliver the named channel to the correct target.','Penance')})
spec('PRIEST',2,'Keep injured allies in range. Identify whether the next heal must be direct or group recovery.',{
 basic('Renew','An ally needs sustained healing and is not about to die before its ticks land.','Apply periodic recovery to useful missing Health.'),basic('Flash Heal','The ally needs a short direct heal before the next dangerous hit.','Use immediate direct recovery instead of another periodic refresh.')},
 {basic('Prayer of Healing','Several eligible group members are injured and can survive its cast.','Land the group heal before the next damage event.'),basic('Circle of Healing','Several injured allies meet its target rules and it is ready.','Use its instant group recovery when the recipients need it.','Circle of Healing')},
 {basic('Inner Focus','A costly planned heal is needed and the cooldown is ready.','Prepare the named cost/critical interaction.','Inner Focus'),basic('Prayer of Healing','Inner Focus is active and several eligible allies need the heal.','Spend the effect on useful group recovery.')})
spec('PRIEST',3,'Keep the priority enemy in range. Check Shadow Word: Pain and the remaining Mind Flay channel time.',{
 basic('Shadow Word: Pain','Your periodic effect is missing and the target will survive useful ticks.','Start useful sustained damage instead of refreshing an active effect.'),basic('Mind Blast','Mind Blast is ready and the cast can finish safely.','Use the named direct cast.'),basic('Mind Flay','The target is attackable and you can safely finish the planned channel.','Do not replace a channel with an unspecified shadow spell.')},
 {basic('Shadow Word: Pain','An additional permitted enemy will live long enough for useful ticks.','Spread only to targets that are safe and useful to damage.'),basic('Mind Sear','The pack and current target rules permit its area channel and you can channel safely.','Use the named group channel only when it is actually learned.','Mind Sear')},
 {basic('Inner Focus','A planned offensive cast can benefit from the current effect.','Use its actual spell interaction rather than inventing a shadow burst cooldown.','Inner Focus'),basic('Mind Blast','The target can be attacked and Mind Blast is ready during the planned window.','Commit a concrete cast to the priority target.')})
spec('ROGUE',1,'Stand in safe melee range. Check Energy, combo points and your next Kick assignment.',{
 basic('Mutilate','You meet its weapon/target requirements, have Energy and are below the combo-point cap.','Build points with the attack this allocation supports.','Mutilate'),basic('Eviscerate','A damage finisher fits the remaining target lifetime and you have combo points and Energy.','Spend points instead of overcapping another builder.')},
 {basic('Fan of Knives','You are in safe range and every enemy in its area may be hit.','Use the named area attack without breaking control.','Fan of Knives')},
 {basic('Cold Blood','A planned damaging finisher can benefit from the current effect.','Prepare the critical-strike effect for its intended attack.','Cold Blood'),basic('Eviscerate','Cold Blood is active and you have the points and Energy for the finisher.','Spend the setup on the intended damaging attack.')})
spec('ROGUE',2,'Reach the assigned enemy. Reserve Energy for Kick and avoid wasting combo-point generation.',{
 basic('Sinister Strike','You have Energy, are below the combo-point cap and no assigned Kick is due.','Build points without consuming the interrupt reserve.'),basic('Eviscerate','You have points and Energy and a direct damage finisher is appropriate.','Spend points before another builder wastes generation.')},
 {basic('Blade Flurry','A second permitted target is in range and controlled enemies will not be hit.','Use the actual cleave window on useful extra targets.','Blade Flurry'),basic('Sinister Strike','Blade Flurry is active and a builder will not waste combo points.','Keep the cleave attached to useful attacks.')},
 {basic('Adrenaline Rush','You can remain in melee and spend the incoming Energy without capping.','Resource generation needs attacks that can actually be used.','Adrenaline Rush'),basic('Sinister Strike','The cooldown is active and another builder will not waste points.','Use the resource window within a builder/finisher cycle.')})
spec('ROGUE',3,'Check stealth, target position and Energy before committing the opening attack.',{
 basic('Ambush','You meet its stealth, position and weapon requirements and the target is assigned for damage.','Use the actual opening attack rather than assuming stealth is active.'),basic('Backstab','Its position and weapon requirements are met and a builder will not cap combo points.','Use a concrete positional builder.'),basic('Eviscerate','A damage finisher fits the target lifetime and you have points and Energy.','Convert the setup into the appropriate finisher.')},
 {basic('Fan of Knives','Every enemy in its area may be damaged and your position is safe.','Use the named learned area attack instead of inventing a Subtlety cleave.','Fan of Knives')},
 {basic('Shadow Dance','The target and your position permit the opening attacks enabled by its current effect.','Setup must be ready before the cooldown starts.','Shadow Dance'),basic('Ambush','Shadow Dance actually permits Ambush and all weapon/position requirements are met.','Spend the opening window on the named attack.')})
spec('WARRIOR',1,'Use the required stance and weapon. Keep Rage for your next assigned interrupt.',{
 basic('Mortal Strike','The priority enemy is in melee, the attack is ready and you have Rage.','Use the named Arms attack.','Mortal Strike'),basic('Overpower','Your current Overpower trigger is available and stance/range requirements are met.','Use the observed trigger instead of assuming it is always castable.'),basic('Execute','The enemy is in its actual execute range and you can afford the attack.','Use the low-health attack when its target condition is satisfied.')},
 {basic('Sweeping Strikes','A second enemy may be hit and you can follow the effect with melee attacks.','Spend the cleave effect only where its additional target is useful.','Sweeping Strikes'),basic('Cleave','Additional permitted enemies are in range and the Rage cost will not prevent assigned utility.','Do not spend the interrupt reserve on extra hits.')},
 {basic('Recklessness','The damage window is active and its defensive downside is safe for this mechanic.','Use the offensive effect only when its risk is acceptable.'),basic('Mortal Strike','The cooldown window is active and Mortal Strike is ready.','Apply the window to the actual priority enemy.','Mortal Strike')})
spec('WARRIOR',2,'Keep the target in melee. Check Rage and the next Pummel assignment.',{
 basic('Bloodthirst','The attack is ready, the assigned target is in melee and you have Rage.','Use the named Fury attack.','Bloodthirst'),basic('Whirlwind','Its area will hit only permitted targets and the Rage cost is affordable.','Do not clip a controlled enemy to press an attack.'),basic('Execute','The target satisfies its low-health requirement and no required utility takes priority.','Spend Rage on the actual execute opportunity.')},
 {basic('Whirlwind','At least two permitted enemies are within its area.','Use the extra hits on the intended pack.'),basic('Cleave','The additional enemies may be hit and you can preserve required Rage.','Avoid emptying Rage before the next Pummel.')},
 {basic('Death Wish','You have sustained melee access and its survival cost is safe.','Use the damage window only while you can attack safely.','Death Wish'),basic('Bloodthirst','Death Wish is active and Bloodthirst is ready.','Turn the cooldown into useful priority-target attacks.','Bloodthirst')})
spec('WARRIOR',3,'Equip the required shield. Position enemies away from allies and reserve Rage for defensive actions.',{
 basic('Shield Block','The next incoming attacks can benefit and the effect is ready.','Prepare the block effect before those attacks land.'),basic('Shield Slam','Shield Slam is ready and the assigned enemy is in range.','Apply the named shield attack to the enemy you must hold.','Shield Slam'),basic('Revenge','Its observed trigger and stance requirements are satisfied.','Use the available reaction instead of assuming its trigger is permanent.')},
 {basic('Thunder Clap','The assigned pack is in its area and stance requirements are met.','Apply the named pack attack without dragging enemies toward allies.'),basic('Cleave','Extra assigned enemies are in range and Rage remains for required defense.','Extra threat must not consume the next defensive action.')},
 {basic('Shield Wall','A predictable dangerous damage window is about to land and requirements are met.','Reduce the incoming window before losing the Health.'),basic('Shield Block','The next incoming blockable attacks still require coverage.','Keep the relevant block window prepared rather than replacing all defense with one cooldown.')})
spec('HUNTER',1,'Put your pet on the assigned kill target. Check its range and path before the pull.',{
 basic('Kill Command','Its actual trigger is available and your pet can reach the assigned enemy.','The pet must be able to deliver the commanded attack.','Kill Command'),basic('Arcane Shot','The target is in valid ranged reach and the shot is ready.','Use a named instant shot while maintaining control of the pet.')},
 {basic('Multi-Shot','Its extra hits will reach only permitted targets.','Do not break the trap with the extra shots.')},
 {basic('Bestial Wrath','Your pet is alive, in range and able to attack throughout the window.','The pet is a required participant, not an optional detail.','Bestial Wrath'),basic('Rapid Fire','You can maintain safe ranged attack uptime.','Attack speed does not help while you cannot fire.')})
spec('HUNTER',2,'Choose a valid ranged position and keep controlled enemies outside Multi-Shot coverage.',{
 basic('Aimed Shot','The target is in range and you can meet the current cast/movement requirements safely.','Commit the named shot only when its firing window exists.','Aimed Shot'),basic('Arcane Shot','The instant shot is ready and no assigned control action takes priority.','Use a concrete ranged action rather than an unspecified shot.')},
 {basic('Multi-Shot','At least two useful targets can be hit without breaking control.','Spend its additional hits on permitted enemies.')},
 {basic('Rapid Fire','The assigned burst target is available and you can keep firing.','Activate during ranged uptime, not while running to range.'),basic('Aimed Shot','The current shot conditions are met during the burst window.','Keep the window attached to attacks that can land.','Aimed Shot')})
spec('HUNTER',3,'Check trap assignments and your ranged attack position.',{
 basic('Explosive Shot','The priority target is in range and another application will not waste the current effect.','Use its current periodic behavior rather than overwriting it blindly.','Explosive Shot'),basic('Arcane Shot','The shot is ready and you need a direct instant ranged attack.','Use a named action while respecting the current shot interactions.')},
 {basic('Multi-Shot','The additional hits will reach permitted targets and miss the trapped enemy.','Protect the control assignment while hitting the pack.')},
 {basic('Rapid Fire','The burst target is attackable and you can keep ranged attacks going.','Activate when its speed window can produce useful attacks.'),basic('Explosive Shot','Its current application rules permit another shot.','Do not overwrite useful remaining periodic damage simply because a burst window started.','Explosive Shot')})
spec('WARLOCK',1,'Choose enemies that will live for periodic damage. Check the assigned curse before spreading effects.',{
 basic('Corruption','The priority enemy lacks your useful application and will live through its ticks.','Do not erase remaining periodic damage with an unnecessary refresh.'),basic('Unstable Affliction','The effect is missing and its target will survive useful ticks.','Apply the named periodic spell to a useful target.','Unstable Affliction'),basic('Shadow Bolt','Useful periodic effects are already running and the cast window is safe.','Use a named filler between required applications.')},
 {basic('Corruption','Another permitted enemy will live long enough for useful ticks.','Spread only to enemies worth damaging.'),basic('Seed of Corruption','The affected enemies may all be hit and the explosion will not break control.','Place the named area-damage setup on the intended pack.','Seed of Corruption')},
 {basic('Haunt','The assigned target has your useful Shadow periodic effects and the cast can land safely.','Use its damage interaction on a prepared target.','Haunt'),basic('Shadow Bolt','Periodic setup is running and a filler cast fits the burst window.','Avoid leaving the target without casts while the prepared effects run.')})
spec('WARLOCK',2,'Keep your pet alive and on the assigned enemy. Check Mana and the next movement mechanic.',{
 basic('Corruption','A useful application is missing from a target that will live for the ticks.','Keep the periodic effect on a target worth damaging.'),basic('Shadow Bolt','The target is in range and you can finish a stationary cast safely.','Combine the caster attack with controlled pet uptime.')},
 {basic('Hellfire','Every affected enemy may be hit, your position is safe and the self-damage will not threaten survival.','The area damage has an actual Health and positioning cost.'),basic('Seed of Corruption','The explosion can hit the intended pack without breaking control.','Use a ranged pack setup when actually learned.','Seed of Corruption')},
 {basic('Metamorphosis','The burst target is attackable and the form\'s current actions can be used safely.','Activate when you can use the actual form toolkit.','Metamorphosis'),basic('Shadow Bolt','Your current form permits Shadow Bolt and a safe cast window exists.','Do not recommend a cast that the current form disallows.')})
spec('WARLOCK',3,'Keep the priority target in range. Check Immolate before choosing a benefiting fire cast.',{
 basic('Immolate','The effect is missing and the target will survive useful ticks.','Set up the fire periodic effect on a useful target.'),basic('Conflagrate','The current Immolate requirement is satisfied and using Conflagrate fits the live effect rules.','Use the named Immolate interaction.','Conflagrate'),basic('Incinerate','Immolate is active and the cast can finish safely.','Use the benefiting direct fire cast instead of an unspecified spell.','Incinerate')},
 {basic('Rain of Fire','The intended pack will remain in its area and the channel position is safe.','Do not spend a channel on enemies leaving the area.')},
 {basic('Chaos Bolt','The assigned burst target is in range and the cast is ready.','Use the named direct cast in its safe window.','Chaos Bolt'),basic('Conflagrate','Its actual Immolate requirement is satisfied during the burst window.','Respect the current effect interaction rather than consuming setup blindly.','Conflagrate')})
A.bear={
 single=recipe('Enter Bear Form and face the assigned enemy away from allies.',{basic('Growl','Your assigned enemy has switched to an ally and can be taunted.','Returns attention to you; it is not a damage filler.'),basic('Maul','You can afford the Rage cost while preserving your next required defensive action.','Applies the named Bear attack to the enemy you must hold.')},'Do not leave Bear Form while a dangerous enemy is attacking you.'),
 group=recipe('Keep the assigned pack in front of you and controlled enemies outside Swipe coverage.',{basic('Swipe','The assigned enemies are within its Bear-form area and may all be damaged.','Applies the area attack to the pack.'),basic('Demoralizing Roar','The assigned enemies can be affected and its attack-reduction effect needs applying.','Apply the debuff before the next relevant incoming attacks.')},'Do not hit controlled enemies with Swipe.'),
 burst=recipe('Reserve a defensive for the next predictable dangerous hit.',{basic('Barkskin','The damage window is about to start and the live client permits it in your current form.','Use the reduction before the damage arrives.'),basic('Frenzied Regeneration','You need recovery and can afford its current resource requirements.','Use the named recovery effect while continuing to control the enemy.')},'Do not consume the resource needed for an immediate defensive merely to increase damage.'),
 movement=shared.DRUID.movement,utility=shared.DRUID.utility,resources=shared.DRUID.resources
}
A.disciplineDamage={
 single=recipe('Keep the assigned enemy in spell range and preserve Mana for your next assigned support action.',{basic('Holy Fire','The cast is ready and the target will survive useful periodic damage.','Apply the named direct/periodic attack.'),basic('Smite','Holy Fire setup is handled and the cast can finish safely.','Use a concrete damage filler instead of a generic offensive spell.')},'Do not ignore a required Dispel Magic to finish an optional Smite.'),
 group=recipe('Identify the enemy that must die first; do not assume this allocation has an area spell.',{basic('Holy Fire','The priority target lacks your useful periodic application.','Focus damage on the kill target.'),basic('Smite','The priority target remains attackable and no assigned utility is due.','Keep focused damage rather than spreading unsupported area attacks.')},'Do not spread damage away from the assigned priority target.'),
 burst=recipe('Agree who receives Power Infusion and ensure the recipient can cast throughout it.',{basic('Power Infusion','The agreed burst window has begun and the recipient is ready.','Give the effect to the intended caster.','Power Infusion'),basic('Smite','Your damage assignment continues and the target can be cast on safely.','Convert the available cast window into the named damage action.')},'Do not use Power Infusion on a player who is about to stop casting.'),
 movement=shared.PRIEST.movement,utility=shared.PRIEST.utility,resources=shared.PRIEST.resources
}
