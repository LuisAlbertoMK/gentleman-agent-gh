# code-review-agent — Reference Materials

> **Externalized from** .agents/skills/code-review-agent/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains worked examples and testing patterns.

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

## Externalized Sections (ADR-007 compression)
## Edge Cases (4)
1. Legacy: No NEW BLOCKER -> WARN TECH-DEBT - doc nil, add timeout wrapper, breaker in v2
2. Vendor/Gen: `generated`/`vendor/` path -> SKIP - add `// code-review:skip`
3. Sec vs Speed: Race<1ms, +40% -> WARN ACCEPTED IF (a) doc (b) metrics alert (c) flag rollback
4. Config/Schema: Rel gate only: default+validation+doc -> PASS (Risk/Res unchanged)
