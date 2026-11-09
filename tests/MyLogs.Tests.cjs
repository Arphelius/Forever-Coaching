const assert=require('assert/strict'),fs=require('fs'),path=require('path'),os=require('os');
const {csv,logParser}=require('../tools/local-combat-log.cjs');
const {writePersonalLog}=require('../tools/Import-MyCombatLogs.cjs');
const {toLua}=require('../tools/lua-data.cjs');
const f=require('../tools/preview-runtime/node_modules/fengari');
assert.deepEqual(csv('1,"quoted,name",[(1,2),(3,4)],last'),['1','quoted,name','[(1,2),(3,4)]','last']);
const guid='Player-1-OWNER',other='Player-1-OTHER',enemy='Creature-1-ENEMY';
const event=(type,source=guid,flags='0x511',tail=[])=>[type,source,'"Fixture"',flags,'0',enemy,'"Enemy"','0x10a48','0',...tail].join(',');
function sample(advanced){
 const parser=logParser(),line=(time,body)=>parser.consume('11/8/2026 15:00:'+String(time).padStart(2,'0')+'.0000  '+body);
 line(0,`COMBAT_LOG_VERSION,22,ADVANCED_LOG_ENABLED,${advanced?1:0}`);line(0,'ZONE_CHANGE,48,"Blackfathom Deeps",1');
 // Numeric COMBATANT_INFO payload must never identify another player as the owner.
 line(0,`COMBATANT_INFO,${other},0,3,5,7,9,11`);
 const fields=[...(advanced?Array(19).fill(0):[]),120,120,20,1,0,0,0];
 line(1,event('SPELL_DAMAGE',guid,'0x511',[403,'"Lightning Bolt"',8,...fields]));
 line(2,event('SPELL_DAMAGE',other,'0x512',[403,'"Lightning Bolt"',8,...fields]));
 line(3,event('SPELL_CAST_SUCCESS',guid,'0x511',[403,'"Lightning Bolt"',8]));
 line(5,'ENCOUNTER_START,99,"Fixture boss",1,5,48');
 line(6,event('SPELL_DAMAGE',guid,'0x511',[403,'"Lightning Bolt"',8,...fields]));
 line(7,event('SWING_DAMAGE',guid,'0x511',fields));line(7,event('SWING_DAMAGE_LANDED',guid,'0x511',fields));
 line(8,event('SPELL_HEAL',guid,'0x511',[331,'"Healing Wave"',8,...(advanced?Array(19).fill(0):[]),200,200,50,0]));
 line(9,event('SPELL_CAST_SUCCESS',guid,'0x511',[403,'"Lightning Bolt"',8]));
 line(10,'ENCOUNTER_END,99,"Fixture boss",1,5,1,5000');
 line(12,event('SPELL_DAMAGE',guid,'0x511',[403,'"Lightning Bolt"',8,...fields]));
 line(14,event('SPELL_DAMAGE',guid,'0x511',[403,'"Lightning Bolt"',8,...fields]));
 line(20,'ZONE_CHANGE,0,"Wetlands",0');return parser.finish();
}
for(const advanced of [false,true]){
 const data=sample(advanced);assert.equal(data.malformedDamageEvents,0);assert.equal(data.fights.length,2,'One combined trash entry and one boss');
 assert(data.fights.every(v=>v.guid===guid),'Never import other group members');
 const boss=data.fights.find(v=>v.kind==='boss'),trash=data.fights.find(v=>v.kind==='trash');
 assert.equal(boss.damage.reduce((n,s)=>n+s.amount,0),200,'Exclude overkill and duplicate SWING_DAMAGE_LANDED');assert.equal(boss.healing,150);assert(boss.kill);assert.equal(boss.duration,5);
 assert.equal(trash.damage.reduce((n,s)=>n+s.amount,0),300,'Trash excludes boss damage and other players');assert.equal(trash.duration,4,'Separate trash intervals exclude boss and downtime');
}
assert.throws(()=>logParser().consume('11/8/2026 15:00:00.000  COMBAT_LOG_VERSION,21,ADVANCED_LOG_ENABLED,1'),/not supported/);
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'my-logs-'));
try{const file=path.join(tmp,'private.lua');fs.writeFileSync(file,'keep');assert.throws(()=>writePersonalLog({fights:[]},file));assert.equal(fs.readFileSync(file,'utf8'),'keep');assert.throws(()=>writePersonalLog({fights:[{}],malformedDamageEvents:1},file));assert.equal(fs.readFileSync(file,'utf8'),'keep');writePersonalLog(sample(true),file);assert(fs.readFileSync(file,'utf8').includes('PersonalCombatLog'));}finally{fs.rmSync(tmp,{recursive:true,force:true});}
const L=f.lauxlib.luaL_newstate();f.lualib.luaL_openlibs(L);
function run(source){if(f.lauxlib.luaL_dostring(L,f.to_luastring(source)))throw Error(f.to_jsstring(f.lua.lua_tostring(L,-1)));}
run(fs.readFileSync('tests/CombatReviewHarness.lua','utf8'));run('unpack=unpack or table.unpack;ForeverCoaching={}');
for(const file of ['Data/SupportedDungeons.lua','Core/MyLogs.lua','UI/GuideSelectors.lua','UI/ClassicTheme.lua','UI/MyLogs.lua'])run(fs.readFileSync('addons/ForeverCoaching/'+file,'utf8'));
run(`
local fc=ForeverCoaching
local cases={{'DRUID','Guardian','tank'},{'HUNTER','Beast Mastery','dps'},{'MAGE','Fire','dps'},{'PALADIN','Holy','healer'},{'PRIEST','Discipline','healer'},{'ROGUE','Combat','dps'},{'SHAMAN','Enhancement','dps'},{'WARLOCK','Demonology','dps'},{'WARRIOR','Protection','tank'}}
for _,case in ipairs(cases)do
 local class,spec,role=unpack(case);UnitClass=function()return class,class end
 ForeverCoachingDB={};fc.ForeverSpellCatalog={classes={[class]={spells={['Fixture class ability']={}}}}}
 local fight={id='1',guid='target-fixture',dungeonKey='blackfathom-deeps',kind='boss',name='Fixture boss',difficulty=1,started=1,duration=60,kill=true,deaths=0,healing=1200,damage={{spellID=1,name='Fixture class ability',amount=6000}},casts={{spellID=1,name='Fixture class ability',count=2}}}
 fc.PersonalCombatLog={schema=1,fights={fight,{id='alien',guid='other-character',duration=60,difficulty=1,damage={},casts={}}}}
 local peer={specKey=class..':fixture',spec=spec,class=class,dungeonKey='blackfathom-deeps',difficulty=10,role=role,complete=true,kill=true,rankingScope='dungeon',performance=200,rotations={{kind='boss',name='Fixture boss',fullSequence=true,complete=true,kill=true,start=0,['end']=60,damage={{amount=12000}},steps={{name='Fixture class ability',count=10}}}}}
 fc.WarcraftLogs={PublicExamples=function()return {peer}end,GetPublicReportModel=function()return {selectedSpec=class..':fixture'}end,GetLogging=function()return false end}
 local model=fc.MyLogs:GetModel();assert(#model.fights==1 and model.reference==peer and model.difficultyNotice:find('cannot be verified',1,true),'Match character/spec/encounter and disclose the separate difficulty namespaces')
 assert(model.review:find('2.0 uses/min',1,true) and model.next:find('Fixture class ability',1,true),'Coaching must explain measured cast-frequency differences')
 assert(model.yourOutput:find('100 DPS',1,true) and model.referenceOutput:find('200 DPS',1,true))
 assert(model.message:find('does not verify',1,true),'Selected spec must not be presented as recorded fact')
 fight.character='Fixture-Normal-EU';peer.player='Fixture';assert(fc.MyLogs:GetModel().missing,'Skip a reference identifiable as the same character');fight.character=nil;peer.player=nil
 fc.MyLogs:SetRole(role=='tank' and 'healer' or 'tank');assert(fc.MyLogs:GetModel().missing,'Reference must match the selected role');fc.MyLogs:SetRole(role)
 peer.difficulty=2;assert(fc.MyLogs:GetModel().missing,'Reject unrelated ranking difficulties');peer.difficulty=10;fight.difficulty=2;assert(fc.MyLogs:GetModel().missing,'Do not substitute a heroic client run');fight.difficulty=1
 peer.rotations[1].name='Other boss';assert(fc.MyLogs:GetModel().missing,'Never substitute a different boss');peer.rotations[1].name='Fixture boss'
 fight.kill=false;assert(fc.MyLogs:GetModel().missing,'Unfinished encounters are not compared to full clears');fight.kill=true
 fight.casts[1].count=10;assert(fc.MyLogs:GetModel().good:find('similar or higher',1,true),'Report a measured positive habit')
 local parent=CreateFrame('Frame');parent:SetSize(800,440);parent:Show();local view=fc:BuildMyLogsPage(parent);assert(view.document and view.fightPicker and view.specPicker and view.importButton)
 view.importButton.scripts.OnClick();assert(view.importGuide,'Import setup is available from a single button')
end
fc.PersonalCombatLog={};assert(not fc.MyLogs:GetModel().ready,'Clear personal data on characters without a matching import')
`);
f.lua.lua_close(L);
console.log('PASS: local version-22 standard/advanced combat parsing, owner isolation, overkill/duplicate prevention, boss/trash segmentation, effective healing, safe delivery, nine-class comparisons, context/spec disclosure, coaching and real My Logs UI. Synthetic fixtures only.');
