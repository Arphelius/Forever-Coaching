// Antialiased browser approximation. Palettes/spec selection come from addon Lua.
window.TalentEffects=(()=>{
 const scenes=new Set(),tau=Math.PI*2;
 const authoredAtlases={};
 let staticBorderLoad;
 function refreshBorders(){if(staticBorderLoad)return staticBorderLoad;
 staticBorderLoad=fetch('/simple-borders.tga?v=paladin-light-5',{cache:'no-store'}).then(r=>{if(!r.ok)throw Error('Static borders unavailable');return r.arrayBuffer();}).then(decode=>{
  const bytes=new Uint8Array(decode),v=new DataView(decode),w=v.getUint16(12,true),h=v.getUint16(14,true),pixels=new ImageData(w,h);
  if(bytes[2]!==2||bytes[16]!==32||!(bytes[17]&32))throw Error('Unsupported static border atlas');
  for(let i=0;i<w*h;i++){const s=18+bytes[0]+i*4,d=i*4;pixels.data[d]=bytes[s+2];pixels.data[d+1]=bytes[s+1];pixels.data[d+2]=bytes[s];pixels.data[d+3]=bytes[s+3];}
  const atlas=document.createElement('canvas');atlas.width=w;atlas.height=h;atlas.getContext('2d').putImageData(pixels,0,0);authoredAtlases['simple-borders']=atlas;
 }).catch(error=>{document.getElementById('error').textContent=error.message;}).finally(()=>{staticBorderLoad=null;});return staticBorderLoad;}
 refreshBorders();
 // Decode the exact uncompressed BGRA atlas shipped with the addon.
 for(const kind of ['feral-fangs','enhancement','enhancement-rear','enhancement-elements','elemental','water','holy-paladin','retribution','protection-paladin','beast-mastery','marksmanship','survival','balance','feral-dps','feral-tank','restoration-druid','arcane','fire','frost','frostfire','discipline','holy-priest','shadow-priest','assassination','combat','combat-smoke','combat-blood','subtlety','affliction','fel','destruction','arms','fury','protection-warrior','arms-border','fury-border','protection-warrior-border'])fetch(`/${kind}.tga`).then(r=>{if(!r.ok)throw new Error('Animation atlas unavailable');return r.arrayBuffer();}).then(buffer=>{
  const bytes=new Uint8Array(buffer),view=new DataView(buffer);
  const width=view.getUint16(12,true),height=view.getUint16(14,true);
  if(bytes[2]!==2||bytes[16]!==32||!(bytes[17]&32))throw new Error('Unsupported animation atlas format');
  const pixels=new ImageData(width,height),offset=18+bytes[0];
  for(let i=0;i<width*height;i++){const src=offset+i*4,dst=i*4;pixels.data[dst]=bytes[src+2];pixels.data[dst+1]=bytes[src+1];pixels.data[dst+2]=bytes[src];pixels.data[dst+3]=bytes[src+3];}
  const atlas=document.createElement('canvas');atlas.width=width;atlas.height=height;
  atlas.getContext('2d').putImageData(pixels,0,0);authoredAtlases[kind]=atlas;
 }).catch(error=>{document.getElementById('error').textContent=error.message+' — restart Preview-Addon.cmd.';});
 const rgb=(v,a=1)=>`rgba(${v.map(n=>Math.round(n*255)).join(',')},${a})`;
 function line(c,points,color,width=2){c.beginPath();points.forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.strokeStyle=color;c.lineWidth=width;c.lineCap='round';c.lineJoin='round';c.stroke();}
 function sword(c,x,color,dagger=false){c.save();c.translate(x,0);c.fillStyle='#d9edf7';c.beginPath();c.moveTo(-2,10);c.lineTo(-2,dagger?-12:-20);c.lineTo(0,dagger?-18:-27);c.lineTo(3,dagger?-12:-20);c.lineTo(2,10);c.fill();line(c,[[-8,10],[8,10]],'#d3b36a',3);line(c,[[0,11],[0,21]],'#845c36',4);line(c,[[0,dagger?-14:-23],[1,dagger?-5:-13]],color,2);c.restore();}
 function shield(c,x,color){c.save();c.translate(x,0);c.beginPath();c.moveTo(-12,-18);c.quadraticCurveTo(0,-24,12,-18);c.lineTo(11,3);c.quadraticCurveTo(6,17,0,21);c.quadraticCurveTo(-6,17,-11,3);c.closePath();c.fillStyle=color;c.globalAlpha=.35;c.fill();c.globalAlpha=1;c.strokeStyle='#dfd9b6';c.lineWidth=1.5;c.stroke();line(c,[[0,-15],[0,11]],'#fff1bd',1.5);c.restore();}
 function motifs(c,p,t){
  const color=rgb(p.color),accent=rgb(p.accent),kind=p.kind||'';c.shadowColor=color;c.shadowBlur=5;
  if(['arms','assassination','combat','fury','protection-warrior','arms-border','fury-border','protection-warrior-border'].includes(kind)){sword(c,kind==='protection-warrior'?34:-34,accent,kind==='combat'||kind==='assassination');if(kind==='combat'||kind==='fury')sword(c,34,accent,kind==='combat');if(kind==='protection-warrior')shield(c,-34,color);}
  if(kind==='protection-paladin')shield(c,-34,color);
  if(['holy-paladin','holy-priest','discipline','shadow-priest','retribution'].includes(kind)){
   c.globalAlpha=.4+.2*Math.sin(t*2);for(let i=-1;i<=1;i++)line(c,[[i*5,-30],[i*10,-53]],accent,2);
   if(kind==='holy-priest')for(const side of [-1,1])for(let f=0;f<4;f++)line(c,[[side*24,4],[side*(38+f*3),-20+f*8]],accent,3);
   if(kind==='discipline'){c.beginPath();c.ellipse(0,0,28,34,0,0,tau);c.strokeStyle=accent;c.lineWidth=2;c.stroke();}
   if(kind==='retribution'){line(c,[[-6,-35],[-6,-47],[-3,-50],[0,-38],[1,-51],[4,-52],[5,-38],[8,-47],[11,-46],[11,-33],[5,-27],[-3,-28],[-8,-34]],accent,2);}
   c.globalAlpha=1;
  }
  if(kind==='marksmanship'){for(const r of [30,38]){c.beginPath();c.arc(0,0,r,0,tau);c.strokeStyle=accent;c.lineWidth=1;c.stroke();}for(const side of [-1,1]){line(c,[[side*26,0],[side*45,0]],color);line(c,[[0,side*26],[0,side*45]],color);}}
  if(kind==='elemental'||kind==='enhancement')for(const side of [-1,1]){c.globalAlpha=.45+.55*Math.max(0,Math.sin(t*6));line(c,[[side*35,-23],[side*29,-8],[side*38,-9],[side*30,12],[side*38,7],[side*32,24]],accent,1.6);c.globalAlpha=1;}
  if(kind==='feral-tank'||kind==='feral-dps')for(const side of [-1,1])for(let i=0;i<3;i++){c.beginPath();c.moveTo(side*(28+i*6),-18);c.quadraticCurveTo(side*(37+i*5),0,side*(25+i*6),20);c.strokeStyle=accent;c.lineWidth=kind==='feral-tank'?3:1.5;c.stroke();}
  if(kind==='subtlety'){c.fillStyle='rgba(20,12,29,.65)';c.beginPath();c.ellipse(0,-36,15,9,0,0,tau);c.fill();line(c,[[-9,-37],[-4,-35]],'#ff3434',2);line(c,[[4,-35],[9,-37]],'#ff3434',2);}
  if(kind==='balance'){c.fillStyle=color;c.beginPath();c.arc(-34,0,9,0,tau);c.fill();c.globalCompositeOperation='destination-out';c.beginPath();c.arc(-30,-3,8,0,tau);c.fill();c.globalCompositeOperation='source-over';c.fillStyle=accent;c.beginPath();c.arc(34,0,7,0,tau);c.fill();for(let i=0;i<8;i++){const a=i*tau/8;line(c,[[34+Math.cos(a)*10,Math.sin(a)*10],[34+Math.cos(a)*14,Math.sin(a)*14]],accent,1);}}
  if(kind==='beast-mastery')for(let i=-1;i<=1;i++){c.fillStyle=accent;c.beginPath();c.ellipse(i*13,36,4,5,-.3,0,tau);c.fill();for(let j=0;j<3;j++){c.beginPath();c.arc(i*13-4+j*4,28,1.7,0,tau);c.fill();}}
  if(kind==='survival'){line(c,[[-43,9],[-33,0],[-24,9],[-33,5],[-43,9]],color,2);c.fillStyle=accent;c.beginPath();c.arc(34,6,6,0,tau);c.fill();line(c,[[35,0],[39,-7],[44,-5]],'#e8cfa0',1.5);}
 }
 function draw(scene,time){
  const {canvas,p}=scene;
  if(p.kind==='simple-border'){
   const bigger=['affliction','fel','destruction'].includes(p.border.kind)?1.10:p.border.kind==='water'?1.08:1;
   const size=(canvas.parentElement.offsetWidth-2)*1024/406*bigger,atlas=authoredAtlases[p.border.atlas];
   if(!atlas)return;
   if(scene.drawnSize===size&&scene.drawnAtlas===atlas)return;
   canvas.style.width=`${size}px`;canvas.style.height=`${size}px`;
   const c=canvas.getContext('2d');c.clearRect(0,0,300,300);
   const col=p.border.frame%8,row=Math.floor(p.border.frame/8);
   c.drawImage(atlas,col*128+.5,row*128+.5,127,127,0,0,300,300);
   scene.drawnSize=size;scene.drawnAtlas=atlas;return;
  }
  if(['enhancement','enhancement-rear','enhancement-elements','elemental','water','holy-paladin','retribution','protection-paladin','beast-mastery','marksmanship','survival','balance','feral-dps','feral-tank','restoration-druid','arcane','fire','frost','frostfire','discipline','holy-priest','shadow-priest','assassination','combat','subtlety','affliction','fel','destruction','arms','fury','protection-warrior','arms-border','fury-border','protection-warrior-border'].includes(p.kind)){
   const nodeWidth=(scene.node||canvas.parentElement).offsetWidth;
   const size=p.kind==='frost'?(nodeWidth-2)*650/406:['frostfire','shadow-priest','combat','subtlety','affliction','fel','destruction','arms','fury','protection-warrior','arms-border','fury-border','protection-warrior-border'].includes(p.kind)?(nodeWidth-2)*1024/406:(nodeWidth+6)*(p.kind==='enhancement'?1.7:2.4);
   if(scene.node){canvas.style.left=`${scene.node.offsetLeft+scene.node.offsetWidth/2}px`;canvas.style.top=`${scene.node.offsetTop+scene.node.offsetHeight/2}px`;}
   canvas.style.width=`${size}px`;canvas.style.height=`${size}px`;
   const c=canvas.getContext('2d');c.setTransform(1,0,0,1,0,0);c.clearRect(0,0,300,300);
   if(scene.started===undefined)scene.started=time;
   const age=time-scene.started;
   const atlas=authoredAtlases[p.kind];
   if(p.kind==='combat'&&authoredAtlases['combat-smoke']){const sf=Math.floor(age*12)%36;c.drawImage(authoredAtlases['combat-smoke'],sf%8*128+.5,Math.floor(sf/8)*128+.5,127,127,0,0,300,300);}
   const tick=Math.floor(age*12);
   const mountainFrame=tick<36?tick:18+(tick-36)%18;
   if(atlas){const frame=['arms-border','fury-border','protection-warrior-border'].includes(p.kind)?0:p.kind==='protection-warrior'?mountainFrame:p.kind==='combat'?Math.min(35,Math.floor(age*10)):['affliction','arms'].includes(p.kind)?Math.min(107,tick):p.kind==='destruction'?(tick<108?tick:72+(tick-108)%36):p.kind==='fel'?tick%108:Math.floor(age*(p.kind==='arcane'?18:12))%36,columns=['affliction','fel','destruction','arms'].includes(p.kind)?16:8,col=frame%columns,row=Math.floor(frame/columns);
    c.drawImage(atlas,col*128+.5,row*128+.5,127,127,0,0,300,300);}
   if(p.kind==='combat'&&age>=35/10&&authoredAtlases['combat-blood']){const bf=Math.floor(age*12)%36;c.drawImage(authoredAtlases['combat-blood'],bf%8*128+.5,Math.floor(bf/8)*128+.5,127,127,0,0,300,300);}
   return;
  }
  const c=canvas.getContext('2d');c.setTransform(2,0,0,2,150,150);c.clearRect(-75,-75,150,150);
  const color=rgb(p.color),accent=rgb(p.accent),wave=.5+.5*Math.sin(time*2);
  c.shadowColor=color;c.shadowBlur=9+wave*5;c.strokeStyle=rgb(p.color,.6+wave*.25);c.lineWidth=2;c.beginPath();c.roundRect(-23,-23,46,46,9);c.stroke();
  for(let i=0;i<18;i++){
   const progress=(time*.28+i/18)%1,a=i*tau/18+Math.sin(time*.3)*.12,r=28+progress*15;
   let x=Math.cos(a)*r,y=Math.sin(a)*r,fade=Math.sin(progress*Math.PI),mode=p.mode;
   if(mode==='felshadow')mode=i%2?'embers':'wisps';if(mode==='magma')mode=i%2?'embers':'surge';if(mode==='earthstorm')mode=i%2?'shards':'surge';
   c.fillStyle=i%2?color:accent;c.strokeStyle=i%2?color:accent;c.globalAlpha=fade*.8;c.shadowBlur=5;
   if(['embers','bleed','poison','leaves'].includes(mode)){x=(i%2?1:-1)*(27+Math.sin(time+i)*5);y=mode==='embers'?28-progress*65:-30+progress*65;}
   c.save();c.translate(x,y);
   if(mode==='shards'||mode==='leaves'){c.rotate(a+Math.sin(time+i)*.2);c.beginPath();c.moveTo(0,-7);c.lineTo(3,1);c.lineTo(0,5);c.lineTo(-2,1);c.closePath();c.fill();}
   else if(mode==='surge'||mode==='slashes'||mode==='berserk'){c.rotate(a);c.globalAlpha=fade**3;line(c,[[0,0],[5+fade*4,0]],i%2?color:accent,1.5);}
   else if(mode==='wisps'||mode==='dots'||mode==='water'){const g=c.createRadialGradient(0,0,0,0,0,mode==='water'?5:9);g.addColorStop(0,rgb(i%2?p.color:p.accent,.6));g.addColorStop(1,rgb(p.color,0));c.fillStyle=g;c.beginPath();c.arc(0,0,9,0,tau);c.fill();}
   else{c.beginPath();c.ellipse(0,0,1.3,mode==='embers'?3:2.2,0,0,tau);c.fill();}
   c.restore();
  }
  c.globalAlpha=1;motifs(c,p,time);
 }
 function frame(ms){const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;for(const scene of scenes){if(!scene.canvas.isConnected){scenes.delete(scene);continue;}if(!document.hidden)draw(scene,reduced?1:ms/1000);}requestAnimationFrame(frame);}requestAnimationFrame(frame);
 return {refreshBorders,attachBorder(node,p){const border=window.TalentBorderStyles[p?.kind];if(border){if(['elemental','water','assassination','combat','subtlety','discipline','shadow-priest'].includes(p.kind))node.classList.add('simple-border-'+p.kind);this.attach(node,{kind:'simple-border',border:{...border,kind:p.kind}});}},
 attach(node,p){if(!p)return;const canvas=document.createElement('canvas');canvas.width=300;canvas.height=300;canvas.className='talent-effect';canvas.setAttribute('aria-hidden','true');
  if(['enhancement','elemental','water','holy-paladin','retribution','protection-paladin','beast-mastery','marksmanship','survival','balance','feral-dps','feral-tank','restoration-druid','arcane','fire','frost','frostfire','discipline','holy-priest','shadow-priest','assassination','combat','subtlety','affliction','fel','destruction','arms','fury','protection-warrior','arms-border','fury-border','protection-warrior-border'].includes(p.kind)){
   node.classList.add('authored-'+p.kind);
   // WoW overlay extends three pixels past each icon edge, then scales by 2.4.
   const size=(node.offsetWidth+6)*2.4;canvas.style.width=`${size}px`;canvas.style.height=`${size}px`;
   node.title+=(node.title?'\n':'')+p.kind+' animation • addon atlas • 12 FPS';
  }
  if(p.kind==='enhancement'){
   canvas.style.zIndex='4';node.parentElement.append(canvas);
   scenes.add({canvas,p,node});
   const rear=document.createElement('canvas');rear.width=300;rear.height=300;rear.className='talent-effect';rear.style.zIndex='4';rear.setAttribute('aria-hidden','true');node.parentElement.append(rear);scenes.add({canvas:rear,p:{...p,kind:'enhancement-rear'},node});
   const front=document.createElement('canvas');front.width=300;front.height=300;front.className='talent-effect';front.setAttribute('aria-hidden','true');node.append(front);
   scenes.add({canvas:front,p:{...p,kind:'enhancement-elements'}});
  }else{node.append(canvas);scenes.add({canvas,p});if(p.kind==='feral-dps')this.attach(node,{kind:'simple-border',border:{atlas:'feral-fangs',frame:0}});}}};
})();
