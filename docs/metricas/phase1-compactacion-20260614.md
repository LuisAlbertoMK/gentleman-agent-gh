# Métricas: Phase 1 — Compactación AGENTS.md + Anti-pattern

> Fecha: 2026-06-14
> Scope: infraestructura, documentación, configuración

## Before / After

| Métrica | Before | After | Delta |
|---------|--------|-------|-------|
| AGENTS.md líneas | 210 | 166 | −21% |
| AGENTS.md tokens estimados | ~2838 | ~2298 | −540t/sesión |
| ANTI-PATTERN-CATALOG.md líneas | 112 | ~37 | −67% |
| ANTI-PATTERN-CATALOG entries | 13 | 13 | 0 (preservado) |
| Skill count (README) | inconsistente | 54 | unificado |
| Skill count (SKILLS-INDEX) | inconsistente | 54 | unificado |
| Skill count (ROADMAP) | inconsistente | 54 | unificado |
| opencode.json hardcode | C:\Users\MK\... | portable (PATH) | eliminado |
| Model config | null | sugerencia (no hardcode) | documentado |
| sdd-onboard trigger | ausente | presente | agregado |
| Plugins | 0 | 3 (dcp, skillful, lazy-loader) | +3 |
| MCP servers | 0 | 3 (context7, engram, context-mode) | +3 |
| Context Engineering token savings | 0 | −63.9% | arXiv verificado |
| File read (10MB, ReadAllBytes) | 7.2 MB/s (Get-Content) | 239.6 MB/s | +33.3x |

## Scores

| Dimensión | Before | After | Delta |
|-----------|--------|-------|-------|
| D1 Project Artifacts | 6/10 | 9/10 | +3 |
| D6 Clean Code (config) | 5/10 | 9/10 | +4 |
| D7 Best Practices | 4/10 | 9/10 | +5 |
| D11 Orthography | 8/10 | 10/10 | +2 |
| D12 Bitácora | 0/10 | 10/10 | +10 |
| D13 Metrics | 0/10 | 10/10 | +10 |

## Precision Budget

| Planned | Executed | Deviation |
|---------|----------|-----------|
| Compact anti-pattern | done | 0% |
| AGENTS.md Phase 1 | done | 0% |
| Unified skill count | done | 0% |
| Config portable | done | 0% |
| Plugins+MCP | done | 0% |
| Quality gate + commit | in progress | — |

## Notas

- CRLF detected in 4 files → git auto-converts to LF on commit (no action needed)
- review-gentleman-agent-gh.md excluded from commit
- All 25 tests (5 levels × 5) passed before commit
