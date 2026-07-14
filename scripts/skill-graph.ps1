#requires -Version 7.6

<#
.SYNOPSIS
    Skill dependency graph - sparse loading resolver

.PARAMETER Task
    Natural language task description to resolve relevant skills

.PARAMETER Expand
    Graph expansion depth (0-3, default 1). Controls how many hops of
    dependencies to include in results

.PARAMETER ListAll
    List all registered skills grouped by category

.PARAMETER RecommendAgent
    Recommend agent skills for a given task using regex pattern matching

.PARAMETER Format
    Output format: Text (default), Json, or Csv

.PARAMETER Quiet
    Suppress informational messages, output raw data only
#>

param(
    [string]$Task = "",
    [ValidateRange(0, 3)][int]$Expand = 1,
    [switch]$ListAll,
    [switch]$RecommendAgent,
    [ValidateSet("Text", "Json", "Csv")][string]$Format = "Text",
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# Registry — skill definitions
# ============================================================================

$skillRegistry = @()

function Register-Skill(
    $Name,
    $TriggersRaw,
    $Category,
    $Effort,
    $DependsOnRaw,
    $RelatedRaw,
    $Description
) {
    $script:skillRegistry += [PSCustomObject]@{
        Name        = $Name
        Triggers    = $TriggersRaw.Split('|')
        Category    = $Category
        DependsOn   = if ($DependsOnRaw) { , $DependsOnRaw.Split('|') } else { , @() }
        Related     = if ($RelatedRaw) { , $RelatedRaw.Split('|') } else { , @() }
        Description = $Description
        Effort      = $Effort
    }
}

# --- compression ---
Register-Skill karpathy-loop "karpathy|less tokens|context compression|compact prompt|karpathy loop|optimize prompt|measure tokens" compression low "" "" "Karpathy-style compression + iterative loop"
Register-Skill lean-context "compact|less tokens|caveman|ultra-lean|minimal context" compression low "" "" "Ultra-lean context mode"
Register-Skill execution-mode "execution mode|quick|thorough|draft|modo" compression low "" "" "Quick/Thorough/Draft execution modes"


# --- quality ---
Register-Skill quality-gate "quality gate|pre-commit|validate commit" quality medium "" "auto-metrics|commit-crafter" "Pre-commit quality gate"
Register-Skill auto-metrics "auto-score|metrics|post-task|evaluate|self-evaluate" quality medium skill-validate "" "Post-task self-evaluation with 7-dim scoring"
Register-Skill immune-system "immune system|anti-pattern|permanent immunity|nunca mas|bug|fix|error" quality high "" "" "Permanent immunity catalog for repeated errors"
Register-Skill code-review-agent "code review|CR|revisar codigo|review code" quality medium best-practices "" "Automated code review with standards"
Register-Skill skill-testing "test skill|verify skill|coverage|skill test" quality medium "" "" "Test and verify skill coverage"
Register-Skill judgment-day "judgment day|dual review|juzgar|evaluar skill" quality high "" "" "Dual review and judgment for skills"
Register-Skill triple-verify "triple verify|triangulate|3 enfoques|verificacion profunda|!ship|!listo|!fast|!draft" quality high "" "" "Triple verification - 3 enfoques, thresholds por zona"
Register-Skill external-auditor "external audit|blind review|second opinion|verifica mi auto-score|contralor externo" quality medium "" "" "Blind second-opinion audit via subagent"

# --- memory ---
Register-Skill session-resume "session resume|donde lo dejamos|continua|session start|git state|memory|recordar|acordate|multi-session|donde quedamos|handoff" memory medium dreaming "" "Safe session resume with git state gate"

Register-Skill dreaming "dreaming|cross-session|pattern extraction|memory curation|engram" memory high auto-metrics "" "Cross-session pattern extraction via Engram"
Register-Skill bitacora "bitacora|historial|historico|request log" memory low "" "" "Session activity log and history tracking"
Register-Skill metricas "metricas|before after|percent improvement|delta" memory low "" "" "Before/after metrics tracking for improvements"
Register-Skill engram-protocol "engram|persistent memory|mem save|mem search|memory protocol" memory medium "" "" "Persistent memory protocol via Engram MCP"


# --- meta ---
Register-Skill skill-creator "create skill|new skill|crear skill" meta medium "" "" "Create new AI skills from requirements"
Register-Skill skill-registry "skill registry|catalog|registro skills" meta medium "" "" "Skill registry management and catalog"
Register-Skill skill-improver "skill improvement|audit skills|refactor skills" meta medium "" "" "Audit and improve existing skills"
Register-Skill skill-graph "sparse loading|skill resolution|relevant skills|which skill|resolver skill|minimo skills" meta low "" "" "Sparse loading - resolve only relevant skills + dependencies"
Register-Skill gap-analysis "gap analysis|system audit|identificar gaps|project intake" meta high "project-mapper|security-scanner" "" "Complete 8-dim gap analysis"
Register-Skill cross-project-forge "forge|promote pattern|auto-skill|forjar|convertir patron|skill desde patron" meta medium "" "" "Promote recurring patterns to auto-generated skills"
Register-Skill cross-project-wisdom "patterns|wisdom|lesson learned|in another project|last time this|cross-project|retrospectiva|experiencia previa|!wisdom|pattern guard" meta low "" "" "Load patterns from prior projects"
Register-Skill external-improvement "5 fases|extimprove|external improvement|mejora externa" meta high "" "" "5-phase improvement cycle for external projects"
Register-Skill opencode-skill-creator "create opencode skill|opencode skill|new opencode skill" meta medium "" "" "Create OpenCode-specific skills with intake interview"

# --- code-ops ---
Register-Skill commit-crafter "commit|commit message|conventional commit" code-ops low "" "quality-gate" "Craft conventional commit messages from diff"
Register-Skill refactoring-planner "refactor|refactoring|reestructurar|migrate" code-ops medium "" "" "Plan and execute code refactoring"
Register-Skill project-mapper "mapear|project map|estructura|tech stack" code-ops medium "" "gap-analysis" "Map project structure, stack, and architecture"
Register-Skill security-scanner "security|seguridad|vulnerabilidad|auditar" code-ops medium best-practices "" "Security audit and vulnerability scanner"
Register-Skill performance-tracker "performance score|mobile perf|desktop perf|rendimiento|app score|benchmark" code-ops medium "" "" "Score and track app performance across 6 dimensions"


# --- SDD ---
Register-Skill sdd "SDD pipeline|SDD phase|spec-driven development" SDD medium "" "sdd-init|sdd-explore|sdd-propose|sdd-spec|sdd-design|sdd-tasks|sdd-apply|sdd-verify|sdd-archive" "Unified SDD pipeline - 9 phases"
Register-Skill sdd-quick "SDD quick|fast path|quick SDD|low risk SDD|simple change SDD" SDD low "" "sdd-propose|sdd-apply|sdd-verify" "3-phase fast path for LOW-risk changes"
Register-Skill sdd-init "SDD init|bootstrap|iniciar SDD" SDD medium "" "" "SDD init - bootstrap project context"
Register-Skill sdd-explore "explore codebase|pre-design|investigar|codebase exploration" SDD medium "" "" "Explore codebase"
Register-Skill sdd-propose "proposal|intent|approach|change proposal" SDD medium sdd-explore "" "Create change proposals"
Register-Skill sdd-spec "specs|specification|Given When Then|requisitos|spec" SDD medium sdd-propose "" "Write specifications from proposals"
Register-Skill sdd-design "technical design|HOW|diseno tecnico" SDD medium sdd-spec "" "Create technical design from specs"
Register-Skill sdd-tasks "task breakdown|implementation plan|tareas|task list" SDD medium sdd-design "" "Break down designs into tasks"
Register-Skill sdd-apply "apply tasks|implement|aplicar" SDD medium sdd-tasks "commit-crafter" "Apply tasks to implement changes"
Register-Skill sdd-verify "validate vs specs|verify|verificar" SDD medium sdd-spec "" "Validate implementation against specs"
Register-Skill sdd-archive "archive changes|delta to main|archivar" SDD medium "sdd-verify|sdd-apply" "" "Archive completed changes"


# --- coordination ---
Register-Skill delivery-harness "coordinate|orchestrate|multi-agent|delegate work" coordination high "subagent-isolation|work-unit-commits" "chained-pr" "Orchestrate multi-agent work delivery"
Register-Skill chained-pr "stacked PR|chained PR|sequential branches|PR chain" coordination medium work-unit-commits "delivery-harness|branch-pr" "Manage stacked sequential PRs"
Register-Skill branch-pr "branch PR|branch naming|create PR|open pull request" coordination medium "" "chained-pr|issue-creation" "Branch creation and PR workflow"
Register-Skill issue-creation "create issue|GitHub issue|bug report|feature request" coordination medium "" branch-pr "GitHub issue creation"
Register-Skill subagent-isolation "subagent isolation|context boundaries|delegation" coordination medium "" "" "Isolate subagent contexts and prevent contamination"
Register-Skill command-wrapper "command wrapper|safe execution|error handling|output parse" coordination low "" "" "Safe command execution with error handling"
Register-Skill opencode-model-router "model router|routing|que modelo|delegate or direct|que hacer con esta tarea|trial risk|security gate" coordination high "" "" "Route tasks by model strength with security gates"
Register-Skill ralph-loop "ralph loop|auto-continue|keep going|continue task|loop until done" coordination medium "" "" "Auto-continues until task completion"
Register-Skill cancel-ralph "cancel ralph|stop loop|abort loop|cancel auto" coordination low "" "" "Cancel active Ralph Loop"

# --- web-quality ---
Register-Skill accessibility "accessibility|a11y|WCAG|screen reader|keyboard nav|make accessible" web-quality medium "" "" "Audit and improve web accessibility"
Register-Skill performance "web performance|speed up|reduce load time|page speed|performance audit" web-quality medium "" "" "Optimize web performance"
Register-Skill seo "SEO|search engine|meta tags|structured data|sitemap" web-quality medium "" "" "Optimize for search engine visibility"
Register-Skill best-practices "best practices|security audit|modernize code|code quality review" web-quality medium "" "" "Apply modern web development best practices"
Register-Skill web-quality-audit "web quality audit|lighthouse audit|review web quality" web-quality medium "accessibility|performance|seo|best-practices" "" "Comprehensive web quality audit"
Register-Skill development-mode "performance mode|dev mode|modo desarrollo|high performance|modo rendimiento" web-quality medium "" "" "System resource prioritization mode"
Register-Skill baseline-ui "ui cleanup|polish interface|fix layout|ui slop|generic ui|design review|baseline ui|anti-slop" web-quality medium accessibility "" "Anti-slop UI enforcement"
Register-Skill ui-engine "ui system|grid|flexbox|container queries|oklch|tokens|animation|compositor" web-quality medium "" "" "UI system — Grid/Flexbox/@layer/:has(), container queries, compositor-only animation, OKLCH tokens"

# --- visual/images/documents ---
Register-Skill visual-testing "screenshot|visual diff|visual bug|regression test|VRT|UI broken|text overflow|layout shift|responsive test" testing medium "" "" "Visual verification — screenshots, visual regression, UI bug detection"
Register-Skill image-pipeline "compress image|optimize image|resize image|convert webp|convert avif|describe image|image too heavy|slow images|image bug" performance medium "" "" "Image optimization — compress, convert, resize, describe"
Register-Skill pdf-utils "PDF|extract PDF|parse PDF|merge PDF|generate PDF|PDF table|PDF invoice|read PDF|PDF to text|PDF to markdown" documents medium "" "" "PDF processing — extract text, parse tables, generate reports"

# --- research ---
Register-Skill research "research|investigar|technical investigation|learn|compare solutions|evaluate" research medium "" "" "Structured research workflow for technical investigations"

# --- specialized ---
Register-Skill recovery-protocol "recovery|no es eso|frustration|stuck|bloqueado|bug|fix|error" specialized medium "" "" "Recovery protocol for frustration and errors"
Register-Skill context-watchdog "context overflow|token limit|context explosion" specialized medium "" "" "Monitor and prevent context window overflow"
Register-Skill ci-cd "CI/CD|pipeline|GitHub Actions|continuous integration" specialized medium "" "" "CI/CD pipeline automation"
Register-Skill work-unit-commits "work-unit|commit organization" specialized low "" "" "Organize commits into logical work units"
Register-Skill self-improvement "self-improvement|improvement cycle|auto-improve|inter 30|cycle|self-reflection|Hermes|error patterns|reflexion" specialized high "" "dreaming" "Self-improvement cycle with inter(30) minimum + per-task reflection"
Register-Skill cognitive-doc-design "doc design|documentation patterns|cognitive load|progressive disclosure" specialized medium "" "" "Design docs that reduce cognitive load"
Register-Skill comment-writer "comment writer|PR feedback|review comment|write feedback" specialized low "" "" "Write warm, direct collaboration comments"
Register-Skill senior-engineer "senior architect|trade-offs|system design|arquitectura" specialized high "" "" "Senior engineer persona for architecture decisions"
Register-Skill prompt-engineering "improve prompt|ReAct|multi-agent|prompt engineering" specialized medium "" "" "Advanced prompt engineering techniques"
Register-Skill help "ralph help|commands|plugin help|available commands" specialized low "" "" "Explain Ralph Loop plugin and available commands"
Register-Skill vision-analyze "vision analyze|image analysis|screenshot analysis|visual inspection|describe screenshot" testing medium "" "" "Local vision analysis — screenshots, UI review, error detection via Ollama"
Register-Skill workflow-optimizer "workflow optimize|process optimize|streamline|reduce steps|automate workflow" specialized low "" "" "Optimize workflow patterns — faster info access, reduced token waste"


# ============================================================================
# Graph — build adjacency graph from registry
# ============================================================================

function New-Graph {
    $graph = @{Nodes = @{}; AdjList = @{}}

    foreach ($skill in $skillRegistry) {
        $name = $skill.Name
        $graph.Nodes[$name] = $skill
        $graph.AdjList[$name] = @{to = @{}; from = @{}}
    }

    foreach ($skill in $skillRegistry) {
        foreach ($dep in $skill.DependsOn) {
            if ($graph.AdjList.ContainsKey($dep)) {
                $graph.AdjList[$dep].to[$skill.Name] = "depends_on"
                $graph.AdjList[$skill.Name].from[$dep] = "depended_by"
            }
        }
        foreach ($rel in $skill.Related) {
            if ($graph.AdjList.ContainsKey($rel)) {
                $graph.AdjList[$rel].to[$skill.Name] = "related"
                $graph.AdjList[$skill.Name].from[$rel] = "related"
            }
        }
    }

    return $graph
}

# ============================================================================
# Resolver — BFS graph resolution from task text
# ============================================================================

function Resolve-Skill {
    param(
        [string]$TaskText,
        [int]$MaxDepth = 1
    )

    $Tokens = $TaskText.ToLowerInvariant() -split '\s+|[-_/.,!?;:()]' |
        Where-Object { $_.Length -gt 2 } |
        Select-Object -Unique

    $SkillScores = @{}
    $MatchResults = $skillRegistry | ForEach-Object -Parallel {
        $matchCount = 0
        $tokens = $using:Tokens
        foreach ($token in $tokens) {
            $pattern = [regex]::Escape($token)
            foreach ($trigger in $_.Triggers) {
                if ($trigger.ToLowerInvariant() -match $pattern) {
                    $matchCount++
                    break
                }
            }
        }
        if ($matchCount -gt 0) {
            [PSCustomObject]@{Name = $_.Name; MatchCount = $matchCount}
        }
    } -ThrottleLimit ([Math]::Max(2, [int]([Environment]::ProcessorCount / 2)))

    foreach ($match in $MatchResults) {
        if ($match) {
            $SkillScores[$match.Name] = $match.MatchCount
        }
    }

    $MatchedNames = $SkillScores.Keys |
        Sort-Object { $SkillScores[$_] } -Descending

    $Graph = New-Graph
    $Visited = @{}
    $Queue = [System.Collections.Queue]::new()
    $Depths = @{}

    foreach ($name in $MatchedNames) {
        $Queue.Enqueue($name)
        $Depths[$name] = 0
        $Visited[$name] = $true
    }

    while ($Queue.Count -gt 0) {
        $current = $Queue.Dequeue()
        if ($Depths[$current] -ge $MaxDepth) { continue }

        foreach ($neighbor in $Graph.AdjList[$current].to.Keys) {
            if (-not $Visited[$neighbor]) {
                $Visited[$neighbor] = $true
                $Depths[$neighbor] = $Depths[$current] + 1
                $Queue.Enqueue($neighbor)
            }
        }
    }

    $results = $Visited.Keys | ForEach-Object {
        $skill = $skillLookup[$_]
        [PSCustomObject]@{
            Name        = $_
            Score       = if ($SkillScores.ContainsKey($_)) { $SkillScores[$_] } else { 0 }
            Depth       = $Depths[$_]
            DependsOn   = $skill.DependsOn
            Related     = $skill.Related
            Category    = $skill.Category
            Effort      = $skill.Effort
            Description = $skill.Description
        }
    }

    return ($results | Sort-Object Depth, { -$_.Score })
}

# ============================================================================
# Agent Recommender — regex pattern matching against task text
# ============================================================================

$agentRecommendations = @(
    @{
        P = '(?i)(?:review|audit|check|quality|verify|validate)\s.*(?:code|security|skill|pr)'
        S = @('code-review-agent', 'security-scanner', 'quality-gate', 'triple-verify')
    }
    @{
        P = '(?i)(?:fix|bug|error|crash|issue|problem|broken|not\s+working)'
        S = @('recovery-protocol', 'immune-system', 'triple-verify')
    }
    @{
        P = '(?i)(?:design|architecture|plan|propose|proposal)'
        S = @('senior-engineer', 'sdd-propose', 'sdd-design')
    }
    @{
        P = '(?i)(?:test|testing|coverage|spec|specification)'
        S = @('skill-testing', 'sdd-spec', 'sdd-verify', 'go-testing')
    }
    @{
        P = '(?i)(?:doc|documentation|readme|guide|manual|help)'
        S = @('cognitive-doc-design', 'doc-sync')
    }
    @{
        P = '(?i)(?:commit|pr|pull.request|merge|ship|push)'
        S = @('commit-crafter', 'quality-gate', 'branch-pr', 'chained-pr')
    }
    @{
        P = '(?i)(?:deploy|ci|cd|pipeline|github.action|release)'
        S = @('ci-cd', 'command-wrapper')
    }
    @{
        P = '(?i)(?:refactor|restructur|clean|migrat|extract)'
        S = @('refactoring-planner', 'lean-context')
    }
    @{
        P = '(?i)(?:performance|speed|slow|lazy|load\s+time|render|optimize|compress)'
        S = @('karpathy-loop', 'performance', 'lean-context', 'caveman')
    }
    @{
        P = '(?i)(?:accessib|a11y|wcad|screen\s+reader)'
        S = @('accessibility')
    }
    @{
        P = '(?i)(?:seo|search|meta|sitemap|structured.data)'
        S = @('seo')
    }
    @{
        P = '(?i)(?:research|investigar|compare|evaluate|learn)'
        S = @('research', 'prompt-engineering')
    }
    @{
        P = '(?i)(?:mapear|map|project\s+structure|tech\s+stack|audit\s+project)'
        S = @('project-mapper', 'gap-analysis')
    }
)

function Get-AgentRecommendation {
    param([string]$TaskText)

    $results = $agentRecommendations | ForEach-Object -Parallel {
        if ($using:TaskText -match $_.P) { $_.S }
    } -ThrottleLimit ([Math]::Max(2, [int]([Environment]::ProcessorCount / 2)))

    $recommended = @($results | Where-Object { $_ } | Select-Object -Unique)

    if ($recommended.Count -eq 0) {
        $resolved = @(Resolve-Skill $TaskText 1)
        $recommended = @($resolved | Where-Object { $_.Depth -eq 0 } |
            Sort-Object Score -Descending | ForEach-Object { $_.Name })
    }

    return @($recommended)
}

# ============================================================================
# Lookup table — name -> skill object (used by Resolve-Skill)
# ============================================================================

$skillLookup = @{}
foreach ($skill in $skillRegistry) {
    $skillLookup[$skill.Name] = $skill
}

# ============================================================================
# Output
# ============================================================================

if ($ListAll) {
    $grouped = $skillRegistry | Group-Object Category

    if ($Format -eq "Json") {
        $grouped | ForEach-Object {
            $group = $_
            @{
                Category = $group.Name
                Skills   = @($group.Group | Sort-Object Name | ForEach-Object {
                        @{
                            Name      = $_.Name
                            Effort    = $_.Effort
                            DependsOn = @($_.DependsOn)
                            Related   = @($_.Related)
                        }
                    })
            }
        } | ConvertTo-Json -Depth 3
        exit 0
    }

    if ($Format -eq "Csv") {
        $flatList = foreach ($group in $grouped) {
            foreach ($skill in ($group.Group | Sort-Object Name)) {
                [PSCustomObject]@{
                    Category  = $group.Name
                    Skill     = $skill.Name
                    Effort    = $skill.Effort
                    DependsOn = if ($skill.DependsOn.Count -gt 0) {
                        $skill.DependsOn -join "; "
                    } else { "" }
                    Related   = if ($skill.Related.Count -gt 0) {
                        $skill.Related -join "; "
                    } else { "" }
                }
            }
        }
        $flatList | ConvertTo-Csv -NoTypeInformation
        exit 0
    }

    foreach ($group in $grouped) {
        if (-not $Quiet) {
            Write-Host ("`n[" + $group.Name.ToUpper() + "]  (" + $group.Count + " skills)") -ForegroundColor Green
        }
        $group.Group | Sort-Object Name | ForEach-Object {
            $depString = if ($_.DependsOn.Count -gt 0) {
                "  deps: " + ($_.DependsOn -join ", ")
            } else { "" }
            $effortBadge = if ($_.Effort -ne "medium") {
                "  [" + $_.Effort + "]"
            } else { "" }
            Write-Host ("  " + $_.Name + $effortBadge + $depString) -ForegroundColor White
        }
    }
    if (-not $Quiet) {
        Write-Host ("`nTotal: " + $skillRegistry.Count + " skills in " + $grouped.Count + " categories") -ForegroundColor Cyan
    }
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Task)) {
    if (-not $Quiet) {
        Write-Host "Usage:" -ForegroundColor Yellow
        Write-Host ("  .\scripts\skill-graph.ps1 -Task `"<task>`" [-Expand N] [-Format Json|Csv]") -ForegroundColor Cyan
        Write-Host ("  .\scripts\skill-graph.ps1 -ListAll [-Format Json|Csv]") -ForegroundColor Cyan
        Write-Host ("  .\scripts\skill-graph.ps1 -Task `"<task>`" -RecommendAgent") -ForegroundColor Cyan
        Write-Host ("`nRegistry: " + $skillRegistry.Count + " skills") -ForegroundColor Green
    }
    exit 0
}

if ($RecommendAgent) {
    $recommended = @(Get-AgentRecommendation $Task)
    if ($Format -eq "Json") {
        @{
            Task            = $Task
            Recommendations = $recommended
            RegistrySize    = $skillRegistry.Count
        } | ConvertTo-Json
        exit 0
    }
    if (-not $Quiet) {
        Write-Host ("Recommendations for: $Task") -ForegroundColor Cyan
    }
    $recommended | ForEach-Object {
        Write-Host ("  skill: $_") -ForegroundColor White
    }
    if (-not $Quiet) {
        Write-Host ("`n(" + $recommended.Count + " skills recommended)") -ForegroundColor Green
    }
    exit 0
}

$resolved = @(Resolve-Skill $Task $Expand)

if ($Format -eq "Json") {
    $resolved | Select-Object Name, Score, Depth, Category, Effort, Description |
        ConvertTo-Json -Depth 2
    exit 0
}

if ($Format -eq "Csv") {
    $resolved | Select-Object Name, Score, Depth, Category, Effort |
        ConvertTo-Csv -NoTypeInformation
    exit 0
}

if ($resolved.Count -eq 0) {
    if (-not $Quiet) {
        Write-Host ("No matching skills for: $Task") -ForegroundColor Yellow
    }
    exit 0
}

if (-not $Quiet) {
    Write-Host ("Skills for: $Task  (depth=$Expand)") -ForegroundColor Cyan
}
$resolved | ForEach-Object {
    $depthMarker = if ($_.Depth -gt 0) { " hop=$($_.Depth)" } else { "" }
    Write-Host ("  " + $_.Name + " [score=$($_.Score)]" + $depthMarker) -ForegroundColor White
}
if (-not $Quiet) {
    Write-Host ("`n(" + $resolved.Count + " skills resolved)") -ForegroundColor Green
}
