# Rebuild the pinned factual talent allocations. The preset strings and scenario
# were checked against MythicSim's public race-board baseline requests.
$ErrorActionPreference = 'Stop'
$commit = 'a667dce8492bd9fb94269a9f864289cb74006775'
$presets = Get-Content (Join-Path $PSScriptRoot '../docs/research/mythicsim-catalog.json') -Raw | ConvertFrom-Json
$healers = Get-Content (Join-Path $PSScriptRoot '../docs/research/healer-catalog.json') -Raw | ConvertFrom-Json
$additionalPath=Join-Path $PSScriptRoot '../docs/research/additional-guide-builds.json'
if(Test-Path $additionalPath){$healers+=Get-Content $additionalPath -Raw -Encoding UTF8 | ConvertFrom-Json}
$templatesPath=Join-Path $PSScriptRoot '../docs/research/published-build-templates.json'
if(Test-Path $templatesPath){$healers+=Get-Content $templatesPath -Raw -Encoding UTF8 | ConvertFrom-Json}
$levelingPath=Join-Path $PSScriptRoot '../docs/research/mobalytics-leveling-builds.json'
if(Test-Path $levelingPath){$healers+=Get-Content $levelingPath -Raw -Encoding UTF8 | ConvertFrom-Json}
$auditPath=Join-Path $PSScriptRoot '../docs/research/mobalytics-audit-builds.json'
if(Test-Path $auditPath){$healers+=Get-Content $auditPath -Raw -Encoding UTF8 | ConvertFrom-Json}
foreach ($preset in $presets) {
    if ($preset.Engine -ne $commit) {throw 'A preset uses a different engine. Fetch its matching talent layout before importing.'}
}
$layouts = @{}
$cachePath=Join-Path $PSScriptRoot ('../docs/research/talent-layouts-'+$commit+'.json')
$cached=if(Test-Path $cachePath){Get-Content $cachePath -Raw -Encoding UTF8 | ConvertFrom-Json}else{$null}
foreach ($class in @('druid','hunter','mage','paladin','priest','rogue','shaman','warlock','warrior')) {
    if($cached -and $cached.PSObject.Properties[$class]){$layouts[$class]=$cached.$class;continue}
    $url = "https://api.github.com/repos/sage3648/mythicsim-forever-engine-go/contents/ui/sim/talents/trees/$class.json?ref=$commit"
    $file = Invoke-RestMethod $url -TimeoutSec 30
    $layouts[$class] = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($file.content)) | ConvertFrom-Json
}
if(-not $cached){[IO.File]::WriteAllText($cachePath,($layouts | ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))}
foreach ($guide in $healers) {
    if($guide.Level -eq 60 -and $guide.Fit -eq 'pvp' -and $guide.Evidence -eq 'theorycraft') {
        $guide.Evidence='experimental'
        if($guide.Title -notmatch '\(Experimental\)'){$guide.Title+=' (Experimental)'}
    }
    $trees=$layouts[$guide.Slug]
    $codes=@();$totals=@()
    foreach ($tree in $trees) {
        $code='';$total=0
        foreach ($talent in $tree.talents) {
            $property=$guide.Ranks.PSObject.Properties[$talent.fancyName]
            $rank=if($property){[int]$property.Value}else{0}
            if($rank -gt $talent.maxPoints){throw ('Invalid guide rank: '+$talent.fancyName)}
            $code+=[string]$rank;$total+=$rank
        }
        $codes+=$code.TrimEnd('0');$totals+=$total
    }
    foreach($property in $guide.Ranks.PSObject.Properties) {
        if(-not ($trees.talents | Where-Object {$_.fancyName -eq $property.Name})) {throw ('Unknown guide talent: '+$property.Name)}
    }
    if (($totals | Measure-Object -Sum).Sum -ne $guide.Points) {throw ('Wrong guide point count: '+$guide.Title)}
    $presets+= [pscustomobject]@{Class=$guide.Class;Slug=$guide.Slug;Spec=$guide.Id;Title=$guide.Title;Code=($codes -join '-');Totals=$totals;Engine=$commit;Generated=$guide.Updated;URL=$guide.URL;Role=$guide.Role;BoardRank=0;BoardGroup='';Duration=0;Variation=0;TargetLevel=0;Targets=0;Source=$guide.Source;Level=$guide.Level;Evidence=$guide.Evidence;Note=$guide.Note;Fit=$guide.Fit;Points=$guide.Points;Activities=$guide.Activities}
}
$tournamentPath=Join-Path $PSScriptRoot '../docs/research/forever-open-builds.json'
if(Test-Path $tournamentPath) {
    $tournament=Get-Content $tournamentPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($record in $tournament) {
        $trees=@();$totals=@();$codes=$record.Code.Split('_')
        foreach($tree in $record.Layout.Trees | Sort-Object Ordinal) {
            $talents=@();$total=0
            foreach($talent in $tree.Nodes | Sort-Object Index) {
                $talents+=[pscustomobject]@{fancyName=$talent.Name;maxPoints=$talent.MaxRank;spellId=$talent.SpellId;location=[pscustomobject]@{rowIdx=$talent.Row;colIdx=$talent.Col}}
                if($talent.Index -lt $codes[$tree.Ordinal].Length){$total+=[int]::Parse($codes[$tree.Ordinal].Substring($talent.Index,1))}
            }
            $trees+=[pscustomobject]@{name=$tree.Name;talents=$talents};$totals+=$total
        }
        $name=$record.Player -replace ' Foreverpvp$',''
        $presets+=[pscustomobject]@{Class=(Get-Culture).TextInfo.ToTitleCase($record.Class);Slug=$record.Class;Spec=('forever-open-finals-'+$record.TeamId);Title=($name+' / Finals');Code=($record.Code.Replace('_','-'));Totals=$totals;Engine='';Generated=$record.EventDate;URL=$record.Profile;Role='damage';BoardRank=0;BoardGroup='';Duration=0;Variation=0;TargetLevel=0;Targets=0;Source='Raider.IO / Forever Open';Level=30;Evidence='tournament';Note='Level 30 duel submission; requires 5 extra talent points. Matchups and event rules matter.';Fit='pvp_duels';Points=$record.Points;ArchivedLayout=$trees;Calculator=$record.Calculator;RawCode=$record.Code;Revision=$record.Revision;Player=$record.Player;Stage=$record.Stage;EventDate=$record.EventDate;LegacyPoints=($record.Points-21);SeriesWins=$record.SeriesWins;SeriesLosses=$record.SeriesLosses}
    }
}
function Quote-Lua([string]$value) { return '"' + $value.Replace('\','\\').Replace('"','\"') + '"' }
# Keep other research snapshots on disk, but publish recommendations only from
# the user's preferred sources. Decoder/layout hosts are not guide sources.
$preferredHosts=@('mythicsim.com','wowhead.com','mobalytics.gg','raider.io','foreverlogs.gg')
$presets=@($presets | Where-Object {
    $sourceUri=$null
    if([Uri]::TryCreate([string]$_.URL,[UriKind]::Absolute,[ref]$sourceUri)) {
        $hostName=$sourceUri.DnsSafeHost.ToLowerInvariant() -replace '^www\.',''
        $sourceUri.Scheme -eq 'https' -and $hostName -in $preferredHosts
    } else {$false}
})
$lines = [Collections.Generic.List[string]]::new()
$lines.Add('-- MythicSim baseline snapshots; generated by tools/Import-MythicSimBuilds.ps1.')
$lines.Add('-- Talent strings describe final allocations, not a leveling order.')
$lines.Add('ForeverCoaching = ForeverCoaching or {}')
$lines.Add('ForeverCoaching.Builds = { game="WoW Forever", contentType="Sourced catalog", classes={')
foreach ($class in @('Druid','Hunter','Mage','Paladin','Priest','Rogue','Shaman','Warlock','Warrior')) {
    $lines.Add('    '+$class+'={ variants={')
    foreach ($preset in $presets | Where-Object { $_.Class -eq $class }) {
        $trees = if($preset.ArchivedLayout){$preset.ArchivedLayout}else{$layouts[$preset.Slug]}
        $codes = $preset.Code.Split('-')
        $source=if($preset.Source){$preset.Source}else{'MythicSim'}
        $level=if($preset.Level){$preset.Level}else{60}
        $points=if($preset.Points -ne $null){$preset.Points}else{51}
        $evidence=if($preset.Evidence){$preset.Evidence}else{'simulation'}
        $lines.Add('        { kind="reference", id='+(Quote-Lua $preset.Spec)+', maxLevel='+$level+', points='+$points+', title='+ (Quote-Lua $preset.Title)+', specialization='+(Quote-Lua $preset.Title)+',')
        $lines.Add('          role='+(Quote-Lua $preset.Role)+', evidence='+(Quote-Lua $evidence)+', note='+(Quote-Lua $preset.Note)+', fit='+(Quote-Lua $preset.Fit)+', boardRank='+$preset.BoardRank+', boardGroup='+(Quote-Lua $preset.BoardGroup)+',')
        if($preset.Activities){$lines.Add('          activities={'+(($preset.Activities | ForEach-Object {Quote-Lua $_}) -join ',')+'},')}
        $lines.Add('          validationStatus='+(Quote-Lua $(if($evidence -eq 'simulation'){'sim_reference'}else{'awaiting_combat_comparison'}))+',')
        $lines.Add('          duration='+$preset.Duration+', variation='+$preset.Variation+', targetLevel='+$preset.TargetLevel+', targets='+$preset.Targets+',')
        $lines.Add('          talentString='+(Quote-Lua $preset.Code)+', distribution='+(Quote-Lua ($preset.Totals -join ' / '))+',')
        if($preset.ArchivedLayout) {
            if($null -ne $preset.SeriesWins){$lines.Add('          seriesWins='+$preset.SeriesWins+', seriesLosses='+$preset.SeriesLosses+',')}
            $lines.Add('          legacyPoints='+$preset.LegacyPoints+', player='+(Quote-Lua $preset.Player)+', event="The Forever Open", stage='+(Quote-Lua $preset.Stage)+', eventDate='+(Quote-Lua $preset.EventDate)+', originalCode='+(Quote-Lua $preset.RawCode)+',')
        } elseif($points -gt $level-9) {
            $lines.Add('          legacyPoints='+($points-($level-9))+',')
        }
        $snapshot=if($preset.ArchivedLayout){'calculator revision '+$preset.Revision}else{'70425 layout'}
        $lines.Add('          source={name='+(Quote-Lua $source)+', guideUpdated='+(Quote-Lua $preset.Generated.Substring(0,10))+', engine='+(Quote-Lua $preset.Engine)+', talentSnapshot='+(Quote-Lua $snapshot)+',')
        $comparison=if($preset.ArchivedLayout){'https://raider.io/events/the-forever-open/brackets/finals'}else{'https://mythicsim.com/wow-forever/tier-list'}
        $lines.Add('            url='+(Quote-Lua $preset.URL)+', comparisonUrl='+(Quote-Lua $comparison)+', calculatorUrl='+(Quote-Lua $preset.Calculator)+', revision='+(Quote-Lua $preset.Revision)+'},')
        if($preset.ArchivedLayout) {
            $lines.Add('          treeLayout={')
            foreach($tree in $trees) {
                $lines.Add('            {name='+(Quote-Lua $tree.name)+',nodes={')
                foreach($talent in $tree.talents) {
                    $lines.Add('              {name='+(Quote-Lua $talent.fancyName)+',spellId='+$talent.spellId+',maxRank='+$talent.maxPoints+',row='+$talent.location.rowIdx+',col='+$talent.location.colIdx+'},')
                }
                $lines.Add('            }},')
            }
            $lines.Add('          },')
        }
        $lines.Add('          talents={')
        for ($treeIndex=0; $treeIndex -lt $trees.Count; $treeIndex++) {
            $code = if ($treeIndex -lt $codes.Count) { $codes[$treeIndex] } else { '' }
            $total=0
            for ($index=0; $index -lt $code.Length; $index++) {
                $rank=[int]::Parse($code.Substring($index,1))
                if ($index -ge $trees[$treeIndex].talents.Count) { throw 'Talent index exceeds source layout' }
                $talent=$trees[$treeIndex].talents[$index]
                if ($rank -gt $talent.maxPoints) { throw 'Talent rank exceeds source maximum' }
                $total += $rank
                if ($rank -eq 0) { continue }
                $lines.Add('            {name='+(Quote-Lua $talent.fancyName)+', tree='+(Quote-Lua $trees[$treeIndex].name)+', treeIndex='+($treeIndex+1)+', talentIndex='+($index+1)+', rank='+$rank+', maxRank='+$talent.maxPoints+', tier='+($talent.location.rowIdx+1)+'},')
            }
            if ($total -ne $preset.Totals[$treeIndex]) { throw 'Allocation does not match published tree totals' }
        }
        $lines.Add('          } },')
    }
    $lines.Add('    } },')
}
$lines.Add('} }')
$lines.Add('ForeverCoaching.TalentTrees = {')
foreach ($class in @('druid','hunter','mage','paladin','priest','rogue','shaman','warlock','warrior')) {
    $lines.Add('  '+$class.ToUpper()+'={')
    foreach ($tree in $layouts[$class]) {
        $lines.Add('    {name='+(Quote-Lua $tree.name)+', nodes={')
        foreach ($talent in $tree.talents) {
            $lines.Add('      {name='+(Quote-Lua $talent.fancyName)+', spellId='+$talent.spellId+', maxRank='+$talent.maxPoints+', row='+$talent.location.rowIdx+', col='+$talent.location.colIdx+'},')
        }
        $lines.Add('    }},')
    }
    $lines.Add('  },')
}
$lines.Add('}')
$destination=Join-Path $PSScriptRoot '../addons/ForeverCoaching/Data/LevelingBuilds.lua'
[IO.File]::WriteAllText($destination,($lines -join "`n")+"`n",[Text.UTF8Encoding]::new($false))
Write-Output ('Imported '+$presets.Count+' sourced catalog entries with matching point totals.')
