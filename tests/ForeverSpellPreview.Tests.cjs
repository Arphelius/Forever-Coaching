const assert=require('assert/strict'),{spawn}=require('child_process');
async function main(){
 const port=14317,base='http://127.0.0.1:'+port;
 const child=spawn(process.execPath,['tools/talent-preview-server.cjs'],{env:{...process.env,ELECTRON_RUN_AS_NODE:'1',FC_PREVIEW_PORT:String(port)},windowsHide:true,stdio:['ignore','pipe','pipe']});
 let errors='';child.stderr.on('data',b=>errors+=b);
 try{
  await new Promise((resolve,reject)=>{const timer=setTimeout(()=>reject(Error('Preview startup timeout: '+errors)),15000);child.once('exit',code=>{clearTimeout(timer);reject(Error('Preview exited '+code+': '+errors));});child.stdout.on('data',b=>{if(String(b).includes('Talent preview:')){clearTimeout(timer);resolve();}});});
  for(const asset of ['/locale-messages.js','/localization.js']){const response=await fetch(base+asset);assert(response.ok,'Missing localization asset '+asset);assert((await response.text()).includes('window.Addon'));}
  for(const cls of ['WARRIOR','HUNTER','MAGE','ROGUE','PRIEST','WARLOCK','PALADIN','DRUID','SHAMAN']){
   const read=async build=>{const r=await fetch(base+'/state?class='+cls+'&level=60&build='+build);const data=await r.json();assert(r.ok,data.error);return data;};
   const initial=await read(0);assert(initial.abilityLessons.length>=40,cls+' complete lessons');
   assert(initial.abilityLessons.every(l=>l.sourceBuild==='1.60.1.70707'&&l.sourceUrl.includes('foreverchanges.pro')));
   const selected=await read(initial.choices[0].index);assert(selected.specScenarios.available,cls+' scenarios');
   assert(selected.specScenarios.basis.includes('1.60.1.70707'));
   assert(selected.specScenarios.scenarios.length===11);
   if(cls==='HUNTER')assert(initial.abilityLessons.some(l=>l.name==='Summon Hawk')&&!initial.abilityLessons.some(l=>l.name==='Kill Command'));
   const first=initial.layout[0].nodes.findIndex(n=>n.row===0)+1;
   const custom={class:cls,name:'Test "custom" build',role:'damage',ranks:{},order:[]};
   const change={treeIndex:1,talentIndex:first,delta:1};
   const response=await fetch(base+'/state?class='+cls+'&level=60&custom='+encodeURIComponent(JSON.stringify(custom))+'&customChange='+encodeURIComponent(JSON.stringify(change)));
   const result=await response.json();assert(response.ok,result.error);assert.equal(result.custom.points,1);assert(result.custom.valid);assert.equal(result.build.kind,'custom');assert.equal(result.build.title,custom.name);assert.equal(result.orderType,'custom');assert.equal(result.nextPoint.talentIndex,first);assert(result.effect?.kind);
  }
  console.log('PASS: real HTTP preview state for all nine classes, complete sourced lessons and scenario integration.');
 }finally{child.kill();}
}
main().catch(error=>{console.error(error);process.exitCode=1;});
