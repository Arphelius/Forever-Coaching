window.CustomTalentBuilds=(()=>{
 let active=false,hooks,latest,busy=false,deleteArmed=false;
 const drafts={},ids={};let pending;
 const key='fc-custom-builds-v1';let saved=[];
 try{const value=JSON.parse(localStorage.getItem(key)||'[]');if(Array.isArray(value))saved=value;}catch{}
 const cls=()=>hooks.$('class').value;
 const fresh=className=>({class:className,name:'My custom build',role:'damage',ranks:{},order:[]});
 const draft=()=>drafts[cls()]||(drafts[cls()]=fresh(cls()));
 const el=(tag,text)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;return n;};
 const button=(label,click)=>{const b=el('button',label);b.type='button';b.disabled=busy;b.onclick=()=>{if(!busy)return click();};return b;};
 const store=()=>{try{localStorage.setItem(key,JSON.stringify(saved));return true;}catch{hooks.$('custom-status').textContent='Could not save this build. Browser storage is unavailable.';return false;}};
 function status(text){hooks.$('custom-status').textContent=text;}
 async function update(){busy=true;try{await hooks.refresh();}finally{busy=false;if(active&&hooks.getState())render(hooks.getState());}}
 function render(state){
  if(!active||state.custom?.draft.class!==cls())return;
  const custom=state.custom;if(custom){latest=custom;drafts[cls()]={...custom.draft,order:Array.isArray(custom.draft.order)?custom.draft.order:[],ranks:custom.draft.ranks||{}};pending=null;}
  const host=hooks.$('custom-controls');host.hidden=false;host.replaceChildren();
  host.append(el('p','Left-click to add a point; right-click to remove it. Your click order becomes the leveling order.'));
  const form=el('div');form.className='custom-build-actions';
  const nameLabel=el('label','Build name'),name=el('input');name.type='text';name.maxLength=60;name.value=draft().name;name.dataset.noTranslate='';name.oninput=()=>draft().name=name.value;nameLabel.append(name);form.append(nameLabel);
  const roleLabel=el('label','Role'),role=el('select');for(const value of custom?.roles||['damage'])role.add(new Option(value,value));role.value=draft().role;role.onchange=()=>{draft().role=role.value;update();};roleLabel.append(role);form.append(roleLabel);
  form.append(button('New build',()=>{drafts[cls()]=fresh(cls());delete ids[cls()];deleteArmed=false;return update();}));
  form.append(button('Save custom build',async()=>{
   const savingClass=cls();await update();if(cls()!==savingClass)return;if(!latest?.valid){status(latest?.error||'Add at least one talent point before saving.');return;}
   const id=ids[cls()]||('browser-custom-'+Date.now());const entry={id,draft:JSON.parse(JSON.stringify(draft()))};
   const index=saved.findIndex(b=>b.id===id);if(index<0&&saved.filter(b=>b.draft?.class===cls()).length>=50){status('Custom build limit reached for this class.');return;}
   const previous=saved.slice();if(index<0)saved.push(entry);else saved[index]=entry;
   if(store()){ids[cls()]=id;render(hooks.getState());status('Custom build saved.')}else saved=previous;
  }));
  form.append(button('Reset points',()=>{draft().ranks={};draft().order=[];update();}));
  const remove=button('Delete build',()=>{
   if(!ids[cls()])return;if(!deleteArmed){deleteArmed=true;status('Press Delete build again to confirm.');return;}
   const previous=saved;saved=saved.filter(b=>b.id!==ids[cls()]);if(!store()){saved=previous;return;}
   delete ids[cls()];drafts[cls()]=fresh(cls());deleteArmed=false;return update();
  });remove.disabled=!ids[cls()]||busy;form.append(remove);host.append(form);
  const message=el('p',custom?.error||'Saved in this browser. In-game custom builds are saved separately by the addon.');message.id='custom-status';host.append(message);
  hooks.$('stats').textContent=`${custom?.points||0} / 51 points`;
  hooks.$('summary').textContent='Choose talents for an experiment, save the build, and reopen it from Custom Builds.';
  hooks.$('source').hidden=true;hooks.$('learn').hidden=true;
  const library=hooks.$('builds');library.replaceChildren();
  for(const entry of saved.filter(b=>b.draft?.class===cls())){
   const b=button(entry.draft.name,()=>{drafts[cls()]=JSON.parse(JSON.stringify(entry.draft));ids[cls()]=entry.id;deleteArmed=false;return update();});b.dataset.noTranslate='';library.append(b);
  }
  if(!library.children.length)library.append(el('p','No custom builds saved for this class.'));
 }
 return {
  init(value){hooks=value;const tabs=el('div');tabs.className='custom-build-actions';
   tabs.append(button('Published builds',()=>{active=false;hooks.$('custom-controls').hidden=true;hooks.$('learn').hidden=false;hooks.refresh();}),button('Custom Builds',()=>{active=true;return update();}));
   const host=el('div');host.id='custom-controls';host.hidden=true;const article=document.querySelector('main>article');article.prepend(tabs,host);
  },
  isActive:()=>active,
  request(){return active?{draft:draft(),change:pending?.class===cls()?pending:null}:null;},
  render,
  async change(treeIndex,talentIndex,delta){if(busy)return;pending={class:cls(),treeIndex,talentIndex,delta};deleteArmed=false;await update();},
 };
})();
