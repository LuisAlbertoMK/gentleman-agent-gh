---
name: issue-creation
description: >
  Create GitHub issues. Triggers: "create issue", "report bug", "request feature".
---

## Template
```markdown
## Description
{what}

## Steps to Reproduce
1. {step}
2. {step}

## Expected
{what should happen}

## Actual
{what actually happens}

## Workaround
{if any}
```

## Command
```bash
gh issue create --title "{title}" --body "$(cat <<'EOF'
## Description
{desc}
EOF
)"
```

* issue-creation v2.0 — Karpathy Optimized *