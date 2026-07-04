# Seguridad (SEG) — Hallazgos Consolidados

> **Cobertura**: 3 fuentes previas (Auditoría Adaptada, Hallazgos Completos, Auditoría Externa)
> **Última revisión**: 2026-07-03 | **Verificación**: Subagente 2 contra código real

---

## Resumen

| ID | Severidad | Descripción | Fuentes | Estado |
|----|-----------|-------------|---------|--------|
| H-001 | 🔴 Crítico | Download cradle sin verificación (flujo opcional gentle-ai) | AA-Negocio#2, AA-Auth#1, AA-Inyección#1, AE-F3 | ✅ Resuelto |
| H-002 | 🔴 Crítico | Pre-commit hook — 5 bloques de inyección de comandos | AA-Auth#3,#4 | ✅ Resuelto |
| H-009 | 🟠 Alto | Secrets scan incompleto (verify.ps1, score-auto.ps1) | AA-Auth#7,#8, AA-Datos#1,#2 | ✅ Resuelto |
| H-010 | 🟡 Medio | Skills/ secrets scan limitado a skills/ solo (cubierto por H-009) | AA-Datos#2 | ✅ Resuelto |

---

## Detalle

### H-001: Download cradle sin verificación (✅ RESUELTO)

**Severidad**: 🔴 Crítico → ✅ Resuelto
**Origen**: Auditoría Adaptada (negocio.md#2, auth-autorizacion.md#1, inyeccion-validacion.md#1) + Auditoría Externa (F3)
**Archivo**: `scripts/install.ps1:46` (flujo opcional)
**Verificado**: 2026-07-03 — Código actual **YA** implementa:
1. Download a archivo temporal (`Invoke-WebRequest -OutFile $tmpFile`)
2. SHA256 checksum opcional vía `$env:GENTLE_AI_INSTALL_HASH`
3. Confirmación interactiva antes de ejecutar
4. Cleanup del archivo temporal

**Resuelto**: El código original con `Invoke-Expression (Invoke-WebRequest ...).Content` fue reemplazado por download-to-file + checksum + confirm. No hay `Invoke-Expression` en el flujo.

---

### H-002: Pre-commit hook — inyección de comandos

**Severidad**: 🔴 Crítico
**Estado**: ✅ **Resuelto** — commit 3b144ab reescribió `.githooks/pre-commit`: usa `pwsh.exe` en vez de `powershell.exe`, check de PS7, eliminó código obsoleto PS5.1 con cadenas sin escapar.

---

### H-009: Secrets scan incompleto (✅ RESUELTO)

**Severidad**: 🟠 Alto → ✅ Resuelto
**Origen**: AA-Auth#7,#8, AA-Datos#1,#2
**Archivos**: `scripts/verify.ps1:48`, `scripts/score-auto.ps1:23`
**Verificado**: 2026-07-03 — Código actual de `verify.ps1` YA escanea: scripts/, skills/, workflows/, docs/ con 10+ patrones (GH_TOKEN, ghp_, github_pat_, AKIA, SSH keys, Slack tokens, OpenAI keys, etc.). `score-auto.ps1` fue extendido para cubrir scripts/*.ps1, .github/workflows/*.yml, opencode.json.
**Resuelto**: Ambos archivos cubren ahora los directorios críticos. Score-auto.ps1 penaliza si encuentra secrets en cualquier ubicación.

---

### H-010: Skills secrets scan limitado

**Severidad**: 🟡 Medio
**Estado**: 🟡 Parcial — lo cubre parcialmente H-009.
**Descripción**: El scan de secrets en skills/ es un subconjunto del problema mayor de H-009. Se consolida en ese hallazgo.
**Recomendación**: Escalar H-009 para cubrir este caso.
