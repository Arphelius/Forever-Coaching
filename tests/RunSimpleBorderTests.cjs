const assert=require('assert/strict'),fs=require('fs'),path=require('path'),vm=require('vm'),crypto=require('crypto');
const media='addons/ForeverCoaching/Media/TalentEffects';
const window={};vm.runInNewContext(fs.readFileSync('tools/talent-preview/border-styles.js','utf8'),{window});
const styles=window.TalentBorderStyles;
assert.equal(Object.keys(styles).length,29);
const lua=fs.readFileSync('addons/ForeverCoaching/Data/TalentBorderStyles.lua','utf8');
const designs=fs.readFileSync('addons/ForeverCoaching/UI/TalentArtPreview.lua','utf8');
const textures=new Map(),hashes=new Set();
for(const [kind,style] of Object.entries(styles)){
 assert(designs.includes(`","${kind}",`),`Preview missing ${kind}`);
 assert(lua.includes(`["${kind}"]={file="${style.file}",frame=${style.frame}}`),`Lua/browser mismatch: ${kind}`);
 const filename=path.join(media,style.file+'.tga'),bytes=fs.readFileSync(filename);
 assert.equal(bytes[2],2);assert.equal(bytes[16],32);assert.equal(bytes.readUInt16LE(12),1024);assert.equal(bytes.readUInt16LE(14),1024);
 const col=style.frame%8,row=Math.floor(style.frame/8),cell=Buffer.alloc(128*128*4);
 for(let y=0;y<128;y++)bytes.copy(cell,y*512,18+((row*128+y)*1024+col*128)*4,18+((row*128+y)*1024+col*128+128)*4);
 assert.equal(cell[(64*128+64)*4+3],0,`Artwork center covered: ${kind}`);
 const hash=crypto.createHash('sha256').update(cell).digest('hex');assert(!hashes.has(hash),`Duplicate border: ${kind}`);hashes.add(hash);
 textures.set('/'+style.atlas+'.tga',bytes);
}
let callback,draws=0;
class Canvas{
 constructor(){this.width=300;this.height=300;this.style={};this.isConnected=true;this.classList={add(){}};}
 setAttribute(){}
 getContext(){return {putImageData(){},clearRect(){},drawImage(){draws++;},setTransform(){}};}
}
const context={window,Uint8Array,DataView,ImageData:class{constructor(w,h){this.data=new Uint8Array(w*h*4);}},
 document:{hidden:false,createElement:()=>new Canvas(),getElementById:()=>({textContent:''})},
 fetch:url=>(url=url.split('?')[0],textures.has(url))?Promise.resolve({ok:true,arrayBuffer:async()=>{const b=textures.get(url);return b.buffer.slice(b.byteOffset,b.byteOffset+b.byteLength);}}):new Promise(()=>{}),
 requestAnimationFrame:fn=>{callback=fn;},matchMedia:()=>({matches:false})};
vm.runInNewContext(fs.readFileSync('tools/talent-preview/effects.js','utf8'),context);
(async()=>{
 await new Promise(setImmediate);
 const nodes=[];
 for(const kind of Object.keys(styles)){
  const node={offsetWidth:38,title:'',classList:{add(){}},append(c){c.parentElement=this;}};nodes.push(node);
  window.TalentEffects.attachBorder(node,{kind});
 }
 callback(1000);assert.equal(draws,29,'All border textures should render');
 callback(2000);callback(10000);assert.equal(draws,29,'Static borders must not redraw or animate over time');
 nodes[0].offsetWidth=48;callback(11000);assert.equal(draws,30,'Resizing must redraw the affected border');
 console.log('All 29 borders: matching manifests, valid unique assets, clear artwork centers, static rendering, and resizing passed.');
})().catch(error=>{console.error(error);process.exitCode=1;});
