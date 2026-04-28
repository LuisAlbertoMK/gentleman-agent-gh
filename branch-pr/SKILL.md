---
name: branch-pr
description: >
  PR workflow. Triggers: "create PR", "open PR", "prepare PR".
---

## Workflow
1. Check branch status
2. Analyze changes
3. Create PR via gh

## PR Template
```markdown
## Summary
- {change 1}
- {change 2}

## Testing
- [ ] unit tests
- [ ] manual test
```

## Command
```bash
gh pr create --title "{title}" --body "$(cat <<'EOF'
## Summary
- {change}
EOF
)"
```

* branch-pr v2.0 — Karpathy Optimized *