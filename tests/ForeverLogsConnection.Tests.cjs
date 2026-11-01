const assert=require('assert/strict');
const {Readable}=require('stream');
const {createClient}=require('../tools/foreverlogs-review.cjs');
const {createBridge}=require('../tools/foreverlogs-bridge.cjs');
async function main(){
 const calls=[];
 const client=createClient('private-fixture',async(url,key)=>{assert.equal(key,'private-fixture');calls.push(url);return {reports:[{id:42,title:'Processed report'}]};});
 assert(client.configured());assert(!client.connected(),'A configured key is not verified until an authenticated request succeeds');
 await assert.rejects(client.listReports(),/Connect/);
 const bridge=createBridge('.',client);
 let ownerToken=null;
 async function request(body,expected=200){const req=Readable.from(body?[Buffer.from(JSON.stringify(body))]:[]);req.method=body?'POST':'GET';req.headers={host:'127.0.0.1:4317',origin:'http://127.0.0.1:4317','content-type':'application/json',...(ownerToken?{'x-forever-owner-token':ownerToken}:{})};req.socket={remoteAddress:'127.0.0.1'};let code,data;await bridge(req,{writeHead(v){code=v;},end(v){data=JSON.parse(v);}});assert.equal(code,expected);assert(!JSON.stringify(data).includes('private-fixture'));return data;}
 let status=await request();assert(status.configured&&!status.connected);assert.equal(status.mode,'aggregate-statistics');assert(!status.ownerToken);
 for(const action of ['reports','report','actors','review','import','disconnect'])await request({action},403);
 await request({action:'connect'},400);
 await request({action:'connect',key:'different-owner-key'},400);
 ownerToken=(await request({action:'connect',key:'private-fixture'})).ownerToken;assert(ownerToken);assert(client.connected());
 const page=await request({action:'reports',offset:40});assert.equal(page.reports[0].id,42);assert(calls.includes('/reports?limit=20&offset=40'));
 const oldToken=ownerToken;await request({action:'lockOwner'});await request({action:'reports'},403);assert(client.configured(),'Locking owner tools should leave player service configured');
 ownerToken=(await request({action:'connect',key:'private-fixture'})).ownerToken;assert.notEqual(ownerToken,oldToken);
 await assert.rejects(client.listReports(-1),/Invalid/);
 await request({action:'disconnect'});status=await request();assert(!status.configured&&!status.connected);
 const denied=createClient('rejected-fixture',async()=>{throw Error('The API key was rejected.');});await assert.rejects(denied.connect(),/rejected/);assert(!denied.connected());
 console.log('PASS: configured versus verified credentials, key-free status, report pagination, denied keys and disconnect.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
