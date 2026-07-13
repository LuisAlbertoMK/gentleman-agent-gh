# Reporte Técnico — gentleman-agent-gh

**Repo analizado:** LuisAlbertoMK/gentleman-agent-gh (zip local, snapshot `master`)
**Método:** inspección directa de código fuente (283 archivos, 58 scripts PowerShell, 58 skills, CI, configuración MCP)
**Score autodeclarado:** 9.3/10 (`.project.json`) — nota: es un score **autogenerado por el propio sistema**, no una auditoría externa independiente.

---

## 1. Resumen ejecutivo

| Dimensión | Estado |
|---|---|
| Arquitectura general | Sólida, bien documentada, alto nivel de ingeniería de prompts |
| Seguridad | Aceptable en superficie, pero con **contradicciones de permisos** relevantes |
| Testing real | **Débil** — casi no hay tests automatizados pese a declarar "TDD" y "triple verify" |
| CI/CD | Funcional pero con **al menos 1 bug confirmado** (ruta rota) |
| Rendimiento | Buenas prácticas de compresión de contexto, pero riesgo de sobre-ingeniería |
| Dependencia externa | **Alto riesgo estructural** — depende de modelos "free tier" inestables/stealth |

---

## 2. Errores concretos encontrados

### 2.1 CI roto — ruta de CHANGELOG incorrecta (bug confirmado)
`.github/workflows/release.yml` ejecuta:
```
awk '/^## \[Unreleased\]/{flag=1; next} /^## \[/{flag=0} flag' CHANGELOG.md > release-notes.md
```
Pero el archivo real está en `docs/CHANGELOG.md`, no en la raíz. **Cada release generará notas vacías** o el job fallará. Impacto: alto — rompe la automatización de releases sin que nadie lo note hasta publicar un tag.

**Fix:** cambiar `CHANGELOG.md` → `docs/CHANGELOG.md` en el workflow.

### 2.2 `catch {}` vacío (swallow de errores)
`scripts/wisdom-stats.ps1:98` — bloque catch vacío que descarta silenciosamente cualquier excepción. Contradice el principio de "Best Practices 10.0" que el propio sistema se autoasigna. Riesgo bajo pero rompe la trazabilidad de errores que el resto del proyecto sí cuida (hay `capture-errors.ps1` dedicado).

### 2.3 Inconsistencia score README vs `.project.json`
El README dice **8.5/10**; `.project.json` dice **9.3/10**. Drift de documentación — no es grave, pero mina la credibilidad del "auto-scoring" si ni el propio repo se mantiene sincronizado con su métrica insignia.

### 2.4 Dependabot con ecosistema irrelevante
`.github/dependabot.yml` incluye `package-ecosystem: "nuget"`, pero no hay evidencia de archivos `.csproj`/`.sln`/NuGet en el repo (es 100% PowerShell + npm + markdown). Ese bloque no hace nada útil y genera ruido/falsos positivos de configuración.

---

## 3. Seguridad

### 3.1 Modelo de permisos contradictorio (hallazgo más importante)
En `opencode.json`, los agentes "analiz-only" (seguridad, SEO, infra, frontend, performance, datascience, docs) usan el prompt `_analyze-only-protocol.md` — es decir, **su rol declarado es solo analizar, no modificar**. Sin embargo, su bloque de permisos real es:
```json
"permission": { "bash": "allow", "edit": "deny", "read": "allow", "write": "allow" }
```
- `edit: deny` pero `write: allow` es contradictorio — `write` permite crear/sobrescribir archivos igualmente.
- `bash: allow` sin restricciones en un agente que se supone "solo lee" contradice el propósito de aislamiento (uno de tus propios skills se llama `subagent-isolation`).

**Riesgo real:** un agente "gentleman-security" (que analiza vulnerabilidades) técnicamente puede ejecutar cualquier comando de shell y escribir archivos, pese a que su diseño conceptual asume que es de solo lectura. Esto rompe el modelo de "blast radius" que documentaste bien en otros lados (defensa en profundidad).

**Fix sugerido:** para agentes `_analyze-only-protocol`, usar `"write": "deny"` y `"bash": "ask"` o una allowlist explícita de comandos de solo lectura (`git diff`, `git log`, `grep`, etc.).

### 3.2 Permiso bash global muy amplio
```json
"permission": { "bash": { "*": "allow", "git commit *": "ask", "git push": "ask", ... } }
```
Todo comando bash está permitido por defecto salvo una lista corta de operaciones git destructivas. Para un entorno con 12 agentes autónomos operando sobre tu filesystem real (Windows), esto es una superficie de ataque amplia frente a prompt injection vía contenido externo (páginas web, resultados de MCP, archivos de terceros que el agente pueda leer). No hay allowlist positiva, solo denylist.

### 3.3 Puntos positivos de seguridad
- `check-mcp-security.ps1` es un script serio: valida origen de servidores MCP, transporte, exposición de tokens, presupuesto de herramientas (<50) y riesgo de supply chain (`npx -y`). Buena práctica poco común.
- `opencode.json` deniega lectura de `.env`, `credentials.json`, `secrets/**` explícitamente — correcto.
- No se detectaron secretos hardcodeados (API keys, passwords) en el código escaneado.
- No hay uso de `Invoke-Expression`/`iex` sobre input dinámico — evita una clase entera de inyección de comandos en PowerShell.

### 3.4 Riesgo de cadena de suministro
El uso de `npx -y @upstash/context7-mcp@3.2.2` y similares está versionado (bien), pero sigue dependiendo de resolución de paquetes npm en cada arranque de MCP — vale la pena evaluar `npm ci`/lockfile o vendoring si la estabilidad es crítica.

---

## 4. Testing / Calidad — el gap más grande

Pese a que el proyecto declara TDD ("Test-first, code-after") y "Triple verify (E1/E2/E3)" como pilar central:
- Solo existe **un archivo de test real**: `scripts/score-auto.tests.ps1`.
- 58 scripts PowerShell y 58 skills **no tienen cobertura de test automatizada** más allá de chequeos de sintaxis (`ParseFile`) y linters (PSScriptAnalyzer).
- El "triple verify" (E1/E2/E3) descrito en el README parece ser una verificación de **agentes LLM revisándose entre sí**, no tests unitarios tradicionales — válido como capa adicional, pero no sustituye tests deterministas para scripts críticos (instaladores, `skill-graph.ps1`, `score-auto.ps1`).

**Recomendación:** priorizar Pester tests para los scripts de mayor impacto/tamaño (`skill-graph.ps1` 478 líneas, `score-auto.ps1` 251 líneas, `setup-machine.ps1` 344 líneas) ya que son los que más rompen si fallan silenciosamente.

---

## 5. Rendimiento / Optimización

### Positivo
- `skill-graph.ps1`: resolución BFS de skills con carga "sparse" (reducción declarada de 85-92% de contexto cargado) — buena decisión de diseño para no saturar la ventana de contexto del agente.
- Límite de 3KB por skill, con gate en CI que advierte overweight (solo 1 skill lo excede: `dreaming/SKILL.md` a 3.7KB — menor).
- `token-count.ps1` y `benchmark.ps1` dan visibilidad de costo de contexto — poco común en proyectos de este tipo.

### A vigilar
- 79 marcadores TODO/FIXME/HACK en el código — volumen considerable para un repo que se autocalifica 10/10 en "Clean Code" (9.9) y "Dead Code" (10.0). Vale la pena una pasada de limpieza o al menos triage.
- Scripts largos (`skill-graph.ps1` 478 líneas, `wisdom-forge.ps1` 380 líneas) — candidatos a modularización si su complejidad ciclomática crece.
- 49-58 scripts PowerShell es una superficie de mantenimiento grande para un proyecto individual; el riesgo no es rendimiento en runtime sino **costo de mantenimiento humano** a mediano plazo.

---

## 6. Gaps / Deuda arquitectónica

1. **Dependencia crítica de modelos "free tier"/stealth de OpenCode Zen** (Big Pickle, Nemotron 3 Ultra Free, DeepSeek V4 Flash Free, Kimi K2.5 Free, Mimo v2.5 Free). Estos modelos están documentados como "por tiempo limitado" — si OpenCode los retira o cambia sus términos, **7 de los 12 agentes quedan sin modelo asignado** de un día para otro. No hay fallback declarado en `opencode.json` (no hay `model_fallback` ni segunda opción).
2. **Acoplamiento a Windows como plataforma primaria.** El soporte Linux/macOS (`install.sh`, `setup-machine.sh`) parece añadido después (ver CHANGELOG: "bash equivalent... for portability") — coherente con tu perfil (trabajas en CDMX pero la mayoría de scripts asumen PowerShell 7.6 con `#requires`).
3. **No hay `opencode.json` schema-linted en CI** más allá de que exista el archivo — un typo en el JSON de agentes no se detecta automáticamente salvo que rompa el arranque de OpenCode.
4. **README vs código:** cuenta de skills fluctúa (69 mencionadas en el README anterior, 58 reales en este snapshot, 64 en `.project.json`) — sugiere que el README no se regenera automáticamente pese a existir `!score`/`docs update` como comando.

---

## 7. Recomendaciones priorizadas

| Prioridad | Acción | Esfuerzo |
|---|---|---|
| 🔴 Alta | Fix ruta `CHANGELOG.md` → `docs/CHANGELOG.md` en `release.yml` | 1 línea |
| 🔴 Alta | Revisar permisos de agentes `_analyze-only-protocol`: `write: deny`, `bash: ask`/allowlist | Medio |
| 🟠 Media | Definir fallback de modelo para agentes en free-tier (evitar punto único de fallo) | Medio |
| 🟠 Media | Añadir tests Pester reales a los 3-5 scripts más críticos/largos | Alto |
| 🟡 Baja | Limpiar/triage de los 79 TODO/FIXME | Bajo |
| 🟡 Baja | Quitar bloque `nuget` de dependabot.yml (no aplica) | 1 línea |
| 🟡 Baja | Corregir el `catch {}` vacío en `wisdom-stats.ps1` | 1 línea |
| 🟡 Baja | Automatizar sincronía README ↔ `.project.json` (conteo de skills, score) | Bajo |

---

## 8. Conclusión

El proyecto tiene un nivel de ingeniería de prompts y de meta-tooling (auto-scoring, ciclos de mejora, bias calibration) muy por encima del promedio de setups personales de agentes IA. La mayor brecha no está en la sofisticación conceptual sino en tres puntos concretos y accionables: **un CI roto de forma silenciosa, un modelo de permisos que no refleja la intención de "solo análisis" declarada en los prompts, y una ausencia casi total de tests deterministas** pese a que "TDD" y "triple verify" son pilares centrales del propio proyecto. Ninguno es difícil de corregir; todos son baratos de arreglar en relación al valor que ya tiene el sistema.
