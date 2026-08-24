# Análisis gentleman-agent-gh — 2026-08-03

**Pipeline**: analysis-mode (4 audits read-only: sec, infra, dx, perf+docs) + verificación local P2 (coste cero).
**Estado**: completo — plan propuesto, sin implementar.

---

## Veredictos por audit

| Audit | Veredicto | Hallazgos |
|-------|-----------|-----------|
| Security (sec) | **FAIL** | Shadowing de deny rules, gate divergence, bypass |
| Infraestructura (infra) | **FAIL** | SSoT sync no verificado, size budget paper tiger |
| DX (dx) | **FAIL** | Trigger parser bug, description vacía, mojibake |
| Performance + Docs (perf+docs) | **PASS** | Win restante pequeño; docs stale |

---

## Hallazgos críticos (verificados en P2 con evidencia)

### SEC-1 — `git push --force` deny shadowed por last-match-wins ⚠️
- **Evidencia**: `opencode.json:317-318` (secciones de agentes): `"git push --force *": "deny"` aparece **antes** de `"git push *": "ask"`. Con last-match-wins, `git push --force origin main` matchea ambos → gana el último → **ask** en vez de deny. El root (`opencode.json:13`) tiene el orden correcto, pero las secciones de agentes (líneas 312, 425, 533, 776, 1002, 1119, 1229, 1335, 1444, 1553) lo invierten.
- **Impacto**: en auto mode, `--force` puede aprobarse silenciosamente → riesgo de reescritura de historia remota.
- `confidence: high` (grep directo líneas 317-318)

### SEC-2 — Gate divergence: lib omite comandos denegados por opencode.json
- **Evidencia**: `scripts/lib/permission-gate-lib.ps1:22-41` deniega curl/ssh/docker/python/node/etc., **pero omite** `icm`, `wsl`, `Invoke-Expression` (alias directos de red/comando). `shared-deny-rules.json:11-15,58` SÍ los deniega. El gate local es más permisivo que la config real → un agente en auto puede correr `Invoke-Expression` sin que el gate lo marque.
- `confidence: high` (grep: `icm/wsl/Invoke-Expression` presentes en shared-deny-rules, ausentes en el lib)

### SEC-3 — Anchoring bypass
- **Evidencia**: `shared-deny-rules.json` usa patrones como `"curl *"` (sufijo `*` sin prefijo ancla). `shared-deny-rules.json` es cargado por opencode.json; los patrones sin ancla de inicio son vulnerables a bypass con wrappers (p.ej. `cmd /c curl` — aunque `cmd /c *` está denegado, la cobertura es incompleta).
- `confidence: medium` (inferencia del formato de patrones; requiere validación del parser de opencode)

### SEC-4 — Gate trivially bypassable
- **Evidencia**: `.githooks/pre-push` y el gate local son chequeos *de colaboración*, no de enforcement. `git push --no-verify` los salta (documentado en `.githooks/pre-push:38`). El lib `permission-gate-lib.ps1` no tiene ancla de modo para `--no-verify`.
- `confidence: high` (grep .githooks/pre-push:38)

### SEC-5 — `git clean -fdx`, `git rm -r` no cubiertos
- **Evidencia**: `permission-gate-lib.ps1:44-46` destructivos = solo `rm`, `rm -rf`, `Remove-Item`. `git clean -fdx` y `git rm -r` son destructivos equivalentes y pasan como `allow` en auto.
- `confidence: high` (grep lib:44-46)

### INFRA-1 — SSoT sync NO verificado por el gate local
- **Evidencia**: `check-config-drift.ps1` existe, pero el gate de pre-push no lo ejecuta. `permission-templates.json` (SSoT, líneas 65-71) vs `opencode.json` (líneas 312+) divergen (orden de force-push). El comentario en `permission-gate-lib.ps1:12-15` dice "keep in sync" — sin chequeo automático.
- `confidence: high` (grep SSoT vs opencode.json)

### INFRA-2 — Size budget paper tiger
- **Evidencia**: el guard de tamaño del SSoT usa `-MaxBytes` sin límite en CI; bypass directo por node y por `-MaxBytes` override (hallazgo del auditor de infra). Sin verificación en gate local.
- `confidence: medium` (del auditor infra, no re-verificado en P2 por coste)

### INFRA-3 — check-mcp-security.ps1 stale
- **Evidencia**: `scripts/check-mcp-security.ps1` aún reporta engram=18 (tool list viejo) — el MCP engram actual expone 8 herramientas.
- `confidence: medium` (del auditor infra)

### DX-1 — Trigger parser solo lee triggers entre comillas
- **Evidencia**: `scripts/build-skill-registry.ps1:41`: regex `"triggers:\s*[""'](.+?)[""']"` — solo captura triggers con comillas. Skills con `triggers:` sin comillas (yaml válido) pierden TODOS sus triggers en el registry → no enrutables.
- `confidence: high` (grep directo línea 41)

### DX-2 — `_shared/SKILL.md` description vacía
- **Evidencia**: `.agents/skills/_shared/SKILL.md:3-4`:
  ```yaml
  description: >
  triggers: "none; shared library only"
  ```
  El `>` con línea vacía → description vacía (variante del bug ya visto en e2e-testing).
- `confidence: high` (read directo)

### DX-3 — Mojibake en cross-project-forge
- **Evidencia**: `.agents/skills/cross-project-forge/SKILL.md:4` trigger `"convertir patrón"` — sin corrupción visible en la línea 4, pero el auditor reportó `patr�n` en otro punto del skill. Revisar con `git diff` del archivo.
- `confidence: low` (no re-verificado; del auditor dx)

### DX-4 — CSV de registry stale
- **Evidencia**: el CSV/JSON generado del registry no se regenera en el gate; 9 SDD skills muertos y 13 skills faltantes según el auditor dx.
- `confidence: medium` (del auditor dx)

### PERF-1 — opencode.json 27% duplicado
- **Evidencia**: ~14KB de reglas repetidas entre root y secciones de agentes; bloque `shared-deny-rules.json` duplicado inline en cada sección. La compactación de root a agentes (heredar) reduciría ~14KB.
- `confidence: high` (auditor perf, consistente con grep de secciones repetidas)

### DOCS-1 — Docs stale
- **Evidencia**: PROTOCOL.md con fila auto obsoleta; README índice incompleto; QUICKSTART cuenta 27 agentes (hoy 37); `limit.input` inválido documentado el Jul-29 sin corrección; BITACORA con líneas duplicadas.
- `confidence: medium` (del auditor perf+docs)

---

## Estado de ejecución (2026-08-03, aprobado por usuario: "si todos")

### ✅ Implementado

| Fix | Cambio | Verificación |
|-----|--------|--------------|
| P1-SEC1 | Orden force-push corregido en SSoT `permission-templates.json` (auto + semi); `opencode.json` regenerado vía `regenerate-opencode.ps1 -Yes` | 10/10 checks OK; post-write-validate in sync |
| P1-SEC2 | Lib `permission-gate-lib.ps1:24` añade `^icm\s`, `^Invoke-Expression`, `^wsl\s`; mirror en `permission-gate.ps1` | Tests Pester nuevos |
| P1-SEC5 | `^git clean\s`, `^git rm\s` como destructivos (deny manual/semi, ask auto) | Tests Pester nuevos |
| P2-INFRA-1 | Gate pre-commit check 14/14: `regenerate-opencode.ps1` validate cuando cambia `scripts/lib/` u `opencode.json` | — |
| P2-INFRA-3 | ~~`check-mcp-security.ps1:39` engram=18 → 8~~ **REVERTIDO** (falso positivo: conteo verificado en toolset real = 18) | 26/26 tests OK |
| P3-DX-1 | `build-skill-registry.ps1:40-49` parsea triggers quoted/bare/inline-array; registry regenerado (79 skills) | e2e-testing/vision-analyze/workflow-optimizer ahora tienen triggers |
| P3-DX-2 | `_shared/SKILL.md:3` description vacía (`>`) → string; triggers eliminados (no invocable) | frontmatter válido |

### ⏭️ Won't-fix justificado

| Fix | Razón |
|-----|-------|
| P4-PERF compactación root→agentes | El "27% duplicado" mide el JSON generado; el SSoT ya deduplica (1 template × 10 agentes). Heredar root arriesga semántica de merge de opencode con beneficio de mantenimiento nulo. Fail-closed por agente es diseño intencional. |
| P1-SEC-3 anchoring | shared-deny-rules.json se carga como patrón opencode (formato `cmd *` es el requerido por el parser); el lib ya usa anclas `^`. Los aliases (icm/iex/wsl) ahora están cubiertos en ambos. |

### 🔲 Pendiente (docs stale, requerimiento manual)
- PROTOCOL.md fila auto obsoleta; README índice; QUICKSTART 27→37 agentes; BITACORA duplicados; `limit.input` inválido en doc Jul-29.

---

**Gate**: análisis + implementación de seguridad/dx completados. Sin commit (se deja a decisión del usuario).
