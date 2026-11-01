// Pinned preview-only dependencies; no npm installation or lifecycle scripts.
const fs=require('fs'),path=require('path'),https=require('https'),zlib=require('zlib'),crypto=require('crypto');
const root=path.join(__dirname,'preview-runtime','node_modules');
const packages=[['fengari','0.1.4'],['sprintf-js','1.1.3'],['readline-sync','1.4.10'],['tmp','0.0.33'],['os-tmpdir','1.0.2']];
function ready(){
 try{
  for(const [name,version] of packages)if(JSON.parse(fs.readFileSync(path.join(root,name,'package.json'),'utf8')).version!==version)return false;
  const f=require(path.join(root,'fengari'));const L=f.lauxlib.luaL_newstate();f.lualib.luaL_openlibs(L);f.lua.lua_close(L);return true;
 }catch{return false;}
}
function get(url){return new Promise((resolve,reject)=>{
 const req=https.get(url,res=>{
  if(res.statusCode!==200){res.resume();reject(Error('Runtime download returned HTTP '+res.statusCode));return;}
  const chunks=[];let size=0;
  res.on('data',chunk=>{size+=chunk.length;if(size>8*1024*1024)res.destroy(Error('Runtime download exceeds size limit'));else chunks.push(chunk);});
  res.on('end',()=>resolve(Buffer.concat(chunks)));res.on('error',reject);
 });req.setTimeout(20000,()=>req.destroy(Error('Runtime download timed out')));req.on('error',reject);
});}
async function install(name,version){
 const base='https://registry.npmjs.org/'+name;
 const metadata=JSON.parse((await get(base+'/'+version)).toString('utf8'));
 const tarball=await get(base+'/-/'+name+'-'+version+'.tgz');
 const integrity=metadata.dist?.integrity;
 if(typeof integrity!=='string'||!integrity.startsWith('sha512-')||'sha512-'+crypto.createHash('sha512').update(tarball).digest('base64')!==integrity)throw Error('Integrity check failed for '+name);
 const tar=zlib.gunzipSync(tarball,{maxOutputLength:32*1024*1024}),dir=path.join(root,name);
 for(let offset=0;offset+512<=tar.length;){
  const header=tar.subarray(offset,offset+512),file=header.subarray(0,100).toString().split('\0')[0];if(!file)break;
  const size=parseInt(header.subarray(124,136).toString().replace(/\0/g,'').trim()||'0',8),type=String.fromCharCode(header[156]);
  if(!Number.isSafeInteger(size)||size<0||offset+512+size>tar.length)throw Error('Invalid runtime archive');
  // PAX metadata is not a file and is never extracted or executed.
  if(type==='x'||type==='g'){offset+=512+Math.ceil(size/512)*512;continue;}
  const dest=path.resolve(dir,file.replace(/^package\//,''));
  const rootDirectory=file==='package/'&&type==='5'&&dest===dir;
  if(!rootDirectory&&(!file.startsWith('package/')||!dest.startsWith(dir+path.sep)))throw Error('Unsafe runtime archive path in '+name+': '+JSON.stringify(file));
  if(type==='0'||type==='\0'){fs.mkdirSync(path.dirname(dest),{recursive:true});fs.writeFileSync(dest,tar.subarray(offset+512,offset+512+size));}
  offset+=512+Math.ceil(size/512)*512;
 }
}
(async()=>{
 if(!ready()){
  console.log('Preparing the local Lua preview runtime (first launch requires internet)...');
  await Promise.all(packages.map(([name,version])=>install(name,version)));
  if(!ready())throw Error('The installed Lua runtime failed its startup check.');
 }
 console.log('ForeverCoachingLuaReady');
})().catch(error=>{console.error('Preview runtime setup failed: '+error.message);process.exitCode=1;});
