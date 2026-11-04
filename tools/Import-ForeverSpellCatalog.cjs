// Offline import. Downloads/checks are separate from publishing reviewed gameplay rules.
// Usage: node tools/Import-ForeverSpellCatalog.cjs snapshot-directory
const fs=require('fs'),path=require('path');
const {page,lua,classes}=require('./forever-source.cjs');
function signature(text){let hash=0;for(const byte of Buffer.from(text.toLowerCase().replace(/[^a-z0-9]/g,'')))hash=(hash*31+byte)%2147483647;return hash;}
function generate(dir){
 const manifest=JSON.parse(fs.readFileSync(path.join(dir,'manifest.json'),'utf8'));
 if(!/^\d+\.\d+\.\d+\.\d+$/.test(manifest.build)||!/^\d{4}-\d{2}-\d{2}$/.test(manifest.reviewed))throw Error('Snapshot build/date required');
 const catalog={build:manifest.build,reviewed:manifest.reviewed,notesUrl:manifest.notesUrl,classes:{}};
 for(const cls of classes){
  const book=page(path.join(dir,'forever-'+cls+'.html'),'book'),spells={};
  for(const tab of [...book.tabs,...(book.demons||[])])for(const spell of tab.spells||[]){
   const ranks=(spell.ranks||[]).filter(r=>r.forever&&typeof r.forever==='object');
   if(!ranks.length)continue;
   const ids=[...new Set(ranks.map(r=>r.forever.spell_id).filter(Number.isInteger))];
   const rank=ranks[ranks.length-1].forever;
   const description=[...ranks].reverse().find(r=>typeof r.forever.text==='string'&&r.forever.text.trim())?.forever.text||null;
   if(!ids.length&&!description)throw Error(cls+': spell without ID or effect '+spell.name);
   spells[spell.name]={ids,tab:tab.name,level:spell.level||0,status:spell.status,icon:spell.icon,passive:rank.rank==='Passive',cost:rank.cost,cast:rank.cast,cooldown:rank.cooldown,range:rank.range,description,
    // Keep rank/level information even when Blizzard has not published the new ID.
    rankEffects:ranks.map(r=>({id:r.forever.spell_id,text:r.forever.text,level:r.forever.level||spell.level||0,rank:r.rank})),
    effects:Object.fromEntries(ranks.filter(r=>Number.isInteger(r.forever.spell_id)).map(r=>[r.forever.spell_id,{text:r.forever.text,level:r.forever.level||spell.level||0,rank:r.rank}]))};
  }
  const trees=page(path.join(dir,'talents-'+cls+'.html'),'trees'),talents={};
  if(trees.length!==3||Object.keys(spells).length<25)throw Error(cls+': incomplete class data');
  for(const tree of trees)for(const t of tree.talents){
   if(t.reported_change_kind==='removed'||t.calculator_eligible===false)continue;
   if(!Number.isInteger(t.max_rank)||t.max_rank<1||!Number.isInteger(t.structure?.tier)||!Number.isInteger(t.structure?.col))throw Error(cls+': incomplete talent '+t.name);
   for(let rank=1;rank<=t.max_rank;rank++)if(typeof t.rank_texts?.[rank]!=='string'||t.rank_texts[rank].startsWith('$'))throw Error(cls+': missing talent rank '+t.name+' '+rank);
   talents[t.name]={ranks:Object.fromEntries(Object.entries(t.rank_texts).map(([rank,text])=>[rank,signature(text)])),effects:t.rank_texts,maxRank:t.max_rank,
    requires:t.structure.reported_prerequisite||null,treeIndex:tree.tree_index+1,row:t.structure.tier,col:t.structure.col,icon:t.icon,evidence:t.evidence_status};
  }
  catalog.classes[cls.toUpperCase()]={sourceUrl:'https://foreverchanges.pro/spellbook/'+cls,changesUrl:'https://foreverchanges.pro/talents/'+cls,spells,talents};
 }
 catalog.revision=manifest.build+':'+require('crypto').createHash('sha256').update(JSON.stringify(catalog.classes)).digest('hex').slice(0,16);
 return catalog;
}
if(require.main===module){const catalog=generate(process.argv[2]||'.tmp');fs.writeFileSync('addons/ForeverCoaching/Data/ForeverSpellCatalog.lua','-- Generated from reviewed snapshots by tools/Import-ForeverSpellCatalog.cjs.\nForeverCoaching=ForeverCoaching or {}\nForeverCoaching.ForeverSpellCatalog='+lua(catalog)+'\n');console.log(Object.entries(catalog.classes).map(([c,v])=>c+': '+Object.keys(v.spells).length+' spells, '+Object.keys(v.talents).length+' talents').join('\n'));}
module.exports={generate};
