#requires -Version 5.1
<# .SYNOPSIS Resolve relevant skills for any task using dependency graph — sparse loading #>
param($T="",[ValidateRange(0,3)][int]$E=1,[switch]$L,[switch]$R,[ValidateSet("Text","Json","Csv")]$F="Text")
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$D=@'
n,c,e,t,d,de,r
karpathy-loop,c,m,"karpathy,context compression,compact prompt,optimize prompt,less tokens","Karpathy"
lean-context,c,l,"compact,less tokens,caveman,minimal context","Lean"
execution-mode,c,l,"execution mode,quick,thorough,draft","Exec",
skill-digestion,c,l,"skill digestion,compact on load,compress skill","Digest",
quality-gate,q,m,"quality gate,pre-commit,validate commit","Gate",,"auto-metrics,commit-crafter"
auto-metrics,q,m,"auto-score,metrics,post-task,evaluate","PostEval",skill-validate,
immune-system,q,h,"immune system,anti-pattern,permanent immunity,bug,fix,error","Immunity"
code-review-agent,q,m,"code review,CR,review code","CodeRev",best-practices,
skill-testing,q,m,"test skill,verify skill,coverage","TestCov"
skill-validate,q,m,"skill validation,benchmark,multi-trial","Bench"
judgment-day,q,h,"judgment day,dual review","JudgeDay"
session-resume,m,m,"resume,session start,git state","Resume",dreaming,
code-memory,m,m,"code memory,memory,multi-session","Mem",,"session-resume,dreaming"
dreaming,m,h,"dreaming,cross-session,pattern extraction,engram","Dream",auto-metrics,
bitacora,m,l,"bitacora,historial,request log","Log"
metricas,m,l,"metricas,before after,percent improvement,delta","Metrics"
decision-capture,m,m,"decision,trade-off,decision log","Decisions"
skill-creator,x,m,"create skill,new skill","Create"
skill-registry,x,m,"skill registry,catalog","Registry"
skill-improver,x,m,"skill improvement,audit skills,refactor skills","Improve"
gap-analysis,x,h,"gap analysis,system audit,project intake","Gap",,"project-mapper,security-scanner"
commit-crafter,o,l,"commit,commit message,conventional commit","Commit",,quality-gate
refactoring-planner,o,m,"refactor,refactoring,migrate","Refactor"
project-mapper,o,m,"project map,structure,tech stack","Map",,gap-analysis
security-scanner,o,m,"security,audit,vulnerability","SecScan",best-practices,
performance-tracker,o,m,"performance score,benchmark,app score","Perf"
sdd,s,m,"SDD pipeline,spec-driven development","SDD",,"sdd-init,sdd-explore,sdd-propose,sdd-spec,sdd-design,sdd-tasks,sdd-apply,sdd-verify,sdd-archive"
sdd-init,s,m,"SDD init,bootstrap project","SDDinit"
sdd-explore,s,m,"explore codebase,pre-design,codebase exploration","Explore"
sdd-propose,s,m,"proposal,change proposal","Propose",sdd-explore,
sdd-spec,s,m,"specs,Given When Then","Spec",sdd-propose,
sdd-design,s,m,"technical design,HOW","Design",sdd-spec,
sdd-tasks,s,m,"task breakdown,implementation plan","Tasks",sdd-design,
sdd-apply,s,m,"apply tasks,implement","Apply",sdd-tasks,commit-crafter
sdd-verify,s,m,"validate vs specs,verify","Verify",sdd-spec,
sdd-archive,s,m,"archive changes","Archive","sdd-verify,sdd-apply",
sdd-onboard,s,m,"SDD onboard,onboarding,guia SDD","Guide"
delivery-harness,r,h,"multi-agent,orchestrate,coordinate,delegate","AgentOrch","subagent-isolation,work-unit-commits",chained-pr
chained-pr,r,m,"stacked PR,chained PR,sequential branches","ChainedPR","work-unit-commits","delivery-harness,branch-pr"
branch-pr,r,m,"branch PR,create PR","BranchPR",,"chained-pr,issue-creation"
issue-creation,r,m,"create issue,GitHub issue","Issue",,branch-pr
subagent-isolation,r,m,"subagent isolation,context boundaries","SubIso"
command-wrapper,r,l,"command wrapper,safe execution,error handling","CmdWrap"
accessibility,w,m,"accessibility,a11y,WCAG","a11y"
performance,w,m,"web performance,page speed,speed up","Perf"
seo,w,m,"SEO,search engine,meta tags","SEO"
best-practices,w,m,"best practices,code quality,security","BP"
web-quality-audit,w,m,"web quality audit,lighthouse","WebAudit","accessibility,performance,seo,best-practices",
development-mode,w,m,"performance mode,dev mode,rendimiento","DevMode"
research,h,m,"research,investigation","Research"
recovery-protocol,z,m,"recovery,bug,fix,error,frustration","Recovery"
context-watchdog,z,m,"context overflow,token limit","Watchdog"
ci-cd,z,m,"CI/CD,GitHub Actions,pipeline","CI/CD"
work-unit-commits,z,l,"work-unit,commit organization","WUC"
self-improvement,z,h,"self-improvement,auto-improve,inter 30,cycle","SelfImprov",,"self-reflection,dreaming"
self-reflection,z,m,"self-reflection,Hermes,reflection","Reflect"
cognitive-doc-design,z,m,"doc design,cognitive load","DocDesign"
comment-writer,z,l,"comment writer,PR feedback","Comment"
senior-engineer,z,h,"senior architect,system design,trade-offs","SrEng"
prompt-engineering,z,m,"prompt engineering,ReAct,multi-agent","PromptEng"
go-testing,z,m,"Go tests,golang","GoTest"
python-async,z,m,"Python async,asyncio","AsyncPy"
'@
$r=$D|ConvertFrom-Csv|%{[PSCustomObject]@{Name=$_.n;Category=$_.c;Effort=$_.e;Triggers=if($_.t){@($_.t-split',')}else{@()};DependsOn=if($_.de){@($_.de-split',')}else{@()};Related=if($_.r){@($_.r-split',')}else{@()};Description=$_.d}}
