function parseCSV(text){
 const rows=[];let row=[],field='',quoted=false;
 for(let i=0;i<text.length;i++){
  const c=text[i];
  if(c==='"'){if(quoted&&text[i+1]==='"'){field+='"';i++;}else quoted=!quoted;}
  else if(c===','&&!quoted){row.push(field);field='';}
  else if(c==='\n'&&!quoted){row.push(field.replace(/\r$/,''));rows.push(row);row=[];field='';}
  else field+=c;
 }
 if(field||row.length){row.push(field.replace(/\r$/,''));rows.push(row);}
 const header=rows.shift();return rows.map(values=>Object.fromEntries(header.map((name,i)=>[name.replace(/^\uFEFF/,''),values[i]||''])));
}
module.exports={parseCSV};
