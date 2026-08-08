# 01 — Análisis detallado · Unidades A y B (tests + adversarial)

## Unit A — `scripts/tests/generate-config.Tests.ps1` (ses_0216)

- Archivo: 183 líneas, 3 Describes, 6 Its. `git log -- <file>` → SIN commits (nuevo, uncommitted — consistente con Enfoque B2 test-only).
- Fixtures production-exact (L21-33): `auto-sub` {bash allow, task deny}, `readonly` {bash deny, edit deny, write deny, task deny}, `readwrite` {bash ask}.
- Cobertura real: fail-closed (unmapped → exit 1; colisión bash → exit 1), merge (auto-sub cero ask; readonly deny total), validación (--validate idempotente), hidden propagation.
- **Re-verificación Unit D**: `Invoke-Pester` → `Tests Passed: 6, Failed: 0, Skipped: 0` (8.02s). Evidencia cruda: `03-evidencia/pester-run.txt`.
- **Gap detectado**: el test de colisión (L87-101) solo cubre `bash`; no existe test para `task` (ver evidencia-h2.md §6).

## Unit B — Adversarial (ses_0214c7)

- 4 vectores de evasión H1–H4 sobre el pipeline de permisos. H2 documentado en `evidencia-h2.md` (re-verificado por Unit D con read/grep).
- H1/H3/H4: detalle completo en la evidencia de la sesión ses_0214c7 (orquestador). Este log registra el inventario y el H2, que es el que entra al DoD.
- Clasificación: Unit B marca H2 crítico; DoD §1.4 lo puntúa HIGH (latente). El ADR-008 lo registra como Proposed.