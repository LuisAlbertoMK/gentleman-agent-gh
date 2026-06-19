# APPROACH 3: JSON Property Graph
# ================================
# Portable, human-readable graph stored as JSON.
# Best for: Portability, debugging, small graphs, hand-editing.
# Pattern: Document-based with embedded edge lists.

. $PSScriptRoot\graph-engine.ps1

$script:JsonPath = "$PSScriptRoot\property-graph.json"

function New-JsonPropertyGraph {
    param([string]$Name = "property-graph")
    return New-Graph -Name $Name
}

function Add-PropertyNode {
    param(
        [hashtable]$Graph,
        [string]$Id,
        [hashtable]$Properties = @{},
        [string]$Type = "file"
    )
    $props = $Properties
    $props.type = $Type
    return Add-GraphNode -Graph $Graph -Id $Id -Label ($Properties.name -or $Id) -Type $Type -Metadata $Properties
}

function Add-PropertyEdge {
    param(
        [hashtable]$Graph,
        [string]$From,
        [string]$To,
        [string]$Label = "references",
        [hashtable]$Properties = @{}
    )
    $null = $Properties # reserved for future edge metadata
    return Add-GraphEdge -Graph $Graph -From $From -To $To -Type $Label
}

function Export-JsonPropertyGraph {
    param(
        [hashtable]$Graph,
        [string]$Path = $script:JsonPath
    )
    $json = Convert-GraphToJson -Graph $Graph
    $json | Set-Content -Path $Path -Encoding UTF8
    return @{ path = $Path; size = (Get-Item $Path).Length }
}

function Import-JsonPropertyGraph {
    param([string]$Path = $script:JsonPath)
    if (-not (Test-Path $Path)) { return New-JsonPropertyGraph }
    $data = Get-Content $Path -Raw | ConvertFrom-Json
    $graph = New-Graph -Name $data.name
    foreach ($n in $data.nodes) {
        $meta = @{}
        $n.metadata.PSObject.Properties | ForEach-Object { $meta[$_.Name] = $_.Value }
        $graph = Add-GraphNode -Graph $graph -Id $n.id -Label $n.label -Type $n.type -Metadata $meta
    }
    foreach ($e in $data.edges) {
        $graph = Add-GraphEdge -Graph $graph -From $e.from -To $e.to -Type $e.type -Weight $e.weight
    }
    return $graph
}

function Query-PropertyGraphByProperty {
    param(
        [hashtable]$Graph,
        [string]$PropertyName,
        [string]$PropertyValue
    )
    $results = @()
    foreach ($nodeId in $Graph.Nodes.Keys) {
        $node = $Graph.Nodes[$nodeId]
        if ($node.metadata.ContainsKey($PropertyName) -and $node.metadata[$PropertyName] -eq $PropertyValue) {
            $results += $node
        }
    }
    return $results
}

Write-Host "Approach 3: JSON Property Graph loaded"
