// Remove entire bundled entries; historical research files are retained separately.
const fs=require('fs');
const file='addons/ForeverCoaching/Data/LevelingBuilds.lua';
const lines=fs.readFileSync(file,'utf8').split('\n'),output=[];
let removed=0;
for(let i=0;i<lines.length;i++){
 if(lines[i].startsWith('ForeverCoaching.TalentTrees=')){output.push(...lines.slice(i));break;}
 if(!lines[i].startsWith('    {')){output.push(lines[i]);continue;}
 const block=[lines[i]];
 if(lines[i].trim()==='{'){
  while(++i<lines.length){block.push(lines[i]);if(/^    },\s*$/.test(lines[i]))break;}
 }
 const text=block.join('\n'),level=text.match(/(?:\["maxLevel"\]|\bmaxLevel)\s*=\s*(\d+)/);
 if(!level)throw Error('Build has no declared level');
 if(Number(level[1])<60)removed++;else output.push(...block);
}
fs.writeFileSync(file,output.join('\n'));
console.log('Removed '+removed+' builds ending below level 60.');
