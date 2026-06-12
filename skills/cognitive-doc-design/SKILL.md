---
name: cognitive-doc-design
description: >
  cognitive-doc-design skill
triggers: "Cognitive load, docs for reviewers"
  Trigger: Writing guides, READMEs, RFCs, onboarding, architecture docs.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

## PATTERNS
| Principle | Rule |
|-----------|------|
| Lead with answer | Outcome FIRST. Context after. |
| Progressive disclosure | Happy path → details → edge cases |
| Chunking | Small sections, one idea each |
| Signposting | Headings/labels/callouts |
| Recognition > recall | Tables, checklists, examples |
| Review empathy | Reviewer verifies without reconstructing story |

## STRUCTURE
```markdown
# Title (outcome-oriented)
<what, who it helps, why matters>

## Quick path
1. Action · 2. Action · 3. Verification

## Details | Topic | Decision |

## Checklist | - [ ] Reader confirms |

## Next step
```

## PR DOCS
What to review first · what's OoS · links to chain PRs
One focus per section · checklists for acceptance criteria

