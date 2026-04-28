---
name: skill-creator
description: >
  Crea skills AI. Triggers: "create skill", "new agent pattern", "document conventions".
---

## When

YES → patrón reusable, workflow complejo, decision tree
NO → ya existe docs, trivial, one-off

## Structure

```
skill/
├── SKILL.md           # Required
└── assets/           # Optional (templates, schemas)
```

## SKILL.md Template

```markdown
---
name: {name}
description: >
  {desc}. Trigger: {when load}.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
{when use}

## Patterns
{critical rules}

## Examples
{minimal code}

## Commands
```bash
{common cmds}
```
```

## Fields

| Field | Req | Desc |
|-------|-----|------|
| name | Yes | lowercase, hyphens |
| description | Yes | what + trigger |
| license | Yes | Apache-2.0 |
| metadata.author | Yes | gentleman-programming |
| metadata.version | Yes | semver |

## Naming

| Type | Pattern | Example |
|------|---------|---------|
| Generic | tech | pytest |
| Project | proj-component | myapp-api |
| Test | proj-test-x | myapp-test-api |
| Workflow | action-target | skill-creator |

## Checklist

- [ ] No existe skill
- [ ] Reusable
- [ ] Nombre OK
- [ ] Frontmatter completo
- [ ] Patterns claros
- [ ] Ejemplos mínimos
- [ ] Commands
- [ ] AGENTS.md actualizado

* skill-creator v2.0 — Karpathy Optimized *