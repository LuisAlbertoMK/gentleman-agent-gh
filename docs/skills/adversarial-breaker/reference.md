# adversarial-breaker — Reference Materials

> **Externalized from** .agents/skills/adversarial-breaker/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains Engram/calibration/parallel-dispatch detail and worked examples.

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

## Examples
`!breaker auth-refactor` → `AB-auth-refactor|R:1/2|A:3|SAFE|V:APPROVED` (all P1-P7 pass, cal≥8). BROKEN→fixer gets `##R2—Focus:{R1}`→re-run.

## Testing
1. Pre-reg: dirty→`git stash`→tests→`git stash pop`→diff empty. 2. Verdict: missing `V:`→FAIL, never APPROVED. 3. Engram: `mem_search` returns `## Past Attack Context` with `Broken{N}x:`.
