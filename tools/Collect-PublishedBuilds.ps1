$ErrorActionPreference='Stop'
$commit='a667dce8492bd9fb94269a9f864289cb74006775'
$layouts=Get-Content (Join-Path $PSScriptRoot "../docs/research/talent-layouts-$commit.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$records=@();$issues=@()
function Plain([string]$value){return ([Net.WebUtility]::HtmlDecode(($value -replace '<[^>]+>',' ')) -replace '\s+',' ').Trim()}
foreach($class in @('druid','hunter','mage','paladin','priest','rogue','shaman','warlock','warrior')) {
    $index=(Invoke-WebRequest "https://damagemeters.com/forever/builds/$class" -UseBasicParsing -TimeoutSec 30).Content
    $paths=@([regex]::Matches($index,'href="(/forever/builds/'+$class+'/(?:60-pvp|\d+-leveling))"') | ForEach-Object {$_.Groups[1].Value} | Sort-Object -Unique)
    foreach($path in $paths) {
        $url='https://damagemeters.com'+$path
        $html=(Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 30).Content
        $section=[regex]::Match($html,'(?s)<section aria-labelledby="sheet-talents".*?</section>').Value
        $title=Plain ([regex]::Match($html,'(?s)<h1[^>]*>(.*?)</h1>').Groups[1].Value)
        $level=[int][regex]::Match($path,'/(\d+)-').Groups[1].Value
        $ranks=@{};$total=0;$errors=@()
        foreach($li in [regex]::Matches($section,'(?s)<li[^>]*>(.*?)</li>')) {
            $allocation=Plain $li.Groups[1].Value
            $match=[regex]::Match($allocation,'^(.+?)\s+(\d+)\s*/\s*(\d+)$')
            if(-not $match.Success){$errors+='Unrecognized talent row';continue}
            $name=$match.Groups[1].Value;$rank=[int]$match.Groups[2].Value
            $talent=$layouts.$class.talents | Where-Object {$_.fancyName -eq $name}
            if(-not $talent -or $rank -gt $talent.maxPoints){$errors+='Talent incompatible with pinned layout: '+$name}
            if($ranks.ContainsKey($name)){$errors+='Repeated talent: '+$name}
            $ranks[$name]=$rank;$total+=$rank
        }
        if($total -ne $level-9){$errors+='Published ranks spend '+$total+' points; expected '+($level-9)}
        foreach($tree in $layouts.$class) {
            foreach($talent in $tree.talents) {
                if(-not $ranks.ContainsKey($talent.fancyName)){continue}
                $earlier=0
                foreach($other in $tree.talents) {
                    if($other.location.rowIdx -lt $talent.location.rowIdx -and $ranks.ContainsKey($other.fancyName)){$earlier+=$ranks[$other.fancyName]}
                }
                if($earlier -lt $talent.location.rowIdx*5){$errors+='Insufficient earlier-tier points: '+$talent.fancyName}
            }
        }
        if($errors.Count -gt 0){$issues+=@{URL=$url;Issues=$errors};Write-Output ('Skipped inconsistent source: '+$path);continue}
        $pvp=$path.EndsWith('60-pvp')
        $records+=@{Class=(Get-Culture).TextInfo.ToTitleCase($class);Slug=$class;Id=('damagemeters-'+$class+'-'+($path.Split('/')[-1]));Title=($title+' (Experimental)');Source='DamageMeters / published template';URL=$url;Updated='2026-10-22';Level=$level;Points=$total;Role='damage';Evidence='experimental';Fit=if($pvp){'pvp'}else{'leveling'};Note=if($pvp){'Published level 60 PvP template; awaiting combat evidence.'}else{'Published leveling destination; no per-level order or performance ranking established.'};Ranks=$ranks}
        Write-Output ('Collected: '+$title)
    }
}
$directory=Join-Path $PSScriptRoot '../docs/research'
[IO.File]::WriteAllText((Join-Path $directory 'published-build-templates.json'),(ConvertTo-Json -InputObject @($records) -Depth 12),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $directory 'published-build-source-issues.json'),(ConvertTo-Json -InputObject @($issues) -Depth 12),[Text.UTF8Encoding]::new($false))
Write-Output ('Collected '+$records.Count+' complete templates; '+$issues.Count+' inconsistent sources excluded.')
