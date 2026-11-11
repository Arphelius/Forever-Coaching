const fs=require('fs'),path=require('path');
const {createClient}=require('./warcraftlogs-client.cjs');
const {readReportPages}=require('./saved-report-pages.cjs');
const {addonDirectory}=require('./coaching-delivery.cjs');
const {refresh}=require('./automatic-public-reports.cjs');
async function main(){
 const args=process.argv.slice(2),options={};
 for(let i=0;i<args.length;i+=2){if(!['--game-root','--hours','--request-budget'].includes(args[i])||!args[i+1])throw Error('Invalid automatic update option.');options[args[i]]=args[i+1];}
 const root=path.resolve(__dirname,'..'),addon=addonDirectory(options['--game-root']||'D:/World of Warcraft/_forever_');
 const manifest=fs.readFileSync(path.join(addon,'ForeverCoaching.toc'),'utf8');
 if(!manifest.includes('Data\\PublicReportCatalog.lua'))throw Error('Install the current addon first.');
 const pages=path.join(root,'.local/optimization');
 const hasPages=fs.existsSync(pages)&&fs.readdirSync(pages).some(f=>/\.html?$/i.test(f));
 const seeds=hasPages?readReportPages(pages).codes:[];
 const client=createClient({cacheDirectory:path.join(root,'.local/warcraftlogs/api-cache'),requestBudget:Number(options['--request-budget']||100)});
 const lock=path.join(root,'.local/optimization/automatic.lock');fs.mkdirSync(path.dirname(lock),{recursive:true});
 // The open exclusive lock is removed on exit; stale locks are inspected by PID.
 if(fs.existsSync(lock)){
  const pid=Number(fs.readFileSync(lock,'utf8'));if(!Number.isSafeInteger(pid)||pid<=0)throw Error('Invalid update lock.');
  let alive=true;try{process.kill(pid,0);}catch(e){if(e.code==='ESRCH')alive=false;else throw e;}
  if(alive){console.log('Another catalog update is running.');return;}fs.unlinkSync(lock);
 }
 const fd=fs.openSync(lock,'wx');fs.writeFileSync(fd,String(process.pid));
 try{await refresh({client,seeds,stateFile:path.join(root,'.local/optimization/automatic-state.json'),hours:Number(options['--hours']||4),destinations:[path.join(root,'addons/ForeverCoaching/Data/PublicReportCatalog.lua'),path.join(addon,'Data/PublicReportCatalog.lua')],onProgress:console.log});}
 finally{fs.closeSync(fd);fs.unlinkSync(lock);}
}
main().catch(e=>{console.error(e.message);process.exitCode=e.code==='WCL_REQUEST_BUDGET'?75:1;});
