$ErrorActionPreference='Stop'
$repo='C:\Users\satok\NetHackJP'
$currPath=Join-Path $repo 'dat/quest.lua'
$currLines=Get-Content -Path $currPath
$headText=git -C $repo show HEAD:dat/quest.lua | Out-String
$headLines=$headText -split "`r?`n"
function Get-BlockTokens($lines){
  $role='';$key='';$inRole=$false;$inKey=$false;$map=@{}
  for($i=0;$i -lt $lines.Count;$i++){
    $line=$lines[$i]
    if($line -match '^\s{3}([A-Za-z]+)\s*=\s*\{$'){ $role=$matches[1];$inRole=$true;$inKey=$false;$key=''; continue }
    if($inRole -and $line -match '^\s{6}([A-Za-z_]+)\s*=\s*\{$'){ $key=$matches[1];$inKey=$true; $id="$role/$key"; if(-not $map.ContainsKey($id)){ $map[$id]=[ordered]@{Tokens=@();FirstLine=$i+1} }; continue }
    if($inKey -and $line -match '^\s{6}\},\s*$'){ $inKey=$false;$key=''; continue }
    if($inRole -and -not $inKey -and $line -match '^\s{3}\},\s*$'){ $inRole=$false;$role=''; continue }
    if($inRole -and $inKey){ $id="$role/$key"; $t=[regex]::Matches($line,'%[A-Za-z]+')|% Value; if($t.Count -gt 0){ $map[$id].Tokens += $t } }
  }
  return $map
}
function CountMap($arr){ $h=@{}; foreach($t in $arr){ if($h.ContainsKey($t)){$h[$t]++} else {$h[$t]=1} }; return $h }
$curr=Get-BlockTokens $currLines
$head=Get-BlockTokens $headLines
$issues=@()
foreach($id in $head.Keys){
  if(-not $curr.ContainsKey($id)){ continue }
  $h=CountMap $head[$id].Tokens
  $c=CountMap $curr[$id].Tokens
  $missing=@()
  foreach($tk in $h.Keys){ $hc=$h[$tk]; $cc=0; if($c.ContainsKey($tk)){$cc=$c[$tk]}; if($hc -gt $cc){ $missing += ("$tk x"+($hc-$cc)) } }
  if($missing.Count -gt 0){ $issues += [pscustomobject]@{Id=$id;Line=$curr[$id].FirstLine;Missing=($missing -join ', ')} }
}
$issues=$issues|Sort-Object Line
$out=@()
$out += "MISSING_BLOCKS=$($issues.Count)"
$out += ($issues | % { "L$($_.Line) $($_.Id) :: missing $($_.Missing)" })
$out | Set-Content -Path (Join-Path $repo 'tmp_placeholder_diff.txt') -Encoding UTF8
Write-Output "WROTE tmp_placeholder_diff.txt with $($issues.Count) issue blocks"
