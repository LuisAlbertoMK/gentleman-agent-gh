# Decision Matrix

## Framework de Decisión

```
                        PROBLEM
                           │
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
      BUILD NOW       BUILD LATER     DON'T BUILD
      (proven)        (prototype)    (not worth)
```

## Decision Categories

| Tipo | Quien Decide | Cuándo |
|------|-------------|--------|
| **Architecture** | Senior/Architect | Antes de implementation |
| **Trade-off** | Senior | Siempre visible |
| **Priority** | Tech Lead | Sprint planning |
| **Tooling** | Team | Consenso |

## Trade-off Template

```markdown
## Decision: [Título]

### Context
[Qué necesitamos decidir]

### Options

| Option | Pros | Cons | Risk |
|--------|------|------|------|
| A | [pro] | [con] | [risk] |

### Recommended
[Option + 이유]

### Consequences
- [Consecuencia 1]
- [Consecuencia 2]
```

## Go / No-Go Criteria

| Criteria | Go | No-Go |
|----------|-----|-------|
| Business value | Defined | Unclear |
| Technical feasibility | Proven | Unknown |
| Timeline | < 2 weeks | > 1 month |
| Risk | Low/Med | High |
| Rollback | Easy | Hard |

## Reversibility Matrix

| Decision Type | Reversible? | Cost to Reverse |
|---------------|-------------|---------------|
| Rename variable | ✅ Yes | < 1 hour |
| Add field | ✅ Yes | < 1 day |
| New endpoint | ⚠️ Depends | Medium |
| Schema change | ❌ Hard | Large |
| Algorithm | ⚠️ Depends | Medium |
| Library | ⚠️ Depends | Large |
| Architecture | ❌ No | Very Large |
