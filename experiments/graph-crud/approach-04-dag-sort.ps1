# APPROACH 4: Directed Acyclic Graph (DAG) — Topological Sort
# =============================================================
# Import dependencies as DAG. Topological sort for build order.
# Best for: Dependency resolution, build ordering, cycle detection.
# Pattern: Kahn's algorithm for topological ordering.

. $PSScriptRoot\graph-engine.ps1

function Build-DependencyDAG {
    <#
    .SYNOPSIS
    Build directed acyclic graph from skill cross-references
    #>
    param([string]$RootPath = "skills")
    
    $graph = New-Graph -Name "DAG"
    
    # Parse all SKILL.md files
    $files = Get-ChildItem -Recurse -Filter "SKILL.md" -Path $RootPath
    foreach ($f in $files) {
        $name = $f.Directory.Name
        $content = Get-Content $f.FullName -Raw
        
        $graph = Add-GraphNode -Graph $graph -Id $name -Label $name -Type "skill" -Metadata @{
            path = $f.FullName
            size = $f.Length
        }
        
        # Dependencies = references to other skills
        $refs = [regex]::Matches($content, 'skill-[\w-]+')
        foreach ($ref in $refs) {
            $target = $ref.Value
            if ($target -ne $name) {
                # Edge means: $name depends on $target
                $graph = Add-GraphNode -Graph $graph -Id $target -Label $target -Type "skill"
                $graph = Add-GraphEdge -Graph $graph -From $name -To $target -Type "depends-on"
            }
        }
    }
    
    return $graph
}

function Get-TopologicalSort {
    <#
    .SYNOPSIS
    Kahn's algorithm: returns nodes in dependency order (dependencies first)
    Returns $null if cycle detected
    #>
    param([hashtable]$Graph)
    
    $inDegree = @{}
    foreach ($nodeId in $Graph.Nodes.Keys) {
        $inDegree[$nodeId] = 0
    }
    foreach ($e in $Graph.Edges) {
        $inDegree[$e.to]++
    }
    
    $queue = [System.Collections.Queue]::new()
    foreach ($nodeId in $inDegree.Keys) {
        if ($inDegree[$nodeId] -eq 0) { $queue.Enqueue($nodeId) }
    }
    
    $sorted = @()
    while ($queue.Count -gt 0) {
        $node = $queue.Dequeue()
        $sorted += $node
        
        $adj = $Graph.AdjList[$node]
        if ($adj) {
            foreach ($toId in $adj.to.Keys) {
                $inDegree[$toId]--
                if ($inDegree[$toId] -eq 0) { $queue.Enqueue($toId) }
            }
        }
    }
    
    if ($sorted.Count -ne $Graph.Nodes.Count) {
        # Cycle detected
        $remaining = $Graph.Nodes.Keys | Where-Object { $_ -notin $sorted }
        return @{ sorted = $sorted; cycle = $true; cycleNodes = $remaining }
    }
    
    return @{ sorted = $sorted; cycle = $false }
}

function Find-DAGCycle {
    <#
    .SYNOPSIS
    DFS-based cycle detection
    #>
    param([hashtable]$Graph)
    
    $WHITE = 0; $GRAY = 1; $BLACK = 2
    $color = @{}
    foreach ($k in $Graph.Nodes.Keys) { $color[$k] = $WHITE }
    $cycleNodes = @()
    
    function Visit($nodeId) {
        if ($color[$nodeId] -eq $GRAY) { return $true }  # cycle
        if ($color[$nodeId] -eq $BLACK) { return $false }
        
        $color[$nodeId] = $GRAY
        $adj = $Graph.AdjList[$nodeId]
        if ($adj) {
            foreach ($toId in $adj.to.Keys) {
                if (Visit $toId) { $cycleNodes += $nodeId; return $true }
            }
        }
        $color[$nodeId] = $BLACK
        return $false
    }
    
    foreach ($nodeId in $Graph.Nodes.Keys) {
        if ($color[$nodeId] -eq $WHITE) {
            if (Visit $nodeId) {
                return @{ hasCycle = $true; cycleNodes = $cycleNodes }
            }
        }
    }
    
    return @{ hasCycle = $false }
}

Write-Host "Approach 4: DAG Topological Sort loaded"
