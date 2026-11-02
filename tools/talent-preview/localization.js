// Translate only addon-owned text nodes. Form values, links and game names stay intact.
window.AddonI18n=(()=>{
 const languages=[['en','English'],['ro','Română'],['es','Español'],['fr','Français'],['de','Deutsch'],['pt','Português']];
 let language='en',names=[],entries=[],queued=false,selector;
 const original=new WeakMap(),last=new WeakMap(),attributes=new WeakMap();
 try{const saved=localStorage.getItem('fc-language');if(languages.some(([code])=>code===saved))language=saved;}catch{}
 const boundary=(s,a,b)=>(a===0||!/[A-Za-z0-9_]/.test(s[a-1]))&&(b===s.length||!/[A-Za-z0-9_]/.test(s[b]));
 function literal(s,key,value){let out='',offset=0;for(;;){const at=s.indexOf(key,offset);if(at<0)return out+s.slice(offset);out+=s.slice(offset,at)+(boundary(s,at,at+key.length)?value:key);offset=at+key.length;}}
 function mask(s){names.forEach((name,i)=>{if(s.includes(name))s=literal(s,name,'\u0003'+i+'\u0004');});return s;}
 function prepare(){entries=Object.entries(window.AddonLocaleMessages?.[language]||{}).map(([key,target])=>({key:mask(key),target})).filter(e=>!/^\u0003\d+\u0004$/.test(e.key)).sort((a,b)=>b.key.length-a.key.length);}
 function text(value){if(language==='en'||typeof value!=='string')return value;const tokens=[];const hold=s=>{tokens.push(s);return '\u0001'+(tokens.length-1)+'\u0002';};let s=mask(value.replace(/https?:\/\/\S+/g,hold));for(const {key,target}of entries)if(s.includes(key))s=literal(s,key,hold(target));return s.replace(/\u0001(\d+)\u0002/g,(_,i)=>tokens[+i]).replace(/\u0003(\d+)\u0004/g,(_,i)=>names[+i]);}
 function translate(){queued=false;document.documentElement.lang=language;const walker=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT);let node;while((node=walker.nextNode())){
  if(node.parentElement?.closest('script,style,textarea,input,[data-no-translate]'))continue;
  if(last.get(node)!==node.nodeValue)original.set(node,node.nodeValue);
  const source=original.get(node);if(source===undefined)continue;const translated=text(source);last.set(node,translated);if(translated!==node.nodeValue)node.nodeValue=translated;
 }
 for(const element of document.querySelectorAll?.('[placeholder],[title],[aria-label]')||[]){
  if(element.closest('[data-no-translate]'))continue;
  let record=attributes.get(element);if(!record){record={};attributes.set(element,record);}
  for(const key of ['placeholder','title','aria-label']){const value=element.getAttribute(key);if(value===null)continue;let entry=record[key];if(!entry||entry.last!==value)entry=record[key]={source:value};const translated=text(entry.source);entry.last=translated;if(value!==translated)element.setAttribute(key,translated);}
 }
 if(selector)selector.value=language;}
 function schedule(){if(!queued){queued=true;queueMicrotask(translate);}}
 function setProtectedNames(extra=[]){names=[...new Set(['Forever Coaching','Forever Logs','MythicSim','Mobalytics','SimGearForever','Druid','Hunter','Mage','Paladin','Priest','Rogue','Shaman','Warlock','Warrior',...extra])].filter(Boolean).sort((a,b)=>b.length-a.length);prepare();schedule();}
 function setLanguage(code){if(!languages.some(([key])=>key===code))return false;language=code;try{localStorage.setItem('fc-language',code);}catch{}prepare();schedule();return true;}
 function init(){const label=document.createElement('label'),caption=document.createTextNode('Language');selector=document.createElement('select');selector.setAttribute('aria-label','Language');selector.dataset.noTranslate='';for(const[code,name]of languages)selector.add(new Option(name,code));selector.value=language;selector.onchange=()=>setLanguage(selector.value);label.append(caption,selector);label.className='language-control';document.querySelector('header').append(label);new MutationObserver(schedule).observe(document.body,{childList:true,subtree:true,characterData:true,attributes:true,attributeFilter:['placeholder','title','aria-label']});setProtectedNames();}
 init();return {text,setLanguage,setProtectedNames,getLanguage:()=>language,languages};
})();
