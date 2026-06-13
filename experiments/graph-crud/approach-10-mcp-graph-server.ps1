# APPROACH 10: MCP Graph Server (API-Based Knowledge Graph)
# ===========================================================
# Expose graph via a local REST/MCP server for agent queries.
# Best for: AI agent integration, cross-session persistence.
# Pattern: Server-based graph with HTTP query interface.

. $PSScriptRoot\graph-engine.ps1

$script:ServerPort = 8742
$script:ServerProcess = $null

function Start-GraphServer {
    <#
    .SYNOPSIS
    Start a minimal HTTP server that serves graph queries
    Uses PowerShell's built-in HttpListener
    #>
    param(
        [hashtable]$Graph,
        [int]$Port = $script:ServerPort
    )
    
    $script:ServerGraph = $Graph
    
    # Create server in background
    $scriptBlock = {
        param($Port, $Graph)
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://localhost:$Port/")
        $listener.Start()
        
        function Handle-Request($ctx) {
            $req = $ctx.Request
            $resp = $ctx.Response
            $path = $req.Url.AbsolutePath.Trim('/')
            
            $result = switch ($path) {
                'status' { @{ status = "ok"; nodes = $Graph.Nodes.Count; edges = $Graph.Edges.Count } }
                'nodes' { $Graph.Nodes.Keys | ForEach-Object { $Graph.Nodes[$_] } }
                'edges' { $Graph.Edges }
                'dependents' { 
                    $id = $req.QueryString['id']
                    if ($id) { Find-GraphDependents -Graph $Graph -StartId $id }
                    else { @{ error = "Missing 'id' param" } }
                }
                'impact' {
                    $id = $req.QueryString['id']
                    if ($id) { 
                        $deps = Find-GraphDependents -Graph $Graph -StartId $id
                        @{ target = $id; count = @($deps).Count; dependents = $deps }
                    }
                    else { @{ error = "Missing 'id' param" } }
                }
                'path' {
                    $from = $req.QueryString['from']
                    $to = $req.QueryString['to']
                    if ($from -and $to) { Find-GraphShortestPath -Graph $Graph -From $from -To $to }
                    else { @{ error = "Missing 'from' or 'to' param" } }
                }
                'search' {
                    $q = $req.QueryString['q']
                    if ($q) {
                        $Graph.Nodes.Keys | Where-Object { $_ -like "*$q*" -or $Graph.Nodes[$_].label -like "*$q*" }
                    }
                    else { @{ error = "Missing 'q' param" } }
                }
                default { @{ error = "Unknown endpoint: /$path"; endpoints = @("status","nodes","edges","dependents?id=X","impact?id=X","path?from=X&to=Y","search?q=X") } }
            }
            
            $json = ($result | ConvertTo-Json -Depth 5)
            $buffer = [Text.Encoding]::UTF8.GetBytes($json)
            $resp.ContentType = "application/json"
            $resp.ContentLength64 = $buffer.Length
            $resp.OutputStream.Write($buffer, 0, $buffer.Length)
            $resp.Close()
        }
        
        # Single request handling (for test)
        $ctx = $listener.GetContext()
        Handle-Request($ctx)
        $listener.Stop()
    }
    
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList @($Port, $Graph)
    Start-Sleep -Milliseconds 500  # Let server start
    
    # Quick test
    try {
        $test = Invoke-WebRequest "http://localhost:$Port/status" -UseBasicParsing -TimeoutSec 2
        $script:ServerProcess = $job
        return @{ 
            running = $true
            port = $Port
            endpoints = @("status","nodes","edges","dependents?id=X","impact?id=X","path?from=X&to=Y","search?q=X")
        }
    }
    catch {
        return @{ running = $false; error = $_.Exception.Message }
    }
}

function Query-GraphRestAPI {
    <#
    .SYNOPSIS
    Query the graph server via HTTP
    #>
    param(
        [string]$Endpoint = "status",
        [hashtable]$Params = @{},
        [int]$Port = $script:ServerPort
    )
    
    $query = ""
    if ($Params.Count -gt 0) {
        $parts = $Params.Keys | ForEach-Object { "$_=$($Params[$_])" }
        $query = "?" + ($parts -join "&")
    }
    
    $url = "http://localhost:$Port/$Endpoint$query"
    try {
        $resp = Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 5
        return ($resp.Content | ConvertFrom-Json)
    }
    catch {
        return @{ error = $_.Exception.Message }
    }
}

function Export-GraphToMCP {
    <#
    .SYNOPSIS
    Export graph to MCP-compatible format (for opencode.json integration)
    #>
    param([hashtable]$Graph)
    
    $mcpTools = @()
    
    $mcpTools += @{
        name = "graph_search"
        description = "Search for nodes in the knowledge graph"
        inputSchema = @{
            type = "object"
            properties = @{
                query = @{ type = "string"; description = "Search query" }
            }
        }
    }
    
    $mcpTools += @{
        name = "graph_impact"
        description = "Find impact of changing a node (what depends on it)"
        inputSchema = @{
            type = "object"
            properties = @{
                nodeId = @{ type = "string"; description = "Node ID to analyze" }
                maxDepth = @{ type = "integer"; description = "Max traversal depth" }
            }
        }
    }
    
    $mcpTools += @{
        name = "graph_dependents"
        description = "Find all nodes that depend on a given node"
        inputSchema = @{
            type = "object"
            properties = @{
                nodeId = @{ type = "string" }
            }
        }
    }
    
    return @{
        graphName = $Graph.Name
        nodeCount = $Graph.Nodes.Count
        edgeCount = $Graph.Edges.Count
        mcpTools = $mcpTools
    }
}

Write-Host "Approach 10: MCP Graph Server loaded"
