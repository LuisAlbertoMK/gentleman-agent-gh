---
name: cognitive-doc-design
description: > Design docs that reduce cognitive load for readers/reviewers.
  Trigger: Writing guides, READMEs, RFCs, onboarding, architecture docs.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## CRITICAL PATTERNS
| Pattern | Rule |
|---------|------|
| Lead with answer | Decision/action/outcome FIRST. Context after. |
| Progressive disclosure | Happy path first → details → edge cases |
| Chunking | Small sections, short lists. One idea per section. |
| Signposting | Headings, labels, callouts — reader knows where they are |
| Recognition > recall | Tables, checklists, examples over prose |
| Review empathy | Docs so reviewer verifies without reconstructing story |

## DEFAULT STRUCTURE
```markdown
# Outcome-oriented title
<1 para: what, who it helps, why matters>

## Quick path
1. First action  2. Second action  3. Verification

## Details
| Topic | Decision |

## Checklist
- [ ] Reader can confirm this

## Next step
<Link or action>
```

## PR DOCS
- State what to review first, what's out of scope
- Link previous/next PR if chained
- One focus per section
- Checklists for acceptance criteria
