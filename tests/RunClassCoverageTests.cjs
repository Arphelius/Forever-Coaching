const {spawnSync}=require('child_process');
const suites=[
 'ClassSpecRotationMatrix.Tests.cjs','ClassBuffUpkeep.Tests.cjs','BuffAuraLifecycle.Tests.cjs',
 'BuildRecommendations.Tests.cjs','EnhancementVFX.Tests.cjs',
 'RunTalentArtPreviewTests.cjs','RunLiveRotationTests.cjs',
 'ProfessionItems.Tests.cjs','ShieldUpkeep.Tests.cjs','UtilityRotation.Tests.cjs',
 'GroupThreatWarnings.Tests.cjs','WarningToast.Tests.cjs',
];
for(const suite of suites){
 const result=spawnSync(process.execPath,[`tests/${suite}`],{stdio:'inherit'});
 if(result.error)throw result.error;
 if(result.status!==0)process.exit(result.status||1);
}
console.log('PASS: shared class/spec coverage audit. Live-client visual and gameplay validation remains separate.');
