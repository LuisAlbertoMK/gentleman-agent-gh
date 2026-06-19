# APPROACH 2: SQLite + Recursive CTE (Hybrid Graph)
# ==================================================
# Graph stored in SQLite with indexes. Recursive CTE for traversal.
# Best for: Persistent storage, complex queries, >10K nodes.
# Pattern: File-based persistence with SQL query engine.

. $PSScriptRoot\graph-engine.ps1

$script:DbPath = "$PSScriptRoot\graph-crud.db"

function Initialize-SqliteGraph {
    param([string]$DbPath = $script:DbPath)
    
    # Check if sqlite3 is available
    $sqlite = Get-Command "sqlite3.exe" -ErrorAction SilentlyContinue
    if (-not $sqlite) {
        Write-Warning "sqlite3 not found. Using fallback: JSON-based file storage."
        return $null
    }

    # Create schema
    $schema = @"
CREATE TABLE IF NOT EXISTS nodes (
    id TEXT PRIMARY KEY,
    label TEXT NOT NULL,
    type TEXT DEFAULT 'file',
    metadata TEXT DEFAULT '{}',
    created_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS edges (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_id TEXT NOT NULL,
    to_id TEXT NOT NULL,
    type TEXT DEFAULT 'references',
    weight INTEGER DEFAULT 1,
    FOREIGN KEY (from_id) REFERENCES nodes(id),
    FOREIGN KEY (to_id) REFERENCES nodes(id)
);
CREATE INDEX IF NOT EXISTS idx_edges_from ON edges(from_id);
CREATE INDEX IF NOT EXISTS idx_edges_to ON edges(to_id);
CREATE INDEX IF NOT EXISTS idx_edges_type ON edges(type);
CREATE INDEX IF NOT EXISTS idx_nodes_type ON nodes(type);
"@
    $schema -split ';' | ForEach-Object {
        if ($_.Trim()) {
            & $sqlite.source $DbPath $_.Trim() 2>$null
        }
    }
    
    return $DbPath
}

function Import-GraphToSqlite {
    param([hashtable]$Graph, [string]$DbPath = $script:DbPath)
    
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $sqlite = Get-Command "sqlite3.exe" -ErrorAction SilentlyContinue
    if (-not $sqlite) { return @{ success = $false; reason = "sqlite3 not found" } }
    
    # Batch insert nodes
    foreach ($nodeId in $Graph.Nodes.Keys) {
        $node = $Graph.Nodes[$nodeId]
        $meta = ($node.metadata | ConvertTo-Json -Compress) -replace "'", "''"
        $id = $nodeId -replace "'", "''"
        $label = ($node.label -replace "'", "''")
        $q = "INSERT OR REPLACE INTO nodes (id, label, type, metadata) VALUES ('$id', '$label', '$($node.type)', '$meta');"
        & $sqlite.source $DbPath $q 2>$null
    }
    
    # Batch insert edges
    foreach ($e in $Graph.Edges) {
        $from = $e.from -replace "'", "''"
        $to = $e.to -replace "'", "''"
        $q = "INSERT INTO edges (from_id, to_id, type, weight) VALUES ('$from', '$to', '$($e.type)', $($e.weight));"
        & $sqlite.source $DbPath $q 2>$null
    }
    
    $sw.Stop()
    return @{ success = $true; elapsed = $sw.Elapsed; nodes = $Graph.Nodes.Count; edges = $Graph.Edges.Count }
}

function Query-SqliteRecursiveCTE {
    <#
    .SYNOPSIS
    Recursive CTE query for transitive dependents
    #>
    param(
        [string]$StartId,
        [int]$MaxDepth = 10,
        [string]$DbPath = $script:DbPath
    )
    $sqlite = Get-Command "sqlite3.exe" -ErrorAction SilentlyContinue
    if (-not $sqlite) { return $null }
    
    $id = $StartId -replace "'", "''"
    $query = @"
WITH RECURSIVE deps(id, depth, path) AS (
    SELECT e.to_id, 1, e.from_id || '->' || e.to_id
    FROM edges e
    WHERE e.from_id = '$id'
    UNION ALL
    SELECT e.to_id, d.depth + 1, d.path || '->' || e.to_id
    FROM edges e
    JOIN deps d ON e.from_id = d.id
    WHERE d.depth < $MaxDepth
)
SELECT id, depth, path FROM deps ORDER BY depth;
"@
    return & $sqlite.source $DbPath $query 2>$null
}

Write-Host "Approach 2: SQLite Recursive CTE loaded"
