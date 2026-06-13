# APPROACH 1: In-Memory Adjacency List
# =====================================
# Fastest for small-medium graphs. O(1) node lookup, O(d) neighbor iteration.
# Best for: <10K nodes, frequent read/write, low memory overhead.
# Pattern: Direct map-based with bi-directional edges.

. $PSScriptRoot\graph-engine.ps1

function Build-AdjacencyGraph {
    param([string]$RootPath = "skills")
    
    $graph = New-Graph -Name "Adjacency-List"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Phase 1: Add all skill directories as nodes
    $dirs = Get-ChildItem -Directory -Path $RootPath -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        $graph = Add-GraphNode -Graph $graph -Id $d.Name -Label $d.Name -Type "skill-dir" -Metadata @{
            path = $d.FullName
            created = $d.CreationTime.ToString("yyyy-MM-dd")
        }
    }
    
    # Phase 2: Parse SKILL.md frontmatter for dependency edges
    $skillFiles = Get-ChildItem -Recurse -Filter "SKILL.md" -Path $RootPath
    foreach ($f in $skillFiles) {
        $skillName = $f.Directory.Name
        $content = Get-Content $f.FullName -Raw
        
        # Extract triggers and cross-references
        if ($content -match 'triggers:\s*"(.+?)"') {
            $graph = Add-GraphNode -Graph $graph -Id "$skillName/triggers" -Label $Matches[1] -Type "triggers"
            $graph = Add-GraphEdge -Graph $graph -From $skillName -To "$skillName/triggers" -Type "has-triggers"
        }
        
        # Cross-references to other skills
        $refs = [regex]::Matches($content, 'skill-[\w-]+')
        foreach ($ref in $refs) {
            $target = $ref.Value
            if ($target -ne $skillName) {
                $graph = Add-GraphNode -Graph $graph -Id $target -Label $target -Type "skill-ref"
                $graph = Add-GraphEdge -Graph $graph -From $skillName -To $target -Type "references"
            }
        }
        
        # Trigger keywords as edges
        if ($content -match 'triggers:\s*"(.*?)"') {
            $keywords = $Matches[1] -split ',\s*'
            foreach ($kw in $keywords[0..[Math]::Min(4, $keywords.Count-1)]) {
                $kwId = "keyword:$($kw.Trim())"
                $graph = Add-GraphNode -Graph $graph -Id $kwId -Label $kw.Trim() -Type "keyword"
                $graph = Add-GraphEdge -Graph $graph -From $skillName -To $kwId -Type "triggered-by"
            }
        }
    }
    
    $sw.Stop()
    return @{ graph = $graph; buildTime = $sw.Elapsed }
}

function Query-AdjacencyFindRefs {
    param($Graph, [string]$SkillName)
    $deps = Find-GraphDependents -Graph $Graph -StartId $SkillName
    return @{ dependents = $deps; count = @($deps).Count }
}

function Query-AdjacencyShortestPath {
    param($Graph, [string]$From, [string]$To)
    return Find-GraphShortestPath -Graph $Graph -From $From -To $To
}

Write-Host "Approach 1: Adjacency List loaded"
