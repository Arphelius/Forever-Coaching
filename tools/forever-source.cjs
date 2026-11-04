// Parsing is strict: a partial or changed upstream page must not replace bundled data.
const fs=require('fs');
function rsc(html){return [...html.matchAll(/self\.__next_f\.push\(\[1,("(?:\\.|[^"\\])*")\]\)/g)].map(m=>JSON.parse(m[1])).join('');}
function objectAfter(raw,key){let start=raw.indexOf('"'+key+'":');if(start<0)throw Error('Missing source field: '+key);start+=key.length+3;let depth=0,quoted=false,escape=false;for(let i=start;i<raw.length;i++){const c=raw[i];if(quoted){if(escape)escape=false;else if(c==='\\')escape=true;else if(c==='"')quoted=false;}else if(c==='"')quoted=true;else if(c==='{'||c==='[')depth++;else if(c==='}'||c===']'){if(--depth===0)return JSON.parse(raw.slice(start,i+1));}}throw Error('Incomplete source field: '+key);}
function page(file,key){return objectAfter(rsc(fs.readFileSync(file,'utf8')),key);}
function lua(value){if(value===null||value===undefined)return 'nil';if(typeof value==='string')return JSON.stringify(value).replace(/\\u([0-9a-f]{4})/g,(_,h)=>String.fromCharCode(parseInt(h,16)));if(typeof value==='number'||typeof value==='boolean')return String(value);if(Array.isArray(value))return '{'+value.map(lua).join(',')+'}';return '{'+Object.entries(value).map(([k,v])=>'['+lua(k)+']='+lua(v)).join(',')+'}';}
const classes=['warrior','hunter','mage','rogue','priest','warlock','paladin','druid','shaman'];
module.exports={rsc,objectAfter,page,lua,classes};
