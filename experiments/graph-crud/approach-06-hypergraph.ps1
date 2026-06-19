# APPROACH 6: Tag-Based Hypergraph
# ==================================
# Skills/file nodes + hyperedges (category, tag, domain).
# Best for: Multi-dimensional classification, faceted search.
# Pattern: N-ary edges connecting 2+ nodes via shared categories.

. $PSScriptRoot\graph-engine.ps1

function Build-Hypergraph {
    <#
    .SYNOPSIS
    Build hypergraph where edges can connect 2+ nodes via categories
    #>
    param([string]$RootPath = "skills")
    
    $graph = New-Graph -Name "Hypergraph"
    $hyperEdges = @{}  # categoryName -> @[nodeIds]
    
    # Define categories (these become hyperedges)
    $categories = @{
        "prompting"     = @("karpathy-prompt", "prompt-engineering", "karpathy-loop", "caveman", "lean-context")
        "quality"       = @("quality-gate", "auto-metrics", "immune-system", "code-review-agent")
        "memory"        = @("session-resume", "code-memory", "dreaming")
        "skills-meta"   = @("skill-creator", "skill-registry", "skill-improver", "skill-digestion")
        "sdd-cycle"     = @("sdd-init", "sdd-explore", "sdd-propose", "sdd-spec", "sdd-design", "sdd-tasks", "sdd-apply", "sdd-verify", "sdd-archive")
        "pr-workflow"   = @("branch-pr", "pr-evidence", "issue-creation", "comment-writer")
        "performance"   = @("performance-tracker", "metricas")
        "security"      = @("security-scanner")
    }
    
    # Add all skill nodes
    $dirs = Get-ChildItem -Directory -Path $RootPath -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        $graph = Add-GraphNode -Graph $graph -Id $d.Name -Label $d.Name -Type "skill" -Metadata @{ path = $d.FullName }
    }
    
    # Add category nodes and create hyperedges
    foreach ($cat in $categories.Keys) {
        $catId = "category:$cat"
        $graph = Add-GraphNode -Graph $graph -Id $catId -Label $cat -Type "category"
        
        foreach ($skillId in $categories[$cat]) {
            if ($Graph.Nodes.ContainsKey($skillId)) {
                $graph = Add-GraphEdge -Graph $graph -From $skillId -To $catId -Type "belongs-to"
                # Store hyperedge membership
                if (-not $hyperEdges.ContainsKey($cat)) { $hyperEdges[$cat] = @() }
                $hyperEdges[$cat] += $skillId
            }
        }
    }
    
    return @{ graph = $graph; hyperEdges = $hyperEdges }
}

function Query-HypergraphByCategory {
    <#
    .SYNOPSIS
    Find all skills in a category (hyperedges)
    #>
    param(
        [hashtable]$Graph,
        [hashtable]$HyperEdges,
        [string]$Category
    )
    if ($HyperEdges.ContainsKey($Category)) {
        return $HyperEdges[$Category] | ForEach-Object { $Graph.Nodes[$_] }
    }
    return @()
}

function Query-HypergraphIntersection {
    <#
    .SYNOPSIS
    Find skills in ALL given categories (AND intersection)
    #>
    param(
        [hashtable]$HyperEdges,
        [string[]]$Categories
    )
    if ($Categories.Count -eq 0) { return @() }
    
    $result = $HyperEdges[$Categories[0]]
    for ($i = 1; $i -lt $Categories.Count; $i++) {
        $result = $result | Where-Object { $_ -in $HyperEdges[$Categories[$i]] }
    }
    return $result
}

Function Get-HypergraphTagCloud {
    <#
    .SYNOPSIS
    Return all categories with skill counts
    #>
    param([hashtable]$HyperEdges)
    $cloud = @{}
    foreach ($cat in $HyperEdges.Keys) {
        $cloud[$cat] = @{ count = $HyperEdges[$cat].Count; skills = $HyperEdges[$cat] }
    }
    return $cloud
}

Write-Host "Approach 6: Hypergraph loaded"
