# SDD Change Proposal: gentleman-jd-patterns

## Intent
Implement mechanical wiring for Zylos judge patterns 2/3/4/5 via ONE new script `scripts/jd-verifier.ps1` + Pester tests + minimal SKILL.md pointers. Pattern 6 (IRM) stays "future" (no model infra).

## Scope (In / Out)

### In — New Files
- `scripts/jd-verifier.ps1` — #requires 7, [CmdletBinding()], params: -Zone <ROJA|AMARILLA>, -Rounds <int> default 0, -FastPath switch, -RepeatFinding switch, -RepoRoot <string> default repo root, -Json switch
- `scripts/tests/jd-verifier.Tests.ps1` — Pester tests with PESTER_TEST=1 isolation (no repo mutation)
- `references/jd-patterns-wiring.md` — ~30 lines externalized wiring detail (keeps SKILL.md ≤4620B)

### In — Modified Files
- `.agents/skills/judgment-day/SKILL.md` — append ≤2 lines in Protocol pointing to script + reference; append changelog frontmatter "; 2026-09-01 wiring jd-verifier.ps1 (p2/p4/p5 enforcement)"
- `docs/sdd/registry.yaml` — register this change (archive phase)

### Out
- No changes to `bin/fast.exe`, `review-pipeline`, `code-review-agent`, or `immune-system` skill internals
- No model infra for Pattern 6 (IRM)
- No modifications to `.githooks/`, `opencode.json`, or existing scripts

## Approach

### Script Behavior (`scripts/jd-verifier.ps1`)
- **-FastPath**: Run `bin/fast.exe --gate --json` if exe exists → if passed && elapsedMs≤162 → output "VERIFY-OK mechanical (<ms>ms)" else "ESCALATE dual-judge"; exe missing → ESCALATE with warn
- **-Rounds >2**: Exit code 2 + "ASK-USER (Reflexion cap)"
- **-RepeatFinding**: Output "CONSTITUTIONAL → register via immune-system (.agents/skills/immune-system)"
- **Always**: Output "SELF-CONSISTENCY: profiles A/B = majority-of-2 (diverge → tie-break by higher severity)" guidance line
- **-Json**: Emit `{verifier, zone, fastPath:{ran, passed, elapsedMs, decision}, rounds:{value, capped}, constitutional, timestamp}`

### Pester Tests (`scripts/tests/jd-verifier.Tests.ps1`)
- Fixture: RepoRoot without `bin/` → ESCALATE
- Fixture: Fake `fast.exe` stub emitting passed/elapsedMs JSON → VERIFY-OK path + ESCALATE path
- Rounds cap → exit 2
- RepeatFinding output
- -Json schema keys validated
- PESTER_TEST=1 must not mutate repo

### SKILL.md Budget Invariant
- Current: 4478B / 4620B limit
- Add ≤2 short lines in Protocol section pointing to script + reference
- Externalize ~30 lines wiring detail to `references/jd-patterns-wiring.md`
- MUST keep SKILL.md ≤4620B (shrink elsewhere by trimming redundancy if needed — do NOT delete taxonomy table)

## Risks
- **SKILL.md budget**: 4478B is tight vs 4620B limit; adding even 2 lines risks overflow — must trim redundancy elsewhere (e.g., Reference Materials section, Red Flags table) without removing taxonomy
- **fast.exe dependency**: Script assumes `bin/fast.exe` exists for fast-path; missing exe must ESCALATE cleanly without throwing — tested via fixture without bin/

## Proposal Path
`docs/sdd/changes/gentleman-jd-patterns/proposal.md`