# Plan — Mejora Autónoma Iterativa (post-cleanup)

> **Protocolo**: v3 adaptado (ver `docs/protocolo_mejora_autonoma_v3.md`)
> **Fecha**: 2026-08-11
> **Modelo**: laguna-s-2.1-free
> **Scope**: mejora post-cleanup (branch cleanup + ship + close pipeline completado)

## 1. Estado actual (post-pipeline)

| Métrica | Estado | Fuente |
|---|---|---|
| E2E Pester | 709/709 pass | calidad gate |
| Quality gate | 22/22 ALL CLEAR | `.githooks/pre-commit-gate.ps1` |
| Score | 8.9/10 (stable) | `.project.json`, `score-auto.ps1` |
| Branch principal | `main` (única activa) | git, origin (LuisAlbertoMK fork) |
| master (Go project) | Archivado en tag `archive/gentle-ai-go-snapshot-v2` | git ls-remote --tags |
| Original + experimento branches | Borrados | git history |

## 2. Gaps detectados (evidencia del quality gate)

| Gap | Evidencia | Blast radius | ICE Score |
|---|---|---|---|
| **G1** 8 SDD skills >3KB | Quality gate [5/13] flaggea 8 skills | Bajo (docs/skill compression) | 8 |
| **G2** Token budget excedido | skills 2638B/2000, prompts 1891B/2000 (83 files over) | Bajo | 6 |
| **G3** Protocolo v3 (96 líneas) sin comprimir | Karpathy compression candidate | Bajo | 5 |
| **G4** `master` = default branch en GitHub | No se puede borrar sin cambiar default en Settings | Bajo (manual) | 3 |

### G1 — Skills >3KB (Karpathy T2 candidates)

```
sdd-archive   4406B  ← mayor prioridad (más lejos de 2KB)
sdd-spec      4460B  ←
sdd-propose   4336B  ←
sdd-tasks     4306B  ←
sdd-apply     4060B  ←
sdd-init      3979B  ←
sdd-verify    3630B  ←
```

### Jerarquía de métricas (v3 §3)
```
correctness > security > performance > size/legibilidad
```
Compresión de skills: prioriza correctness (intents preserved) > robustness (edge cases covered) sobre size reduction.

## 3. Scope lock (Ciclo 1)

| Módulo | Permiso | Justificación |
|---|---|---|
| `.agents/skills/sdd-*` | read/write | G1: Karpathy compress 8 skills |
| `docs/protocolo_mejora_autonoma_v3.md` | read | G3: reference for compression |
| `scripts/token-count.ps1` | read | G2: measuring compression effectiveness |
| `.project.json` | read/write | Score auto-updates |
| `docs/mejoras/` | read/write | Plan + logs |

**Desvío requiere**: ADR mini.

## 4. Enfoques (≥3 por gap)

### G1 — Comprimir 8 SDD skills
1. **E1**: Karpathy T2 (merge redundant, bullets, remove context) — aplicar a los 4 skills +4KB primero
2. **E2**: Karpathy T3 (template structures, minimal identity) — los 4 skills 3.6-4.5KB
3. **E3**: Move common boilerplate to `_shared/` + trigger tables — refactorizar después de T2/T3

### G2 — Token budget
1. **E1**: Comprimir skills (G1) first — reduces 1188B immediately
2. **E2**: Compress AGENTS.md router table (mencionado en BITACORA.md 2026-06-26)
3. **E3**: Lean-context mode para prompts/shared (already documented in `commands/ctx-lite.md`)

### G3 — Comprimir protocolo v3
1. **T1**: Remove transitional phrases, merge redundant checklist items
2. **T2**: Convert 7.2 table (mejoras vs gap) to compact format
3. **T3**: Minimal identity — "Protocolo v3" instead of full title

### G4 — Borrar master
1. **E1**: User changes default branch master→main in GitHub Settings
2. **E2**: `git push origin --delete master`
3. **E3**: Verify tag `archive/gentle-ai-go-snapshot-v2` accesible

## 5. Definition of Done

- [ ] G1: 0 skills >3KB (8 skills comprimidos a ≤2.5KB cada uno)
- [ ] G2: Token budget dentro de límites (skills ≤2000B, prompts ≤2000B)
- [ ] G3: Protocolo v3 comprimido a ≤55 líneas (T2)
- [ ] G4: `master` borrado del remote (requiere acción manual del user)
- [ ] Quality gate: 22/22 ALL CLEAR
- [ ] Score sin regresión (≥8.9/10)
- [ ] ADR: `adr/ADR-021-karpathy-sdd-compression.md`

## 6. Presupuesto

- Máx 4 ciclos (uno por gap)
- ≤30 min por ciclo (G1 es el más grande)
- Umbral: mejora marginal <10% → stop
- Checkpoint: no required (todos gaps Bajo, ninguno Alto)

## 7. Rollback

- Cada compressión = commit separado con prefix `karpathy:`
- Tag previo a G1: `archive/pre-karpathy-compression-2026-08-11`
- Revertir: `git revert <commit-range>` por skill

## 8. Siguiente paso

Ejecutar G1-E1: Karpathy T2 compression en los 4 skills +4KB (sdd-archive, sdd-spec, sdd-propose, sdd-tasks). Medir tokens con `scripts/token-count.ps1`. Verificar con `!verify` y `!ship`.
