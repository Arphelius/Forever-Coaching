const fs=require('fs'),path=require('path');
const {createHash}=require('crypto');
function addonDirectory(gameRoot){
 if(typeof gameRoot!=='string'||!path.isAbsolute(gameRoot))throw Error('Choose your Forever game folder.');
 const root=fs.realpathSync(gameRoot),addon=path.join(root,'Interface','AddOns','ForeverCoaching');
 const samePath=(a,b)=>process.platform==='win32'?a.toLowerCase()===b.toLowerCase():a===b;
 // A helper export must stay in the selected game's own addon directory.
 for(const part of [path.join(root,'Interface'),path.join(root,'Interface','AddOns'),addon,path.join(addon,'Data')]){
  if(fs.lstatSync(part).isSymbolicLink()||!samePath(fs.realpathSync(part),part))throw Error('Choose a game installation without redirected addon folders.');
 }
 const manifest=fs.readFileSync(path.join(addon,'ForeverCoaching.toc'),'utf8');
 if(!manifest.split(/\r?\n/).some(line=>line.trim()==='Data\\CompanionReviews.lua'))throw Error('Update Forever Coaching in this game folder before sending reviews.');
 return addon;
}
function deliver(gameRoot,results){
 const selected=results.filter(r=>r.analysis?.mentoring?.ready===true);
 if(!selected.length)return {sent:0,message:'More matching reference fights are needed. No peer review was sent to WoW.'};
 if(selected.length>30||selected.some(r=>typeof r.importCode!=='string'||r.importCode.length>60000||!r.importCode.startsWith('FCWCL1|')))throw Error('Review delivery is invalid.');
 const addon=addonDirectory(gameRoot),destination=path.join(addon,'Data','CompanionReviews.lua');
 if(fs.existsSync(destination)&&fs.lstatSync(destination).isSymbolicLink())throw Error('The review file must not be redirected.');
 const records=selected.map(r=>({id:createHash('sha256').update(r.importCode).digest('hex')+require('crypto').randomBytes(8).toString('hex'),code:r.importCode}));
 // Review codes contain ASCII percent-encoded data. Never serialize OAuth
 // state, tokens, raw events or arbitrary helper objects into the addon.
 const quote=value=>'"'+value.replace(/[\\"\x00-\x1f\x7f]/g,c=>c==='\\'?'\\\\':c==='"'?'\\"':'\\'+c.charCodeAt(0).toString().padStart(3,'0'))+'"';
 const text='-- Personal coaching reviews from the local companion. No credentials.\nForeverCoaching=ForeverCoaching or {}\nForeverCoaching.CompanionReviews={'+records.map(r=>'{id='+quote(r.id)+',code='+quote(r.code)+'}').join(',')+'}\n';
 const temporary=path.join(addon,'Data','.CompanionReviews-'+require('crypto').randomBytes(8).toString('hex')+'.tmp');
 try{fs.writeFileSync(temporary,text,{flag:'wx'});fs.renameSync(temporary,destination);}finally{if(fs.existsSync(temporary))fs.unlinkSync(temporary);}
 return {sent:records.length,message:'Ready in WoW. Type /reload, then open Combat Review on the reviewed character.'};
}
function discover(){
 const roots=[process.env.FC_WOW_ROOT,path.resolve(__dirname,'../../../../..'),'D:/World of Warcraft/_forever_','C:/World of Warcraft/_forever_','C:/Program Files (x86)/World of Warcraft/_forever_'].filter(Boolean),found=[];
 for(const candidate of roots){try{const root=fs.realpathSync(candidate);addonDirectory(root);if(!found.includes(root))found.push(root);}catch{}}
 return found;
}
module.exports={addonDirectory,deliver,discover};
