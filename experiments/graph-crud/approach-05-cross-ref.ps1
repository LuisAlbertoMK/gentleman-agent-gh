# APPROACH 5: Cross-Reference Analyzer (Grep-Based Graph)
# =========================================================
# Build graph by grepping file contents for references.
# Best for: Existing codebases, no parser needed, fast initial build.
# Pattern: Regex-based edge discovery.

. $PSScriptRoot\graph-engine.ps1

function Build-CrossReferenceGraph {
    <#
    .SYNOPSIS
    Build graph by scanning all text files for cross-references
    #>
    param(
        [string]$RootPath = ".",
        [string[]]$Patterns = @("skill-[\w-]+", "file:[\w./-]+", "import.*from.*['""](.+)['""]")
    )
    
    $graph = New-Graph -Name "Cross-Ref"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $stats = @{ filesScanned = 0; refsFound = 0 }
    
    $files = Get-ChildItem -Path $RootPath -Recurse -Include @("*.md", "*.ps1", "*.json", "*.js", "*.go") -Exclude @("*node_modules*", "*.git*", "experiments")
    
    foreach ($f in $files) {
        $fileId = $f.FullName.Replace($RootPath, "").Replace("\", "/").TrimStart("/")
        $graph = Add-GraphNode -Graph $graph -Id $fileId -Label $f.Name -Type "file" -Metadata @{
            ext = $f.Extension
            size = $f.Length
            modified = $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        }
        $stats.filesScanned++
        
        # Read first 50 lines for refs (optimization)
        $lines = Get-Content $f.FullName -TotalCount 50 -ErrorAction SilentlyContinue
        $content = $lines -join "`n"
        
        foreach ($pattern in $Patterns) {
            $matchResults = [regex]::Matches($content, $pattern)
            foreach ($m in $matchResults) {
                $refId = $m.Groups[1].Value -replace "^['""]|['""]$", ""
                if ($refId -and $refId -ne $fileId) {
                    $graph = Add-GraphNode -Graph $graph -Id $refId -Label $refId -Type "reference"
                    $graph = Add-GraphEdge -Graph $graph -From $fileId -To $refId -Type "cross-ref"
                    $stats.refsFound++
                }
            }
        }
    }
    
    $sw.Stop()
    return @{ graph = $graph; stats = $stats; elapsed = $sw.Elapsed }
}

function Find-CrossRefOrphans {
    <#
    .SYNOPSIS
    Find files that reference non-existent targets
    #>
    param(
        [hashtable]$Graph,
        [string[]]$ExistingNodes
    )
    $brokenRefs = @()
    foreach ($e in $Graph.Edges) {
        if ($e.to -notin $ExistingNodes -and $e.to -notin $Graph.Nodes.Keys) {
            $brokenRefs += @{ from = $e.from; ref = $e.to; type = $e.type }
        }
    }
    return $brokenRefs
}

Write-Host "Approach 5: Cross-Reference Analyzer loaded"
