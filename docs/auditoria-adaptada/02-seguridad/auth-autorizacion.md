# Seguridad · Auth/Autorización · gentleman-agent-gh
Fecha: 2026-07-03
Auditor: agente-optimizado v1.0
Alcance: Auth/Autorización, manejo de credenciales, permisos, escalación de privilegios, GitHub Actions, sanitización de comandos

---

## Hallazgos

| # | Severidad | Archivo:Línea | Descripción | Recomendación |
|---|---|---|---|---|
| 1 | 🔴 Crítico | scripts/install.ps1:46 | **Download cradle sin verificacion**: Invoke-Expression + Invoke-WebRequest descarga y ejecuta codigo remoto sin checksum, sin firma, sin HTTPS pinning. | Agregar verificacion de checksum SHA256 antes de invocar. Clonar repo primero y ejecutar localmente. |
| 2 | 🔴 Crítico | scripts/bootstrap.ps1:17 | **Mismo download cradle**: iex con download de install.ps1 como one-liner. Sin verificacion de integridad. | Misma recomendacion que #1. El dominio gentleman.sh es un redirect. |
| 3 | 🔴 Crítico | .githooks/pre-commit:94-104 | **Inyeccion de comandos PowerShell**: El hook embebe $REPO_ROOT via interpolacion shell directamente en bloques -Command de pwsh. | Escapar $REPO_ROOT o usar scripts .ps1 separados en vez de -Command inline. |
| 4 | 🔴 Crítico | .githooks/pre-commit:122-128,146-164,183,224-226 | **Misma vulnerabilidad**: Otros 4 bloques embeben $REPO_ROOT sin escape en comandos pwsh. | Factorizar en scripts .ps1 separados (ya existen) y llamarlos con argumentos tipados. |
| 5 | 🟠 Alto | scripts/intake-verify.ps1:21 | **gh sin validacion de autenticacion**: gh pr list --limit 5 se ejecuta sin verificar autenticacion. Si no hay sesion GitHub, falla silenciosamente. | Agregar gh auth status antes de usar gh pr list. |
| 6 | 🟠 Alto | opencode.json:202,218 | **Supply chain risk - npx -y sin pinning**: Dos MCP servers usan npx -y que autodescarga codigo npm sin verificacion ni version pinning. | Pinner version: @upstash/context7-mcp@1.2.3. Reemplazar por instalacion local con lockfile. |
| 7 | 🟠 Alto | scripts/verify.ps1:48 | **Secrets scan con patterns incompletos**: Solo busca password=, secret=, api_key=, token=. No detecta GH_TOKEN, ghp_, AKIA, sk-... | Agregar patterns del check-mcp-security.ps1 que ya tiene deteccion mas completa. |
| 8 | 🟡 Medio | scripts/score-auto.ps1:23 | **Secrets scan limitado a SKILL.md**: Solo escanea .agents/skills/*/SKILL.md. No cubre scripts .ps1, .yml, .json, prompts. | Extender scan a scripts/, .github/workflows/, opencode.json. |
| 9 | 🟡 Medio | scripts/pull-upstream.ps1:47-54 | **Path traversal potencial en -TargetFile**: Acepta -TargetFile sin validar que el path este dentro del repo. | Validar que Resolve-Path $TargetFile este dentro del repo root. |
| 10 | 🟡 Medio | scripts/sync-global.ps1:92-93 | **MCP remoto sin auth explicita**: Configura context7 como remote sin definir autenticacion en el JSON global. | Documentar requisitos de auth para cada MCP remoto. Dejar enabled=false por defecto. |
| 11 | 🟡 Medio | scripts/check-upstream.ps1:91 | **URL de repo hardcodeada pasada a bash**: git ls-remote con URL hardcodeada. Bajo riesgo hoy, pero el patron permite inyeccion si cambia el upstream. | Validar que la URL coincida con https://github.com/* antes de pasar a bash. |
| 12 | 🟡 Medio | scripts/bash-safe.ps1:61,66 | **Invoke-Bash pasa comandos sin sanitizar**: Cualquier caller que pase input de usuario permite ejecucion arbitraria. | Documentar que callers deben escapar input. Considerar validar caracteres de control. |
| 13 | 🟡 Medio | scripts/dev-server.ps1:108-110 | **Procesos arbitrarios sin validacion**: Start-Server acepta -Command y -Arguments sin allowlist. | Agregar allowlist de comandos permitidos (npm, python, dotnet, node). |
| 14 | 🟡 Medio | scripts/optimize-system.ps1:81,94 | **DISM invocado sin confirmacion**: Opera como admin (verifica) pero la ejecucion es irreversible y no pide confirmacion explicita. | Agregar confirmacion antes de operaciones destructivas. |
| 15 | 🟡 Medio | .githooks/pre-commit:199-208 | **ROJA classification oversensitive**: Marca todo scripts/ y .github/ como ROJA sin distinguir archivos sensibles. | Priorizar archivos con secretos/tokens sobre scripts genericos en zona ROJA. |
| 16 | 🟢 Bajo | opencode.json:199-205 | **Config de MCP usa {env:...} correctamente**: CONTEXT7_API_KEY se referencia como env var, no hardcodeado. Buen patron. | Mantener. Considerar validar vars de entorno existentes en check-mcp-security.ps1. |
| 17 | 🟢 Bajo | opencode.json:246-252 | **Permisos de lectura deniegan .env* correctamente**: Bloquea .env, credentials.json, secrets/. Conflicto: *.env.example vs *.env.*. | Resolver ambiguedad: cambiar *.env.* por *.env.local, *.env.production especificos. |
| 18 | 🟢 Bajo | opencode.json:230-242 | **Permisos bash restrictivos para git destructivo**: git push --force, rebase, merge, branch -D, stash drop tienen "ask". Buen patron. | Considerar agregar gh pr create, gh issue, gh repo delete a "ask". |
| 19 | 🟢 Bajo | scripts/pssa-gate.ps1:28 | **Auto-healing de archivos sin backup**: Modifica scripts .ps1 in-place (BOM, switch defaults) sin hacer backup. | Agregar -WhatIf por defecto y requerir -Force para cambios reales. |
| 20 | 🟢 Bajo | scripts/check-mcp-security.ps1:97-116 | **Mejor deteccion de tokens del proyecto**: Test-HardcodedToken detecta --api-key, GH_TOKEN, ghp_, gho_, github_pat_, ctx7sk_. Omite {env:...}. | Promover este scan a verify.ps1 - E2 para que se ejecute en cada gate. |
| 21 | 🟢 Bajo | .gitignore:107-112 | **Exclusion de secretos en git correcta**: .env, .env.*, *.pem, *.key, secrets/, credentials.json ignorados por git. | Mantener. Considerar agregar .env.local, .env.production, *.keystore. |
| 22 | 🟢 Bajo | scripts/setup-machine.ps1:130-132 | **Junction creation sin elevation check previo**: No verifica admin antes de intentar New-Item -ItemType Junction. | Agregar verificacion de admin al inicio del script como en optimize-system.ps1. |
| 23 | 🟢 Bajo | scripts/intake-verify.ps1:100 | **Write-Host en catch expone detalles de error**: Error interno se propaga al output. No expone credenciales hoy, pero podria si el script se extendiera. | Usar Write-Warning generico y loguear detalle a archivo. |

---

## Resumen

| Categoria | Cantidad |
|---|---|
| 🔴 Criticos | 4 |
| 🟠 Altos | 3 |
| 🟡 Medios | 8 |
| 🟢 Bajos | 8 |
| **Total** | **23** |

---

## Notas adicionales

- **Puntos fuertes**: Multiples capas de deteccion de secretos (check-mcp-security.ps1, verify.ps1 E2, score-auto.ps1). .gitignore excluye archivos de secretos correctamente. Modelo de permisos OpenCode bloquea lectura de .env* y credenciales. MCPs usan {env:VAR} en vez de valores hardcodeados.

- **No se encontraron**: Tokens de GitHub hardcodeados (ghp_, gho_, github_pat_), API keys en texto plano, ni secretos en archivos trackeados por git.

- **Patron a replicar**: La funcion Test-HardcodedToken en check-mcp-security.ps1 tiene el mejor set de patterns de deteccion. Deberia promoverse al CI/CD (quality-gate.yml) y al verify.ps1 E2.

- **Riesgo mayor**: Los download cradles en install.ps1 y bootstrap.ps1 (hallazgos 1 y 2) ejecutan codigo remoto sin verificacion. Vector de ataque clasico si upstream fuera comprometido.

- **Riesgo de inyeccion en githooks**: Los 4 bloques de PowerShell inline en pre-commit hook (hallazgos 3 y 4) son fragiles. Solucion: reemplazar por llamadas a scripts .ps1 separados que ya existen.

- **Supply chain MCP**: npx -y sin version pinning (hallazgo 6) es un riesgo real si el paquete npm subyacente es comprometido.
