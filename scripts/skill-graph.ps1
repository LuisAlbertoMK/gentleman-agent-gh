#requires -Version 5.1

<#
.SYNOPSIS
  Skill dependency graph - resolve skills by task keywords.
.PARAMETER Task
  Keywords to resolve skills for.
.PARAMETER Expand
  Dep hops (default:1, max:3).
.PARAMETER ListAll
  List all skills.
.PARAMETER Format
  Output format: Text|Json|Csv.
#>

param([string]$Task="",[ValidateRange(0,3)][int]$Expand=1,[switch]$ListAll,[switch]$RecommendAgent,[ValidateSet("Text","Json","Csv")][string]$Format="Text")
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'

$csvData = @'
n,c,e,t,d,de,r
karpathy-loop,compression,medium,"karpathy,less tokens,context compression,compact prompt,Karpathy prompt,karpathy loop,optimize prompt,measure tokens,self-improve prompt","Karpathy-style compression + iterative loop for prompts (merged karpathy-prompt)",,
lean-context,compression,low,"compact,less tokens,caveman,caveman,ultra-lean,minimal context","Ultra-lean context mode",,
execution-mode,compression,low,"execution mode,quick,thorough,draft,modo","Quick or Thorough or Draft execution modes",,
skill-digestion,compression,low,"skill digestion,compact on load,compress skill","Digest and compact skills when loaded",,
quality-gate,quality,medium,"quality gate,pre-commit,validate commit","Pre-commit quality gate with 5 checks",,"auto-metrics,commit-crafter"
auto-metrics,quality,medium,"auto-score,metrics,post-task,evaluate,self-evaluate","Post-task self-evaluation with 7-dim scoring",skill-validate,
immune-system,quality,high,"immune system,anti-pattern,permanent immunity,nunca mas,bug,fix,error","Permanent immunity catalog for repeated errors",,
code-review-agent,quality,medium,"code review,CR,revisar codigo,review code","Automated code review with standards",best-practices,
skill-testing,quality,medium,"test skill,verify skill,coverage,skill test","Test and verify skill coverage",,
skill-validate,quality,medium,"skill validation,benchmark,multi-trial,validate skill,3 trials","3-trial benchmark validation for skills",,
judgment-day,quality,high,"judgment day,dual review,juzgar,evaluar skill","Dual review and judgment for skills",,
session-resume,memory,medium,"resume,donde lo dejamos,continua,session start,git state","Safe session resume with git state gate",dreaming,
code-memory,memory,medium,"code memory,memory,recordar,acordate,multi-session","Cross-session code memory and recall",,"session-resume,dreaming"
dreaming,memory,high,"dreaming,cross-session,pattern extraction,memory curation,engram","Cross-session pattern extraction via Engram",auto-metrics,
bitacora,memory,low,"bitacora,historial,historico,request log","Session activity log and history tracking",,
metricas,memory,low,"metricas,before or after,percent improvement,delta","Before or after metrics tracking for improvements",,
decision-capture,memory,medium,"decision,trade-off,decision log","Capture and log architectural decisions",,
skill-creator,meta,medium,"create skill,new skill,crear skill","Create new AI skills from requirements",,
skill-registry,meta,medium,"skill registry,catalog,registro skills","Skill registry management and catalog",,
skill-improver,meta,medium,"skill improvement,audit skills,refactor skills","Audit and improve existing skills",,
gap-analysis,meta,high,"gap analysis,system audit,identificar gaps,project intake","Complete 8-dim gap analysis for any system",,"project-mapper,security-scanner"
commit-crafter,code-ops,low,"commit,commit message,conventional commit","Craft conventional commit messages from diff",,quality-gate
refactoring-planner,code-ops,medium,"refactor,refactoring,reestructurar,migrate","Plan and execute code refactoring",,
project-mapper,code-ops,medium,"mapear,project map,estructura,tech stack","Map project structure, stack, and architecture",,gap-analysis
security-scanner,code-ops,medium,"security,seguridad,vulnerabilidad,auditar","Security audit and vulnerability scanner",best-practices,
performance-tracker,code-ops,medium,"performance score,mobile perf,desktop perf,rendimiento,app score,benchmark","Score and track app performance across 6 dimensions",,
sdd,SDD,medium,"SDD pipeline,SDD phase,spec-driven development","Unified SDD pipeline -- 9 phases (init->archive)",,"sdd-init,sdd-explore,sdd-propose,sdd-spec,sdd-design,sdd-tasks,sdd-apply,sdd-verify,sdd-archive"
sdd-init,SDD,medium,"SDD init,bootstrap,iniciar SDD","SDD init -- bootstrap project context (wrapper, canonical at sdd/phases/00-init.md)",,
sdd-explore,SDD,medium,"explore codebase,pre-design,investigar,codebase exploration","Explore codebase (wrapper, canonical at sdd/phases/01-explore.md)",,
sdd-propose,SDD,medium,"proposal,intent,approach,change proposal","Create change proposals (wrapper, canonical at sdd/phases/02-propose.md)",sdd-explore,
sdd-spec,SDD,medium,"specs,specification,Given When Then,requisitos,spec","Write specifications from proposals (wrapper, canonical at sdd/phases/04-spec.md)",sdd-propose,
sdd-design,SDD,medium,"technical design,HOW,diseno tecnico","Create technical design from specs (wrapper, canonical at sdd/phases/03-design.md)",sdd-spec,
sdd-tasks,SDD,medium,"task breakdown,implementation plan,tareas,task list","Break down designs into tasks (wrapper, canonical at sdd/phases/05-tasks.md)",sdd-design,
sdd-apply,SDD,medium,"apply tasks,implement,aplicar","Apply tasks to implement changes (wrapper, canonical at sdd/phases/06-apply.md)",sdd-tasks,commit-crafter
sdd-verify,SDD,medium,"validate vs specs,verify,verificar","Validate implementation against specs (wrapper, canonical at sdd/phases/07-verify.md)",sdd-spec,
sdd-archive,SDD,medium,"archive changes,delta to main,archivar","Archive completed changes (wrapper, canonical at sdd/phases/08-archive.md)","sdd-verify,sdd-apply",
sdd-onboard,SDD,medium,"SDD onboard,onboarding,nuevo proyecto SDD,guia SDD","Guide users through complete SDD cycle",,
delivery-harness,coordination,high,"coordinate,orchestrate,multi-agent,delegate work","Orchestrate multi-agent work delivery","subagent-isolation,work-unit-commits",chained-pr
chained-pr,coordination,medium,"stacked PR,chained PR,sequential branches,PR chain","Manage stacked sequential PRs (refs: chaining-details.md)",work-unit-commits,"delivery-harness,branch-pr"
branch-pr,coordination,medium,"branch PR,branch naming,create PR,open pull request","Branch creation and PR workflow for gentle-ai",,"chained-pr,issue-creation"
issue-creation,coordination,medium,"create issue,GitHub issue,bug report,feature request","GitHub issue creation with issue-first workflow for gentle-ai",,branch-pr
subagent-isolation,coordination,medium,"subagent isolation,context boundaries,delegation","Isolate subagent contexts and prevent contamination",,
command-wrapper,coordination,low,"command wrapper,safe execution,error handling,output parse","Safe command execution with error handling",,
accessibility,web-quality,medium,"accessibility,a11y,WCAG,screen reader,keyboard nav,make accessible","Audit and improve web accessibility",,
performance,web-quality,medium,"web performance,speed up,reduce load time,page speed,performance audit","Optimize web performance for faster loading",,
seo,web-quality,medium,"SEO,search engine,meta tags,structured data,sitemap","Optimize for search engine visibility",,
best-practices,web-quality,medium,"best practices,security audit,modernize code,code quality review","Apply modern web development best practices",,
web-quality-audit,web-quality,medium,"web quality audit,lighthouse audit,review web quality","Comprehensive web quality audit","accessibility,performance,seo,best-practices",
development-mode,web-quality,medium,"performance mode,dev mode,modo desarrollo,high performance,modo rendimiento","System resource prioritization mode",,
research,research,medium,"research,investigar,technical investigation,learn,compare solutions,evaluate","Structured research workflow for technical investigations",,
recovery-protocol,specialized,medium,"recovery,no es eso,frustration,stuck,bloqueado,bug,fix,error","Recovery protocol for frustration and errors",,
context-watchdog,specialized,medium,"context overflow,token limit,context explosion","Monitor and prevent context window overflow",,
ci-cd,specialized,medium,"CI/CD,pipeline,GitHub Actions,continuous integration","CI/CD pipeline automation",,
work-unit-commits,specialized,low,"work-unit,commit organization","Organize commits into logical work units",,
self-improvement,specialized,high,"self-improvement,improvement cycle,auto-improve,inter 30,cycle","Self-improvement cycle with inter(30) minimum",,"self-reflection,dreaming"
self-reflection,specialized,medium,"self-reflection,Hermes,error patterns,reflexion","Hermes closed learning loop",,
cognitive-doc-design,specialized,medium,"doc design,documentation patterns,cognitive load,progressive disclosure","Design docs that reduce cognitive load",,
comment-writer,specialized,low,"comment writer,PR feedback,review comment,write feedback","Write warm, direct collaboration comments",,
senior-engineer,specialized,high,"senior architect,trade-offs,system design,arquitectura","Senior engineer persona for architecture decisions",,
prompt-engineering,specialized,medium,"improve prompt,ReAct,multi-agent,prompt engineering","Advanced prompt engineering techniques",,
go-testing,specialized,medium,"Go tests,Bubbletea TUI,golang test","Go testing patterns and tools",,
python-async,specialized,medium,"Python async,asyncio","Python async/await patterns",,
'@
$script:skillRegistry = $csvData | ForEach-Object {
    [PSCustomObject]@{
        Name=$_.n;Category=$_.c;Effort=$_.e
        Triggers=if($_.t){@($_.t-split',')}else{@()}
        DependsOn=if($_.de){@($_.de-split',')}else{@()}
        Related=if($_.r){@($_.r-split',')}else{@()}
        Description=$_.d
    }
}
