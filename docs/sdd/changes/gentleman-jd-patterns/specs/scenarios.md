# SDD Delta Spec: gentleman-jd-patterns — Scenarios

## FastPath Scenarios

### Scenario: FastPath — exe exists, passes, within budget
Given `-FastPath` is specified
And `bin/fast.exe` exists at `$RepoRoot/bin/fast.exe`
And `fast.exe --gate --json` returns `{"passed":true,"elapsedMs":97}`
When `jd-verifier.ps1 -Zone ROJA -FastPath -RepoRoot $RepoRoot` runs
Then stdout contains "VERIFY-OK mechanical (97ms)"
And exit code is 0
And if `-Json`: `fastPath.ran=true`, `fastPath.passed=true`, `fastPath.elapsedMs=97`, `fastPath.decision="VERIFY-OK"`

### Scenario: FastPath — exe exists, passes, exceeds budget
Given `-FastPath` is specified
And `bin/fast.exe` exists
And `fast.exe --gate --json` returns `{"passed":true,"elapsedMs":163}`
When `jd-verifier.ps1 -Zone ROJA -FastPath` runs
Then stdout contains "ESCALATE dual-judge"
And exit code is 0
And if `-Json`: `fastPath.decision="ESCALATE"`, `fastPath.elapsedMs=163`

### Scenario: FastPath — exe exists, fails
Given `-FastPath` is specified
And `bin/fast.exe` exists
And `fast.exe --gate --json` returns `{"passed":false,"elapsedMs":120}`
When `jd-verifier.ps1 -Zone ROJA -FastPath` runs
Then stdout contains "ESCALATE dual-judge"
And exit code is 0
And if `-Json`: `fastPath.passed=false`, `fastPath.decision="ESCALATE"`

### Scenario: FastPath — exe missing
Given `-FastPath` is specified
And `bin/fast.exe` does NOT exist at `$RepoRoot/bin/fast.exe`
When `jd-verifier.ps1 -Zone ROJA -FastPath -RepoRoot $RepoRoot` runs
Then stdout contains "ESCALATE dual-judge"
And stderr contains "WARN: bin/fast.exe not found"
And exit code is 0
And if `-Json`: `fastPath.ran=true`, `fastPath.passed=null`, `fastPath.elapsedMs=null`, `fastPath.decision="ESCALATE"`

### Scenario: FastPath — not specified (default)
Given `-FastPath` is NOT specified
When `jd-verifier.ps1 -Zone ROJA` runs
Then no fast.exe is invoked
And if `-Json`: `fastPath.ran=false`, `fastPath.decision="NOT_RUN"`

## Rounds Cap Scenarios

### Scenario: Rounds — within limit (0, 1, 2)
Given `-Rounds 2` (or 1, or 0)
When `jd-verifier.ps1 -Zone ROJA -Rounds 2` runs
Then exit code is NOT 2
And if `-Json`: `rounds.value=2`, `rounds.capped=false`

### Scenario: Rounds — exceeds cap (3+)
Given `-Rounds 3` (or any value > 2)
When `jd-verifier.ps1 -Zone ROJA -Rounds 3` runs
Then stdout contains "ASK-USER (Reflexion cap)"
And exit code is 2
And if `-Json`: `rounds.value=3`, `rounds.capped=true`
And script does NOT proceed to FastPath or other logic

## Constitutional / RepeatFinding Scenarios

### Scenario: RepeatFinding — switch present
Given `-RepeatFinding` is specified
When `jd-verifier.ps1 -Zone ROJA -RepeatFinding` runs
Then stdout contains "CONSTITUTIONAL → register via immune-system (.agents/skills/immune-system)"
And exit code is 0
And if `-Json`: `constitutional=true`

### Scenario: RepeatFinding — switch absent
Given `-RepeatFinding` is NOT specified
When `jd-verifier.ps1 -Zone ROJA` runs
Then stdout does NOT contain "CONSTITUTIONAL"
And if `-Json`: `constitutional=false`

## Self-Consistency Guidance Scenarios

### Scenario: Self-consistency line always present
Given any valid parameter combination
When `jd-verifier.ps1 ...` runs
Then stdout contains exactly once: "SELF-CONSISTENCY: profiles A/B = majority-of-2 (diverge → tie-break by higher severity)"

## Json Output Scenarios

### Scenario: Json — full object with all keys
Given `-Json` and `-FastPath` and `-Rounds 1` and `-RepeatFinding`
And `bin/fast.exe` exists and returns `{"passed":true,"elapsedMs":88}`
When `jd-verifier.ps1 -Zone ROJA -FastPath -Rounds 1 -RepeatFinding -Json` runs
Then stdout is valid JSON with all 7 top-level keys
And `verifier="jd-verifier"`
And `zone="ROJA"`
And `fastPath.ran=true`, `fastPath.passed=true`, `fastPath.elapsedMs=88`, `fastPath.decision="VERIFY-OK"`
And `rounds.value=1`, `rounds.capped=false`
And `constitutional=true`
And `timestamp` matches ISO8601 regex

### Scenario: Json — AMARILLA zone
Given `-Json -Zone AMARILLA -FastPath`
And `bin/fast.exe` missing
When `jd-verifier.ps1 -Zone AMARILLA -FastPath -Json` runs
Then `zone="AMARILLA"` in output
And `fastPath.decision="ESCALATE"`

## Pester Test Scenarios

### Scenario: Test — fixture without bin/ (ESCALATE path)
Given test runs with `PESTER_TEST=1`
And temp RepoRoot has NO `bin/` directory
When test invokes `jd-verifier.ps1 -FastPath -RepoRoot $tempRoot`
Then output contains "ESCALATE dual-judge"
And stderr contains WARN about missing exe
And no repo files modified (`git status --porcelain` clean)

### Scenario: Test — fixture with fake fast.exe stub (VERIFY-OK path)
Given test runs with `PESTER_TEST=1`
And temp RepoRoot has `bin/fast.exe` stub that emits `{"passed":true,"elapsedMs":97}`
When test invokes `jd-verifier.ps1 -FastPath -RepoRoot $tempRoot`
Then output contains "VERIFY-OK mechanical (97ms)"
And exit code 0

### Scenario: Test — fixture with fake fast.exe stub (ESCALATE path)
Given test runs with `PESTER_TEST=1`
And temp RepoRoot has `bin/fast.exe` stub that emits `{"passed":false,"elapsedMs":200}`
When test invokes `jd-verifier.ps1 -FastPath -RepoRoot $tempRoot`
Then output contains "ESCALATE dual-judge"
And exit code 0

### Scenario: Test — rounds cap (exit 2)
Given test runs with `PESTER_TEST=1`
When test invokes `jd-verifier.ps1 -Rounds 3`
Then exit code is 2
And output contains "ASK-USER (Reflexion cap)"

### Scenario: Test — RepeatFinding output
Given test runs with `PESTER_TEST=1`
When test invokes `jd-verifier.ps1 -RepeatFinding`
Then output contains "CONSTITUTIONAL → register via immune-system"

### Scenario: Test — Json schema keys present
Given test runs with `PESTER_TEST=1`
When test invokes `jd-verifier.ps1 -Json -FastPath`
Then stdout parses as JSON with all 7 required top-level keys

### Scenario: Test — PESTER_TEST isolation (no repo mutation)
Given test runs with `PESTER_TEST=1`
And temp RepoRoot initialized as git repo
When all tests in suite complete
Then `git status --porcelain` in actual repo root shows no changes

## SKILL.md Budget Scenarios

### Scenario: SKILL.md byte count after edit ≤ 4620
Given `.agents/skills/judgment-day/SKILL.md` is modified per proposal
When byte count is measured (e.g., `[System.Text.Encoding]::UTF8.GetByteCount((Get-Content -Raw))`)
Then count ≤ 4620

### Scenario: SKILL.md retains taxonomy table
Given modified SKILL.md
When content is inspected
Then lines containing the Zylos 6-pattern taxonomy table (| # | Pattern | ...) are present and unchanged

### Scenario: SKILL.md changelog appended
Given modified SKILL.md frontmatter
When `changelog` value is read
Then it ends with "; 2026-09-01 wiring jd-verifier.ps1 (p2/p4/p5 enforcement)"

### Scenario: SKILL.md Protocol has ≤2 new lines
Given modified SKILL.md
When Protocol section is compared to original
Then ≤2 new lines added pointing to script and reference doc

## Reference File Scenarios

### Scenario: Reference file exists with wiring detail
Given `references/jd-patterns-wiring.md` created
When file is read
Then content is ~30 lines
And documents patterns 2/3/4/5 wiring (fast-path, self-consistency, reflexion cap, constitutional trigger)