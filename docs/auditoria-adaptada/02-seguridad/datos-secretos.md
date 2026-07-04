# Seguridad · Datos/Secretos · gentleman-agent-gh

**Fecha**: 2026-07-03
**Proyecto**: Gentleman Agent — repositorio de scripts PowerShell + skills para agente AI OpenCode
**Alcance**: Hardcoded credentials, tokens, API keys, secrets en git history, .env/config exposure, PII, almacenamiento inseguro

---

## Metodologia

- Barrido de 48 scripts `.ps1`, configs JSON, workflows YAML, y 68 skills en `.agents/skills/`
- Patterns buscados: `ghp_`, `gho_`, `github_pat_`, `AKIA`, `ASIA`, `sk-`, `-----BEGIN.*PRIVATE KEY`, `password\s*=`, `api[_-]?key\s*=`, `token\s*=`, `secret\s*=`, `connection.*string`, URLs con `://user:pass@`, `ctx7sk_`, `CONTEXT7_API_KEY`, `GITHUB_TOKEN`, `GH_TOKEN`
- Revision de git history completo (99 commits, branch `master`)
- Verificacion cruzada con `.githooks/pre-commit`, `.gitignore`, `opencode.json` permissions, y layers de deteccion existentes

---

## Hallazgos

| # | Severidad | Archivo:Linea | Descripcion | Recomendacion |
|---|---|---|---|---|
| 1 | 🟡 Medio | `scripts/verify.ps1:48` | **Secrets scan con patterns incompletos**. Solo busca `password=`, `secret=`, `api_key=`, `token=`, `connection*string=`. No detecta `GH_TOKEN=`, `ghp_`, `AKIA`, `sk-`, `-----BEGIN`, ni `github_pat_`. | Incorporar los patterns de `scripts/check-mcp-security.ps1:97-116` (que ya tiene `GH_TOKEN`, `ghp_`, `gho_`, `github_pat_`, `ctx7sk_`, `--api-key`, etc.) y agregar `AKIA`, `ASIA`, `-----BEGIN`. |
| 2 | 🟡 Medio | `scripts/score-auto.ps1:23` | **Skill secrets scan gap**. Solo verifica `api_key|secret|password|token|credential` en skills. Omite `GH_TOKEN`, `GITHUB_TOKEN`, `ghp_`, `github_pat_`, claves SSH, y tokens de proveedores AI. | Extender regex a: `(api[_-]?key|secret|password|token|credential|GH_TOKEN|GITHUB_TOKEN|ghp_|github_pat_|-----BEGIN)`. |
| 3 | 🟡 Medio | `docs/research/build-optimization.md:412-413` | **Referencia a `${{ secrets.TURBO_TOKEN }}` en documentacion**. Archivo markdown (no workflow real) muestra ejemplo CI con `TURBO_TOKEN` y `TURBO_TEAM` como secretos de GitHub Actions. Aunque es ilustrativo, referenciar secretos en docs puede llevar a copiar/pegar inseguro. | Reemplazar con placeholder generico tipo `${{ secrets.MY_TOKEN }}` que no refiera a secretos reales de TurboRepo. |
| 4 | 🟡 Medio | `.githooks/pre-commit` (todo el archivo) | **Pre-commit hook sin verificacion de secretos**. El hook ejecuta 9 checks pero ninguno escanea el diff staged por tokens/passwords/API keys. El `quality-gate` skill describe este scan, pero no esta implementado en el hook real. | Agregar step al pre-commit que corra `git diff --cached \| Select-String -Pattern '(api[_-]?key|secret|token|-----BEGIN|ghp_)'` y bloquee si hay match. |
| 5 | 🟢 Bajo | `scripts/check-mcp-security.ps1:235-240` | **Advertencia de riesgo supply chain via `npx -y`**. El script correctamente advierte que `npx -y` ejecuta codigo npm sin verificacion de integridad. Los MCPs `context7` y `sequential-thinking` en `opencode.json` usan `npx -y`. Riesgo bajo para repo personal pero documentado. | Considerar pinning de versiones (ej. `@upstash/context7-mcp@3.2.2`). Ya esta identificado como riesgo aceptado en `docs/operations/mcp-security-checkpoint.md:92`. |
| 6 | 🟢 Bajo | `opencode.json:246-252` | **Ambiguedad en reglas de denegacion de lectura**. Las reglas `*.env.*` (linea 251) y `**/.env.*` (linea 247) son casi identicas. `*.env.*` matchearia `*.env.example` tambien, aunque el archivo existe en el repo y no tiene secretos reales. | Unificar reglas: mantener `**/.env*` y eliminar duplicacion. Agregar excepcion explicita para `.env.example`. |
| 7 | 🟢 Bajo | `scripts/optimize-system.ps1:47,59` | **Exposicion de informacion de sistema via CIM**. Usa `Get-CimInstance Win32_LogicalDisk` y `Win32_ComputerSystem` y escribe resultados a consola. Revela espacio en disco y datos del sistema. | Aceptado para script admin. Considerar flag `-Quiet` para suprimir output en CI. |
| 8 | 🟢 Bajo | scripts/*.ps1 (multiple archivos) | **Uso extensivo de `$env:USERPROFILE` en paths**. 50+ referencias exponen el nombre de usuario del SO en output de error y help messages. No es PII critica pero es informacion del sistema. | Aceptado para scripts locales. Podria mitigarse con `[Environment]::GetFolderPath('UserProfile')`. |
| 9 | 🟢 Bajo | Git history (todo el repo) | **Referencia a `CONTEXT7_API_KEY` en git history como env var**. `opencode.json` siempre uso `{env:CONTEXT7_API_KEY}`, nunca valores hardcodeados. Commit `1de7730` migro context7 de remote HTTP a local STDIO. No se encontraron claves reales en ningun commit. | Sin accion — patron actual con `{env:...}` es seguro. Historial limpio confirmado. |

---

## Resumen

| Categoria | Cantidad |
|-----------|----------|
| **Total hallazgos** | **9** |
| 🔴 Criticos | 0 |
| 🟠 Altos | 0 |
| 🟡 Medios | 4 |
| 🟢 Bajos | 5 |

### Puntos fuertes

- **No se encontraron secretos hardcodeados** en todo el codigo fuente trackeado (0 tokens GitHub, 0 AWS keys, 0 private keys, 0 passwords reales).
- **`.gitignore` robusto**: excluye `.env`, `.env.*`, `*.pem`, `*.key`, `secrets/`, `credentials.json`.
- **`opencode.json` usa `{env:VAR}`** para `CONTEXT7_API_KEY` — nunca valores literales.
- **Multiples capas de deteccion**: `check-mcp-security.ps1`, `verify.ps1`, `score-auto.ps1`, `quality-gate` skill, `security-scanner` skill.
- **Seguridad por capas**: `.project.json` reporta `secrets: false` y dimension `Security: 10/10`.
- **MCP Security Gate** completo: `docs/operations/mcp-security-checkpoint.md` con threat model, NSA advisory mapping, y risk assessment.
- **Git history limpio**: inspeccionados 99 commits; no hay evidencia de secretos commiteados en el pasado.

### Riesgos principales

1. **verify.ps1 tiene deteccion de secretos incompleta** — mientras `check-mcp-security.ps1` tiene patrones robustos (GH_TOKEN, ghp_, ctx7sk_, --api-key), `verify.ps1` (el gate principal de CI) solo cubre un subset. Esto crea una falsa sensacion de seguridad.
2. **Falta secrets scan en pre-commit hook** — el hook `.githooks/pre-commit` ejecuta 9 checks pero ninguno es de secretos. La unica proteccion pre-commit es via el `quality-gate` skill (que solo se activa si el agente la carga).
3. **Docs con referencias a secretos de CI** — `build-optimization.md` contiene ejemplos con `${{ secrets.TURBO_TOKEN }}` que alguien podria copiar textualmente.

### Score de seguridad actual (del proyecto)

Segun `.project.json`: **Seguridad = 10/10**, `secrets: false`, `weak_crypto: false`.

> **Este score refleja el estado actual del codigo (sin secretos), pero no la completitud de los mecanismos de prevencion (hallazgos #1, #2, #4).**
