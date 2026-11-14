// Import reviewed named allocations, never decode a historical code against current indices.
const fs=require('fs');
const {lua}=require('./forever-source.cjs');
function build(record,trees){
 const talents=[],totals=[0,0,0],remaining=[];
 trees.forEach((tree,ti)=>tree.nodes.forEach((n,ni)=>{
  const rank=record.ranks[n.name]||0;
  if(!rank)return;
  if(!Number.isInteger(rank)||rank<0||rank>n.maxRank)throw Error('Invalid rank: '+n.name);
  totals[ti]+=rank;
  talents.push({name:n.name,tree:tree.name,treeIndex:ti+1,talentIndex:ni+1,rank,maxRank:n.maxRank,tier:n.row+1});
  remaining.push({...n,rank,treeIndex:ti+1,talentIndex:ni+1});
 }));
 if(totals.reduce((a,b)=>a+b,0)!==51||Object.keys(record.ranks).some(n=>!talents.some(t=>t.name===n)))throw Error('Incomplete allocation: '+record.id);
 const spent=[0,0,0],ranks={},planningOrder=[];
 while(planningOrder.length<51){
  const n=remaining.find(n=>(ranks[n.name]||0)<n.rank&&spent[n.treeIndex-1]>=n.row*5&&(!n.requires||(ranks[n.requires]||0)>=(remaining.find(t=>t.name===n.requires)?.maxRank||Infinity)));
  if(!n)throw Error('Illegal prerequisites or tiers: '+record.id);
  ranks[n.name]=(ranks[n.name]||0)+1;spent[n.treeIndex-1]++;
  planningOrder.push({level:planningOrder.length+10,name:n.name,rank:ranks[n.name],maxRank:n.maxRank,treeIndex:n.treeIndex,talentIndex:n.talentIndex,spellId:n.spellId,icon:n.icon,why:'Suggested planning order to the published level 60 allocation; not an authored leveling route.'});
 }
 return {kind:'reference',id:record.id,title:record.title,specialization:record.title,maxLevel:60,points:51,role:'healer',evidence:'guide',fit:record.fit,activities:record.activities,boardRank:0,boardGroup:'',validationStatus:'awaiting_combat_comparison',note:'Published level 60 Wowhead allocation, checked 2026-11-14. No measured healer ranking.',source:{name:'Wowhead',url:record.url,calculatorUrl:record.calculatorUrl,guideUpdated:'2026-11-04',reviewed:'2026-11-14'},distribution:totals.join(' / '),talentString:trees.map(t=>t.nodes.map(n=>record.ranks[n.name]||0).join('').replace(/0+$/,'')).join('-'),talents,planningOrder};
}
if(require.main===module){
 const snapshot=JSON.parse(fs.readFileSync(process.argv[2]));
 const records=JSON.parse(fs.readFileSync('docs/research/wowhead-healer-builds-2026-11-14.json'));
 const file='addons/ForeverCoaching/Data/LevelingBuilds.lua';let content=fs.readFileSync(file,'utf8');
 for(const cls of [...new Set(records.map(r=>r.class))]){
  const rows=records.filter(r=>r.class===cls).map(r=>build(r,snapshot.TalentTrees[cls.toUpperCase()]));
  for(const row of rows){
   const id='["id"]='+lua(row.id);
   content=content.split('\n').filter(line=>!(line.startsWith('    {')&&line.includes(id))).join('\n');
  }
  const marker='  '+cls+'={variants={';if(!content.includes(marker))throw Error('Missing class '+cls);
  content=content.replace(marker,marker+'\n'+rows.map(r=>'    '+lua(r)+',').join('\n'));
 }
 fs.writeFileSync(file,content);console.log('Imported '+records.length+' complete healer allocations.');
}
module.exports={build};

