const {reportCode}=require('./warcraftlogs-client.cjs');
const {resolveDungeon}=require('./forever-dungeons.cjs');
async function scanReports(client,seeds,{discover=true,maxReports=500,maxPages=100,zoneIDs=[]}={}){
 if(!Number.isSafeInteger(maxReports)||maxReports<1||maxReports>5000||!Number.isSafeInteger(maxPages)||maxPages<1||maxPages>1000)throw Error('Invalid public report scan limits.');
 const queue=[...new Set(seeds.map(reportCode))],seen=new Set(queue),reports=[],scopes=[],scopeKeys=new Set(),notes=[];
 for(const zoneID of zoneIDs){if(!Number.isSafeInteger(zoneID)||zoneID<=0)throw Error('Invalid public report zone.');const key='zone:'+zoneID;if(!scopeKeys.has(key)){scopeKeys.add(key);scopes.push({gameZone:null,zoneID});}}
 let cursor=0,pages=0,incomplete=false;
 async function loadQueued(){
  while(cursor<queue.length&&cursor<maxReports){
   const code=queue[cursor++];
   try{
    const report=await client.report(code);reports.push(report);
    for(const fight of report.fights){const dungeon=resolveDungeon(fight.gameZone?.name,fight.name);if(!dungeon||!Number.isSafeInteger(fight.gameZone?.id)||!Number.isSafeInteger(report.zone?.id))continue;
     const key=fight.gameZone.id+':'+report.zone.id+':'+report.masterData.gameVersion;
     if(!scopeKeys.has(key)){scopeKeys.add(key);scopes.push({gameZone: fight.gameZone.id,zoneID:report.zone.id});}
    }
   }catch(error){incomplete=true;notes.push(`${code}: ${error.message}`);}
  }
 }
 await loadQueued();
 if(discover&&typeof client.instanceReports==='function'){
  for(const scope of scopes){
   const returned=new Set();
   try{
    for(let page=1;page<=maxPages;page++){
     const batch=await client.instanceReports(scope.gameZone,page,{zoneID:scope.zoneID});pages++;
     let added=0;
     for(const code of batch.codes){if(!returned.has(code)){returned.add(code);added++;}if(!seen.has(code)){seen.add(code);queue.push(code);}}
     await loadQueued();
     if(!batch.hasMore)break;
     if(added===0){incomplete=true;notes.push('Instance discovery repeated a page; scanning stopped for that scope.');break;}
     if(page===maxPages||cursor>=maxReports){incomplete=true;notes.push('Public report discovery reached a configured limit; coverage is incomplete.');break;}
    }
   }catch(error){incomplete=true;notes.push('Instance discovery unavailable: '+error.message);}
   if(cursor>=maxReports)break;
  }
 }else if(discover){incomplete=true;notes.push('Instance discovery is unavailable; only supplied reports were examined.');}
 if(queue.length>cursor){incomplete=true;notes.push('Some discovered reports were not examined because the report limit was reached.');}
 return {reports,notes:[...new Set(notes)],scan:{reports:reports.length,reportsAttempted:cursor,discoveryPages:pages,incomplete,publicApiOnly:true}};
}
module.exports={scanReports};
