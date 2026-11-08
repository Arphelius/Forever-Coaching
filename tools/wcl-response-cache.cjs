// Local API data only. Authentication responses and request headers never enter this cache.
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const hash=value=>crypto.createHash('sha256').update(value).digest('hex');
function responseCache(directory,namespace,{now=Date.now,ttl=7*86400000}={}){
 const root=path.resolve(directory);
 fs.mkdirSync(root,{recursive:true});
 if(fs.lstatSync(root).isSymbolicLink())throw Error('API cache directory must not be a symbolic link.');
 function file(key){return path.join(root,hash(namespace+'\n'+key)+'.json');}
 return {
  get(key){
   try{const target=file(key),stat=fs.lstatSync(target);if(stat.isSymbolicLink()||stat.size>32*1024*1024)return;
    const entry=JSON.parse(fs.readFileSync(target,'utf8'));
    if(entry.schema===1&&Number.isFinite(entry.savedAt)&&entry.savedAt<=now()&&now()-entry.savedAt<ttl&&entry.data&&typeof entry.data==='object')return entry.data;
   }catch(error){if(!['ENOENT'].includes(error.code)&&!(error instanceof SyntaxError))throw error;}
  },
  set(key,data){
   const target=file(key);if(fs.existsSync(target)&&fs.lstatSync(target).isSymbolicLink())throw Error('API cache entry must not be a symbolic link.');
   const temp=target+'.'+crypto.randomBytes(8).toString('hex')+'.tmp';
   try{fs.writeFileSync(temp,JSON.stringify({schema:1,savedAt:now(),data}),{flag:'wx'});fs.renameSync(temp,target);}finally{if(fs.existsSync(temp))fs.unlinkSync(temp);}
  },
 };
}
module.exports={responseCache};
