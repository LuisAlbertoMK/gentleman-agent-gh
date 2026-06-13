$SkillsDir = "$PSScriptRoot\..\..\skills"
. "$PSScriptRoot\graph-engine.ps1"

function fmt($t) {
    $ms = $t.TotalMilliseconds
    if ($ms -lt 1) { return "$([math]::Round($ms*1000,0))us" }
    if ($ms -lt 1000) { return "$([math]::Round($ms,1))ms" }
    return "$([math]::Round($ms/1000,2))s"
}

# ---- BUILD GRAPH ----
Write-Host "=== GRAPH BUILD ==="
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$g = New-Graph
$dirs = Get-ChildItem $SkillsDir -Directory | Where-Object { $_.Name -ne '_shared' }
$names = $dirs | ForEach-Object { $_.Name }
foreach ($n in $names) { $g = Add-GraphNode $g -Id $n }
$edgeCount = 0
foreach ($dir in $dirs) {
    $c = Get-Content (Join-Path $dir.FullName "SKILL.md") -Raw -ErrorAction SilentlyContinue
    if (-not $c) { continue }
    foreach ($target in $names) {
        if ($target -eq $dir.Name) { continue }
        if ($c -match [regex]::Escape($target)) {
            $g = Add-GraphEdge $g -From $dir.Name -To $target
            $edgeCount++
        }
    }
}
$sw.Stop()
$buildTime = $sw.Elapsed
Write-Host ("Nodes: " + $g.Nodes.Count + ", Edges: " + $edgeCount + ", Build: " + (fmt $buildTime))

# ---- TEST 1: BASICO ----
Write-Host "`n=== BASICO: Direct dependents of quality-gate ==="
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$grep1 = @()
foreach ($dir in $dirs) {
    $c = Get-Content (Join-Path $dir.FullName "SKILL.md") -Raw -ErrorAction SilentlyContinue
    if ($c -and $c -match 'quality-gate') { $grep1 += $dir.Name }
}
$t_grep1 = $sw.Elapsed

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$g1 = Find-GraphDependencies $g -StartId "quality-gate" -MaxDepth 1
$t_g1 = $sw.Elapsed

$s1 = [math]::Round($t_grep1.TotalMilliseconds / [math]::Max($t_g1.TotalMilliseconds, 0.001), 1)
Write-Host ("  GREP: " + $grep1.Count + " in " + (fmt $t_grep1))
Write-Host ("  GRAPH: " + $g1.Count + " in " + (fmt $t_g1) + "  -> " + $s1 + "x")

# ---- TEST 2: MEDIO ----
Write-Host "`n=== MEDIO: Transitivo depth=3 (session-resume) ==="
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$seen = @{ 'session-resume' = $true }; $grep2 = @{}; $cur = @('session-resume')
for ($d = 0; $d -lt 3 -and $cur.Count -gt 0; $d++) {
    $nxt = @()
    foreach ($sk in $cur) {
        foreach ($dir in $dirs) {
            if ($seen.ContainsKey($dir.Name)) { continue }
            $c = Get-Content (Join-Path $dir.FullName "SKILL.md") -Raw -ErrorAction SilentlyContinue
            if ($c -and $c -match [regex]::Escape($sk)) {
                $seen[$dir.Name] = $true; $grep2[$dir.Name] = $d+1; $nxt += $dir.Name
            }
        }
    }
    $cur = $nxt
}
$t_grep2 = $sw.Elapsed

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$g2 = Find-GraphDependencies $g -StartId "session-resume" -MaxDepth 3
$t_g2 = $sw.Elapsed
$s2 = [math]::Round($t_grep2.TotalMilliseconds / [math]::Max($t_g2.TotalMilliseconds, 0.001), 1)
Write-Host ("  GREP: " + $grep2.Count + " in " + (fmt $t_grep2))
Write-Host ("  GRAPH: " + $g2.Count + " in " + (fmt $t_g2) + "  -> " + $s2 + "x")

# ---- TEST 3: DIFICIL ----
Write-Host "`n=== DIFICIL: Full impact of quality-gate ==="
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$seen2 = @{ 'quality-gate' = $true }; $grep3 = @{}; $cur2 = @('quality-gate')
while ($cur2.Count -gt 0) {
    $nxt2 = @()
    foreach ($sk in $cur2) {
        foreach ($dir in $dirs) {
            if ($seen2.ContainsKey($dir.Name)) { continue }
            $c = Get-Content (Join-Path $dir.FullName "SKILL.md") -Raw -ErrorAction SilentlyContinue
            if ($c -and $c -match [regex]::Escape($sk)) {
                $seen2[$dir.Name] = $true; $grep3[$dir.Name] = $true; $nxt2 += $dir.Name
            }
        }
    }
    $cur2 = $nxt2
}
$t_grep3 = $sw.Elapsed

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$g3 = Find-GraphDependencies $g -StartId "quality-gate" -MaxDepth 10
$t_g3 = $sw.Elapsed
$s3 = [math]::Round($t_grep3.TotalMilliseconds / [math]::Max($t_g3.TotalMilliseconds, 0.001), 1)
Write-Host ("  GREP: " + $grep3.Count + " in " + (fmt $t_grep3))
Write-Host ("  GRAPH: " + $g3.Count + " in " + (fmt $t_g3) + "  -> " + $s3 + "x")

# ---- TEST 4: COMPLEJO ----
Write-Host "`n=== COMPLEJO: Most referenced skill ==="
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$rc = @{}
foreach ($dir in $dirs) {
    $c = Get-Content (Join-Path $dir.FullName "SKILL.md") -Raw -ErrorAction SilentlyContinue
    foreach ($n in $names) {
        if ($n -eq $dir.Name) { continue }
        if ($c -and $c -match [regex]::Escape($n)) {
            if (-not $rc.ContainsKey($n)) { $rc[$n] = 0 }
            $rc[$n]++
        }
    }
}
$top = ($rc.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1)
$t_grep4a = $sw.Elapsed

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$seen3 = @{ $top.Key = $true }; $grep4 = @{}; $cur3 = @($top.Key)
while ($cur3.Count -gt 0) {
    $nxt3 = @()
    foreach ($sk in $cur3) {
        foreach ($dir in $dirs) {
            if ($seen3.ContainsKey($dir.Name)) { continue }
            $c = Get-Content (Join-Path $dir.FullName "SKILL.md") -Raw -ErrorAction SilentlyContinue
            if ($c -and $c -match [regex]::Escape($sk)) {
                $seen3[$dir.Name] = $true; $grep4[$dir.Name] = $true; $nxt3 += $dir.Name
            }
        }
    }
    $cur3 = $nxt3
}
$t_grep4 = $sw.Elapsed

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$g4 = Find-GraphDependencies $g -StartId $top.Key -MaxDepth 10
$t_g4 = $sw.Elapsed
$s4 = [math]::Round($t_grep4.TotalMilliseconds / [math]::Max($t_g4.TotalMilliseconds, 0.001), 1)
Write-Host ("  Most ref'd: " + $top.Key + " (" + $top.Value + "x)")
Write-Host ("  GREP: " + $grep4.Count + " in " + (fmt $t_grep4))
Write-Host ("  GRAPH: " + $g4.Count + " in " + (fmt $t_g4) + "  -> " + $s4 + "x")

# ---- SUMMARY ----
Write-Host "`n============================================"
Write-Host "SUMMARY: GREP vs GRAPH (BFS)"
Write-Host "============================================"
Write-Host ("{0,-45} {1,10} {2,10} {3,8}" -f "Test", "GREP", "GRAPH", "Speedup")
Write-Host ("{0,-45} {1,10} {2,10} {3,8}" -f ("-"*45), ("-"*10), ("-"*10), ("-"*8))
$tg = 0.0; $tgr = 0.0
$results = @(
    @("1. Basico (directos)", $t_grep1.TotalMilliseconds, $t_g1.TotalMilliseconds, $s1),
    @("2. Medio (trans depth=3)", $t_grep2.TotalMilliseconds, $t_g2.TotalMilliseconds, $s2),
    @("3. Dificil (impacto full)", $t_grep3.TotalMilliseconds, $t_g3.TotalMilliseconds, $s3),
    @("4. Complejo (mas ref'd)", $t_grep4.TotalMilliseconds, $t_g4.TotalMilliseconds, $s4)
)
foreach ($r in $results) {
    $w = if ($r[3] -gt 1) { $r[3].ToString("F1")+"x GRAPH" } else { "GREP" }
    Write-Host ("{0,-45} {1,10:F1} {2,10:F1} {3,8}" -f $r[0], $r[1], $r[2], $w)
    $tg += $r[1]; $tgr += $r[2]
}
$totalS = [math]::Round($tg/[math]::Max($tgr, 0.001), 1)
$buildMs = $sw.Elapsed.TotalMilliseconds
Write-Host ("{0,-45} {1,10:F1} {2,10:F1} {3,8}" -f "TOTAL (4 queries)", $tg, $tgr, "$($totalS)x")
Write-Host ""

Write-Host ("--- BREAK-EVEN ---")
Write-Host ("  Build graph: " + (fmt $buildTime))
$withBuild = $tgr + $buildTime
Write-Host ("  4 queries + build: " + (fmt (New-TimeSpan -Milliseconds $withBuild)) + " graph vs " + (fmt (New-TimeSpan -Milliseconds $tg)) + " grep")
if ($withBuild -lt $tg) {
    Write-Host ("  GRAPH WINS at 4 queries (saves " + (fmt (New-TimeSpan -Milliseconds ($tg - $withBuild))) + ")")
} else {
    $perQ = [math]::Max(($tg - $tgr)/4, 0.001)
    $be = [math]::Ceiling($swB.Elapsed.TotalMilliseconds / $perQ)
    Write-Host ("  BREAK-EVEN after " + $be + " queries")
    Write-Host ("  Per-query savings: " + (fmt (New-TimeSpan -Milliseconds $perQ)))
}
