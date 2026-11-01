window.CombatReviewPage=(()=>{
 let host,data=null,busy=false,checked=false,status='';const pages=new Map();
 const colors={druid:'#ff7d0a',hunter:'#abd473',mage:'#69ccf0',paladin:'#f58cba',priest:'#eeeeee',rogue:'#fff569',shaman:'#398bea',warlock:'#b39ddb',warrior:'#c79c6e'};
 const el=(tag,text,cls)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n;};
 const button=(label,action)=>{const b=el('button',label);b.type='button';b.disabled=busy;b.onclick=action;return b;};
 async function load(){if(busy)return;busy=true;status='Loading rankings…';draw();try{const response=await fetch('/foreverlogs',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action:'rankingBoards'})});const result=await response.json();if(!response.ok)throw Error(result.error||'Rankings unavailable.');data=result;status=result.notice||'';}catch(error){status=error.message;}finally{busy=false;draw();}}
 function draw(){if(!host)return;host.replaceChildren();
  const header=el('div',undefined,'rankings-heading');header.append(el('div','CLASS PERFORMANCE','review-eyebrow'),el('h2','How each class performs'),el('p','Compare specializations across damage, healing and tank scenarios.'),button('Refresh rankings',load));host.append(header);
  if(status)host.append(el('p',status,'review-status'));
  const grid=el('div',undefined,'rankings-grid');
  for(const board of data?.boards||[]){
   const card=el('section',undefined,'ranking-board'),heading=el('div',undefined,'ranking-board-heading');heading.append(el('h3',board.title),el('span','MEDIAN '+board.unit));card.append(heading);
   const rows=el('ol',undefined,'ranking-board-rows');rows.setAttribute('aria-label',board.title+' rankings');
   const page=Math.min(pages.get(board.id)||0,Math.max(0,Math.ceil(board.rows.length/5)-1));
   for(const row of board.rows.slice(page*5,page*5+5)){
    const item=el('li',undefined,'ranking-row'),name=el('div',undefined,'ranking-name');
    name.append(el('strong',row.className),el('span',row.specName));name.title=row.className+' / '+row.specName;name.style.color=colors[row.className.toLowerCase()]||'#dae4ee';
    const value=el('div',undefined,'ranking-value');value.append(el('strong',row.value.toLocaleString(undefined,{maximumFractionDigits:0})),el('span',board.unit));
    item.append(el('span',String(row.rank),'ranking-position'),name,value);item.title=row.samples.toLocaleString()+' recorded samples';rows.append(item);
   }
   card.append(rows);
   if(!board.rows.length)card.append(el('p',board.note||'No recorded rankings available yet.','ranking-empty'));
   if(board.rows.length>5){const nav=el('div',undefined,'ranking-pagination');const previous=button('Previous',()=>{pages.set(board.id,page-1);draw();});previous.disabled=busy||page===0;const next=button('Next',()=>{pages.set(board.id,page+1);draw();});next.disabled=busy||(page+1)*5>=board.rows.length;nav.append(previous,el('span',`${page*5+1}–${Math.min(page*5+5,board.rows.length)} / ${board.rows.length}`),next);card.append(nav);}
   grid.append(card);
  }
  host.append(grid);
  if(data?.basis){const details=el('details');details.append(el('summary','About these rankings'),el('p',data.basis),el('p','Trash damage is a recorded content category, not a controlled multi-target simulation. Tank damage ranks damage output, not survivability. Rankings refresh from cached aggregate data, up to 30 minutes old.'));host.append(details);}
  const source=el('a','Data provided by Forever Logs');source.href='https://foreverlogs.gg/';source.target='_blank';source.rel='noopener noreferrer';host.append(source);
 }
 return {render(panel){host=panel;draw();if(!checked){checked=true;load();}}};
})();
