# SDD Delta Spec: gentleman-dashboard — data.json Contract

## ADDED Requirements

### Requirement: data.json structure and types
The generator SHALL emit `docs/dashboard/data.json` with exactly these keys and types:
- `generatedAt`: string (ISO8601, e.g., "2026-09-01T14:30:00.000Z")
- `agents`: object with key `total` (integer, MUST equal live opencode.json agent count = 58)
- `skills`: object with keys `total` (integer, MUST equal live `.agents/skills/*/SKILL.md` count = 93), `budgeted` (integer), `overBudget` (integer), `overBudgetSkills` (array of objects with `name`, `budget`, `actual`, `delta`)
- `gate`: object with keys `pass` (boolean), `elapsedMs` (integer), `crossRef` (integer), `tokenBudget` (object with `total`, `overBudgetFiles`)
- `projectScore`: integer (from `.project.json`)

### Requirement: counts match live repo
The `agents.total` value MUST equal the number of agents defined in `opencode.json` (currently 58).
The `skills.total` value MUST equal the number of directories under `.agents/skills/` containing `SKILL.md` (currently 93).
The `skills.overBudget` value MUST equal `fast.exe --gate --json` output `tokenBudget.overBudgetFiles` (currently 8).
The `gate.crossRef` value MUST equal `fast.exe --gate --json` output `crossRef` count.
The `gate.tokenBudget.total` value MUST equal `fast.exe --gate --json` output `tokenBudget.total`.

### Requirement: generatedAt is valid ISO8601
The `generatedAt` field MUST be a valid ISO8601 timestamp in UTC (ending with Z or ±HH:MM offset).

## Scenarios

### Scenario: Happy path — valid data.json emitted
Given the generator runs with `PESTER_TEST=0`
And `opencode.json` contains 58 agents
And `.agents/skills/` contains 93 skill directories
And `fast.exe --gate --json` returns crossRef=12, tokenBudget.total=45000, tokenBudget.overBudgetFiles=8
And `.project.json` contains score=87
When the generator executes
Then `docs/dashboard/data.json` exists
And `generatedAt` is valid ISO8601
And `agents.total` equals 58
And `skills.total` equals 93
And `skills.overBudget` equals 8
And `gate.crossRef` equals 12
And `gate.tokenBudget.total` equals 45000
And `gate.tokenBudget.overBudgetFiles` equals 8
And `projectScore` equals 87

### Scenario: Edge case — skill count changes
Given the generator runs
And a new skill is added to `.agents/skills/` (total becomes 94)
When the generator executes
Then `skills.total` equals 94

### Scenario: Error case — fast.exe fails
Given `fast.exe --gate --json` returns non-zero exit code
When the generator executes
Then `gate.pass` is false
And `gate.elapsedMs` is 0
And `gate.crossRef` is 0
And `gate.tokenBudget.total` is 0
And `gate.tokenBudget.overBudgetFiles` is 0