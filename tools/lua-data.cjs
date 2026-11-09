function toLua(value){
 if(value==null)return 'nil';
 if(typeof value==='string')return '"'+value.replace(/[\\"\x00-\x1f\x7f]/g,c=>c==='\\'?'\\\\':c==='"'?'\\"':'\\'+c.charCodeAt(0).toString().padStart(3,'0'))+'"';
 if(typeof value==='number'){if(!Number.isFinite(value))throw Error('Invalid numeric log value.');return String(value);}
 if(typeof value==='boolean')return String(value);
 if(Array.isArray(value))return '{'+value.map(toLua).join(',')+'}';
 if(typeof value==='object')return '{'+Object.entries(value).map(([key,item])=>'['+toLua(key)+']='+toLua(item)).join(',')+'}';
 throw Error('Unsupported log data.');
}
module.exports={toLua};
