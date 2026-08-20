---
name: adversarial-breaker
description: "Adversarial verification — fixer→breaker chain. Independent offensive agent."
triggers: "adversarial, breaker, !breaker, verify fix, romper, verificar fix, try to break, offensive verification"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
fixer done+ROJA/AMARILLA(auth/storage/API)+not config-only. Skip:VERDE·non-code·comments·docs. Token-save:diff<10L+config/lock/docs.

## Protocol
1.Bundle:diff+files+fixer_claims+test_results+zone+pipeline_mode
2.Engram:`mem_search("breaker/{target}")`→`## Past Attack Context`
3.Zone:`review-rules.jsonc`. AMARILLA+auth→ROJA
4.Profiles:by ext. `.agents/attack-surface.{project}.md`→inject
5.Pre-reg:`git stash`→tests→pop. Break→`PRE-BREAK`
6.Dispatch:diff>50/ROJA→Parallel Break-7(3). Else→single
7.Launch:breaker-briefing+profile(s)+past+bundle
8.Parse:4-field. Parallel→merge. <3→FAIL→rerun
9.Calibrate:depth/relevance/coverage/specificity
10.Verdict:calibration-adjusted+PRE-BREAK flag
11.R2:if FIX→Round 2
12.Record:Engram+test cases

## Engram
Query:`mem_search("breaker/{target}")`→past→`## Past Attack Context\nBroken{N}x:\n-R{r}({d}):{s}—{vec}`
Record:`title:"breaker:{t}:R{r}" type:discovery content:{what,why,learned:[V,F,Cal,Verdict]}`. FAIL→test case `Input/Expected/Actual/Path/Guard` `topic_key:"breaker/{t}/testcase"`. 3+→immune-system.

## Calibration
D:1-3"pass null"|4-7null/empty/boundary|8-10null+race+injection. Rel:1-3Generic|4-7Domain|8-10Targeted. Cov:<50%|50-80%|All+P7/P6. Spec:generic|`'OR1=1--`|Input→path→actual
Adj:≥8Confirm|5-7Cautious(FIX→BLOCK,user)|<5Override→FAIL→rerun

## Parallel Break-7
ROJA→3|AMARILLA+diff>50→3|≤50→Single|VERDE→Skip
Security:injection/auth/leakage/traversal P1,P3,P6,P7|Logic:edge/concurrency/type P1,P2,P4,P5,P6|Regression:caller/contract P7+trace
Merge:collect→dedup→CRITICAL→BLOCK,2+same→BLOCK→calibrate. 1timeout→2. 2+→single. 3→FAIL→escalate

## Verdicts
AllPASS→APPROVED|1-2minor→FIX|Critical→BLOCK|<3/malformed→FAIL|Timeout→ESCALATE
`AB-{t}|R:{N}/2|A:{n}|SAFE/BROKEN|V:{v}`
## R2&Esc: new diff after fix; both diffs—R1+new. `##R2—Focus:{R1}`. Max2. Escalate:Target/Rounds/Pipeline/Chain/Blocker/Rec

## Integration
quality-gate(BEFORE)|triple-verify(AFTER)|judgment-day|subagent-isolation|external-auditor(BLOCK→confirm)|immune-system(repeated→fix)
Projects:`.agents/attack-surface.{project}.md`+`.agents/breaker-profiles/{project}/`

## Anti-Patterns
Breaker trusts fixer·No attempts·3+r·Before QG·4R review·Happy path·Non-code/tiny diffs·No pre-reg·No test cases·Generic surface

## Examples
`!breaker auth-refactor` → `AB-auth-refactor|R:1/2|A:3|SAFE|V:APPROVED` (all P1-P7 pass, cal≥8). BROKEN→fixer gets `##R2—Focus:{R1}`→re-run.

## Testing
1. Pre-reg: dirty→`git stash`→tests→`git stash pop`→diff empty. 2. Verdict: missing `V:`→FAIL, never APPROVED. 3. Engram: `mem_search` returns `## Past Attack Context` with `Broken{N}x:`.