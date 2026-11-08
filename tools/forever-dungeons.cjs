const dungeons=require('../data/forever-dungeons.json');
const normal=s=>String(s||'').toLowerCase().replace(/[^a-z0-9]/g,'');
function resolveDungeon(instance,encounter){
 const names=new Set([instance,encounter,instance+': '+encounter].map(normal));
 const matches=dungeons.filter(d=>[d.name,...d.aliases].some(n=>names.has(normal(n))));
 return matches.length===1?matches[0]:null;
}
module.exports={dungeons,resolveDungeon};
