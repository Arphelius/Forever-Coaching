const fs=require('fs'),path=require('path'),crypto=require('crypto');
const {parseLog}=require('./local-combat-log.cjs');
const {addonDirectory}=require('./coaching-delivery.cjs');
const {toLua}=require('./lua-data.cjs');
function writePersonalLog(data,destination){
 if(!data.fights?.length)throw Error('No identifiable player fights in supported dungeons were found. Existing imports were preserved.');
 if(data.malformedDamageEvents)throw Error('Some damage events could not be decoded safely. Existing imports were preserved.');
 if(fs.existsSync(destination)&&fs.lstatSync(destination).isSymbolicLink())throw Error('Personal log file must not be redirected.');
 const temp=destination+'.'+crypto.randomBytes(8).toString('hex')+'.tmp';
 try{fs.writeFileSync(temp,'-- PRIVATE player combat data. Excluded from releases.\nForeverCoaching=ForeverCoaching or {}\nForeverCoaching.PersonalCombatLog='+toLua(data)+'\n',{flag:'wx'});fs.renameSync(temp,destination);}finally{if(fs.existsSync(temp))fs.unlinkSync(temp);}
}
async function importLog(gameRoot,file){
 const addon=addonDirectory(gameRoot),manifest=fs.readFileSync(path.join(addon,'ForeverCoaching.toc'),'utf8');
 if(!manifest.includes('Data\\PersonalCombatLog.lua'))throw Error('Install the My Logs addon update first.');
 if(!file){const dir=path.join(gameRoot,'Logs'),files=fs.readdirSync(dir).filter(n=>/^WoWCombatLog.*\.txt$/i.test(n)).map(n=>path.join(dir,n)).sort((a,b)=>fs.statSync(b).mtimeMs-fs.statSync(a).mtimeMs);file=files[0];}
 if(!file)throw Error('No combat log was found. Enable combat logging and record a dungeon first.');
 const data=await parseLog(file);data.sourceFile=path.basename(file);data.importedAt=Date.now();
 writePersonalLog(data,path.join(addon,'Data','PersonalCombatLog.lua'));
 return data;
}
if(require.main===module){let gameRoot,file;try{const args=process.argv.slice(2);for(let i=0;i<args.length;i+=2){if(args[i]==='--game-root')gameRoot=args[i+1];else if(args[i]==='--file')file=args[i+1];else throw Error('Use --game-root GAME_FOLDER and optional --file COMBAT_LOG.');}importLog(gameRoot,file).then(data=>console.log(`Imported ${data.fights.length} personal encounter/trash summaries from ${data.sourceFile}. Use /reload, then My Logs. Spec is selected in-game; raw logs do not verify the selected spec. No Warcraft Logs credentials are required.`)).catch(error=>{console.error(error.message);process.exitCode=1;});}catch(error){console.error(error.message);process.exitCode=1;}}
module.exports={importLog,writePersonalLog};
