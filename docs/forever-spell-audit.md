# Forever spell and scenario audit

Reviewed 2026-11-01 against the ForeverChanges spellbooks and class changes for
beta **1.60.1.70707**, including the October 30 update:
[all classes](https://foreverchanges.pro/changes).

The generated `Data/ForeverSpellCatalog.lua` contains 515 spell entries across
all nine classes: rank IDs, training metadata, and source links. It excludes
spells listed only in the site's removed-spells section. Warlock demon abilities
are included. Talent rank fingerprints let lessons detect changed effect text
without redistributing the website's tooltip catalogue.

`Data/ForeverSpellGuidance.lua` reconciles lesson IDs, adds reviewed practical
notes, replaces outdated scenario actions, and checks dynamically assembled
scenarios against this catalogue. The same data loads in the addon and browser.
The live priorities were updated separately, including proc checks and the
consumption of Immolate after Conflagrate. Scenario sequences remain conditional
walkthroughs, not a simulated optimal rotation.

Existing build allocations are not automatically rewritten from a spell audit.
An older talent effect that fails the current rank fingerprint is withheld;
the lesson links to the current source and the in-game spell tooltip remains
available. Base costs, training levels, cast times and cooldowns do not include
the player's equipment, talents or active buffs. Actual learning, affordability,
range, proc state and readiness must still be read from the game client.

To refresh the catalogue, save each public `/spellbook/<class>` page as
`forever-<class>.html` and `/class/<class>` as `forever-changes-<class>.html` in
a temporary directory, then run:

```
node tools/Import-ForeverSpellCatalog.cjs <snapshot-directory>
node tests/ForeverSpellAudit.Tests.cjs
node tests/ForeverSpellPreview.Tests.cjs
```

Review and update the importer build/date and practical notes when refreshing.
HTML snapshots stay local; only factual metadata and fingerprints are committed.
