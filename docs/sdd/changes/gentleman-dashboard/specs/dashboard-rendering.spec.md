# SDD Delta Spec: gentleman-dashboard — Dashboard Rendering

## ADDED Requirements

### Requirement: Four metric cards render real values
The dashboard SHALL display exactly 4 cards in a responsive grid:
1. **Gate Card**: Shows `gate.pass` as PASS/FAIL badge, `gate.elapsedMs` formatted as "X ms", `gate.crossRef` count, `gate.tokenBudget.overBudgetFiles` count
2. **Fast Card**: Shows `gate.elapsedMs` (duplicate for visibility), `gate.crossRef`, `gate.tokenBudget.total` formatted with commas
3. **Agents Card**: Shows `agents.total` as large number
4. **Skills Card**: Shows `skills.total`, `skills.budgeted`, `skills.overBudget`, and top 5 `skills.overBudgetSkills` as a mini-list (name + delta)

All card values MUST come from `data.json` fetch — NO hardcoded values.

### Requirement: Skills table lists over-budget skills
Below the cards, a sortable table SHALL render with columns: Skill Name, Budget, Actual, Delta.
The table MUST list all skills from `skills.overBudgetSkills` array (currently 8 rows).
Table MUST be sortable by clicking column headers (Name, Budget, Actual, Delta).

### Requirement: Page size under 50KB
The complete `docs/dashboard/index.html` (HTML + inline CSS + inline JS) MUST be < 50,000 bytes gzipped or raw.
No external CSS/JS/CDN dependencies allowed.

### Requirement: Fetch failure shows inline error
If `fetch('./data.json')` fails (network error, 404, invalid JSON), the dashboard SHALL display an inline error message in place of the cards/table: "Failed to load dashboard data. Run generator script." — NOT a blank page.

## Scenarios

### Scenario: Happy path — all cards render with live data
Given `docs/dashboard/data.json` exists with valid data (agents.total=58, skills.total=93, skills.overBudget=8, gate.pass=true)
When the browser loads `docs/dashboard/index.html`
Then all 4 cards are visible
And Gate card shows "PASS" badge
And Agents card shows "58"
And Skills card shows "93 total, 85 budgeted, 8 over budget"
And Skills table has 8 rows
And page size < 50KB

### Scenario: Happy path — skills table sortable
Given the skills table is rendered with 8 rows
When user clicks "Delta" column header
Then rows reorder by delta descending
When user clicks "Delta" again
Then rows reorder by delta ascending

### Scenario: Edge case — empty overBudgetSkills
Given `skills.overBudget` is 0 and `skills.overBudgetSkills` is empty array
When the dashboard renders
Then Skills card shows "0 over budget"
And Skills table shows "No over-budget skills" message (no empty table)

### Scenario: Error case — fetch fails (404)
Given `data.json` does not exist (404)
When the dashboard loads
Then inline error message "Failed to load dashboard data. Run generator script." is visible
And no cards or table are rendered

### Scenario: Error case — fetch fails (invalid JSON)
Given `data.json` exists but contains invalid JSON
When the dashboard loads
Then inline error message is visible
And no cards or table are rendered

### Scenario: Responsive — mobile viewport
Given viewport width < 600px
When the dashboard renders
Then 4 cards stack in single column
And skills table horizontal scrolls if needed