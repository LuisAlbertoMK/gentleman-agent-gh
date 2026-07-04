# GAPS · Técnico · gentleman-agent-gh

**Fecha:** 2026-07-03
**Alcance:** scripts/*.ps1 (48 + 7 smoke), .agents/skills/*/SKILL.md (68), .githooks/* (2), commands/*.md (13), prompts/sdd/*.md (11)
**Método:** Lectura de código, grep de patrones, verificación de sintaxis, validación de referencias cruzadas, detección de stubs/placeholders

---

## Hallazgos

| # | Severidad | Archivo:Línea | Descripción | Recomendación |
|---|-----------|---------------|-------------|---------------|
| 1 | 🟠 Alta | scripts\intake-debug.ps1:10 | **Hardcoded path absoluto**: "C:\Program Files\PowerShell\7\pwsh.exe". Rompe portabilidad en sistemas donde PS7 está en ruta distinta o no existe | Usar (Get-Process -Id 12404).Path o $PSHOME\pwsh.exe. Alternativamente, depender de #requires -Version 7.6 y $PSVersionTable |
| 2 | 🟠 Alta | scripts\check-upstream.ps1:71 | **Hardcoded path absoluto**: $bashPath = "C:\Program Files\Git\bin\bash.exe". Fallará si Git está instalado en otra ubicación o si se usa WSL bash | Delegar a scripts\bash-safe.ps1 (que ya tiene detección automática de bash). No duplicar lógica de descubrimiento |
| 3 | 🟠 Alta | scripts\install.ps1:46 | **Invoke-Expression con web payload**: Invoke-Expression (Invoke-WebRequest -Uri  -UseBasicParsing).Content. Anti-patrón de seguridad: ejecuta código remoto sin verificar hash/firma | Reemplazar por descarga a archivo temporal + verificación de hash SHA256 antes de ejecutar, o documentar explícitamente el riesgo con un warning al usuario |
| 4 | 🟠 Alta | scripts\dev-server.ps1 | **Sin Set-StrictMode**: el script no declara Set-StrictMode. Esto permite referencias a variables no definidas y otros errores silenciosos | Agregar Set-StrictMode -Version Latest después de param() |
| 5 | 🟠 Alta | scripts\install.ps1 | **Sin Set-StrictMode**: igual que dev-server.ps1, no declara strict mode | Agregar Set-StrictMode -Version Latest |
| 6 | 🟠 Alta | scripts\setup-machine.ps1 | **Sin Set-StrictMode**: a pesar de tener $ErrorActionPreference = "Stop", no tiene Set-StrictMode. Puede ocultar errores de tipeo en variables | Agregar Set-StrictMode -Version Latest después de param() |
| 7 | 🟠 Alta | AGENTS.md:44 | **Documentación incompleta de shortcuts**: eview-rules.jsonc define 5 modos (!ship, !listo, !fast, !check, !draft) pero AGENTS.md:44 solo documenta 4 (!ship, !check, !fast, !draft). !listo está ausente de AGENTS.md aunque aparece en SKILLS-INDEX.md, README.md y docs/operations/shortcuts.md | Agregar !listo a la tabla de shortcuts en AGENTS.md, o eliminar el modo si es obsoleto |
| 8 | 🟡 Media | scripts\backup.ps1:1,13 y 8 scripts más | **#requires -Version duplicado**: 9 scripts tienen la línea #requires -Version 7.6 dos veces (antes y después del bloque de ayuda <#...#>). No causa error funcional pero es redundante y sugiere edición descuidada | Eliminar la segunda ocurrencia en cada script. Scripts afectados: ackup.ps1, ench-file-io.ps1, nsure-tools.ps1, pssa-gate.ps1, estore.ps1, score-auto.ps1, skill-test-suite.ps1, 	oken-count.ps1, 	okenize-all.ps1 |
| 9 | 🟡 Media | scripts\setup-machine.ps1:1, scripts\dev-server.ps1:1 | **#requires -Version inconsistente**: usan #requires -Version 7.0 mientras los otros 46 scripts usan 7.6. Si se requiere una feature específica de 7.6, estos fallarán silenciosamente | Unificar a #requires -Version 7.6 o documentar por qué usan 7.0 |
| 10 | 🟡 Media | scripts\benchmark.ps1:2 | **Help + param en una línea**: <#.SYNOPSIS...#>param([switch],...). La declaración de parámetros está pegada al comentario de ayuda en la misma línea. Válido sintácticamente pero extremadamente frágil y difícil de leer/mantener | Separar el bloque de ayuda en multilínea (<#...#> con saltos de línea) y poner param() en su propia línea |
| 11 | 🟡 Media | scripts\intake-verify.ps1:3 | **[bool] en lugar de [switch]**: [bool]=True debería ser [switch] para consistencia con el estándar PowerShell. Los switches se comportan diferente (presence-only semantics) | Cambiar [bool]=True a [switch] y ajustar las referencias de $m a $m.IsPresent o $m (PS automatic) |
| 12 | 🟡 Media | .agents\skills\sdd-init\SKILL.md y 9 skills más | **10 skills son stubs/redirects**: sdd-init, sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, caveman — todos contienen solo un redirect a otro archivo. Agregan 10 entradas en el registro de skills sin aportar valor real | Evaluar si los redirects son necesarios para triggers específicos. Si no, consolidar en sdd/SKILL.md y deprecar los wrappers individuales. Si se mantienen, al menos unificar el formato |
| 13 | 🟡 Media | scripts\cross-ref-check.ps1:5 | **Parámetros con nombres de una letra**: [string], [switch]. Disminuye la legibilidad y dificulta el mantenimiento | Usar nombres descriptivos: [string], [switch] |
| 14 | 🟡 Media | scripts\smoke\smoke-*.ps1:11 (múltiples) | **Dependencia externa frágil**: los 7 smoke tests referencian . "C:\Users\MK\.config\opencode\scripts\bash-safe.ps1". Si el repo no está instalado globalmente (setup-machine.ps1 no ejecutado), todos los smoke tests fallan con error críptico | Usar $PSScriptRoot\..\bash-safe.ps1 como fallback antes de la ruta global, o auto-descubrir la raíz del repo |
| 15 | 🟡 Media | scripts\score-auto.ps1:50-52 | **Escritura ciega de .project.json**: parsea output JSON de score-auto.ps1 -Json y escribe directo a .project.json. No valida que el JSON tenga la estructura esperada antes de sobrescribir | Validar que el JSON parseado contenga score.dimensions y score.current antes de escribir. Agregar backup del archivo anterior |
| 16 | 🟡 Media | .githooks\pre-commit:2 | **Sin set -e ni error handling**: el script shell no tiene set -e (exit on error). Si algún comando falla, el hook continúa ejecutándose y reporta resultados incorrectos | Agregar set -e al inicio. Alternativamente, migrar a PowerShell que tiene mejor manejo de errores |
| 17 | 🟡 Media | scripts\pssa-gate.ps1:2 | **Dependencia obligatoria sin fallback**: #Requires -Module @{ModuleName='PSScriptAnalyzer'; ModuleVersion='1.20.0'}. Si el módulo no está instalado o la versión no coincide, el script falla al cargar sin mensaje útil | Usar Import-Module PSScriptAnalyzer -ErrorAction SilentlyContinue con verificación manual y mensaje claro si no está disponible |
| 18 | 🟢 Baja | scripts\tokenize-all.ps1:37-41 | **Fallback silencioso de Python/tiktoken**: si Python no está instalado o tiktoken falla, captura la excepción y asigna $tokens = . Luego reporta -1 como TokensReal sin advertencia visible | Agregar Write-Warning o mensaje informativo cuando el token real no puede calcularse |
| 19 | 🟢 Baja | scripts\bench-file-io.ps1:83 | **Scope frágil en Set-Variable**: Set-Variable -Name content -Value  -Scope 1. El scope 1 asume una profundidad de anidamiento específica que se rompe si se modifica la estructura de bloques | Usar variable de script ($script:content) o retornar el valor directamente |
| 20 | 🟢 Baja | rrors\.gitkeep | **Directorio rrors/ vacío**: solo contiene .gitkeep. No hay un mecanismo activo que lo poble. capture-errors.ps1 guarda en docs/metricas/errors/, no aquí | Eliminar el directorio si no se usa, o conectarlo al pipeline de capture-errors.ps1 |
| 21 | 🟢 Baja | commands\sdd-*.md (múltiples) | **Placeholder $ARGUMENTS en commands**: 3 archivos (sdd-new.md, sdd-continue.md, sdd-ff.md) usan $ARGUMENTS como placeholder de runtime. Este es un patrón del sistema de comandos de OpenCode, no PowerShell | Documentar explícitamente que $ARGUMENTS es un placeholder del orchestrator (no PS), para evitar confusión |
| 22 | 🟢 Baja | scripts\close-session.ps1:92-93 | **Ejecución de session-miner silenciada**: ... 2>&1 | Out-Null. Descarta todo el output del miner, incluyendo errores. Si el miner falla, el usuario no lo sabe | Al menos mostrar un resumen de errores si $LASTEXITCODE -ne 0 |
| 23 | 🟢 Baja | scripts\run-dreaming.ps1:35-37 | **Write-Log con Add-Content pero sin validación de directorio**: asume que .learnings/LEARNINGS.md existe. Si se borra manualmente, falla silenciosamente (catch vacío solo hace Debug) | Verificar existencia del archivo/directorio antes de escribir, o forzar creación |
| 24 | 🟢 Baja | .githooks\post-commit:18-19 | **Usa powershell.exe en vez de pwsh.exe**: invoca PowerShell 5.1 (Windows) en vez de PowerShell 7. Si scripts requieren 7.6, pueden fallar. Además, Windows no garantiza powershell.exe en sistemas Nano/Core | Cambiar a pwsh.exe para consistencia con el resto del proyecto |
| 25 | 🟢 Baja | scripts\check-backlog-integrity.ps1:32 | **Parámetro [bool] en lugar de [switch]**: mismo patrón que hallazgo #11. [bool] debería ser [switch] para convención PS | Migrar a [switch] y actualizar llamados |

---

## Resumen

| Métrica | Valor |
|---------|-------|
| **Total hallazgos** | 25 |
| **🔴 Críticos** | 0 |
| **🟠 Altos** | 7 |
| **🟡 Medios** | 10 |
| **🟢 Bajos** | 8 |
| **Scripts auditados** | 48 + 7 smoke |
| **Skills auditados** | 68 SKILL.md |
| **Githooks auditados** | 2 |
| **Comandos auditados** | 13 |
| **Prompts auditados** | 11 |

### Distribución por categoría

| Categoría | Cantidad | IDs |
|-----------|----------|-----|
| Portabilidad / Paths hardcodeados | 2 | #1, #2 |
| Seguridad | 1 | #3 |
| Error handling / Strict Mode ausente | 3 | #4, #5, #6 |
| Documentación / Drift | 2 | #7, #21 |
| Código redundante / duplicado | 2 | #8, #12 |
| Inconsistencias de versión | 1 | #9 |
| Mantenibilidad / legibilidad | 4 | #10, #11, #13, #19 |
| Dependencias frágiles | 3 | #14, #17, #24 |
| Validación faltante | 2 | #15, #23 |
| Fallback silencioso | 1 | #18 |
| Directorios/archivos muertos | 1 | #20 |
| Output descartado | 1 | #22 |
| Githooks shell scripting | 1 | #16 |

### Notas

- **No se encontraron** TODOs, FIXMEs, HACKs ni XXX en el código de scripts o prompts. El proyecto mantiene una disciplina encomiable en este aspecto.
- **No se encontraron** funciones vacías o stubs verdaderos (los SDD redirects están documentados como consolidados).
- **No se encontraron** bloques grandes de código comentado que deban eliminarse.
- **Las pruebas de .skillspector/tests/** son genuinas: 34 archivos con asserts reales, fixtures y test functions. No hay tests que no testeen nada.
- **La calidad general es buena**: 10.0 de score en .project.json es consistente con la ausencia de issues críticos. Los 25 hallazgos son principalmente de mantenibilidad y consistencia.
