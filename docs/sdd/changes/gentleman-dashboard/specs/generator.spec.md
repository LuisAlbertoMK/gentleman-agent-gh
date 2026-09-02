# SDD Delta Spec: gentleman-dashboard — Generator Script

## ADDED Requirements

### Requirement: PowerShell 7 #requires statement
The script `scripts/generate-dashboard-data.ps1` MUST start with `#requires -Version 7.0` and `#requires -RunAsAdministrator` (for potential file system access).

### Requirement: PESTER_TEST=1 enables temp write only
When environment variable `PESTER_TEST=1` is set:
- The script MUST write output to a temporary file (e.g., `$env:TEMP\dashboard-data-test.json`)
- The script MUST NOT write to `docs/dashboard/data.json`
- The script MUST NOT modify any repository files
- The script MUST exit 0 on success

When `PESTER_TEST` is not set or is not "1":
- The script MUST write to `docs/dashboard/data.json`
- The script MUST create the directory if it doesn't exist

### Requirement: Data sources collected correctly
The script MUST:
1. Read `opencode.json` and count agents (`.agents | Length`)
2. Scan `.agents/skills/*/SKILL.md` directories and count skills
3. Run `fast.exe --gate --json` and parse JSON output for crossRef, tokenBudget
4. Read `.project.json` and extract score
5. Emit combined JSON to output path

### Requirement: Zero mutation of repo files in test mode
When `PESTER_TEST=1`, the script MUST NOT:
- Create `docs/dashboard/` directory
- Write to `docs/dashboard/data.json`
- Modify `opencode.json`, `.project.json`, or any skill files
- Modify any file under version control

## Scenarios

### Scenario: Happy path — normal execution writes to data.json
Given `PESTER_TEST` is not set
And `opencode.json` has 58 agents
And `.agents/skills/` has 93 skills
And `fast.exe --gate --json` returns valid JSON
And `.project.json` has score=87
When the generator runs
Then `docs/dashboard/data.json` is created
And content matches data-contract.spec.md requirements
And script exits 0

### Scenario: Happy path — PESTER_TEST=1 writes to temp only
Given `PESTER_TEST=1`
And all data sources available
When the generator runs
Then a temp file is created at `$env:TEMP\dashboard-data-test.json`
And `docs/dashboard/data.json` is NOT created or modified
And `docs/dashboard/` directory is NOT created
And script exits 0

### Scenario: Edge case — fast.exe not found
Given `fast.exe` is not in PATH
When the generator runs
Then `gate.pass` is false in output
And `gate.elapsedMs` is 0
And script exits 0 (does not throw)

### Scenario: Edge case — opencode.json missing
Given `opencode.json` does not exist
When the generator runs
Then `agents.total` is 0 in output
And script exits 0

### Scenario: Error case — PESTER_TEST=1 but repo file modified
Given `PESTER_TEST=1`
When the generator runs
Then no file under version control is modified (verified by `git status --porcelain` showing no changes)