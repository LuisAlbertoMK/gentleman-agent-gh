---
name: code-review-agent
description: "4R code review - Risk/Readability/Reliability/Resilience with evidence gates and actionable fixes"
triggers: "Code review, CR, revisar codigo, criticar"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2381
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
## Anti-patterns (2)
| Pattern | Detect | Fix |
|---|---|---|
| Rubber-stamp | Missing `### 4R|Risk:` | Reject; require template |
| Bikeshedding | Nits>3 && Risk>=7 unchanged | "Focus Risk/Rel first" |
| Cargo-cult | Fixes lack `Evidence:`/`Ref:` | "Add evidence per Rule 3" |
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
judgment-day*skill-improver*quality-gate*triple-verify*engram-protocol
## Reference
Examples (5) + Testing (3) → docs/skills/code-review-agent/reference.md

