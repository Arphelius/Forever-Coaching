const assert=require('assert/strict'),fs=require('fs'),os=require('os'),path=require('path');
const {loadKey}=require('../tools/foreverlogs-config.cjs');
const root=fs.mkdtempSync(path.join(os.tmpdir(),'fc-key-config-'));
try{
 assert.equal(loadKey(root,{}),'');
 fs.mkdirSync(path.join(root,'.local'));
 const file=path.join(root,'.local','foreverlogs-api-key.txt');
 fs.writeFileSync(file,'fixture-local-key\r\n');assert.equal(loadKey(root,{}),'fixture-local-key');
 assert.equal(loadKey(root,{FOREVERLOGS_API_KEY:'fixture-environment-key'}),'fixture-environment-key');
 fs.writeFileSync(file,'first\nsecond');assert.throws(()=>loadKey(root,{}),/single line/);
 console.log('PASS: local key loading, environment precedence and multiline rejection without credential output.');
}finally{const file=path.join(root,'.local','foreverlogs-api-key.txt');if(fs.existsSync(file))fs.unlinkSync(file);if(fs.existsSync(path.dirname(file)))fs.rmdirSync(path.dirname(file));fs.rmdirSync(root);}
