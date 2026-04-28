---
name: sdd-propose
description: >
  Create change proposal. Trigger: "sdd propose", "create proposal".
---

## Input
- Change name (e.g., "add-dark-mode")
- Exploration (from sdd-explore) OR direct
- Artifact mode (engram|openspec|hybrid|none)

## proposal.md Template
```markdown
# {change-name}

## Intent
{qué user quiere lograr}

## Scope
{in/out}

## Approach
{cómo se hace}

## Trade-offs
{| Option | Pros | Cons |}
|-------|-----|-----|
```

## Outputs
- Save artifact: `sdd/{change}/proposal`
- mem_save: title "sdd-propose/{change}"

* sdd-propose v2.0 — Karpathy Optimized *