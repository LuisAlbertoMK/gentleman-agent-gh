---
name: code-review-agent
description: "4R code review — Risk/Readability/Reliability/Resilience with evidence gates and actionable fixes"
triggers: "Code review, CR, revisar código, criticar"
---
4R: each R scored independently→verdict+fixes.

## When: User asks CR·pre-commit complex·pre-merge high-impact PRs

## 4R
R Risk(error/edge/nil/rollback/monitor)30%|Readability(naming/structure/load/patterns)20%|Reliability(retry/timeout/consistency/data/error-prop)25%|Resilience(fault-isolation/backpressure/circuit-breaker/degradation/recovery)25%

## Workflow: `read diff→score 4R→verdict→fixes→evidence`. Sweet spot 200-400L.
✅all R≥7 | 🔶any 4-6 | ❌any <4

## Output
```
## CR:{summary} ### 4R|Risk:X|Read:X|Rel:X|Res:X|Score:X.X|Verdict:✅/🔶/❌
### Fixes:1.file.go:42—handle nil before range
```
Example: `## CR:API auth middleware—nil check+no rate limit ### 4R|Risk:3|Read:7|Rel:5|Res:4|Score:4.8|Verdict:❌ BLOCKER ### Fixes 1.src/middleware/auth.go:42—err not checked. Fix:if err!=nil{return...,fmt.Errorf(...)}. Evidence:err swallowed,nil user proceeds. 2.src/middleware/ratelimit.go:12—hardcoded 1000r/s. Fix:env var,default 100,sliding window. ### Model:claude-4-opus-20260514`

## Adaptive Profile
1.`mem_search("review-profile/{project}")`→load past patterns→adjust lens 2.Run 4R 3.`mem_save(title:"CR profile—{project}#{N}",type:pattern,topic_key:"review-profile/{project}")`

## Rules
1.Score BEFORE fixing. <5→WHY+checklist 2.Clean→"Approved.No issues." 3.Evidence for Rel+Risk 4.≥1 fix per R<6. Any R<4=**BLOCKER** 5.Model+version in every review 6.Adaptive profile 7.diff<50L→surface-read. >400L→"suggest splitting" 8.BLOCKER chain:(a)exact line (b)trace vuln (c)ref lang/runtime (d)concrete fix

### BLOCKER evidence
`src/handler/order.go:88—rows,_:=db.Query(...)` 1.L85 returns error 2.L88 discarded→zero Orders 3.L92 treats empty="no data" 4.L95 UI empty→error toast. Impact:silent data loss. Fix:rows,err:=db.Query(...)+propagate

## Anti-patterns
Vague"looks good"·Only praise·Skip one R·Repeated findings·BLOCKER no chain·Ignore profile·>400L as single unit

## Refs
judgment-day·senior-engineer·skill-improver·quality-gate·triple-verify·engram-protocol
