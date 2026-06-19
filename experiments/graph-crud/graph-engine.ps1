# Graph Engine for File CRUD â€” gentleman-vMK Agent
# ==================================================
# Base graph: adjacency list with typed edges.
# Supports: BFS, DFS, shortest path, topological sort, impact analysis.
# Operations: AddNode, AddEdge, RemoveNode, RemoveEdge, FindDependents, FindPath

$script:GraphVersion = "1.0.0"

function New-Graph {
    param([string]$Name = "default")
    @{
        Name     = $Name
        Nodes    = @{}   # nodeId -> @{ id, label, type, metadata }
        Edges    = @()   # @{ from, to, type, weight }
        AdjList  = @{}   # nodeId -> @{ to = @{ edgeType = [weights] }, from = @{ edgeType = [weights] } }
        Created  = Get-Date
    }
}

function Add-GraphNode {
    param(
        [hashtable]$Graph,
        [string]$Id,
        [string]$Label = $Id,
        [string]$Type = "file",
        [hashtable]$Metadata = @{}
    )
    if (-not $Graph.Nodes.ContainsKey($Id)) {
        $Graph.Nodes[$Id] = @{ id = $Id; label = $Label; type = $Type; metadata = $Metadata }
        $Graph.AdjList[$Id] = @{ to = @{}; from = @{} }
    }
    return $Graph
}

function Add-GraphEdge {
    param(
        [hashtable]$Graph,
        [string]$From,
        [string]$To,
        [string]$Type = "references",
        [int]$Weight = 1
    )
    if (-not $Graph.Nodes.ContainsKey($From)) { Write-Warning "Node '$From' not found"; return $Graph }
    if (-not $Graph.Nodes.ContainsKey($To))   { Write-Warning "Node '$To' not found"; return $Graph }

    $edge = @{ from = $From; to = $To; type = $Type; weight = $Weight }
    $Graph.Edges += $edge
    
    if (-not $Graph.AdjList[$From].to.ContainsKey($To)) {
        $Graph.AdjList[$From].to[$To] = @{}
    }
    if (-not $Graph.AdjList[$From].to[$To].ContainsKey($Type)) {
        $Graph.AdjList[$From].to[$To][$Type] = @()
    }
    $Graph.AdjList[$From].to[$To][$Type] += $Weight

    if (-not $Graph.AdjList[$To].from.ContainsKey($From)) {
        $Graph.AdjList[$To].from[$From] = @{}
    }
    if (-not $Graph.AdjList[$To].from[$From].ContainsKey($Type)) {
        $Graph.AdjList[$To].from[$From][$Type] = @()
    }
    $Graph.AdjList[$To].from[$From][$Type] += $Weight

    return $Graph
}

function Remove-GraphNode {
    param([hashtable]$Graph, [string]$Id)
    if (-not $Graph.Nodes.ContainsKey($Id)) { return $Graph }
    
    # Remove all edges involving this node
    $Graph.Edges = $Graph.Edges | Where-Object { $_.from -ne $Id -and $_.to -ne $Id }
    $Graph.Nodes.Remove($Id)
    $Graph.AdjList.Remove($Id)
    
    # Clean adjList references
    foreach ($k in $Graph.AdjList.Keys) {
        if ($Graph.AdjList[$k].to.ContainsKey($Id)) { $Graph.AdjList[$k].to.Remove($Id) }
        if ($Graph.AdjList[$k].from.ContainsKey($Id)) { $Graph.AdjList[$k].from.Remove($Id) }
    }
    return $Graph
}

function Remove-GraphEdge {
    param([hashtable]$Graph, [string]$From, [string]$To, [string]$Type)
    $Graph.Edges = $Graph.Edges | Where-Object { 
        -not ($_.from -eq $From -and $_.to -eq $To -and $_.type -eq $Type)
    }
    if ($Graph.AdjList[$From].to.ContainsKey($To)) {
        $Graph.AdjList[$From].to[$To].Remove($Type)
    }
    if ($Graph.AdjList[$To].from.ContainsKey($From)) {
        $Graph.AdjList[$To].from[$From].Remove($Type)
    }
    return $Graph
}

function Find-GraphDependents {
    <#
    .SYNOPSIS
    BFS traversal to find all nodes that depend on a given node
    #>
    param(
        [hashtable]$Graph,
        [string]$StartId,
        [int]$MaxDepth = 10
    )
    $visited = @{}
    $queue = New-Object System.Collections.Queue
    $queue.Enqueue(@{ id = $StartId; depth = 0; path = @($StartId) })
    $results = @()
    $visited[$StartId] = $true

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($current.depth -gt 0) {
            $results += $current
        }
        if ($current.depth -ge $MaxDepth) { continue }
        
        $outEdges = $Graph.AdjList[$current.id]
        if ($outEdges) {
            foreach ($toId in $outEdges.to.Keys) {
                if (-not $visited[$toId]) {
                    $visited[$toId] = $true
                    $queue.Enqueue(@{ id = $toId; depth = $current.depth + 1; path = $current.path + @($toId) })
                }
            }
        }
    }
    return $results
}

function Find-GraphDependencies {
    <#
    .SYNOPSIS
    BFS traversal to find all nodes that a given node depends on (reverse direction)
    #>
    param(
        [hashtable]$Graph,
        [string]$StartId,
        [int]$MaxDepth = 10
    )
    $visited = @{}
    $queue = New-Object System.Collections.Queue
    $queue.Enqueue(@{ id = $StartId; depth = 0; path = @($StartId) })
    $results = @()
    $visited[$StartId] = $true

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($current.depth -gt 0) {
            $results += $current
        }
        if ($current.depth -ge $MaxDepth) { continue }
        
        $inEdges = $Graph.AdjList[$current.id]
        if ($inEdges) {
            foreach ($fromId in $inEdges.from.Keys) {
                if (-not $visited[$fromId]) {
                    $visited[$fromId] = $true
                    $queue.Enqueue(@{ id = $fromId; depth = $current.depth + 1; path = $current.path + @($fromId) })
                }
            }
        }
    }
    return $results
}

function Find-GraphShortestPath {
    <#
    .SYNOPSIS
    BFS shortest path between two nodes
    #>
    param(
        [hashtable]$Graph,
        [string]$From,
        [string]$To
    )
    $visited = @{}
    $queue = New-Object System.Collections.Queue
    $queue.Enqueue(@{ id = $From; path = @($From) })
    $visited[$From] = $true

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        
        if ($current.id -eq $To) { return $current.path }
        
        $outEdges = $Graph.AdjList[$current.id]
        if ($outEdges) {
            foreach ($nextId in $outEdges.to.Keys) {
                if (-not $visited[$nextId]) {
                    $visited[$nextId] = $true
                    $queue.Enqueue(@{ id = $nextId; path = $current.path + @($nextId) })
                }
            }
        }
    }
    return $null  # No path
}

function Get-GraphOrphans {
    <#
    .SYNOPSIS
    Find nodes with no incoming or outgoing edges
    #>
    param([hashtable]$Graph)
    $orphans = @()
    foreach ($nodeId in $Graph.Nodes.Keys) {
        $adj = $Graph.AdjList[$nodeId]
        $inCount = ($adj.from.Keys | Measure-Object).Count
        $outCount = ($adj.to.Keys | Measure-Object).Count
        if ($inCount -eq 0 -and $outCount -eq 0) {
            $orphans += $nodeId
        }
    }
    return $orphans
}

function Get-GraphImpactScore {
    <#
    .SYNOPSIS
    Impact score = number of transitive dependents
    Higher = riskier to change
    #>
    param(
        [hashtable]$Graph,
        [string]$NodeId
    )
    $deps = Find-GraphDependents -Graph $Graph -StartId $NodeId
    return @($deps).Count
}

function Convert-GraphToJson {
    param([hashtable]$Graph)
    $export = @{
        name = $Graph.Name
        nodes = @($Graph.Nodes.Keys | ForEach-Object { $Graph.Nodes[$_] })
        edges = $Graph.Edges
        nodeCount = $Graph.Nodes.Count
        edgeCount = $Graph.Edges.Count
    }
    return ($export | ConvertTo-Json -Depth 10)
}

function Measure-GraphOperations {
    <#
    .SYNOPSIS
    Benchmark graph operations
    #>
    param(
        [hashtable]$Graph,
        [int]$Iterations = 100
    )
    $results = @{}
    $nodeIds = @($Graph.Nodes.Keys)
    $edgeCount = $Graph.Edges.Count
    
    if ($nodeIds.Count -lt 2) {
        Write-Warning "Graph too small for benchmark"
        return $results
    }

    # Measure BFS traversal
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    for ($i = 0; $i -lt $Iterations; $i++) {
        $start = $nodeIds | Get-Random
        $null = Find-GraphDependents -Graph $Graph -StartId $start
    }
    $sw.Stop()
    $results.BFS = @{ ops = $Iterations; total_ms = $sw.Elapsed.TotalMilliseconds; avg_ms = $sw.Elapsed.TotalMilliseconds / $Iterations }

    # Measure node lookup
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    for ($i = 0; $i -lt $Iterations; $i++) {
        $id = $nodeIds | Get-Random
        $null = $Graph.Nodes[$id]
    }
    $sw.Stop()
    $results.Lookup = @{ ops = $Iterations; total_ms = $sw.Elapsed.TotalMilliseconds; avg_us = ($sw.Elapsed.TotalMilliseconds / $Iterations) * 1000 }

    # Measure edge traversal (all edges)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    for ($i = 0; $i -lt $Iterations; $i++) {
        foreach ($e in $Graph.Edges) {
            $null = $e.from + $e.to
        }
    }
    $sw.Stop()
    $results.EdgeScan = @{ ops = $Iterations * $edgeCount; total_ms = $sw.Elapsed.TotalMilliseconds }

    return $results
}

Write-Host "Graph Engine loaded (v$script:GraphVersion)"
