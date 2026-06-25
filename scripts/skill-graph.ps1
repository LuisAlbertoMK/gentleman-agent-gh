#requires -Version 5.1
<# .SYNOPSIS Skill dependency graph - sparse loading resolver #>
param([string]$Task="",[ValidateRange(0,3)][int]$Expand=1,[switch]$ListAll,[switch]$RecommendAgent,[ValidateSet("Text","Json","Csv")][string]$Format="Text")
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$skillRegistry=@()
function Add-Skill { param([string]$Name,[string[]]$Triggers,[string]$Category="general",[ValidateSet("low","medium","high")][string]$Effort="medium",[string[]]$DependsOn=@(),[string[]]$Related=@(),[string]$Description=""); $script:skillRegistry+=[PSCustomObject]@{Name=$Name;Triggers=$Triggers;Category=$Category;DependsOn=$DependsOn;Related=$Related;Description=$Description;Effort=$Effort} }
try {
Add-Skill "karpathy-loop" @("karpathy","less tokens","context compression","compact prompt","karpathy loop","optimize prompt","measure tokens") compression low @() @() "Karpathy-style compression + iterative loop"
Add-Skill "lean-context" @("compact","less tokens","caveman","ultra-lean","minimal context") compression low @() @() "Ultra-lean context mode"
Add-Skill "execution-mode" @("execution mode","quick","thorough","draft","modo") compression low @() @() "Quick/Thorough/Draft execution modes"
Add-Skill "skill-digestion" @("skill digestion","compact on load","compress skill") compression low @() @() "Digest and compact skills when loaded"
Add-Skill "caveman" @("caveman","ultra-lean","compression","minimal context","emergency mode") compression low @() @() "Ultra-minimal compressed context mode - L3 emergency"
Add-Skill "quality-gate" @("quality gate","pre-commit","validate commit") quality medium @() @("auto-metrics","commit-crafter") "Pre-commit quality gate"
Add-Skill "auto-metrics" @("auto-score","metrics","post-task","evaluate","self-evaluate") quality medium @("skill-validate") @() "Post-task self-evaluation with 7-dim scoring"
Add-Skill "immune-system" @("immune system","anti-pattern","permanent immunity","nunca mas","bug","fix","error") quality high @() @() "Permanent immunity catalog for repeated errors"
Add-Skill "code-review-agent" @("code review","CR","revisar codigo","review code") quality medium @("best-practices") @() "Automated code review with standards"
Add-Skill "skill-testing" @("test skill","verify skill","coverage","skill test") quality medium @() @() "Test and verify skill coverage"
Add-Skill "skill-validate" @("skill validation","benchmark","multi-trial","validate skill","3 trials") quality medium @() @() "3-trial benchmark validation"
Add-Skill "judgment-day" @("judgment day","dual review","juzgar","evaluar skill") quality high @() @() "Dual review and judgment for skills"
Add-Skill "triple-verify" @("triple verify","triangulate","3 enfoques","verificacion profunda","!ship","!listo","!fast","!draft") quality high @() @() "Triple verification - 3 enfoques, thresholds por zona"
Add-Skill "external-auditor" @("external audit","blind review","second opinion","verifica mi auto-score","contralor externo") quality medium @() @() "Blind second-opinion audit via subagent"
Add-Skill "review-pipeline" @("review pipeline","skill stacking","full review","preparar commit","ready to ship","listo para commit") quality medium @() @() "Skill stacking: quality-gate to 4R code-review to commit-crafter"
Add-Skill "session-resume" @("resume","donde lo dejamos","continua","session start","git state") memory medium @("dreaming") @() "Safe session resume with git state gate"
Add-Skill "code-memory" @("code memory","memory","recordar","acordate","multi-session") memory medium @() @("session-resume","dreaming") "Cross-session code memory and recall"
Add-Skill "dreaming" @("dreaming","cross-session","pattern extraction","memory curation","engram") memory high @("auto-metrics") @() "Cross-session pattern extraction via Engram"
Add-Skill "bitacora" @("bitacora","historial","historico","request log") memory low @() @() "Session activity log and history tracking"
Add-Skill "metricas" @("metricas","before after","percent improvement","delta") memory low @() @() "Before/after metrics tracking for improvements"
Add-Skill "decision-capture" @("decision","trade-off","decision log") memory medium @() @() "Capture and log architectural decisions"
Add-Skill "skill-creator" @("create skill","new skill","crear skill") meta medium @() @() "Create new AI skills from requirements"
Add-Skill "skill-registry" @("skill registry","catalog","registro skills") meta medium @() @() "Skill registry management and catalog"
Add-Skill "skill-improver" @("skill improvement","audit skills","refactor skills") meta medium @() @() "Audit and improve existing skills"
Add-Skill "skill-graph" @("sparse loading","skill resolution","relevant skills","which skill","resolver skill","minimo skills") meta low @() @() "Sparse loading - resolve only relevant skills + dependencies"
Add-Skill "gap-analysis" @("gap analysis","system audit","identificar gaps","project intake") meta high @() @("project-mapper","security-scanner") "Complete 8-dim gap analysis"
Add-Skill "commit-crafter" @("commit","commit message","conventional commit") code-ops low @() @("quality-gate") "Craft conventional commit messages from diff"
Add-Skill "refactoring-planner" @("refactor","refactoring","reestructurar","migrate") code-ops medium @() @() "Plan and execute code refactoring"
Add-Skill "project-mapper" @("mapear","project map","estructura","tech stack") code-ops medium @() @("gap-analysis") "Map project structure, stack, and architecture"
Add-Skill "security-scanner" @("security","seguridad","vulnerabilidad","auditar") code-ops medium @("best-practices") @() "Security audit and vulnerability scanner"
Add-Skill "performance-tracker" @("performance score","mobile perf","desktop perf","rendimiento","app score","benchmark") code-ops medium @() @() "Score and track app performance across 6 dimensions"
Add-Skill "doc-sync" @("doc sync","documentation sync","sync docs","propagate docs") code-ops low @() @() "Sync documentation across repos, branches, and locations"
Add-Skill "sdd" @("SDD pipeline","SDD phase","spec-driven development") SDD medium @() @("sdd-init","sdd-explore","sdd-propose","sdd-spec","sdd-design","sdd-tasks","sdd-apply","sdd-verify","sdd-archive") "Unified SDD pipeline - 9 phases"
Add-Skill "sdd-init" @("SDD init","bootstrap","iniciar SDD") SDD medium @() @() "SDD init - bootstrap project context"
Add-Skill "sdd-explore" @("explore codebase","pre-design","investigar","codebase exploration") SDD medium @() @() "Explore codebase"
Add-Skill "sdd-propose" @("proposal","intent","approach","change proposal") SDD medium @("sdd-explore") @() "Create change proposals"
Add-Skill "sdd-spec" @("specs","specification","Given When Then","requisitos","spec") SDD medium @("sdd-propose") @() "Write specifications from proposals"
Add-Skill "sdd-design" @("technical design","HOW","diseno tecnico") SDD medium @("sdd-spec") @() "Create technical design from specs"
Add-Skill "sdd-tasks" @("task breakdown","implementation plan","tareas","task list") SDD medium @("sdd-design") @() "Break down designs into tasks"
Add-Skill "sdd-apply" @("apply tasks","implement","aplicar") SDD medium @("sdd-tasks") @("commit-crafter") "Apply tasks to implement changes"
Add-Skill "sdd-verify" @("validate vs specs","verify","verificar") SDD medium @("sdd-spec") @() "Validate implementation against specs"
Add-Skill "sdd-archive" @("archive changes","delta to main","archivar") SDD medium @("sdd-verify","sdd-apply") @() "Archive completed changes"
Add-Skill "sdd-onboard" @("SDD onboard","onboarding","nuevo proyecto SDD","guia SDD") SDD medium @() @() "Guide users through complete SDD cycle"
Add-Skill "delivery-harness" @("coordinate","orchestrate","multi-agent","delegate work") coordination high @("subagent-isolation","work-unit-commits") @("chained-pr") "Orchestrate multi-agent work delivery"
Add-Skill "chained-pr" @("stacked PR","chained PR","sequential branches","PR chain") coordination medium @("work-unit-commits") @("delivery-harness","branch-pr") "Manage stacked sequential PRs"
Add-Skill "branch-pr" @("branch PR","branch naming","create PR","open pull request") coordination medium @() @("chained-pr","issue-creation") "Branch creation and PR workflow"
Add-Skill "issue-creation" @("create issue","GitHub issue","bug report","feature request") coordination medium @() @("branch-pr") "GitHub issue creation"
Add-Skill "subagent-isolation" @("subagent isolation","context boundaries","delegation") coordination medium @() @() "Isolate subagent contexts and prevent contamination"
Add-Skill "command-wrapper" @("command wrapper","safe execution","error handling","output parse") coordination low @() @() "Safe command execution with error handling"
Add-Skill "opencode-model-router" @("model router","routing","que modelo","delegate or direct","que hacer con esta tarea","trial risk","security gate") coordination high @() @() "Route tasks by model strength with security gates"
Add-Skill "accessibility" @("accessibility","a11y","WCAG","screen reader","keyboard nav","make accessible") web-quality medium @() @() "Audit and improve web accessibility"
Add-Skill "performance" @("web performance","speed up","reduce load time","page speed","performance audit") web-quality medium @() @() "Optimize web performance"
Add-Skill "seo" @("SEO","search engine","meta tags","structured data","sitemap") web-quality medium @() @() "Optimize for search engine visibility"
Add-Skill "best-practices" @("best practices","security audit","modernize code","code quality review") web-quality medium @() @() "Apply modern web development best practices"
Add-Skill "web-quality-audit" @("web quality audit","lighthouse audit","review web quality") web-quality medium @("accessibility","performance","seo","best-practices") @() "Comprehensive web quality audit"
Add-Skill "development-mode" @("performance mode","dev mode","modo desarrollo","high performance","modo rendimiento") web-quality medium @() @() "System resource prioritization mode"
Add-Skill "baseline-ui" @("ui cleanup","polish interface","fix layout","ui slop","generic ui","design review") web-quality medium @("accessibility") @() "Anti-slop UI enforcement"
Add-Skill "research" @("research","investigar","technical investigation","learn","compare solutions","evaluate") research medium @() @() "Structured research workflow for technical investigations"
Add-Skill "recovery-protocol" @("recovery","no es eso","frustration","stuck","bloqueado","bug","fix","error") specialized medium @() @() "Recovery protocol for frustration and errors"
Add-Skill "context-watchdog" @("context overflow","token limit","context explosion") specialized medium @() @() "Monitor and prevent context window overflow"
Add-Skill "ci-cd" @("CI/CD","pipeline","GitHub Actions","continuous integration") specialized medium @() @() "CI/CD pipeline automation"
Add-Skill "work-unit-commits" @("work-unit","commit organization") specialized low @() @() "Organize commits into logical work units"
Add-Skill "self-improvement" @("self-improvement","improvement cycle","auto-improve","inter 30","cycle") specialized high @() @("self-reflection","dreaming") "Self-improvement cycle with inter(30) minimum"
Add-Skill "self-reflection" @("self-reflection","Hermes","error patterns","reflexion") specialized medium @() @() "Hermes closed learning loop"
Add-Skill "cognitive-doc-design" @("doc design","documentation patterns","cognitive load","progressive disclosure") specialized medium @() @() "Design docs that reduce cognitive load"
Add-Skill "comment-writer" @("comment writer","PR feedback","review comment","write feedback") specialized low @() @() "Write warm, direct collaboration comments"
Add-Skill "senior-engineer" @("senior architect","trade-offs","system design","arquitectura") specialized high @() @() "Senior engineer persona for architecture decisions"
Add-Skill "prompt-engineering" @("improve prompt","ReAct","multi-agent","prompt engineering") specialized medium @() @() "Advanced prompt engineering techniques"
Add-Skill "go-testing" @("Go tests","Bubbletea TUI","golang test") specialized medium @() @() "Go testing patterns and tools"
Add-Skill "python-async" @("Python async","asyncio") specialized medium @() @() "Python async/await patterns"
} catch { Write-Error "registry build failed: $_"; exit 1 }

# Graph functions
function New-Graph {
    $g = @{ Nodes = @{}; AdjList = @{} }
    foreach ($s in $script:skillRegistry) { $name = $s.Name; $g.Nodes[$name] = $s; $g.AdjList[$name] = @{ to = @{}; from = @{} } }
    foreach ($s in $script:skillRegistry) {
        foreach ($dep in $s.DependsOn) { if ($g.AdjList.ContainsKey($dep)) { $g.AdjList[$dep].to[$s.Name] = "depends_on"; $g.AdjList[$s.Name].from[$dep] = "depended_by" } }
        foreach ($rel in $s.Related) { if ($g.AdjList.ContainsKey($rel)) { $g.AdjList[$rel].to[$s.Name] = "related"; $g.AdjList[$s.Name].from[$rel] = "related" } }
    }
    return $g
}

# BFS skill resolution with keyword scoring (tokens>2 chars)
function Resolve-Skill {
    param([string]$TaskText,[int]$MaxDepth=1)
    $tokens = $TaskText.ToLowerInvariant() -split '\s+|[-_/.,!?;:()]' | Where-Object { $_.Length -gt 2 } | Select-Object -Unique
    $scores = @{}
    foreach ($s in $script:skillRegistry) {
        $matchCount = 0
        foreach ($t in $tokens) { $re = [regex]::Escape($t); foreach ($tr in $s.Triggers) { if ($tr.ToLowerInvariant() -match $re) { $matchCount++; break } } }
        if ($matchCount -gt 0) { $scores[$s.Name] = $matchCount }
    }
    $matched = $scores.Keys | Sort-Object { $scores[$_] } -Descending
    $g = New-Graph; $visited = @{}; $queue = [System.Collections.Queue]::new(); $depth = @{}

    foreach ($m in $matched) { $queue.Enqueue($m); $depth[$m] = 0; $visited[$m] = $true }
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($depth[$current] -ge $MaxDepth) { continue }
        foreach ($neighbor in $g.AdjList[$current].to.Keys) {
            if (-not $visited[$neighbor]) { $visited[$neighbor] = $true; $depth[$neighbor] = $depth[$current] + 1; $queue.Enqueue($neighbor) }
        }
    }
    $result = $visited.Keys | ForEach-Object { $s = $script:RegistryLookup[$_]; [PSCustomObject]@{ Name = $_; Score = if ($scores.ContainsKey($_)) { $scores[$_] } else { 0 }; Depth = $depth[$_]; DependsOn = $s.DependsOn; Related = $s.Related; Category = $s.Category; Effort = $s.Effort; Description = $s.Description } }
    return ($result | Sort-Object Depth, { -$_.Score })
}

# Agent routing table (13 regex routes)
$agentRoutes = @(
    @{ Pattern = '(?i)(?:review|audit|check|quality|verify|validate)\s.*(?:code|security|skill|pr)'; Skills = @('code-review-agent','security-scanner','quality-gate','triple-verify') }
    @{ Pattern = '(?i)(?:fix|bug|error|crash|issue|problem|broken|not\s+working)'; Skills = @('recovery-protocol','immune-system','triple-verify') }
    @{ Pattern = '(?i)(?:design|architecture|plan|propose|proposal)'; Skills = @('senior-engineer','sdd-propose','sdd-design') }
    @{ Pattern = '(?i)(?:test|testing|coverage|spec|specification)'; Skills = @('skill-testing','sdd-spec','sdd-verify','go-testing') }
    @{ Pattern = '(?i)(?:doc|documentation|readme|guide|manual|help)'; Skills = @('cognitive-doc-design','doc-sync') }
    @{ Pattern = '(?i)(?:commit|pr|pull.request|merge|ship|push)'; Skills = @('commit-crafter','quality-gate','branch-pr','chained-pr') }
    @{ Pattern = '(?i)(?:deploy|ci|cd|pipeline|github.action|release)'; Skills = @('ci-cd','command-wrapper') }
    @{ Pattern = '(?i)(?:refactor|restructur|clean|migrat|extract)'; Skills = @('refactoring-planner','lean-context') }
    @{ Pattern = '(?i)(?:performance|speed|slow|lazy|load\s+time|render|optimize|compress)'; Skills = @('karpathy-loop','performance','lean-context','caveman') }
    @{ Pattern = '(?i)(?:accessib|a11y|wcad|screen\s+reader)'; Skills = @('accessibility') }
    @{ Pattern = '(?i)(?:seo|search|meta|sitemap|structured.data)'; Skills = @('seo') }
    @{ Pattern = '(?i)(?:research|investigar|compare|evaluate|learn)'; Skills = @('research','prompt-engineering') }
    @{ Pattern = '(?i)(?:mapear|map|project\s+structure|tech\s+stack|audit\s+project)'; Skills = @('project-mapper','gap-analysis') }
)
function Get-AgentRecommendation {
    param([string]$TaskText)
    $result = @()
    foreach ($route in $agentRoutes) { if ($TaskText -match $route.Pattern) { $result += @($route.Skills | Where-Object { $_ -notin $result }) } }
    if ($result.Count -eq 0) {
        $resolved = @(Resolve-Skill -TaskText $TaskText -MaxDepth 1)
        $result = @($resolved | Where-Object Depth -eq 0 | Sort-Object Score -Descending | ForEach-Object { $_.Name })
    }
    return @($result)
}

# Build fast lookup
$script:RegistryLookup = @{}
foreach ($s in $script:skillRegistry) { $script:RegistryLookup[$s.Name] = $s }

if ($ListAll) {
    $groups = $skillRegistry | Group-Object Category
    if ($Format -eq "Json") { $groups | ForEach-Object { $g=$_; @{Category=$g.Name;Skills=@($g.Group|Sort-Object Name|ForEach-Object{@{Name=$_.Name;Effort=$_.Effort;DependsOn=@($_.DependsOn);Related=@($_.Related)}})}} | ConvertTo-Json -Depth 3; exit 0 }
    if ($Format -eq "Csv") { $flat=foreach($g in $groups){foreach($s in $g.Group|Sort-Object Name){[PSCustomObject]@{Category=$g.Name;Skill=$s.Name;Effort=$s.Effort;DependsOn=if($s.DependsOn.Count-gt0){$s.DependsOn-join"; "}else{""};Related=if($s.Related.Count-gt0){$s.Related-join"; "}else{""}}}}; $flat|ConvertTo-Csv -NoTypeInformation; exit 0 }
    foreach ($g in $groups) { Write-Host ("`n["+$g.Name.ToUpper()+"]  ("+$g.Count+" skills)")-ForegroundColor Green; $g.Group|Sort-Object Name|ForEach-Object{$deps=if($_.DependsOn.Count-gt0){"  deps: "+($_.DependsOn-join", ")}else{""};$eff=if($_.Effort-ne"medium"){"  ["+$_.Effort+"]"}else{""};Write-Host ("  "+$_.Name+$eff+$deps)-ForegroundColor White} }; Write-Host ("`nTotal: "+$skillRegistry.Count+" skills in "+$groups.Count+" categories")-ForegroundColor Cyan; exit 0
}
if ([string]::IsNullOrWhiteSpace($Task)) {
    Write-Host "Usage:"-ForegroundColor Yellow
    Write-Host ("  .\scripts\skill-graph.ps1 -Task `"<task>`" [-Expand N] [-Format Json|Csv]")-ForegroundColor Cyan
    Write-Host ("  .\scripts\skill-graph.ps1 -ListAll [-Format Json|Csv]")-ForegroundColor Cyan
    Write-Host ("  .\scripts\skill-graph.ps1 -Task `"<task>`" -RecommendAgent")-ForegroundColor Cyan
    Write-Host ("`nRegistry: "+$skillRegistry.Count+" skills")-ForegroundColor Green; exit 0
}

if ($RecommendAgent) {
    $recs = @(Get-AgentRecommendation -TaskText $Task)
    if ($Format -eq "Json") { @{Task=$Task;Recommendations=$recs;RegistrySize=$skillRegistry.Count} | ConvertTo-Json; exit 0 }
    Write-Host ("Recommendations for: $Task")-ForegroundColor Cyan
    $recs | ForEach-Object { Write-Host ("  skill: $_")-ForegroundColor White }
    Write-Host ("`n("+$recs.Count+" skills recommended)")-ForegroundColor Green; exit 0
}

$resolved = @(Resolve-Skill -TaskText $Task -MaxDepth $Expand)
if ($Format -eq "Json") { $resolved | Select-Object Name,Score,Depth,Category,Effort,Description | ConvertTo-Json -Depth 2; exit 0 }
if ($Format -eq "Csv") { $resolved | Select-Object Name,Score,Depth,Category,Effort | ConvertTo-Csv -NoTypeInformation; exit 0 }
if ($resolved.Count -eq 0) { Write-Host "No matching skills for: $Task"-ForegroundColor Yellow; exit 0 }
Write-Host ("Skills for: $Task  (depth=$Expand)")-ForegroundColor Cyan
$resolved | ForEach-Object { $d=if($_.Depth -gt 0){" hop=$($_.Depth)"}else{""}; Write-Host ("  "+$_.Name+" [score=$($_.Score)]$d")-ForegroundColor White }
Write-Host ("`n("+$resolved.Count+" skills resolved)")-ForegroundColor Green
