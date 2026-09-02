# SDD Delta Spec: gentleman-jd-patterns — Requirements

## ADDED Requirements

### Requirement: jd-verifier.ps1 script exists with correct signature
The file `scripts/jd-verifier.ps1` MUST exist and start with:
- `#requires -Version 7.0`
- `[CmdletBinding()]`
- Param block with:
  - `[Parameter()][ValidateSet('ROJA','AMARILLA')]$Zone`
  - `[Parameter()][int]$Rounds = 0`
  - `[Parameter()][switch]$FastPath`
  - `[Parameter()][switch]$RepeatFinding`
  - `[Parameter()][string]$RepoRoot = (Get-Location).Path`
  - `[Parameter()][switch]$Json`

### Requirement: FastPath behavior — exe exists, passes, within budget
When `-FastPath` is specified AND `bin/fast.exe` exists at `$RepoRoot/bin/fast.exe`:
- The script MUST run `bin/fast.exe --gate --json` and capture JSON output
- If `passed` is true AND `elapsedMs` ≤ 162:
  - Output "VERIFY-OK mechanical (<elapsedMs>ms)" to stdout
  - Exit code 0
- If `passed` is false OR `elapsedMs` > 162:
  - Output "ESCALATE dual-judge" to stdout
  - Exit code 0

### Requirement: FastPath behavior — exe missing
When `-FastPath` is specified AND `bin/fast.exe` does NOT exist at `$RepoRoot/bin/fast.exe`:
- Output "ESCALATE dual-judge" to stdout
- Output warning "WARN: bin/fast.exe not found at $RepoRoot/bin/fast.exe" to stderr
- Exit code 0

### Requirement: Rounds cap enforcement
When `-Rounds` value > 2:
- Output "ASK-USER (Reflexion cap)" to stdout
- Exit code 2 (do not proceed to other logic)

### Requirement: RepeatFinding constitutional trigger
When `-RepeatFinding` switch is present:
- Output "CONSTITUTIONAL → register via immune-system (.agents/skills/immune-system)" to stdout
- Exit code 0

### Requirement: Self-consistency guidance line (always)
Regardless of other parameters, the script MUST always output:
"SELF-CONSISTENCY: profiles A/B = majority-of-2 (diverge → tie-break by higher severity)"
to stdout (before any other output or after — but present exactly once).

### Requirement: -Json output schema
When `-Json` switch is present, the script MUST emit a single JSON object to stdout with exactly these keys:
```json
{
  "verifier": "jd-verifier",
  "zone": "ROJA|AMARILLA",
  "fastPath": {
    "ran": true|false,
    "passed": true|false|null,
    "elapsedMs": 0|number|null,
    "decision": "VERIFY-OK|ESCALATE|NOT_RUN"
  },
  "rounds": {
    "value": 0|number,
    "capped": true|false
  },
  "constitutional": true|false,
  "timestamp": "ISO8601"
}
```
- `fastPath.ran` = true only if `-FastPath` was specified
- `fastPath.passed` = null if not ran, else boolean from fast.exe
- `fastPath.elapsedMs` = null if not ran, else number from fast.exe
- `fastPath.decision` = "NOT_RUN" if -FastPath not specified, else "VERIFY-OK" or "ESCALATE"
- `rounds.capped` = true if input value > 2 (and exit code 2 was triggered), else false
- `constitutional` = true if `-RepeatFinding` specified, else false

### Requirement: Pester test isolation (PESTER_TEST=1)
The test file `scripts/tests/jd-verifier.Tests.ps1` MUST:
- Set `$env:PESTER_TEST = "1"` in test setup
- Verify no files under version control are modified during test execution (via `git status --porcelain`)
- Use temporary directories for all file I/O
- Not require `bin/fast.exe` to exist (test with stubs)

### Requirement: SKILL.md budget invariant
The file `.agents/skills/judgment-day/SKILL.md` after modification:
- MUST be ≤ 4620 bytes
- MUST retain the Zylos 6-pattern taxonomy table (lines 41-50)
- MUST add ≤2 lines in Protocol section pointing to `scripts/jd-verifier.ps1` and `references/jd-patterns-wiring.md`
- MUST append "; 2026-09-01 wiring jd-verifier.ps1 (p2/p4/p5 enforcement)" to changelog frontmatter line

### Requirement: External reference file
The file `references/jd-patterns-wiring.md` MUST exist with ~30 lines documenting the wiring detail for patterns 2/3/4/5.

## MODIFIED Requirements

### Requirement: judgment-day SKILL.md Protocol section updated
The Protocol section in `.agents/skills/judgment-day/SKILL.md` MUST include a pointer to the verifier script and reference doc (≤2 lines added).

### Requirement: judgment-day SKILL.md changelog updated
The frontmatter `changelog` line MUST end with "; 2026-09-01 wiring jd-verifier.ps1 (p2/p4/p5 enforcement)".

## Scenarios Reference
See `scenarios.md` for GIVEN/WHEN/THEN scenarios covering all requirements.