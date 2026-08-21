---
name: adversarial-breaker
description: "Adversarial verification — fixer→breaker chain. Independent offensive agent."
triggers: "adversarial, breaker, !breaker, verify fix, romper, verificar fix, try to break, offensive verification"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1752
---
## When to Use
fixer done+ROJA/AMARILLA(auth/storage/API)+not config-only. Skip:VERDE·non-code·comments·docs. Token-save:diff<10L+config/lock/docs.
## Protocol
1.Bundle:diff+files+fixer_claims+test_results+zone+pipeline_mode
2.Engram:`mem_search("breaker/{target}")`→`## Past Attack Context`
3.Zone:`review-rules.jsonc`. AMARILLA+auth→ROJA
4.Profiles: `.agents/attack-surface.{project}.md`→inject
5.Pre-reg:`git stash`→tests→pop. Break→`PRE-BREAK`
6.Dispatch:diff>50/ROJA→Parallel Break-7(3). Else→single
7.Launch:breaker-briefing+profile(s)+past+bundle
8.Parse:4-field. Parallel→merge. <3→FAIL→rerun
9.Calibrate:depth/relevance/coverage/specificity
10.Verdict:adjusted+PRE-BREAK
11.R2:FIX→round 2
12.Record:Engram+test cases
## Verdicts
AllPASS→APPROVED|1-2minor→FIX|Critical→BLOCK|<3/malformed→FAIL|Timeout→ESCALATE
`AB-{t}|R:{N}/2|A:{n}|SAFE/BROKEN|V:{v}`
## R2&Esc
new diff after fix; both diffs—R1+new. `##R2—Focus:{R1}`. Max2. Escalate:Target/Rounds/Pipeline/Chain/Blocker/Rec
## Integration
quality-gate(BEFORE)|triple-verify(AFTER)|judgment-day|subagent-isolation|external-auditor(BLOCK→confirm)|immune-system(repeated→fix)
Projects:`.agents/attack-surface.{project}.md`+`.agents/breaker-profiles/{project}/`
## Anti-Patterns
Breaker trusts fixer·No attempts·3+r·Before QG·4R review·Happy path·Non-code/tiny diffs·No pre-reg·No test cases·Generic surface
> docs/skills/adversarial-breaker/reference.md