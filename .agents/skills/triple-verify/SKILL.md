---
name: triple-verify
description: "Triple verification — 3 enfoques, thresholds por zona, modos !ship/!fast/!draft"
triggers: "Triple verify, triangulate, 3 enfoques, !ship, !listo, !fast, !draft"
license: Apache-2.0
metadata:
  tags: [engineering, quality]
  author: gentleman-vMK
  version: "1.0"
  dependencies: [quality-gate, code-review-agent, commit-crafter]
---

## Trigger
Zona Roja SIEMPRE · Amarilla si diff >10L · Verde NUNCA · Keywords: `!ship`/`!listo`/`!fast`/`!draft`
- **Roja** (verify): `src/`, `test/`, `*_test.*`, `scripts/`, `migrations/`, `ci/`, `.github/`, `Dockerfile*`, `*.sql`, `*.ps1`
- **Amarilla** (>10L): `*.css`, `*.scss`, `*.json`, `*.yaml`, `*.toml`, `*.html`, `*.jsx`, `*.tsx`, resto
- **Verde** (skip): `*.md`, `*.txt`, `*.png`, `*.jpg`, `*.svg`, `*.ico`, `*.lock`, `.gitignore`, `.editorconfig`

## 3 Enfoques (DISTINTOS)
| E1 — Testing | E2 — Estático | E3 — Build/Runtime |
|---|---|---|
| Unit/integration/e2e | Lint, 4R, secrets | Build, dry-run, schema |

| Cambio | E1 | E2 | E3 |
|--------|----|----|----|
| Nuevo | `go test`/`npm test` | 4R review | Build OK |
| Refactor | Tests pasan | No regresión | Build + diff |
| Bug fix | Reproduce→fix→pasa | Edge cases | Build + runtime |
| Config/JSON | Schema validate | Lint | Dry-run |
| SQL | Up+down test | Review naming | Dry-run |
| Dockerfile | — | Layers/secrets | `docker build` |
| Scripts PS1 | PSSA pasa | 4R review | `-WhatIf` |

## Workflow
```
Propuesto → Verde? → SKIP
         → Amarilla ≤10? → quality-gate
         → Rojo/Amarilla>10 → TRIPLE VERIFY
            1. Seleccionar 3 enfoques
            2. Ejecutar E1+E2+E3 (paralelo)
            3. Falla? → STOP + evidencia
            4. Pasa → continuar

Post-verify:
  !ship/!listo → quality-gate → commit-crafter → commit+push
  !fast → build → commit+push (salta verify)
  !draft → solo aviso
```

## Decision Tree
```
E1 falla? error nuevo → FIX · pre-existente → user OK
E2 falla? lint/type → auto-fix · 4R<4 → BLOCK · <6 → preguntar
E3 falla? compilación → FIX · warning → user decide

¿Override? !ship --no-verify → emergencia (no recomendado)
```

## Reglas
1. **3 enfoques DISTINTOS**: comportamiento + calidad + compilación (no 3 tests iguales)
2. **Thresholds**: Verde jamás, Roja siempre, Amarilla por tamaño
3. **Default-FAIL**: sin evidencia de 3 pasos → no verificado
4. **Build obligatorio** para código compilable
5. **!ship = responsabilidad**: verify + quality-gate + commit + push

## Referencias
quality-gate · code-review-agent · judgment-day · commit-crafter
