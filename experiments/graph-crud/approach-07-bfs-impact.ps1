# APPROACH 7: BFS Impact Analyzer
# =================================
# Real-time impact analysis using BFS traversal.
# Best for: "What breaks if I change X?" queries.
# Pattern: Prioritized BFS with memoization.

. $PSScriptRoot\graph-engine.ps1

function Build-ImpactGraph {
    <#
    .SYNOPSIS
    Build graph optimized for impact analysis queries
    #>
    param([string]$RootPath = "skills")
    
    $graph = New-Graph -Name "Impact"
    
    $files = Get-ChildItem -Recurse -Filter "SKILL.md" -Path $RootPath -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $name = $f.Directory.Name
        $content_raw = Get-Content $f.FullName -Raw
        $graph = Add-GraphNode -Graph $graph -Id $name -Label $name -Type "skill" -Metadata @{
            path = $f.FullName; size = $f.Length
        }
        
        # Extract all references
        $refs = [regex]::Matches($content_raw, '(?:skill-[\w-]+|performance-tracker|code-review-agent|gap-analysis|project-mapper|security-scanner|doc-sync|bitacora|metricas|commit-crafter|refactoring-planner)')
        foreach ($ref in $refs) {
            $target = $ref.Value
            if ($target -ne $name -and $target -match '^[\w-]+$') {
                $graph = Add-GraphNode -Graph $graph -Id $target -Label $target -Type "skill" -Metadata @{}
                $graph = Add-GraphEdge -Graph $graph -From $name -To $target -Type "references"
            }
        }
    }
    
    # Also parse AGENTS.md references
    $agents = Get-Content -Path "$PSScriptRoot/../../AGENTS.md" -Raw -ErrorAction SilentlyContinue
    if ($agents) {
        $graph = Add-GraphNode -Graph $graph -Id "AGENTS.md" -Label "AGENTS.md" -Type "config"
        $refs = [regex]::Matches($agents, 'skill-[\w-]+')
        foreach ($ref in $refs) {
            $target = $ref.Value
            $graph = Add-GraphNode -Graph $graph -Id $target -Label $target -Type "skill"
            $graph = Add-GraphEdge -Graph $graph -From "AGENTS.md" -To $target -Type "configures"
        }
    }
    
    return $graph
}

$script:ImpactCache = @{}

function Get-ImpactAnalysis {
    <#
    .SYNOPSIS
    Full impact report: what breaks if we modify a node
    #>
    param(
        [hashtable]$Graph,
        [string]$NodeId,
        [int]$MaxDepth = 5,
        [switch]$NoCache
    )
    
    $cacheKey = "$NodeId@$MaxDepth"
    if (-not $NoCache -and $script:ImpactCache.ContainsKey($cacheKey)) {
        return $script:ImpactCache[$cacheKey]
    }
    
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Forward: what this node affects (dependents)
    $forward = Find-GraphDependents -Graph $Graph -StartId $NodeId -MaxDepth $MaxDepth
    
    # Reverse: what this node depends on (dependencies)
    $reverse = Find-GraphDependencies -Graph $Graph -StartId $NodeId -MaxDepth $MaxDepth
    
    # Impact score = weighted count
    $impactScore = @($forward).Count * 2 + @($reverse).Count
    
    # Categorize by depth
    $direct = $forward | Where-Object { $_.depth -eq 1 }
    $indirect = $forward | Where-Object { $_.depth -gt 1 }
    
    $sw.Stop()
    
    $result = @{
        target = $NodeId
        impactScore = $impactScore
        directAffected = @($direct).Count
        indirectAffected = @($indirect).Count
        totalAffected = @($forward).Count
        dependencies = @($reverse).Count
        details = @{
            forward = $forward
            reverse = $reverse
            direct = $direct
            indirect = $indirect
        }
        queryTime = $sw.Elapsed
        cacheKey = $cacheKey
    }
    
    # Cache (LRU-like, limit 50)
    if ($script:ImpactCache.Count -ge 50) {
        $key = ($script:ImpactCache.Keys | Select-Object -First 1)
        $script:ImpactCache.Remove($key)
    }
    $script:ImpactCache[$cacheKey] = $result
    
    return $result
}

function Get-ImpactRanking {
    <#
    .SYNOPSIS
    Rank all nodes by impact score — find the riskiest to modify
    #>
    param([hashtable]$Graph)
    
    $rankings = @()
    foreach ($nodeId in $Graph.Nodes.Keys) {
        $impact = Get-ImpactAnalysis -Graph $Graph -NodeId $nodeId -MaxDepth 3
        $rankings += @{
            node = $nodeId
            label = $Graph.Nodes[$nodeId].label
            type = $Graph.Nodes[$nodeId].type
            impactScore = $impact.impactScore
            totalAffected = $impact.totalAffected
            dependencies = $impact.dependencies
        }
    }
    
    return $rankings | Sort-Object -Property impactScore -Descending
}

Write-Host "Approach 7: BFS Impact Analyzer loaded"
