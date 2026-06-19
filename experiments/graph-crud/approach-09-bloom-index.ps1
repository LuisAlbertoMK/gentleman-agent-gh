# APPROACH 9: Bloom-Filter Indexed Graph
# ========================================
# Hybrid: bloom filters for fast "does this exist?" checks + graph for traversal.
# Best for: Large codebases, pre-filter before expensive operations.
# Pattern: Probabilistic membership testing + exact graph.

. $PSScriptRoot\graph-engine.ps1

function New-BloomFilter {
    <#
    .SYNOPSIS
    Simple bloom filter implementation
    #>
    param(
        [int]$ExpectedItems = 1000,
        [double]$FalsePositiveRate = 0.01
    )
    
    $size = [Math]::Ceiling(-($ExpectedItems * [Math]::Log($FalsePositiveRate)) / ([Math]::Log(2) * [Math]::Log(2)))
    $hashCount = [Math]::Ceiling(($size / $ExpectedItems) * [Math]::Log(2))
    
    return @{
        bitArray = @() * $size
        size = $size
        hashCount = [Math]::Max(1, $hashCount)
        items = 0
    }
}

function Add-ToBloomFilter {
    param([hashtable]$Filter, [string]$Item)
    
    for ($i = 0; $i -lt $Filter.hashCount; $i++) {
        $hash = [Math]::Abs(($Item + "_" + $i).GetHashCode()) % $Filter.size
        $Filter.bitArray[$hash] = $true
    }
    $Filter.items++
}

function Test-BloomFilter {
    param([hashtable]$Filter, [string]$Item)
    
    for ($i = 0; $i -lt $Filter.hashCount; $i++) {
        $hash = [Math]::Abs(($Item + "_" + $i).GetHashCode()) % $Filter.size
        if (-not $Filter.bitArray[$hash]) { return $false }
    }
    return $true  # Probably true (may be false positive)
}

function Build-BloomIndexedGraph {
    <#
    .SYNOPSIS
    Build graph with bloom filter index for fast pre-filtering
    #>
    param([string]$RootPath = "skills")
    
    $graph = New-Graph -Name "Bloom-Indexed"
    $bloom = New-BloomFilter -ExpectedItems 500 -FalsePositiveRate 0.001
    
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Build graph + bloom index simultaneously
    $files = Get-ChildItem -Recurse -Filter "SKILL.md" -Path $RootPath -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $name = $f.Directory.Name
        $graph = Add-GraphNode -Graph $graph -Id $name -Label $name -Type "skill"
        Add-ToBloomFilter -Filter $bloom -Item $name
        
        # Index keywords for fast search
        $content = Get-Content $f.FullName -TotalCount 20 -ErrorAction SilentlyContinue
        foreach ($line in $content) {
            $words = $line -split '\s+' | Where-Object { $_.Length -gt 3 }
            foreach ($w in $words[0..[Math]::Min(5, $words.Count-1)]) {
                Add-ToBloomFilter -Filter $bloom -Item "$name:$w"
                Add-ToBloomFilter -Filter $bloom -Item $w
            }
        }
    }
    
    $sw.Stop()
    return @{ graph = $graph; bloom = $bloom; buildTime = $sw.Elapsed }
}

function Query-BloomKeywordSearch {
    <#
    .SYNOPSIS
    Use bloom filter to quickly find candidate skills matching a keyword
    #>
    param(
        [hashtable]$Graph,
        [hashtable]$Bloom,
        [string]$Keyword
    )
    
    if (-not (Test-BloomFilter -Filter $Bloom -Item $Keyword)) {
        return @{ candidates = @(); bloomMatch = $false; note = "No candidate skills found (bloom negative)" }
    }
    
    # Bloom says "maybe" â€” verify with exact match
    $candidates = @()
    foreach ($nodeId in $Graph.Nodes.Keys) {
        if (Test-BloomFilter -Filter $Bloom -Item "$nodeId:$Keyword") {
            $candidates += $nodeId
        }
    }
    
    return @{ 
        candidates = $candidates 
        bloomMatch = $true
        count = $candidates.Count
        note = if ($candidates.Count -eq 0) { "Bloom false positive" } else { "Found $($candidates.Count) candidates" }
    }
}

function Get-BloomStats {
    param([hashtable]$Bloom)
    $bitsSet = ($Bloom.bitArray | Where-Object { $_ }).Count
    return @{
        size = $Bloom.size
        hashCount = $Bloom.hashCount
        bitsSet = $bitsSet
        utilizationPercent = [Math]::Round($bitsSet / $Bloom.size * 100, 2)
        items = $Bloom.items
    }
}

Write-Host "Approach 9: Bloom-Filter Indexed Graph loaded"
