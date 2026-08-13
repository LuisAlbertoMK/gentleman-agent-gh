# 02 — Plan de Implementación (handoff a Cycle #2 v3)

> Alcance: fix H2 (ADR-024) + Gap D + commits de cierre. Cambios SUGERIDOS — este plan no los ejecuta (Unit D es read-only).

## Task 1: Fix H2 — guard de colisión dinámico (ADR-024)

- **Files**: `scripts/lib/generate-opencode-config.js` (L163) + `scripts/tests/generate-config.Tests.ps1` (nuevo test) | **Change type**: modify/add
- **Before** (L163):
  ```js
  const templateKeys = ['bash', 'edit', 'read', 'write'];
  ```
- **After** (L163):
  ```js
  const templateKeys = Object.keys(template);
  ```
  (mantener el comentario de guard; opcional: aclarar dynamic keys incl. task)
- **Test nuevo** (`generate-config.Tests.ps1`, Describe fail-closed):
  ```powershell
  It 'exits 1 when extraPermKeys collides with task (auto-sub template)' {
      # Overrides: @{ 'gentleman-quick-sub-auto' = @{ extraPermKeys = @{ task = @{ '*' = 'allow' } } } }
      # Template auto-sub (con task) + agent gentleman-quick-sub-auto
      # expect: $LASTEXITCODE -Be 1; $out -Match 'collides with template keys'; $out -Match 'task'
  }
  ```
- **Verification**: `pwsh -NoProfile -Command "Invoke-Pester -Path 'scripts/tests/generate-config.Tests.ps1' -PassThru"` → 7/7; luego `pwsh -NoProfile -Command "& '.\scripts\regenerate-opencode.ps1' -Yes -Quiet"` → 16 checks OK (overrides vivos no colisionan).
- **Rollback**: `git revert` del commit fix, o `git checkout -- scripts/lib/generate-opencode-config.js`. | **Risk**: LOW (1 línea, fail-closed; peor caso regen falla ruidosamente ante override colisionante = comportamiento deseado)

## Task 2: Gap D — metodología benchmark

- **Files**: `benchmarks.md` y/o `docs/metricas/` (persistir runs) | **Change type**: add/config
- **Verification**: 5 runs en el MISMO contexto (subagente), mediana+IQR, delta vs baseline del mismo contexto; re-clasificar FAIL del cycle 1.
- **Rollback**: N/A (aditivo). | **Risk**: LOW

## Task 3: Cierre de ciclo — commits

- **Files**: `scripts/tests/generate-config.Tests.ps1` (test file, hoy uncommitted) + `docs/mejoras/2026-08-07-v3-cycle1-B2.md` + `adr/ADR-024-auto-sub-permission-merge-safety.md` + `mejora-log.md` | **Change type**: add
- **Convención**: commits taggeados por ciclo (`C1-test:`, `C2-fix:`, `C1-docs:`) — rollback map en `docs/mejoras/rollback-map-v3-2026-08-07.md`.
- **Verification**: `git log --oneline` muestra tags; pre-commit gate 18/18; `--validate` sync SSoT. | **Risk**: LOW

## Orden sugerido

1. Task 1 (fix + test) → 2. Task 2 (metodología) → 3. Task 3 (commits). Los archivos de Unit D (Task 3) ya existen; solo falta commitearlos.