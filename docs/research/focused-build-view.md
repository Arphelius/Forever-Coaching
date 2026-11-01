# Focused talent build view

The player-facing page now has four explicit activity buttons: Dungeons,
Leveling, Raids and PvP. Each class shows three specialization cards, defined
by its actual talent trees. Each card resolves to at most one sourced build.
The previous full catalog, filters and manual alternative-build selection are
removed from this page. Original source data remains available internally.

Selection is evidence relevance, not a new DPS/healing optimization:

- Spec membership uses the allocation's largest talent-tree point total.
- Dungeon choices require an explicit dungeon activity in their guide metadata.
  Raid references are not silently reused for dungeon damage.
- Leveling choices require a leveling guide/template.
- Raid choices use the corresponding reference benchmark or healing guide.
- PvP choices use a published PvP plan, with a level-30 tournament submission
  available only as an explicitly labeled duel example.
- Exact preview-level evidence is preferred; future destination allocations
  remain clearly labeled with their target level. No intermediate points are
  invented. Multiple same-spec guide candidates are reduced deterministically
  to one relevant source entry rather than exposed as a long list.
- Missing allocations and conflicting guides are not filled with unrelated
  specs. The corresponding card says recommendation unavailable.

The selected build displays its short rationale, evidence type, source and
snapshot date. The Evidence / source button exposes a copyable direct URL.
Experimental talent highlights name allocated talents without inventing effects.
Benchmarks link to the comparison board; guide choices link to their own page.
Neither is presented as proof of a universal best build.

This UI change does not fill all class/spec/activity source gaps, create a
Forevers Logs comparison, or turn the current catalog into personal simulations.
