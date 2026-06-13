# MASTER BENCHMARK: All 10 Graph Approaches
# ============================================
# Tests each approach against the real skills directory
# Records: build time, query time, memory, nodes/edges

$Root = "D:\gentleman-agent-gh"
$ExpDir = "$Root\experiments\graph-crud"

Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  GRAPH CRUD BENCHMARK — All 10 Approaches   ║" -ForegroundColor Cyan
Write-Host "║  Project: gentleman-vMK-agent-gh (58 skills)║" -ForegroundColor Cyan
Write-Host "║  Date: 2026-06-13                           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan

$results = @()
$summary = @()

# --- APPROACH 1: Adjacency List ---
Write-Host "`n[1/10] Adjacency List..." -ForegroundColor Yellow
. $ExpDir\approach-01-adjacency.ps1
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$r1 = Build-AdjacencyGraph -RootPath "$Root\skills"
$sw.Stop()
$graph1 = $r1.graph
$bench1 = Measure-GraphOperations -Graph $graph1 -Iterations 50
$q1 = Query-AdjacencyFindRefs -Graph $graph1 -SkillName "quality-gate"
$summary += @{
    approach = "01-AdjacencyList"
    buildMs = [Math]::Round($r1.buildTime.TotalMilliseconds, 2)
    nodes = $graph1.Nodes.Count
    edges = $graph1.Edges.Count
    bfsAvgUs = [Math]::Round($bench1.BFS.avg_ms * 1000, 2)
    lookupAvgNs = [Math]::Round($bench1.Lookup.avg_us * 1000, 2)
    queryResult = "$($q1.count) dependents found"
}
Write-Host "  ✓ $($graph1.Nodes.Count) nodes, $($graph1.Edges.Count) edges" -ForegroundColor Green

# --- APPROACH 2: SQLite CTE ---
Write-Host "[2/10] SQLite Recursive CTE..." -ForegroundColor Yellow
. $ExpDir\approach-02-sqlite-cte.ps1
$dbPath = "$ExpDir\graph-crud-test.db"
Remove-Item $dbPath -ErrorAction SilentlyContinue
$dbResult = Initialize-SqliteGraph -DbPath $dbPath
$sw2 = [System.Diagnostics.Stopwatch]::StartNew()
$importResult = Import-GraphToSqlite -Graph $graph1 -DbPath $dbPath
$sw2.Stop()
$cteResult = Query-SqliteRecursiveCTE -StartId "quality-gate" -MaxDepth 5 -DbPath $dbPath
$cteCount = if ($cteResult) { @($cteResult).Count } else { 0 }
$summary += @{
    approach = "02-SQLite-CTE"
    buildMs = [Math]::Round($sw2.Elapsed.TotalMilliseconds, 2)
    nodes = $importResult.nodes
    edges = $importResult.edges
    queryResult = "$cteCount CTE results"
    note = if ($importResult.success) { "sqlite3 OK" } else { "sqlite3 missing" }
}
if ($importResult.success) { Write-Host "  ✓ $($importResult.nodes) nodes, $($importResult.edges) edges" -ForegroundColor Green }
else { Write-Host "  ⚠ sqlite3 not available, using JSON fallback" -ForegroundColor Yellow }

# --- APPROACH 3: JSON Property Graph ---
Write-Host "[3/10] JSON Property Graph..." -ForegroundColor Yellow
. $ExpDir\approach-03-json-property.ps1
$sw3 = [System.Diagnostics.Stopwatch]::StartNew()
$graph3 = New-JsonPropertyGraph -Name "skills-property"
foreach ($nid in $graph1.Nodes.Keys) {
    $n = $graph1.Nodes[$nid]
    $graph3 = Add-PropertyNode -Graph $graph3 -Id $nid -Properties $n.metadata -Type $n.type
}
foreach ($e in $graph1.Edges) {
    $graph3 = Add-PropertyEdge -Graph $graph3 -From $e.from -To $e.to -Label $e.type
}
$export3 = Export-JsonPropertyGraph -Graph $graph3 -Path "$ExpDir\property-graph.json"
$sw3.Stop()
$summary += @{
    approach = "03-JSON-Property"
    buildMs = [Math]::Round($sw3.Elapsed.TotalMilliseconds, 2)
    nodes = $graph3.Nodes.Count
    edges = $graph3.Edges.Count
    fileSizeKB = [Math]::Round($export3.size / 1KB, 1)
    queryResult = "JSON export: $($export3.size)B"
}
Write-Host "  ✓ $($graph3.Nodes.Count) nodes → $($export3.size)B JSON" -ForegroundColor Green

# --- APPROACH 4: DAG Topological Sort ---
Write-Host "[4/10] DAG Topological Sort..." -ForegroundColor Yellow
. $ExpDir\approach-04-dag-sort.ps1
$sw4 = [System.Diagnostics.Stopwatch]::StartNew()
$r4 = Build-DependencyDAG -RootPath "$Root\skills"
$sw4.Stop()
$graph4 = $r4.graph
$topo = Get-TopologicalSort -Graph $graph4
$cycle = Find-DAGCycle -Graph $graph4
$summary += @{
    approach = "04-DAG-TopoSort"
    buildMs = [Math]::Round($sw4.Elapsed.TotalMilliseconds, 2)
    nodes = $graph4.Nodes.Count
    edges = $graph4.Edges.Count
    topoSorted = $topo.sorted.Count
    hasCycle = $cycle.hasCycle
    queryResult = if ($cycle.hasCycle) { "CYCLE DETECTED: $($cycle.cycleNodes.Count) nodes" } else { "Acyclic ✓" }
}
Write-Host "  ✓ $($graph4.Nodes.Count) nodes, cycle: $($cycle.hasCycle)" -ForegroundColor Green

# --- APPROACH 5: Cross-Reference Analyzer ---
Write-Host "[5/10] Cross-Reference Analyzer..." -ForegroundColor Yellow
. $ExpDir\approach-05-cross-ref.ps1
$sw5 = [System.Diagnostics.Stopwatch]::StartNew()
$r5 = Build-CrossReferenceGraph -RootPath $Root -Patterns @("skill-[\w-]+")
$sw5.Stop()
$graph5 = $r5.graph
$orphans = Find-CrossRefOrphans -Graph $graph5 -ExistingNodes @($graph1.Nodes.Keys)
$summary += @{
    approach = "05-CrossRef"
    buildMs = [Math]::Round($sw5.Elapsed.TotalMilliseconds, 2)
    nodes = $graph5.Nodes.Count
    edges = $graph5.Edges.Count
    filesScanned = $r5.stats.filesScanned
    refsFound = $r5.stats.refsFound
    brokenRefs = @($orphans).Count
    queryResult = "$($r5.stats.refsFound) refs from $($r5.stats.filesScanned) files"
}
Write-Host "  ✓ $($r5.stats.refsFound) refs from $($r5.stats.filesScanned) files" -ForegroundColor Green

# --- APPROACH 6: Hypergraph ---
Write-Host "[6/10] Tag-Based Hypergraph..." -ForegroundColor Yellow
. $ExpDir\approach-06-hypergraph.ps1
$sw6 = [System.Diagnostics.Stopwatch]::StartNew()
$r6 = Build-Hypergraph -RootPath "$Root\skills"
$sw6.Stop()
$graph6 = $r6.graph
$tagCloud = Get-HypergraphTagCloud -HyperEdges $r6.hyperEdges
$summary += @{
    approach = "06-Hypergraph"
    buildMs = [Math]::Round($sw6.Elapsed.TotalMilliseconds, 2)
    nodes = $graph6.Nodes.Count
    edges = $graph6.Edges.Count
    categories = $r6.hyperEdges.Count
    queryResult = "$($r6.hyperEdges.Count) hyperedge categories"
}
Write-Host "  ✓ $($r6.hyperEdges.Count) categories, $($graph6.Edges.Count) edges" -ForegroundColor Green

# --- APPROACH 7: BFS Impact Analyzer ---
Write-Host "[7/10] BFS Impact Analyzer..." -ForegroundColor Yellow
. $ExpDir\approach-07-bfs-impact.ps1
$sw7 = [System.Diagnostics.Stopwatch]::StartNew()
$graph7 = Build-ImpactGraph -RootPath "$Root\skills"
$sw7.Stop()
$impactAG = Get-ImpactAnalysis -Graph $graph7 -NodeId "AGENTS.md" -MaxDepth 5
$impactOG = Get-ImpactAnalysis -Graph $graph7 -NodeId "quality-gate" -MaxDepth 5
$ranking = Get-ImpactRanking -Graph $graph7
$topRisk = $ranking | Select-Object -First 3
$summary += @{
    approach = "07-BFS-Impact"
    buildMs = [Math]::Round($sw7.Elapsed.TotalMilliseconds, 2)
    nodes = $graph7.Nodes.Count
    edges = $graph7.Edges.Count
    impactAG = "$($impactAG.totalAffected) affected if AGENTS.md changes"
    impactQG = "$($impactOG.totalAffected) affected if quality-gate changes"
    topRisk = "$($topRisk[0].node): $($topRisk[0].impactScore)"
    queryResult = "Top risk: $($topRisk[0].node) (score $($topRisk[0].impactScore))"
}
Write-Host "  ✓ Impact scores: AGENTS.md=$($impactAG.impactScore), top risk=$($topRisk[0].node)" -ForegroundColor Green

# --- APPROACH 8: Change Propagation Graph ---
Write-Host "[8/10] Change Propagation Graph..." -ForegroundColor Yellow
. $ExpDir\approach-08-change-propagation.ps1
$sw8 = [System.Diagnostics.Stopwatch]::StartNew()
$r8 = Build-PropagationGraph -RootPath "$Root\skills"
$sw8.Stop()
$graph8 = $r8.graph
$propAG = Get-PropagationPath -Graph $graph8 -ChangedFile "AGENTS.md" -MinWeight 1
$summary += @{
    approach = "08-Propagation"
    buildMs = [Math]::Round($r8.buildTime.TotalMilliseconds, 2)
    nodes = $graph8.Nodes.Count
    edges = $graph8.Edges.Count
    propagationAG = "$(@($propAG).Count) files ripple from AGENTS.md"
    queryResult = "Ripple: $(@($propAG).Count) files from AGENTS.md change"
}
Write-Host "  ✓ $(@($propAG).Count) ripple files from AGENTS.md change" -ForegroundColor Green

# --- APPROACH 9: Bloom-Filter Indexed Graph ---
Write-Host "[9/10] Bloom-Filter Indexed Graph..." -ForegroundColor Yellow
. $ExpDir\approach-09-bloom-index.ps1
$sw9 = [System.Diagnostics.Stopwatch]::StartNew()
$r9 = Build-BloomIndexedGraph -RootPath "$Root\skills"
$sw9.Stop()
$graph9 = $r9.graph
$bloomStats = Get-BloomStats -Bloom $r9.bloom
$bq = Query-BloomKeywordSearch -Graph $graph9 -Bloom $r9.bloom -Keyword "quality"
$summary += @{
    approach = "09-Bloom-Index"
    buildMs = [Math]::Round($sw9.Elapsed.TotalMilliseconds, 2)
    nodes = $graph9.Nodes.Count
    bloomUtil = "$($bloomStats.utilizationPercent)%"
    bloomItems = $bloomStats.items
    keywordSearch = "$($bq.count) candidates for 'quality'"
    queryResult = "$($bq.candidates.Count) skills match 'quality' (bloom: $($bq.bloomMatch))"
}
Write-Host "  ✓ Bloom: $($bloomStats.utilizationPercent)% utilized, $($bq.candidates.Count) for 'quality'" -ForegroundColor Green

# --- APPROACH 10: MCP Graph Server ---
Write-Host "[10/10] MCP Graph Server..." -ForegroundColor Yellow
. $ExpDir\approach-10-mcp-graph-server.ps1
$mcp = Export-GraphToMCP -Graph $graph1
$summary += @{
    approach = "10-MCP-Server"
    buildMs = 0
    nodes = $graph1.Nodes.Count
    edges = $graph1.Edges.Count
    mcpTools = $mcp.mcpTools.Count
    queryResult = "$($mcp.mcpTools.Count) MCP tools (graph_search, graph_impact, graph_dependents)"
}
Write-Host "  ✓ $($mcp.mcpTools.Count) MCP tools defined" -ForegroundColor Green

# --- FINAL TABLE ---
Write-Host "`n`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    BENCHMARK RESULTS TABLE                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "`n| Approach | Nodes | Edges | Build(ms) | Query Result |" -ForegroundColor White
Write-Host "|----------|-------|-------|-----------|--------------|" -ForegroundColor White
foreach ($s in $summary) {
    $line = "| $($s.approach) | $($s.nodes) | $($s.edges) | $($s.buildMs) | $($s.queryResult) |"
    Write-Host $line
}

# Save results
$summary | ConvertTo-Json | Set-Content "$ExpDir\benchmark-results.json" -Encoding UTF8
Write-Host "`n✅ Results saved to benchmark-results.json" -ForegroundColor Green
