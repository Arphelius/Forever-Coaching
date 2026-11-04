// Compare a downloaded candidate with the committed factual fingerprints.
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const {generate}=require('./Import-ForeverSpellCatalog.cjs'),{lua}=require('./forever-source.cjs');
const hash=v=>crypto.createHash('sha256').update(JSON.stringify(v)).digest('hex');
function fingerprints(catalog){const out={build:catalog.build,revision:catalog.revision,reviewed:catalog.reviewed,classes:{}};for(const [cls,data]of Object.entries(catalog.classes)){out.classes[cls]={spells:Object.fromEntries(Object.entries(data.spells).map(([name,value])=>[name,hash(value)])),talents:Object.fromEntries(Object.entries(data.talents).map(([name,value])=>[name,hash(value)]))};}return out;}
function compare(before,after){const changes=[];for(const [cls,data]of Object.entries(after.classes))for(const kind of ['spells','talents']){const prior=before.classes[cls]?.[kind]||{};for(const name of new Set([...Object.keys(prior),...Object.keys(data[kind])]))if(prior[name]!==data[kind][name])changes.push({class:cls,kind,name,change:!prior[name]?'added':!data[kind][name]?'removed':'changed'});}return changes;}
function main(args){const dir=args[0];if(!dir)throw Error('Usage: Check-ForeverTuning.cjs snapshot-directory [--accept-baseline]');const baselinePath=path.resolve(__dirname,'../docs/research/forever-tuning-baseline.json'),catalog=generate(dir),candidate=fingerprints(catalog);
 const notes=JSON.parse(fs.readFileSync(path.join(dir,'official-notes.json'),'utf8'));
 const posts=notes.post_stream?.posts?.filter(p=>p.username==='Kaivax'||p.moderator||p.admin).sort((a,b)=>a.post_number-b.post_number);
 if(!posts?.length)throw Error('Official development notes unavailable; do not report the data as current');
 candidate.officialNotesHash=hash(posts.map(p=>({number:p.post_number,text:p.cooked})));
 if(args.includes('--accept-baseline')){fs.writeFileSync(baselinePath,JSON.stringify(candidate,null,2)+'\n');console.log('Recorded reviewed factual baseline '+catalog.revision);return;}
 const baseline=JSON.parse(fs.readFileSync(baselinePath,'utf8')),changes=compare(baseline,candidate);
 fs.writeFileSync(path.join(dir,'candidate-catalog.lua'),'-- Candidate only: requires gameplay review.\nForeverCoaching=ForeverCoaching or {}\nForeverCoaching.ForeverSpellCatalog='+lua(catalog)+'\n');
 const officialNotesChanged=baseline.officialNotesHash!==candidate.officialNotesHash;
 const report={baseline:baseline.revision,candidate:candidate.revision,changed:changes.length>0||baseline.build!==candidate.build||officialNotesChanged,officialNotesChanged,changes};
 fs.writeFileSync(path.join(dir,'tuning-report.json'),JSON.stringify(report,null,2)+'\n');
 fs.writeFileSync(path.join(dir,'tuning-report.md'),'# Forever tuning check\n\nReviewed baseline: '+baseline.build+' ('+baseline.reviewed+'). Candidate: '+catalog.build+'.\n\n'+(report.changed?'Review required before publishing gameplay changes.':'No spell or talent data changes detected.')+(officialNotesChanged?'\n\nOfficial development notes changed: review mechanics even if tooltips are unchanged.':'')+'\n\n'+changes.map(c=>'- '+c.class+' '+c.kind+': '+c.name+' ('+c.change+')').join('\n')+'\n\nReview affected allocations and leveling orders, known-spell gates, proc/cooldown rules, scenario instructions, learning text, gear explanations, combat-review assumptions and simulator weights. Patch-note mechanics can change without tooltip changes; read the official notes too.\n');
 console.log(changes.length+' spell/talent changes. Report: '+path.join(dir,'tuning-report.md'));if(report.changed)process.exitCode=2;
}
if(require.main===module)main(process.argv.slice(2));
module.exports={fingerprints,compare};
