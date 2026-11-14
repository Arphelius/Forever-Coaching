# Level 60 healer coverage refresh

Checked November 14, 2026. The missing full allocations were Restoration Druid,
Discipline Priest, Holy Priest and Restoration Shaman. Added ten published
51-point Wowhead allocations across all five healing specializations, including
current Holy Paladin variants. Existing beta and tournament entries retain their
original levels and point counts.

Exact source and calculator URLs and named ranks are recorded in
`wowhead-healer-builds-2026-11-14.json`. Wowhead's November 4 guides use both
versioned historical calculator layouts and the current `vkndmh` layout. The
allocations were decoded using Wowhead's published `talents-classic` data,
matched to bundled talents by name and checked against current rank caps, tier
spending and prerequisites. Planning orders are generated legal paths to the
published destination, not the author's leveling instructions.

Sources:

- https://www.wowhead.com/forever/guide/classes/priest/discipline/talent-builds-pve-healer
- https://www.wowhead.com/forever/guide/classes/priest/holy/talent-builds-pve-healer
- https://www.wowhead.com/forever/guide/classes/druid/restoration/talent-builds-pve-healer
- https://www.wowhead.com/forever/guide/classes/shaman/restoration/talent-builds-pve-healer
- https://www.wowhead.com/forever/guide/classes/paladin/holy/talent-builds-pve-healer
- https://mythicsim.com/wow-forever

MythicSim's current spec index contains damage and tank simulations, including
Smite and Holy-prot, but no dedicated healing presets for these missing specs.
No healer ranking or new simulation result is inferred from that index.

Rebuild after exporting the current catalog:

```powershell
node tools/Export-ForeverBuilds.cjs .tmp/build-refresh/before.json
node tools/Import-WowheadHealerBuilds.cjs .tmp/build-refresh/before.json
```

The importer changes only these named entries and preserves the current layout
and all other allocations. The recommendation regression test requires a legal,
full 51-point level 60 destination for every talent tree in all nine classes.
Validation is offline; these allocations have not been checked in the game client.
