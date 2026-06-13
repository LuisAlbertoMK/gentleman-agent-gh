# APPROACH 8: Change Propagation Graph
# ======================================
# Track what files need updating when a change occurs.
# Best for: File change impact, ripple effect analysis.
# Pattern: Event-driven propagation with weighted edges.

. $PSScriptRoot\graph-engine.ps1

function Build-PropagationGraph {
    <#
    .SYNOPSIS
    Build a propagation graph where edge weights = change likelihood
    #>
    param([string]$RootPath = "skills")
    
    $graph = New-Graph -Name "Propagation"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Phase 1: Skill nodes
    $skillDirs = Get-ChildItem -Directory -Path $RootPath -ErrorAction SilentlyContinue
    foreach ($d in $skillDirs) {
        $graph = Add-GraphNode -Graph $graph -Id $d.Name -Label $d.Name -Type "skill" -Metadata @{
            path = $d.FullName; modified = $d.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        }
    }
    
    # Config files as nodes
    foreach ($cfg in @("AGENTS.md", "SKILLS-INDEX.md", "README.md", "ANTI-PATTERN-CATALOG.md")) {
        $path = "$PSScriptRoot/../../$cfg"
        if (Test-Path $path) {
            $graph = Add-GraphNode -Graph $graph -Id $cfg -Label $cfg -Type "config" -Metadata @{
                path = (Resolve-Path $path).Path
            }
        }
    }
    
    # Phase 2: Propagation edges with weights
    # AGENTS.md configures skills → change in AGENTS.md affects all referenced skills
    $agents = Get-Content "$PSScriptRoot/../../AGENTS.md" -Raw -ErrorAction SilentlyContinue
    if ($agents) {
        $skillRefs = [regex]::Matches($agents, 'skill-[\w-]+') | ForEach-Object { $_.Value } | Sort-Object -Unique
        foreach ($s in $skillRefs) {
            if ($Graph.Nodes.ContainsKey($s)) {
                # Weight 5 = high propagation (config changes have wide impact)
                $graph = Add-GraphEdge -Graph $graph -From "AGENTS.md" -To $s -Type "propagates" -Weight 5
            }
        }
    }
    
    # SKILLS-INDEX references → medium propagation
    $index = Get-Content "$PSScriptRoot/../../SKILLS-INDEX.md" -Raw -ErrorAction SilentlyContinue
    if ($index) {
        $skillRefs = [regex]::Matches($index, 'skill-[\w-]+') | ForEach-Object { $_.Value } | Sort-Object -Unique
        foreach ($s in $skillRefs) {
            if ($Graph.Nodes.ContainsKey($s)) {
                $graph = Add-GraphEdge -Graph $graph -From "SKILLS-INDEX.md" -To $s -Type "propagates" -Weight 3
            }
        }
    }
    
    # README lists skills → low propagation
    $readme = Get-Content "$PSScriptRoot/../../README.md" -Raw -ErrorAction SilentlyContinue
    if ($readme) {
        $skillRefs = [regex]::Matches($readme, 'skill-[\w-]+') | ForEach-Object { $_.Value } | Sort-Object -Unique
        foreach ($s in $skillRefs) {
            if ($Graph.Nodes.ContainsKey($s)) {
                $graph = Add-GraphEdge -Graph $graph -From "README.md" -To $s -Type "propagates" -Weight 2
            }
        }
    }
    
    $sw.Stop()
    return @{ graph = $graph; buildTime = $sw.Elapsed }
}

function Get-PropagationPath {
    <#
    .SYNOPSIS
    Find what needs to change if we modify a file
    Uses weighted BFS to find maximum propagation paths
    #>
    param(
        [hashtable]$Graph,
        [string]$ChangedFile,
        [int]$MinWeight = 1
    )
    
    # Find all nodes reachable via propagation edges with weight >= MinWeight
    $visited = @{}
    $queue = @(@{ id = $ChangedFile; depth = 0; path = @($ChangedFile); totalWeight = 0 })
    $results = @()
    $visited[$ChangedFile] = $true
    
    while ($queue.Count -gt 0) {
        $current = $queue[0]; $queue = $queue[1..($queue.Count-1)]
        if ($current.depth -gt 0) {
            $results += $current
        }
        
        $outEdges = $Graph.AdjList[$current.id]
        if ($outEdges) {
            foreach ($toId in $outEdges.to.Keys) {
                if (-not $visited[$toId]) {
                    $edgeTypes = $outEdges.to[$toId]
                    $maxW = 0
                    foreach ($et in $edgeTypes.Keys) {
                        foreach ($w in $edgeTypes[$et]) {
                            if ($w -gt $maxW) { $maxW = $w }
                        }
                    }
                    if ($maxW -ge $MinWeight) {
                        $visited[$toId] = $true
                        $queue += @{ 
                            id = $toId
                            depth = $current.depth + 1
                            path = $current.path + @($toId)
                            totalWeight = $current.totalWeight + $maxW
                        }
                    }
                }
            }
        }
    }
    
    return $results | Sort-Object -Property totalWeight -Descending
}

Write-Host "Approach 8: Change Propagation Graph loaded"
