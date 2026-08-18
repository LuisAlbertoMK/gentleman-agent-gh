# issue-creation — Reference Materials

> **Externalized from** .agents/skills/issue-creation/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples

### Example 1: Bug Report — TUI Crash on Resize
```bash
gh issue create -R Gentleman-Programming/gentle-ai \
  --template bug_report.yml \
  -t "fix(tui): crash on terminal resize during agent streaming"
```
**Pre-flight**: Searched `gh issue list --state all -s "resize crash"` → no dupes
**Body**:
```yaml
area: TUI
bug_description: Terminal resizing while agent is streaming output causes panic
steps:
  - Start gga with long-running agent (e.g., ralph-loop)
  - Resize terminal width from 120→80 cols during streaming
  - Observe panic in stdout
expected_vs_actual: "Expected: graceful reflow. Actual: panic: index out of range"
gga_version: "0.8.3"
os: "Linux (Arch)"
agent_client: "opencode"
```

### Example 2: Bug Report — Installer Fails on ARM64 macOS
```bash
gh issue create -R Gentleman-Programming/gentle-ai \
  --template bug_report.yml \
  -t "fix(installer): arm64 macOS binary missing from release assets"
```
**Pre-flight**: `gh issue list --state all -s "arm64" "macOS"` → found #142 (closed, different root cause)
**Body**:
```yaml
area: Installation
bug_description: Release assets lack darwin_arm64 binary; installer falls back to x86_64 + Rosetta
steps:
  - Run `curl -fsSL https://gentleman.dev/install.sh | bash` on M2 Mac
  - Observe Rosetta translation warning
expected_vs_actual: "Expected: native arm64 binary. Actual: x86_64 via Rosetta"
gga_version: "0.8.3"
os: "macOS 14.5 (arm64)"
agent_client: "n/a (installer)"
```

### Example 3: Feature Request — Agent Catalog Filtering
```bash
gh issue create -R Gentleman-Programming/gentle-ai \
  --template feature_request.yml \
  -t "feat(catalog): add tag-based filtering to agent catalog"
```
**Pre-flight**: `gh issue list --state all -s "catalog filter tag"` → no dupes
**Body**:
```yaml
preflight_check: "Searched existing issues; no tag filtering request found"
area: Catalog/Steps
problem: "Users cannot discover agents by capability (e.g., 'all agents that do testing')"
proposed_solution: "Add `tags` field to agent manifests; expose `--tag` filter in `gga catalog list`"
alternatives: "Client-side grep (current workaround)"
context: "Supports discovery for 50+ agents as catalog grows"
```

### Example 4: Feature Request — CI Pipeline as Code
```bash
gh issue create -R Gentleman-Programming/gentle-ai \
  --template feature_request.yml \
  -t "feat(ci): define CI pipeline in CUE instead of YAML"
```
**Pre-flight**: `gh issue list --state all -s "CUE" "CI"` → no dupes
**Body**:
```yaml
preflight_check: "Searched issues and discussions; no CUE migration proposed"
area: CI
problem: "GitHub Actions YAML is verbose, lacks type safety, hard to share logic across workflows"
proposed_solution: "Migrate to Dagger + CUE; define pipeline as code with type checking"
alternatives: "Keep YAML, use composite actions for reuse"
context: "Enables local CI runs via `dagger do ci`; aligns with agent detection as code"
```

### Example 5: Bug Report — Agent Detection False Positive
```bash
gh issue create -R Gentleman-Programming/gentle-ai \
  --template bug_report.yml \
  -t "fix(agent): false positive detection for cursor-agent in VS Code"
```
**Pre-flight**: `gh issue list --state all -s "cursor-agent" "false positive"` → no dupes
**Body**:
```yaml
area: Agent Detection
bug_description: "gga detects 'cursor-agent' as running when only Cursor IDE is open (no agent active)"
steps:
  - Open Cursor IDE with no agent session
  - Run `gga agent detect`
  - Observe 'cursor-agent: running' in output
expected_vs_actual: "Expected: 'cursor-agent: not running'. Actual: false positive"
gga_version: "0.8.3"
os: "Windows 11"
agent_client: "Cursor IDE"
logs: |
  $ gga agent detect
  cursor-agent: running (pid 1234)  # but no agent session exists
```

## Testing Patterns

### Pattern 1: Template Validation via gh api
```bash
# Validate bug_report.yml renders correctly before submit
gh api repos/Gentleman-Programming/gentle-ai/contents/.github/ISSUE_TEMPLATE/bug_report.yml \
  | jq -r '.content' | base64 -d | head -50
# Expect: YAML with required fields (area, bug_description, steps, expected_vs_actual, gga_version, os, agent_client)
```

### Pattern 2: Duplicate Search Automation
```bash
# Search for existing issues with keyword overlap (threshold: 3+ shared tokens)
search_dupes() {
  local query="$1"
  gh issue list -R Gentleman-Programming/gentle-ai --state all --json title,number \
    --jq ".[] | select(.title | test(\"${query// /|}\"; \"i\")) | \"#\\(.number) \\(.title)\""
}
search_dupes "tui resize crash"  # Should return empty for new bug
```

### Pattern 3: Label & Status Verification Post-Create
```bash
# Verify issue has correct auto-labels and status
verify_issue() {
  local num="$1"
  gh issue view "$num" -R Gentleman-Programming/gentle-ai --json labels,state \
    | jq -r '.labels[].name' | sort
}
# Bug → expect: bug, status:needs-review
# Feature → expect: enhancement, status:needs-review
```

## Edge Cases

### Edge Case 1: Template Missing from Repo
**Scenario**: `.github/ISSUE_TEMPLATE/bug_report.yml` deleted or renamed
**Behavior**: `gh issue create --template bug_report.yml` fails with "template not found"
**Mitigation**: Check template exists first: `gh api repos/Gentleman-Programming/gentle-ai/contents/.github/ISSUE_TEMPLATE/bug_report.yml`; if 404, fallback to manual body via `--body-file`

### Edge Case 2: Rate Limit During Duplicate Search
**Scenario**: `gh issue list` hits GitHub API rate limit (5000/hr)
**Behavior**: Search returns partial results or 403; dupe check incomplete
**Mitigation**: Use `gh api --paginate /repos/Gentleman-Programming/gentle-ai/issues?state=all&per_page=100` with `jq` filtering locally; cache results 5 min

### Edge Case 3: Issue Created But Network Fails Before Label Auto-Apply
**Scenario**: `gh issue create` succeeds (returns issue number) but GitHub Actions labeler workflow hasn't run yet
**Behavior**: Issue exists without `status:needs-review` label for 10-30s
**Mitigation**: Poll `gh issue view <num> --json labels` until `status:needs-review` present (max 60s timeout)

### Edge Case 4: Pre-flight Search Returns Closed Dupe with Different Root Cause
**Scenario**: Search finds #142 "arm64 macOS binary missing" (closed as "wont-fix: not supported"), but new issue is "arm64 macOS binary missing FROM RELEASE ASSETS" (different: binary exists but not uploaded)
**Behavior**: Naive dupe check says "exists" → blocks valid issue
**Mitigation**: Read closed issue body; compare root cause keywords; only block if same `area` + same `bug_description` tokens ≥ 80% overlap

## Anti-Patterns

### Anti-Pattern 1: Creating Issues for Questions/Support
**Wrong**: Opening bug_report.yml for "How do I configure X?" or "Why does Y happen?"
**Why**: Issues are for actionable work (bugs/features). Questions belong in Discussions.
**Fix**: Redirect to `https://github.com/Gentleman-Programming/gentle-ai/discussions` with context

### Anti-Pattern 2: Opening PR Without Linking Approved Issue
**Wrong**: `gh pr create -t "fix(tui): resize crash"` without `Closes #<N>` where issue has `status:approved`
**Why**: Bypasses issue-first workflow; no triage, no priority, no maintainer acknowledgment
**Fix**: Ensure issue exists → `status:approved` → PR body includes `Closes #<N>` → CI verifies link

## Maintainer
1.Issue→`needs-review` 2.Valid→`approved` 3.Unclear→comment 4.Invalid→close with reason 5.Contributor→PR linking issue

## Commands
```bash
gh issue list -R Gentleman-Programming/gentle-ai --state all -s "keywords"
gh issue create -R Gentleman-Programming/gentle-ai --template bug_report.yml -t "fix(<scope>):<desc>"
gh issue create -R Gentleman-Programming/gentle-ai --template feature_request.yml -t "feat(<scope>):<desc>"
gh issue view <N> -R Gentleman-Programming/gentle-ai
```
Scopes:`tui`|`cli`|`installer`|`catalog`|`system`|`agent`|`e2e`|`ci`|`docs`

## Refs
branch-pr·commit-crafter·quality-gate·work-unit-commits·opencode-skill-creator
