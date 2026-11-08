const fs=require('fs'),path=require('path');
const {reportCode}=require('./warcraftlogs-client.cjs');
function extractReportCodes(html){
 const codes=new Set();
 for(const match of html.matchAll(/\bhref\s*=\s*["']([^"']+)["']/gi)){
  const href=match[1].replace(/&amp;/g,'&');
  try{const url=new URL(href,'https://forever.warcraftlogs.com');codes.add(reportCode(url.href));}catch{}
 }
 return [...codes];
}
function readReportPages(location){
 const codes=new Set();let pages=0;
 function visit(file){
  const stat=fs.lstatSync(file);if(stat.isSymbolicLink())return;
  if(stat.isDirectory()){for(const name of fs.readdirSync(file))if(!name.endsWith('_files'))visit(path.join(file,name));return;}
  if(!/\.html?$/i.test(file))return;
  if(stat.size>32*1024*1024)throw Error('Saved report page is too large.');
  pages++;for(const code of extractReportCodes(fs.readFileSync(file,'utf8')))codes.add(code);
 }
 visit(location);
 if(!codes.size)throw Error('No Forever report links were found in the saved HTML pages.');
 return {codes:[...codes],pages};
}
module.exports={extractReportCodes,readReportPages};
