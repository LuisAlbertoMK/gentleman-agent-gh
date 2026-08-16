---
name: code-review-agent
description: "4R code review - Risk/Readability/Reliability/Resilience with evidence gates and actionable fixes"
triggers: "Code review, CR, revisar codigo, criticar"
changelog: docs/ciclos/cycle28-20260815.md
---
4R: each R scored independently->verdict+fixes.

## When to Use
User asks CR*pre-commit complex*pre-merge high-impact PRs

## 4R
R Risk(err/edge/nil/rollback/monitor)30%|Read(naming/struct/load/patterns)20%|Rel(retry/timeout/consistency/data/err-prop)25%|Res(fault-iso/backpressure/cb/degradation/recovery)25%

## Workflow: `read diff->score 4R->verdict->fixes->evidence`. 200-400L sweet spot.
PASS all R>=7 | WARN any 4-6 | FAIL any <4

## Output: `## CR:sum ### 4R|Risk:X|Read:X|Rel:X|Res:X|Score:X.X|Verdict:P/W/F ### Fixes:1.f:L-fix`
Ex: auth nil check+no rate limit -> Risk:3|Read:7|Rel:5|Res:4|Score:4.8|FAIL BLOCKER

## Adaptive Profile
mem_search("review-profile/{p}")->load->adjust lens->Run 4R->mem_save(title:"CR profile-{p}#{N}",type:pattern,topic_key:"review-profile/{p}")

## Rules
1.Score BEFORE fixing. <5->WHY+checklist 2.Clean->"Approved.No issues." 3.Evidence for Rel+Risk 4.>=1 fix per R<6. Any R<4=**BLOCKER** 5.Model+version 6.Adaptive profile 7.diff<50L->surface-read. >400L->"suggest splitting" 8.BLOCKER chain:(a)line (b)trace vuln (c)ref lang/runtime (d)fix

## Examples (5)
1. Risk Scan: `grep -rn "err!=|_=" src/; grep -rn "panic|Fatal" src/; grep -rn "SELECT.*+|WHERE.*$" src/`
2. Read Gate: func<=25L/cc<=5(30%), single reason(20%), verbNoun(25%), no 5L+ dup(25%) -> 1-10
3. Rel Evidence: `### Rel Fix(Rel:5) File:http.go:42 Issue:no timeout Evidence:client.Get(url) Fix:Timeout=5s Ref:Go no default`
4. Res Check: `grep -rn "circuit|breaker|rate.Limit|fallback" src/` - >=1 hit/service
5. 4R Scorecard: `RISK=$(grep -c "err!=|_=" src/); READ=$(wc -l src/); REL=$(grep -c "timeout|retry" src/); RES=$(grep -c "circuit|fallback" src/)`

## Testing (3)
1. Inter-Rater k>=0.7: 2 reviewers x10 PRs -> `python -c "import sklearn.metrics as m; print(m.cohen_kappa_score(r1,r2))"`
2. FP Rate <15%: log `|Finding|File:Line|FP?|Pattern|Action|` over 20 reviews
3. BLOCKER Recall 100%: seed 5 vulns (err discard, SQLi, no timeout, no breaker, panic) -> all FAIL with chain

## Edge Cases (4)
1. Legacy: No NEW BLOCKER -> WARN TECH-DEBT - doc nil, add timeout wrapper, breaker in v2
2. Vendor/Gen: `generated`/`vendor/` path -> SKIP - add `// code-review:skip`
3. Sec vs Speed: Race<1ms, +40% -> WARN ACCEPTED IF (a) doc (b) metrics alert (c) flag rollback
4. Config/Schema: Rel gate only: default+validation+doc -> PASS (Risk/Res unchanged)

## Anti-patterns (2)
| Pattern | Detect | Fix |
|---|---|---|
| Rubber-stamp | Missing `### 4R|Risk:` | Reject; require template |
| Bikeshedding | Nits>3 && Risk>=7 unchanged | "Focus Risk/Rel first" |
| Cargo-cult | Fixes lack `Evidence:`/`Ref:` | "Add evidence per Rule 3" |

## Refs
judgment-day*skill-improver*quality-gate*triple-verify*engram-protocol