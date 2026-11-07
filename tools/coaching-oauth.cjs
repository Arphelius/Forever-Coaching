const {randomBytes,createHash}=require('crypto');
const {createClient}=require('./warcraftlogs-client.cjs');
const TOKEN_URL='https://www.warcraftlogs.com/oauth/token';
function createLogin({clientId,redirectURI,fetcher=fetch,now=Date.now,clientFactory=createClient}){
 let pending=null,tokens=null,client=null,refreshing=null,generation=0;
 async function exchange(fields){
  const response=await fetcher(TOKEN_URL,{method:'POST',redirect:'error',signal:AbortSignal.timeout(30000),headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({client_id:clientId,...fields}).toString()});
  if(!response.ok)throw Error('Warcraft Logs sign-in did not complete. Please try again.');
  const data=await response.json();
  if(typeof data.access_token!=='string'||!data.access_token||!Number.isFinite(Number(data.expires_in))||Number(data.expires_in)<=0)throw Error('Warcraft Logs returned an incomplete sign-in.');
  return {access:data.access_token,refresh:typeof data.refresh_token==='string'?data.refresh_token:null,expires:now()+Number(data.expires_in)*1000};
 }
 async function access(){
  if(!tokens)throw Error('Sign in to Warcraft Logs first.');
  if(now()<tokens.expires-30000)return tokens.access;
  if(!tokens.refresh)throw Error('Your connection expired. Sign in again.');
  if(!refreshing){const previous=tokens,version=generation;refreshing=exchange({grant_type:'refresh_token',refresh_token:previous.refresh}).then(next=>{
   if(version!==generation)throw Error('Connection closed.');
   tokens={...next,refresh:next.refresh||previous.refresh};return tokens.access;
  }).finally(()=>{refreshing=null;});}
  return refreshing;
 }
 return {
  configured:()=>typeof clientId==='string'&&!!clientId.trim(),
  connected:()=>!!tokens,
  begin(){
   if(typeof clientId!=='string'||!clientId.trim())throw Error('The addon publisher needs to enable Warcraft Logs sign-in for this helper.');
   const verifier=randomBytes(48).toString('base64url'),state=randomBytes(32).toString('base64url');
   pending={verifier,state,expires:now()+10*60000};
   const url=new URL('https://www.warcraftlogs.com/oauth/authorize');
   for(const [key,value] of Object.entries({client_id:clientId,redirect_uri:redirectURI,response_type:'code',state,code_challenge:createHash('sha256').update(verifier).digest('base64url'),code_challenge_method:'S256',scope:'view-user-profile view-private-reports'}))url.searchParams.set(key,value);
   return url.href;
  },
  async finish({state,code,error}){
   const request=pending;pending=null;
   if(!request||request.expires<now()||state!==request.state)throw Error('This sign-in expired or belongs to another window. Start sign-in again.');
   if(error||typeof code!=='string'||!code||code.length>4096)throw Error('Sign-in was cancelled. You can try again.');
   const version=++generation;
   const next=await exchange({grant_type:'authorization_code',redirect_uri:redirectURI,code,code_verifier:request.verifier});
   if(version!==generation)throw Error('Connection closed.');
   tokens=next;client=clientFactory({api:'user',getAccessToken:access,fetcher});
   try{return await client.currentUser();}catch(error){tokens=null;client=null;throw error;}
  },
  client(){if(!client)throw Error('Sign in to Warcraft Logs first.');return client;},
  disconnect(){generation++;pending=null;tokens=null;client=null;},
 };
}
module.exports={createLogin};
