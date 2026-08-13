# Auditoría técnica — gentleman-agent-gh (rama `main`)

**Fecha:** 2026-08-11 · **Módulo:** `github.com/gentleman-programming/gentle-ai/v2` · **Go 1.25.10**
**Alcance:** arquitectura, deuda técnica, calidad, seguridad · **Método:** análisis estático manual (sin `go` disponible en el entorno — no se ejecutó `go vet`/`go test`/`go build`)

---

## 1. Resumen ejecutivo

| Métrica | Valor |
|---|---|
| LOC total (internal+cmd+bench) | ~300,000 |
| Archivos fuente (no test) | 354 |
| Archivos de test | 469 |
| TODO/FIXME/HACK marcados | 1 |
| Paquetes con `panic()` fuera de tests | 5 |
| `os.Exit()` fuera de tests | 10 |
| Interfaces (`type X interface`) | 14 |

**Veredicto general:** proyecto maduro, con disciplina de testing alta (ratio test/fuente >1) y CI robusto multiplataforma. El riesgo principal no es "código descuidado" sino **concentración de complejidad en pocos archivos gigantes** y **ausencia de tooling de calidad automatizado** (linter estático, security scanner, coverage tracking).

---

## 2. Arquitectura

### 2.1 Distribución de tamaño por paquete

| Paquete | LOC | Nota |
|---|---|---|
| `internal/reviewtransaction` | 34,081 | El más grande del repo con margen — núcleo del sistema de revisión transaccional |
| `internal/cli` | 20,594 | Comandos CLI |
| `internal/components` | 15,702 | Adapters/inyectores por herramienta (sdd, engram, persona, etc.) |
| `internal/tui` | 11,755 | Interfaz de terminal (Bubble Tea) |
| `internal/sddstatus` | 6,076 | Estado de flujo SDD |
| `internal/agents` | 4,557 | Adapters de agentes IA (claude, codex, gemini, opencode…) |

`reviewtransaction` concentra >11% del código total del repo en un solo paquete. Es razonable si es el dominio central (parece serlo, dado `docs/review-integration.md` de 64K y `docs/review-authority-threat-model.md`), pero vale la pena confirmar que no está absorbiendo responsabilidades que deberían vivir en paquetes vecinos.

### 2.2 God files — top 5

| Archivo | Líneas | Funciones |
|---|---|---|
| `internal/tui/model.go` | 4,934 | 130 |
| `internal/cli/review_facade.go` | 4,032 | 91 |
| `internal/components/sdd/inject.go` | 2,650 | — |
| `internal/cli/run.go` | 2,447 | — |
| `internal/reviewtransaction/compact_store.go` | 2,326 | — |

**Oportunidad de mejora:** `model.go` (TUI) y `review_facade.go` (CLI) son los dos archivos más grandes del repo y ambos superan las 4,000 líneas con >90 funciones cada uno. Esto normalmente indica que el archivo está actuando como fachada/router de responsabilidades múltiples que podrían dividirse por sub-dominio (p. ej. `model.go` → separar handlers de mensajes por tipo de evento en archivos propios, patrón que Bubble Tea admite bien).

### 2.3 Patrón de adapters (multi-agente)

El repo sigue consistentemente un patrón de adapter por herramienta de IA (`claudeAdapter`, `opencodeAdapter`, `geminiAdapter`, `hermesAdapter`, `antigravityAdapter`, `openclawAdapter` — 5-8 implementaciones cada uno). Esto es **arquitectura intencional y sana**, no duplicación: cada adapter encapsula las particularidades de su herramienta externa. No se marca como hallazgo negativo.

---

## 3. Deuda técnica

### 3.1 Duplicación real confirmada — `readFileOrEmpty`

Encontradas **4 implementaciones** de la misma función en distintos paquetes de `internal/components/`:

```
internal/components/agentguidance/inject.go   → delega a readBytesOrEmpty (distinta)
internal/components/engram/inject.go          → implementación completa idéntica
internal/components/persona/inject.go         → implementación completa idéntica
internal/components/sdd/inject.go             → implementación completa idéntica
```

Tres copias son **byte-idénticas**:
```go
func readFileOrEmpty(path string) (string, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        if os.IsNotExist(err) {
            return "", nil
        }
        return "", fmt.Errorf("read file %q: %w", path, err)
    }
    ...
}
```

**Recomendación:** extraer a un paquete util compartido (p. ej. `internal/fsutil`) y hacer que los 3-4 paquetes importen desde ahí. Riesgo bajo, esfuerzo bajo, beneficio: un solo punto de mantenimiento si cambia el manejo de errores de lectura de archivos.

### 3.2 TODOs casi inexistentes (1 en 300K líneas)

Puede leerse de dos formas:
- **Lectura optimista:** disciplina alta, no se deja deuda sin resolver.
- **Lectura de riesgo:** la deuda técnica existe pero no se está marcando explícitamente, lo cual dificulta rastrearla (nadie puede grep-ear lo que no está anotado).

Dado el tamaño del repo y la complejidad de los god files identificados en 2.2, es más probable la segunda lectura. **Recomendación:** adoptar convención de `// TODO(usuario): razón` en refactors futuros para que la deuda quede trazable.

### 3.3 Uso de `panic()` fuera de tests (5 ocurrencias)

```
internal/components/opencodedefault/ownership.go
internal/components/engram/inject.go
internal/agents/pi/adapter.go
internal/agents/capabilitymanifest/manifest.go
internal/assets/assets.go
```

En una CLI, `panic()` no capturado en código de librería puede crashear el proceso sin contexto útil para el usuario final. **Recomendación:** revisar cada uno — si son invariantes de inicialización (`assets.go` con `embed.FS` suele ser legítimo), está bien; si son paths alcanzables por input de usuario o del sistema de archivos, deberían convertirse en `error` propagado.

---

## 4. Seguridad

### 4.1 Ejecución de comandos externos (`exec.Command`) — 21 archivos

Se identificaron 21 archivos que invocan procesos externos (`git`, `go`, `claude`, `opencode`, `gemini`, `codex`, PowerShell, GitHub CLI). **Punto positivo:** en los puntos revisados (`run.go`, `agentbuilder/engine.go`, `powershell.go`), el patrón consistente es `exec.Command(name, args...)` con argumentos como slice, **no** interpolación de string hacia una shell — esto evita la clase más común de inyección de comandos (`sh -c "cmd " + input`). Buena práctica sostenida.

**Recomendación de verificación adicional:** no fue posible auditar los 21 archivos en profundidad en esta pasada. Vale la pena un segundo paso enfocado sólo en `exec.Command` que confirme que ningún `args` se construye concatenando input de usuario sin sanitizar antes de pasarlo (ej. rutas de archivo, nombres de branch de git).

### 4.2 Ausencia de escaneo de seguridad automatizado

El CI (`ci.yml`) no incluye `gosec`, `govulncheck`, ni CodeQL. Para un proyecto que ejecuta comandos del sistema y maneja locks de archivos multiplataforma (`reviewtransaction`, `sddstatus`), esto es una brecha real.

**Recomendación:** agregar un job de `govulncheck ./...` (gratuito, oficial de Go, detecta dependencias con CVEs conocidos) como mínimo viable. `gosec` como siguiente paso.

### 4.3 GitHub Actions pineadas por SHA

Punto positivo confirmado: todas las actions en `ci.yml` están pineadas por commit SHA completo (no por tag mutable), que es la práctica recomendada contra supply-chain attacks en Actions.

---

## 5. Calidad y CI/CD

### 5.1 Pipeline actual (`.github/workflows/ci.yml` + otros)

| Job | Qué hace |
|---|---|
| Go Format | `gofmtcheck` |
| Unit Tests | `go test ./...` + `deadcode-ratchet.sh` |
| Windows Runtime | build + suite de tests específicos de Windows (locks, ACLs) |
| Darwin Runtime | `darwin-release-blockers.sh` |
| Organic Runtime E2E | instala `opencode-ai` real y corre e2e |
| E2E Tests | matriz multiplataforma vía Docker (Arch/Fedora/Ubuntu) |

Es un pipeline **inusualmente completo** para un proyecto de este tamaño — cubre concurrencia de locks, permisos de Windows/ACLs, y e2e contra herramientas reales, no sólo mocks. Punto fuerte claro del repo.

### 5.2 Gaps identificados

| Falta | Impacto |
|---|---|
| Linter estático (`golangci-lint` / `staticcheck`) | Bugs de estilo, código muerto no ratcheted, posibles nil-derefs no capturados por `go vet` básico |
| Coverage tracking (`-coverprofile`) | No hay visibilidad de qué % del código gigante en `reviewtransaction`/`cli` está realmente cubierto vs. sólo tiene archivo `_test.go` presente |
| `govulncheck` / `gosec` | Ver 4.2 |
| Dependabot | Mitigado parcialmente — usan Renovate (`renovate.json`), que cubre el mismo caso de uso |

### 5.3 `deadcode-ratchet.sh`

Positivo: el repo ya tiene mecanismo de "ratchet" contra código muerto, lo cual sugiere que el equipo es consciente del riesgo de acumulación en un repo de este tamaño y ya mitiga activamente una de las formas de deuda técnica más comunes.

---

## 6. Documentación

- README de 28K, PRDs de 44K y 68K, `docs/` con 3.2M en subcarpetas (`architecture`, `audits`, `testing`, `releases`) — documentación extensa y activamente mantenida.
- `openspec/` con 17 changes y 9 specs activas — el proyecto usa spec-driven development de forma explícita, coherente con el propósito del repo (herramienta SDD para agentes).
- `docs/audits/` ya existe — sugiere que auditorías internas previas se han hecho y archivado; vale la pena revisar esa carpeta antes de repetir hallazgos ya conocidos por el equipo.

---

## 7. Priorización de acciones (impacto vs. esfuerzo)

| # | Acción | Esfuerzo | Impacto |
|---|---|---|---|
| 1 | Extraer `readFileOrEmpty` duplicado a util compartido | Bajo | Bajo-medio (mantenibilidad) |
| 2 | Agregar `govulncheck ./...` al CI | Bajo | Medio-alto (seguridad, gratis) |
| 3 | Agregar `golangci-lint` con config mínima al CI | Medio | Alto (calidad sostenida) |
| 4 | Auditar los 21 puntos de `exec.Command` por sanitización de args | Medio | Alto (seguridad) |
| 5 | Medir y publicar coverage (`-coverprofile` + badge) | Bajo | Medio (visibilidad) |
| 6 | Dividir `tui/model.go` y `cli/review_facade.go` por sub-responsabilidad | Alto | Medio-alto (mantenibilidad a largo plazo) |
| 7 | Revisar los 5 `panic()` fuera de test — confirmar que ninguno es alcanzable por input externo | Bajo | Medio (robustez) |

---

## 8. Limitaciones de esta auditoría

- No se pudo ejecutar `go build`, `go vet`, `go test` ni ningún linter real: el entorno de análisis no tiene Go instalado y no hay acceso de red a los mirrors de Go/proxy de módulos.
- El análisis de duplicación y complejidad es por patrón textual (`grep`), no AST — puede haber falsos negativos en duplicación semántica (misma lógica, distinto código).
- Con 300K líneas, esta pasada priorizó profundidad en los paquetes más grandes y en seguridad de `exec.Command`; no se revisó línea por línea `internal/components` (15.7K) ni `internal/reviewtransaction` en su totalidad.
