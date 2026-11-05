const assert=require('assert/strict'),fs=require('fs'),path=require('path');
const root=path.resolve('addons/ForeverCoaching');
const main=fs.readFileSync(path.join(root,'ForeverCoaching.toc'),'utf8').replace(/\r\n/g,'\n');
for(const name of fs.readdirSync(root).filter(name=>name.endsWith('.toc'))){
 const manifest=fs.readFileSync(path.join(root,name),'utf8').replace(/\r\n/g,'\n');
 assert.equal(manifest,main,`${name} must load the same modules, in the same order, with the same metadata`);
 for(const line of manifest.split('\n').map(line=>line.trim()).filter(line=>line&&!line.startsWith('#'))){
  assert(fs.existsSync(path.join(root,...line.split('\\'))),`${name}: missing ${line}`);
 }
}
console.log('PASS: all client manifests match and every declared module exists.');
