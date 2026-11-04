// Explicit offline adaptation after a tuning review. Input is a named allocation snapshot,
// not a positional talent string decoded against a different tree revision.
const fs=require('fs'),path=require('path');
const {page,lua,classes}=require('./forever-source.cjs');
function adapt(snapshot,dir,review){
 const layouts={},issues=[];
 for(const slug of classes){
  const cls=slug.toUpperCase(),old=snapshot.TalentTrees[cls],book=page(path.join(dir,'forever-'+slug+'.html'),'book');
  const spells=[...book.tabs,...(book.demons||[])].flatMap(t=>t.spells||[]);
  layouts[cls]=page(path.join(dir,'talents-'+slug+'.html'),'trees').map(tree=>({name:tree.name,nodes:tree.talents.filter(t=>t.reported_change_kind!=='removed'&&t.calculator_eligible!==false).sort((a,b)=>a.structure.tier-b.structure.tier||a.structure.col-b.structure.col).map(t=>{
   const prior=old.flatMap(t=>t.nodes).find(n=>n.name===t.name);
   const spell=spells.find(s=>s.name===t.name),id=spell?.ranks.map(r=>r.forever?.spell_id).find(Number.isInteger);
   return {name:t.name,spellId:id||prior?.spellId,icon:'Interface\\Icons\\'+t.icon,maxRank:t.max_rank,row:t.structure.tier,col:t.structure.col,requires:t.structure.reported_prerequisite||undefined};
  })}));
 }
 const builds={game:'WoW Forever',contentType:'Tuning-reviewed planning catalog',reviewed:review.reviewed,classes:{}};
 for(const [className,data]of Object.entries(snapshot.Builds.classes)){
  const cls=className.toUpperCase(),layout=layouts[cls],lookup={};layout.forEach((t,ti)=>t.nodes.forEach((n,ni)=>lookup[n.name]={...n,tree:t.name,treeIndex:ti+1,talentIndex:ni+1}));
  builds.classes[className]={variants:[]};
  for(const original of data.variants){
   if(!Array.isArray(original.talents)||!original.talents.length)continue;
   const b=structuredClone(original),targets={},totals=[0,0,0];
   for(const talent of b.talents){const name=review.aliases[cls]?.[talent.name]||talent.name,node=lookup[name];if(node)targets[name]=Math.max(targets[name]||0,Math.min(talent.rank,node.maxRank));}
   for(const t of b.talents)totals[t.treeIndex-1]+=t.rank;
   const primary=totals.indexOf(Math.max(...totals)),hybrid=/frostfire|elehance|holy-protection|ret-protection|shockadin/.test(b.id);
   const priority=(cls==='DRUID'&&b.role==='tank'?review.bearPriorities:review.priorities[cls]?.[primary])||[];
   // Row-seven abilities replace the previous spec destination only for full, non-hybrid builds.
   if(!hybrid&&(b.points||51)>=51&&priority.length){for(const name of priority.slice(0,3)){const n=lookup[name];if(n&&n.treeIndex===primary+1)targets[name]=n.maxRank;}}
   let changed=true;while(changed){changed=false;for(const name of Object.keys(targets)){const req=lookup[name]?.requires;if(req&&!targets[req]){if(!lookup[req])throw Error(cls+': missing prerequisite '+req);targets[req]=lookup[req].maxRank;changed=true;}}}
   const ranks={},spent=[0,0,0],order=[];
   const desired=Object.keys(targets).reduce((a,n)=>a+targets[n],0),budget=b.points||51;
   const treeBudgets=totals.slice();if(!hybrid&&budget>=51)treeBudgets[primary]=Math.max(31,treeBudgets[primary]);
   const can=n=>(ranks[n.name]||0)<n.maxRank&&spent[n.treeIndex-1]>=n.row*5&&(!n.requires||(ranks[n.requires]||0)>=lookup[n.requires].maxRank);
   for(let point=0;point<budget;point++){
    const nodes=Object.values(lookup).filter(can);
    const score=n=>{
     const ti=n.treeIndex-1,remaining=(targets[n.name]||0)-(ranks[n.name]||0),inBudget=spent[ti]<treeBudgets[ti];
     let s=(remaining>0?10000:0)+(inBudget?100000:0)+(ti===primary?500:0)-n.row*5;
     const p=priority.indexOf(n.name);if(p>=0)s+=100-p;
     if(review.excludedFillers.includes(n.name))s-=1000000;
     // Never add the other form's destination to a Cat/Bear plan just as a filler.
     if(cls==='DRUID'&&((b.role==='tank'&&['Shifting Power','Predatory Discipline'].includes(n.name))||(b.role!=='tank'&&n.name==='Primal Bite')))s-=1000000;
     return s;
    };
    nodes.sort((a,b)=>score(b)-score(a)||a.treeIndex-b.treeIndex||a.talentIndex-b.talentIndex);
    const n=nodes[0];if(!n)throw Error(cls+': allocation cannot be completed '+b.id);
    ranks[n.name]=(ranks[n.name]||0)+1;spent[n.treeIndex-1]++;
    order.push({level:point+10,name:n.name,rank:ranks[n.name],maxRank:n.maxRank,spellId:n.spellId,icon:n.icon,treeIndex:n.treeIndex,talentIndex:n.talentIndex,why:'Planning order for the tuning-adapted allocation; not the original author\'s leveling route.'});
   }
   const talents=[],codes=layout.map((tree,ti)=>tree.nodes.map((n,ni)=>{const rank=ranks[n.name]||0;if(rank)talents.push({name:n.name,tree:tree.name,treeIndex:ti+1,talentIndex:ni+1,rank,maxRank:n.maxRank,tier:n.row+1});return rank;}).join('').replace(/0+$/,''));
   const same=original.talents.length===talents.length&&talents.every(t=>original.talents.some(o=>o.name===t.name&&o.rank===t.rank&&o.treeIndex===t.treeIndex&&o.talentIndex===t.talentIndex));
   b.talents=talents;b.talentString=codes.join('-');b.distribution=spent.join(' / ');b.treeLayout=undefined;
   // Old simulations are not valid performance evidence for newly tuned classes.
   b.previousEvidence=b.previousEvidence||b.evidence;b.previousBoardRank=b.previousBoardRank||b.boardRank;b.evidence='adapted';b.boardRank=0;b.validationStatus='tuning_comparison_pending';
   b.source={...b.source,previousCalculatorUrl:b.source.previousCalculatorUrl||b.source.calculatorUrl,calculatorUrl:'',previousRevision:b.source.previousRevision||b.source.revision,revision:'',talentSnapshot:review.build,reviewed:review.reviewed,tuningUrl:review.notesUrl};
   b.note='Updated for '+review.reviewed+' class tuning. '+(same?'Allocation retained; ':'Allocation adapted; ')+'performance comparison pending.';
   b.levelingOrder=undefined;b.planningOrder=order;
   if(!same)issues.push({class:cls,id:b.id,previous:original.distribution,current:b.distribution});
   builds.classes[className].variants.push(b);
  }
 }
 return {builds,layouts,issues};
}
function render(result,review){
 const lines=['-- Tuning-reviewed allocations; original source URLs retained.','-- Adapted plans have no current simulation ranking. See docs/research/tuning-'+review.reviewed+'.json.','ForeverCoaching=ForeverCoaching or {}','ForeverCoaching.Builds={game="WoW Forever",contentType="Tuning-reviewed planning catalog",reviewed='+lua(review.reviewed)+',classes={'];
 for(const [cls,data]of Object.entries(result.builds.classes)){
  lines.push('  '+cls+'={variants={');for(const b of data.variants){lines.push('    {');for(const [k,v]of Object.entries(b)){if(v===undefined)continue;if(k==='talents'||k==='planningOrder'){lines.push('      '+k+'={');for(const row of v)lines.push('        '+lua(row)+',');lines.push('      },');}else lines.push('      '+k+'='+lua(v)+',');}lines.push('    },');}lines.push('  }},');
 }
 lines.push('}}','ForeverCoaching.TalentTrees={');for(const [cls,trees]of Object.entries(result.layouts)){lines.push('  '+cls+'={');for(const tree of trees){lines.push('    {name='+lua(tree.name)+',nodes={');for(const node of tree.nodes)lines.push('      '+lua(node)+',');lines.push('    }},');}lines.push('  },');}lines.push('}','');return lines.join('\n');
}
if(require.main===module){const [snapshotFile,dir,reviewFile]=process.argv.slice(2);if(!reviewFile)throw Error('Usage: Adapt-ForeverBuilds.cjs named-snapshot.json snapshot-directory reviewed-rules.json');const review=JSON.parse(fs.readFileSync(reviewFile)),result=adapt(JSON.parse(fs.readFileSync(snapshotFile)),dir,review);fs.writeFileSync('addons/ForeverCoaching/Data/LevelingBuilds.lua',render(result,review));fs.writeFileSync(path.join(dir,'build-adaptations.json'),JSON.stringify(result.issues,null,2));console.log('Updated '+Object.values(result.builds.classes).reduce((a,c)=>a+c.variants.length,0)+' allocations; '+result.issues.length+' changed.');}
module.exports={adapt};
