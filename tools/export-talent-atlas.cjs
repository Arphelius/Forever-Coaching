// Dependency-free PNG (8-bit RGB/RGBA) to WoW BGRA atlas exporter.
const fs=require('fs'),path=require('path'),zlib=require('zlib');
function png(file){
 const b=fs.readFileSync(file),parts=[];let w,h,channels;
 for(let p=8;p<b.length;){const n=b.readUInt32BE(p),type=b.toString('ascii',p+4,p+8),d=b.subarray(p+8,p+8+n);p+=n+12;
  if(type==='IHDR'){w=d.readUInt32BE(0);h=d.readUInt32BE(4);channels=d[9]===6?4:d[9]===2?3:0;if(d[8]!==8||!channels||d[12])throw Error('Unsupported PNG');}
  if(type==='IDAT')parts.push(d);
 }
 const raw=zlib.inflateSync(Buffer.concat(parts)),stride=w*channels,out=Buffer.alloc(stride*h);
 const paeth=(a,b,c)=>{const p=a+b-c,da=Math.abs(p-a),db=Math.abs(p-b),dc=Math.abs(p-c);return da<=db&&da<=dc?a:db<=dc?b:c;};
 for(let y=0;y<h;y++){const filter=raw[y*(stride+1)];for(let x=0;x<stride;x++){
  const i=y*stride+x,a=x>=channels?out[i-channels]:0,u=y?out[i-stride]:0,c=y&&x>=channels?out[i-stride-channels]:0;
  out[i]=(raw[y*(stride+1)+1+x]+(filter===0?0:filter===1?a:filter===2?u:filter===3?Math.floor((a+u)/2):paeth(a,u,c)))&255;
 }}return {w,h,channels,out};
}
const source=process.argv[2],target=process.argv[3];
if(!source||!target)throw Error('Usage: export-talent-atlas.cjs source-directory target.tga');
const frames=Number(process.argv[4]||36),columns=Number(process.argv[5]||8);
if(!Number.isInteger(frames)||frames<1||frames>256||![8,16].includes(columns))throw Error('Invalid frame count or columns');
const rows=Math.max(8,2**Math.ceil(Math.log2(Math.ceil(frames/columns))));
const atlasWidth=columns*128,atlasHeight=rows*128;
const atlas=Buffer.alloc(18+atlasWidth*atlasHeight*4);Buffer.from([0,0,2,0,0,0,0,0,0,0,0,0,0,4,0,4,32,40]).copy(atlas);
atlas.writeUInt16LE(atlasWidth,12);atlas.writeUInt16LE(atlasHeight,14);
for(let frame=0;frame<frames;frame++){
 const im=png(path.join(source,`enhancement_${String(frame).padStart(4,'0')}.png`));
 for(let y=0;y<128;y++)for(let x=0;x<128;x++){
  let alpha=0,r=0,g=0,b=0;const sx=Math.floor(x*im.w/128),sy=Math.floor(y*im.h/128),scale=im.w/128;
  for(let yy=0;yy<scale;yy++)for(let xx=0;xx<scale;xx++){
   const i=((sy+yy)*im.w+sx+xx)*im.channels,a=im.channels===4?im.out[i+3]:255;
   alpha+=a;r+=im.out[i]*a;g+=im.out[i+1]*a;b+=im.out[i+2]*a;
  }
  const dst=18+((Math.floor(frame/columns)*128+y)*atlasWidth+(frame%columns)*128+x)*4;
  atlas[dst]=alpha?Math.round(b/alpha):0;atlas[dst+1]=alpha?Math.round(g/alpha):0;atlas[dst+2]=alpha?Math.round(r/alpha):0;atlas[dst+3]=Math.round(alpha/(scale*scale));
 }
}
fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,atlas);process.stdout.write(`Exported ${target}\n`);
