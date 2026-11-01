const fs=require('fs'),path=require('path');
function loadKey(root,environment=process.env){
 const configured=environment.FOREVERLOGS_API_KEY;
 const value=typeof configured==='string'&&configured.trim()?configured:
  fs.existsSync(path.join(root,'.local','foreverlogs-api-key.txt'))?fs.readFileSync(path.join(root,'.local','foreverlogs-api-key.txt'),'utf8'):'';
 const key=value.trim();
 if(/[\r\n]/.test(key))throw Error('The Forever Logs key file must contain one key on a single line.');
 return key;
}
module.exports={loadKey};
