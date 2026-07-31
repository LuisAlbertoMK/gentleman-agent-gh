#requires -Version 5.1
<#
.SYNOPSIS
    Skill dependency graph - sparse loading resolver
.PARAMETER Task
    Natural language task description to resolve relevant skills
.PARAMETER Expand
    Graph expansion depth (0-3, default 1)
.PARAMETER ListAll
    List all registered skills grouped by category
.PARAMETER RecommendAgent
    Recommend agent skills for a given task
.PARAMETER Format
    Output format: Text (default), Json, or Csv
.PARAMETER Quiet
    Suppress informational messages
#>
param(
    [string]$Task = "",
    [ValidateRange(0, 3)][int]$Expand = 1,
    [switch]$ListAll,
    [switch]$RecommendAgent,
    [ValidateSet("Text", "Json", "Csv")][string]$Format = "Text",
    [switch]$Quiet,
    [string]$PatternsFile = ""
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# Registry — compact array format [name, triggers, category, effort, deps, related, desc]
# ============================================================================
$registryCsv = Join-Path (Split-Path $PSScriptRoot -Parent) 'data/skills-registry.csv'




$validCategories = @('meta','quality','coordination','code-ops','specialized','testing','web-quality','memory','documents','compression','performance','research','SDD')
$validEfforts = @('low','medium','high')

$skillRegistry = foreach ($line in (Get-Content $registryCsv | Select-Object -Skip 1 | Where-Object { $_.Trim() })) {
    $parts = $line.Split('|')
    $name = $parts[0]
    $len = $parts.Length

    # Description = always last field
    $descIdx = $len - 1

    # Find Effort by scanning from end for known values (stop at first match)
    $effIdx = -1
    for ($i = $descIdx - 1; $i -ge 1; $i--) {
        $v = $parts[$i].Trim().ToLowerInvariant()
        if ($v -in $validEfforts) { $effIdx = $i; break }
    }

    # Find Category by scanning from effort position backwards for known values
    $catIdx = -1
    if ($effIdx -gt 0) {
        for ($i = $effIdx - 1; $i -ge 1; $i--) {
            $v = $parts[$i].Trim()
            if ($v -in $validCategories) { $catIdx = $i; break }
        }
    }

    # Triggers = fields between Name and Category (positions 1..catIdx-1)
    $triggers = if ($catIdx -gt 1) { ($parts[1..($catIdx-1)] -join '|') } else { '' }

    # DependsOn = non-empty fields between Effort and Description
    # NOTE: Related cannot be distinguished from DependsOn in pipe-delimited format
    # (both can contain pipes). All mid-fields go into DependsOn.
    $midFields = @()
    if ($effIdx -gt 0) {
        for ($i = $effIdx + 1; $i -lt $descIdx; $i++) {
            if ($parts[$i].Trim() -ne '') { $midFields += $parts[$i] }
        }
    }

    [PSCustomObject]@{
        Name        = $name
        Triggers    = $triggers
        Category    = if ($catIdx -gt 0) { $parts[$catIdx] } else { '' }
        Effort      = if ($effIdx -gt 0) { $parts[$effIdx] } else { '' }
        DependsOn   = ($midFields -join '|')
        Related     = ''
        Description = $parts[$descIdx]
    }
}

# ============================================================================
# Graph — build adjacency graph from registry
# ============================================================================
function New-Graph {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $graph = @{Nodes = @{}; AdjList = @{}}
    foreach ($skill in $skillRegistry) {
        $name = $skill.Name
        $graph.Nodes[$name] = $skill
        $graph.AdjList[$name] = @{to = @{}; from = @{}}
    }
    foreach ($skill in $skillRegistry) {
        foreach ($dep in ($skill.DependsOn -split '\|')) {
            if ($dep -and $graph.AdjList.ContainsKey($dep)) {
                $graph.AdjList[$dep].to[$skill.Name] = "depends_on"
                $graph.AdjList[$skill.Name].from[$dep] = "depended_by"
            }
        }
        # NOTE: Related field is always empty in pipe-delimited format
        # (cannot distinguish deps from related when both contain pipes)
    }
    if ($PSCmdlet.ShouldProcess('skill dependency graph', 'Build graph')) {
        return $graph
    }
    return $null
}

# ============================================================================
# Resolver — BFS graph resolution from task text
# ============================================================================
function Resolve-Skill {
    param([string]$TaskText, [int]$MaxDepth = 1)
    $Tokens = $TaskText.ToLowerInvariant() -split '\s+|[-_/.,!?;:()]' |
        Where-Object { $_.Length -gt 2 } | Select-Object -Unique
    $SkillScores = @{}
    foreach ($skill in $skillRegistry) {
        $matchCount = 0
        foreach ($token in $Tokens) {
            $pattern = [regex]::Escape($token)
            foreach ($trigger in ($skill.Triggers -split '\|')) {
                if ($trigger.ToLowerInvariant() -match $pattern) { $matchCount++; break }
            }
        }
        if ($matchCount -gt 0) { $SkillScores[$skill.Name] = $matchCount }
    }
    if ($externalPatterns.Count -gt 0) {
        foreach ($pattern in $externalPatterns) {
            $patternMatched = $false
            foreach ($kw in $pattern.keywords) {
                foreach ($token in $Tokens) {
                    if ($token -match [regex]::Escape($kw.ToLowerInvariant())) { $patternMatched = $true; break }
                }
                if ($patternMatched) { break }
            }
            if ($patternMatched -and $pattern.boost) {
                if ($SkillScores.ContainsKey($pattern.boost)) { $SkillScores[$pattern.boost] += 2 } else { $SkillScores[$pattern.boost] = 2 }
            }
        }
    }
    $MatchedNames = $SkillScores.Keys | Sort-Object { [int]$SkillScores[$_] } -Descending
    $Graph = New-Graph
    $Visited = @{}; $Queue = [System.Collections.Queue]::new(); $Depths = @{}
    foreach ($name in $MatchedNames) { $Queue.Enqueue($name); $Depths[$name] = 0; $Visited[$name] = $true }
    while ($Queue.Count -gt 0) {
        $current = $Queue.Dequeue()
        if ($Depths[$current] -ge $MaxDepth) { continue }
        foreach ($neighbor in $Graph.AdjList[$current].to.Keys) {
            if (-not $Visited[$neighbor]) { $Visited[$neighbor] = $true; $Depths[$neighbor] = $Depths[$current] + 1; $Queue.Enqueue($neighbor) }
        }
    }
    $skillLookup = @{}; foreach ($skill in $skillRegistry) { $skillLookup[$skill.Name] = $skill }
    $Visited.Keys | ForEach-Object {
        $skill = $skillLookup[$_]
        [PSCustomObject]@{
            Name = $_; Score = if ($SkillScores.ContainsKey($_)) { $SkillScores[$_] } else { 0 }
            Depth = $Depths[$_]; DependsOn = $skill.DependsOn; Related = $skill.Related
            Category = $skill.Category; Effort = $skill.Effort; Description = $skill.Description
        }
    } | Sort-Object Depth, { -$_.Score }
}

# ============================================================================
# Agent Recommender — regex pattern matching
# ============================================================================
$agentRecommendations = @(
    @{ P = '(?i)(?:review|audit|check|quality|verify|validate)\s.*(?:code|security|skill|pr)'; S = @('code-review-agent', 'security-scanner', 'quality-gate', 'triple-verify') }
    @{ P = '(?i)(?:fix|bug|error|crash|issue|problem|broken|not\s+working)'; S = @('recovery-protocol', 'immune-system', 'triple-verify') }
    @{ P = '(?i)(?:design|architecture|plan|propose|proposal)'; S = @('senior-engineer', 'sdd-propose', 'sdd-design') }
    @{ P = '(?i)(?:test|testing|coverage|spec|specification)'; S = @('skill-testing', 'sdd-spec', 'sdd-verify') }
    @{ P = '(?i)(?:doc|documentation|readme|guide|manual|help)'; S = @('cognitive-doc-design') }
    @{ P = '(?i)(?:commit|pr|pull.request|merge|ship|push)'; S = @('commit-crafter', 'quality-gate', 'branch-pr', 'chained-pr') }
    @{ P = '(?i)(?:deploy|ci|cd|pipeline|github.action|release)'; S = @('ci-cd', 'command-wrapper') }
    @{ P = '(?i)(?:refactor|restructur|clean|migrat|extract)'; S = @('refactoring-planner', 'lean-context') }
    @{ P = '(?i)(?:performance|speed|slow|lazy|load\s+time|render|optimize|compress)'; S = @('karpathy-loop', 'performance', 'lean-context') }
    @{ P = '(?i)(?:accessib|a11y|wcad|screen\s+reader)'; S = @('accessibility') }
    @{ P = '(?i)(?:seo|search|meta|sitemap|structured.data)'; S = @('seo') }
    @{ P = '(?i)(?:research|investigar|compare|evaluate|learn)'; S = @('research', 'prompt-engineering') }
    @{ P = '(?i)(?:mapear|map|project\s+structure|tech\s+stack|audit\s+project)'; S = @('project-mapper', 'gap-analysis') }
)

function Get-AgentRecommendation {
    param([string]$TaskText)
    $seen = @{}; $recommended = @()
    foreach ($rec in $agentRecommendations) {
        if ($TaskText -match $rec.P) {
            foreach ($s in $rec.S) { if (-not $seen[$s]) { $seen[$s] = $true; $recommended += $s } }
        }
    }
    if ($recommended.Count -eq 0) {
        $resolved = @(Resolve-Skill $TaskText 1)
        $recommended = @($resolved | Where-Object { $_.Depth -eq 0 } | Sort-Object Score -Descending | ForEach-Object { $_.Name })
    }
    return @($recommended)
}

# ============================================================================
# Patterns — load external patterns from dreaming feed
# ============================================================================
$externalPatterns = @()
if ($PatternsFile -and (Test-Path $PatternsFile)) {
    try {
        $patternData = Get-Content $PatternsFile -Raw | ConvertFrom-Json
        if ($patternData.patterns) { $externalPatterns = $patternData.patterns }
    } catch { Write-Debug "skill-graph: $($_.Exception.Message)" }
}

# ============================================================================
# Output
# ============================================================================
$skillLookup = @{}; foreach ($skill in $skillRegistry) { $skillLookup[$skill.Name] = $skill }

if ($ListAll) {
    $grouped = $skillRegistry | Group-Object Category
    if ($Format -eq "Json") {
        $grouped | ForEach-Object {
            @{ Category = $_.Name; Skills = @($_.Group | Sort-Object Name | ForEach-Object { @{ Name = $_.Name; Effort = $_.Effort } }) }
        } | ConvertTo-Json -Depth 3
        exit 0
    }
    foreach ($group in $grouped) {
        if (-not $Quiet) { Write-Host ("`n[" + $group.Name.ToUpper() + "]  (" + $group.Count + " skills)") -ForegroundColor Green }
        $group.Group | Sort-Object Name | ForEach-Object {
            $depString = if ($_.DependsOn) { "  deps: " + $_.DependsOn } else { "" }
            Write-Host ("  " + $_.Name + $depString) -ForegroundColor White
        }
    }
    if (-not $Quiet) { Write-Host ("`nTotal: " + $skillRegistry.Count + " skills") -ForegroundColor Cyan }
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Task)) {
    if (-not $Quiet) {
        Write-Host "Usage:" -ForegroundColor Yellow
        Write-Host "  .\scripts\skill-graph.ps1 -Task `"<task>`" [-Expand N] [-Format Json|Csv]" -ForegroundColor Cyan
        Write-Host "  .\scripts\skill-graph.ps1 -ListAll [-Format Json|Csv]" -ForegroundColor Cyan
        Write-Host ("`nRegistry: " + $skillRegistry.Count + " skills") -ForegroundColor Green
    }
    exit 0
}

if ($RecommendAgent) {
    $recommended = @(Get-AgentRecommendation $Task)
    if ($Format -eq "Json") { @{ Task = $Task; Recommendations = $recommended } | ConvertTo-Json; exit 0 }
    if (-not $Quiet) { Write-Host ("Recommendations for: $Task") -ForegroundColor Cyan }
    $recommended | ForEach-Object { Write-Host ("  skill: $_") -ForegroundColor White }
    exit 0
}

$resolved = @(Resolve-Skill $Task $Expand)
if ($Format -eq "Json") { $resolved | Select-Object Name, Score, Depth, Category, Effort, Description | ConvertTo-Json -Depth 2; exit 0 }
if ($Format -eq "Csv") { $resolved | Select-Object Name, Score, Depth, Category, Effort | ConvertTo-Csv -NoTypeInformation; exit 0 }
if ($resolved.Count -eq 0) { if (-not $Quiet) { Write-Host ("No matching skills for: $Task") -ForegroundColor Yellow }; exit 0 }
if (-not $Quiet) { Write-Host ("Skills for: $Task  (depth=$Expand)") -ForegroundColor Cyan }
$resolved | ForEach-Object {
    $depthMarker = if ($_.Depth -gt 0) { " hop=$($_.Depth)" } else { "" }
    Write-Host ("  " + $_.Name + " [score=$($_.Score)]" + $depthMarker) -ForegroundColor White
}
if (-not $Quiet) { Write-Host ("`n(" + $resolved.Count + " skills resolved)") -ForegroundColor Green }
