# Propuesta: Fusion de Arquitecturas — gentleman-agent-gh + gentle-orchestrator

> **Fecha**: 2026-08-12
> **Autor**: gentle-orchestrator
> **Estado**: PROPUESTA (pendiente de aprobacion)
> **Repo objetivo**: `gentle-agent-fused` (nuevo proyecto)

---

## Resumen Ejecutivo

Fusionar lo mejor de **gentleman-agent-gh** (framework multi-agente completo con 45 agentes, 78 skills, scoring automatico y auto-mejora) con **gentle-orchestrator** (orquestacion nativa first, lossless blocking prompts, receipt-driven development) en un unico sistema hibrido que mantenga:

- **Multi-agente** por especialidad (de GH)
- **Orquestacion nativa** con autoridad first (de Orch)
- **Scoring automatico** en 13 dimensiones (de GH)
- **Lossless blocking** para decisiones (de Orch)
- **Auto-mejora continua** con backlog priorizado (de GH)

**Objetivo**: Un sistema que sea simultaneamente completo (como GH) y seguro (como Orch).

---

## 1. Arquitectura Propuesta

### 1.1 Capa de Agentes (fusion)

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE ORQUESTACION                      │
│                                                              │
│  ┌──────────────────┐    ┌──────────────────────────────┐   │
│  │  gentle-orchestr │    │  Native Review Authority      │   │
│  │  (Orch)          │◄──►│  (Receipt-first, bounded)    │   │
│  │  Modelo: default │    │                              │   │
│  └────────┬─────────┘    └──────────────────────────────┘   │
│           │                                                  │
│  ┌────────▼─────────────────────────────────────────────┐   │
│  │           CAPA DE ESPECIALISTAS (de GH)               │   │
│  │                                                       │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐ │   │
│  │  │  deep    │ │  codex   │ │  quick   │ │security │ │   │
│  │  │  (nemot) │ │  (deepsk)│ │  (mimo)  │ │ (nemot) │ │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └─────────┘ │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐ │   │
│  │  │  seo     │ │  infra   │ │ frontend │ │  perf   │ │   │
│  │  │  (nemot) │ │  (deepsk)│ │  (kimi)  │ │ (nemot) │ │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └─────────┘ │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐             │   │
│  │  │datascienc│ │  docs    │ │implement.│             │   │
│  │  │  (mimo)  │ │(big-pick)│ │  (deepsk)│             │   │
│  │  └──────────┘ └──────────┘ └──────────┘             │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           CAPA SDD (pipeline nativo)                  │   │
│  │                                                       │   │
│  │  sdd-init -> explore -> propose -> spec -> design     │   │
│  │           -> tasks -> apply -> verify -> archive       │   │
│  │                                                       │   │
│  │  Modelo: hereda del orchestrator (configurable)        │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           CAPA DE REVIEW (fusion)                     │   │
│  │                                                       │   │
│  │  reviewer (4R: Risk/Readability/Reliability/Resil.)   │   │
│  │  + Native Review Authority (receipt, bounded)         │   │
│  │  + Judgment Day (dual adversarial)                    │   │
│  │                                                       │   │
│  │  Modelo: claude-sonnet-4-6 (pago, intencional)        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Tabla de Agentes Fusioados

| Agente | Modelo | Fuente | Permiso | Descripcion |
|--------|--------|--------|---------|-------------|
| `gentle-orchestrator` | default | Orch | bash: deny[17], edit: allow, write: allow | Orquestador principal con native review |
| `gentle-deep` | nemotron-3-ultra-free | GH | bash: deny[17], edit: allow, write: allow | Arquitectura, diseno, codigo complejo |
| `gentle-codex` | deepseek-v4-flash-free | GH | bash: deny[17], edit: allow, write: allow | Generacion de codigo, boilerplate |
| `gentle-quick` | mimo-v2.5-free | GH | bash: deny[17], edit: allow, write: allow | Tareas rapidas, review simple |
| `gentle-security` | nemotron-3-ultra-free | GH | bash: deny[17], edit: deny, write: deny | Analisis de vulnerabilidades (read-only) |
| `gentle-seo` | nemotron-3-super-free | GH | bash: deny[17], edit: deny, write: deny | SEO, GEO, keywords (read-only) |
| `gentle-infra` | deepseek-v4-flash-free | GH | bash: deny[17], edit: deny, write: deny | IaC, K8s, CI/CD (read-only) |
| `gentle-frontend` | kimi-k2.5-free | GH | bash: deny[17], edit: deny, write: deny | React, Tailwind, accesibilidad (read-only) |
| `gentle-performance` | nemotron-3-ultra-free | GH | bash: deny[17], edit: deny, write: deny | Optimizacion, cuellos de botella (read-only) |
| `gentle-datascience` | mimo-v2.5-free | GH | bash: deny[17], edit: deny, write: deny | Pandas, SQL, estadisticas (read-only) |
| `gentle-docs` | big-pickle | GH | bash: deny[17], edit: allow, write: allow | Documentacion tecnica |
| `gentle-implementer` | deepseek-v4-flash-free | GH | bash: deny[17], edit: allow, write: allow | Ejecutor de planes |
| `gentle-reviewer` | claude-sonnet-4-6 | GH+Orch | bash: ask, edit: deny, write: deny | Code review 4R + Native Authority |
| `sdd-orchestrator` | claude-sonnet-4-6 | Orch | bash: deny[17], edit: allow, write: allow | Orquestacion pipeline SDD |

**Subagentes** (delegables via Task, read-only):
- `gentle-deep-sub`, `gentle-codex-sub`, `gentle-quick-sub`, `gentle-implementer-sub`
- `gentle-security-sub`, `gentle-seo-sub`, `gentle-infra-sub`, `gentle-frontend-sub`
- `gentle-performance-sub`, `gentle-datascience-sub`, `gentle-docs-sub`, `gentle-reviewer-sub`

**Agentes SDD** (heredan modelo del orchestrator):
- `sdd-init`, `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`
- `sdd-tasks`, `sdd-apply`, `sdd-verify`, `sdd-archive`

---

## 2. Sistema de Permisos Fusionado

### 2.1 Tres Modos (de GH) + Native Authority (de Orch)

| Modo | Comportamiento | Uso |
|------|----------------|-----|
| `manual` | Cada comando pide aprobacion | Desarrollo inicial, aprendizaje |
| `semi` | Comandos seguros auto-aprobados, escrituras/commits preguntan | Uso diario (recomendado) |
| `auto` | Todo auto-aprobado excepto push + deletes | CI/CD, automatizacion |

### 2.2 Comandos Denegados Globalmente (17 + extras)

```json
{
  "bash": {
    "*": "ask",
    "npm": "deny", "npm *": "deny",
    "pip": "deny", "pip *": "deny",
    "pnpm": "deny", "pnpm *": "deny",
    "bun": "deny", "bun *": "deny",
    "yarn": "deny", "yarn *": "deny",
    "docker": "deny", "docker compose *": "deny",
    "node": "deny", "node *": "deny",
    "npx": "deny", "npx *": "deny",
    "python": "deny", "python *": "deny",
    "python3": "deny", "python3 *": "deny",
    "ruby": "deny", "ruby *": "deny",
    "perl": "deny", "perl *": "deny",
    "php": "deny", "php *": "deny",
    "curl": "deny", "curl *": "deny",
    "wget": "deny", "wget *": "deny",
    "ssh": "deny", "ssh *": "deny",
    "cmd /c *": "deny",
    "powershell -c *": "deny",
    "powershell -command *": "deny",
    "git push --force *": "deny",
    "git checkout -- *": "deny",
    "git clean *": "deny",
    "git restore *": "deny",
    "git rm *": "deny",
    "rm": "deny", "rm *": "deny",
    "rm -rf *": "deny",
    "Remove-Item *": "deny"
  }
}
```

### 2.3 Permisos por Modo

| Modo | Bash default | Safe commands | Writes | Commits | Destructive |
|------|-------------|---------------|--------|---------|-------------|
| `manual` | ask | ask | ask | ask | deny |
| `semi` | ask | allow | ask | ask | deny |
| `auto` | allow | allow | allow | allow | deny |

**Safe commands** (auto-aprobados en semi/auto):
- `git status`, `git diff`, `git log`, `git show`, `git branch`
- `Get-ChildItem`, `Get-Content`, `Test-Path`, `Select-String`
- `ls`, `dir`, `cat`, `grep`, `findstr`, `echo`, `pwd`
- `npm run`, `npm test`, `pytest`, `go test`, `cargo test`
- `rg`, `which`

---

## 3. Skills Fusionadas

### 3.1 Heredadas de GH (78 + _shared)

Todas las skills de `gentleman-agent-gh/.agents/skills/` se mantienen:

| Dominio | Skills | Cantidad |
|---------|--------|----------|
| Verificacion | triple-verify, adversarial-breaker, judgment-day, external-auditor, auto-metrics, immune-system, testing-strategy | 7 |
| Codigo | commit-crafter, code-generation, quick-executor, refactoring-planner | 4 |
| Seguridad | security-scanner, auth-hardening, container-security, llm-security | 4 |
| SDD | sdd (unified), sdd-quick, sdd-propose, sdd-design, sdd-apply, sdd-verify | 6 |
| Coordinacion | delivery-harness, branch-pr, issue-creation, command-wrapper | 4 |
| Analisis | analysis-mode, deep-debugging | 2 |
| Memoria | session-resume, engram-protocol, dreaming, bitacora | 4 |
| Meta | opencode-skill-creator, skill-registry, skill-graph | 3 |
| Ingenieria | plan-execution, infra-audit, perf-profiling | 3 |
| UI/Docs | baseline-ui, ui-engine, accessibility, seo, docs-audit | 5 |
| Testing | visual-testing, e2e-testing, api-testing, image-pipeline, pdf-utils | 5 |
| Comunicacion | comment-writer | 1 |
| Especializados | karpathy-loop, context-watchdog, recovery-protocol, metricas, workflow-optimizer | 5 |
| Otros | quality-gate, code-review-agent, etc. | 25+ |

### 3.2 Nuevas Skills (de Orch)

| Skill | Proposito |
|-------|-----------|
| `native-review` | Bounded review con autoridad nativa |
| `lossless-blocking` | Preserva envelopes de decision |
| `receipt-driven` | Autoridad antes de materializar |
| `language-domain` | Contrato de localizacion |
| `delegation-rules` | Reglas de delegacion por topologia |

### 3.3 Resolucion de Skills

```
1. Intentar resolucion BFS (de GH) con keyword scoring
2. Si no matchea, usar skill tool de OpenCode (de Orch)
3. Fallback: leer SKILL.md directamente de disco
4. Validar: skill-validate.ps1
```

---

## 4. Scoring Automatico (de GH)

### 4.1 Dimensiones (13)

| # | Dimension | Sub-dims | Peso |
|---|-----------|----------|------|
| 1 | Project Artifacts | readme, changelog, cross_ref, skills, project_json, roadmap | 1x |
| 2 | Security | crypto, secrets | 1x |
| 3 | Dead Code | orphans, junctions, commented | 1x |
| 4 | Clean Code | help_rate, param_rate, strict_rate | 1x |
| 5 | Best Practices | param_cov, trycatch | 1x |
| 6 | Orthography | corruption | 1x |
| 7 | Bitacora | exists, content | 1x |
| 8 | Metrics | metrics_dir, errors_dir, error_json, reports | 1x |
| 9 | Script Performance | count, avg_size, huge | 1x |
| 10 | Skill Effectiveness | skill_count, over_3kb, over_5kb, skill_avg | 1x |
| 11 | Cycle Activity | inter_ratio | 1x |
| 12 | Backlog Integrity | integrity | 1x |
| 13 | Score Depth | (promedio de 1-12) | 0.5x |

### 4.2 Comando

```powershell
.\scripts\score-auto.ps1 -Json | Set-Content .project.json
```

---

## 5. Auto-Mejora Continua (de GH)

### 5.1 Ciclo de Mejora

```
LOOP:
  1. LEER CYCLE.md - entender objetivo y restricciones
  2. DIAGNOSTICAR: score, gaps, skill sizes, cross-ref, PSSA
  3. PUNTUAR backlog por Impacto/Riesgo (IR = Impact / Risk)
  4. IDENTIFICAR candidatos ordenados por IR descendente
  5. PARTICIONAR trabajo independiente -> 3 subagentes paralelos
  6. EJECUTAR:
     a. Delegar a 3 subagentes para verificar gaps
     b. Cada subagente retorna: Hallazgos + Archivos + Decisiones + Evidencia
     c. Log a bitacora + inter-track++
  7. ORQUESTRAR: merge resultados, verificar coherencia
  8. VERIFICAR: re-score, comparar delta
  9. Si score mejoro -> Mantener cambios, avanzar baseline
  10. Si score drop >0.5 -> Revert completo
  11. APRENDER: engram, anti-patterns, CYCLE.md
  12. REPORTAR: escribir docs/ciclos/cycle<N>-YYYYMMDD.md
  13. SCORE AUTO-UPDATE: score-auto.ps1
  14. Si inter>=30 AND no dim<9.0 -> SUCCESS
```

### 5.2 Metricas Clave

| Metrica | Target | Herramienta |
|---------|--------|-------------|
| inter(30) | >=30 interacciones/ciclo | `inter-track.ps1` |
| Score delta | >=9.5 | `score-auto.ps1` |
| Backlog integrity | 0 items con status != realidad | auto-check |
| Skill sizes | 0 >3KB, avg <2.0KB | `benchmark.ps1` |
| Working tree | 0 cambios sin commit | `git status --short` |
| Cross-ref | 0 errores | `cross-ref-check.ps1` |

---

## 6. Native Review Authority (de Orch)

### 6.1 Flujo

```
1. gentle-ai review status -> next_transition
2. Si execute -> ejecutar operacion exacta
3. Si collect -> satisfacer inputs, luego status
4. Si stop -> reportar reason_code + continuation
5. Repetir hasta terminal
```

### 6.2 Receipt-Driven Development

```
1. Autoridad nativa first
2. Receipt antes de materializar
3. Lossless blocking para decisiones
4. Bounded review (no loop-until-clean)
5. Correction budget: min(200, ceil(changed_lines / 2))
```

### 6.3 Cost Forecast (4R)

```
4 lentes sobre el candidato congelado:
- R1 Risk (security, privileges)
- R2 Readability (naming, complexity)
- R3 Reliability (tests, coverage)
- R4 Resilience (fallbacks, retry)

Costo: 4 model runs + 1 bounded correction
```

---

## 7. Lossless Blocking Prompts (de Orch)

### 7.1 Reglas

1. **Preservar envelope completo**: why input is required, every group/question, every option, selection mode, allowed-answer domain
2. **No resumir**: nunca abbreviar, reordenar, relabel, merge, o omitir
3. **Native route**: usar `question` tool cuando sea representable
4. **Fallback**: plain chat cuando native no disponible
5. **Validacion**: aceptar solo respuestas del allowed-answer domain

### 7.2 Ejemplo

```
┌─────────────────────────────────────────────────┐
│  SDD Session Preflight                          │
│                                                  │
│  1. Pace: Interactive, Automatic                 │
│  2. Artifacts: OpenSpec, Engram, Both            │
│  3. PRs: Ask me, Single PR, Auto                │
│  4. Review: 400 lines, 800 lines, Other         │
└─────────────────────────────────────────────────┘
```

---

## 8. Estructura de Directorios Propuesta

```
gentle-agent-fused/
  .agents/
    skills/                  # 78+ skills (canonical, git-tracked)
      _shared/               # Referencias compartidas
      native-review/         # Nueva: de Orch
      lossless-blocking/     # Nueva: de Orch
      receipt-driven/        # Nueva: de Orch
  skills/                    # Junctions workspace (git-ignored)
  scripts/                   # 91+ scripts (de GH)
    smoke/                   # Smoke tests
    adversarial-rules/       # Reglas adversariales
    lib/                     # Librerias compartidas
    opencode-config/         # Config de OpenCode
    tests/                   # Tests de scripts
  docs/
    adr/                     # Architecture Decision Records
    agentes/                 # Documentacion de agentes
    compliance/              # Compliance
    cross-project/           # Cross-project patterns
    design/                  # Disenos
    mejoras/                 # Mejoras propuestas
    metricas/                # Metricas de sesion
    operations/              # Quality standard, runbooks
    sdd/                     # Documentacion SDD
    propuestas/              # Propuestas de mejora
    encontrado/              # Analisis de repositorios
  .learnings/                # Session mining + bias calibration
  .jd-cleared/               # Judgment Day clearance markers
  .githooks/                 # Git hooks personalizados
  .opencode/                 # Config de OpenCode
  benchmarks/                # Benchmarks
  commands/                  # Comandos reales
  data/                      # Datos
  tests/                     # Tests Pester
  prompts/
    sdd/                     # Prompts SDD
    shared/                  # Prompts compartidos
  opencode.json              # Config de agentes y permisos
  AGENTS.md                  # Protocolo principal (fusionado)
  PROTOCOL.md                # Reglas operativas
  SHORTCUTS.md               # Todos los shortcuts
  SKILLS-INDEX.md            # Tabla de triggers
  CYCLE.md                   # Manifiesto de mejora continua
  CONTRIBUTING.md            # Como contribuir
  CHANGELOG.md               # Historial
  .gentleman-mode             # Modo de permisos
  .project.json              # Score auto-generado
```

---

## 9. opencode.json Fusionado (esquema)

```json
{
  "model": "opencode/big-pickle",
  "agent": {
    "gentle-orchestrator": {
      "description": "Orquestador principal con native review authority",
      "model": "opencode/big-pickle",
      "mode": "primary",
      "prompt": "{file:prompts/gentle-orchestrator.md}\n\n{file:prompts/shared/_core-behavior-gp.md}",
      "permission": {
        "bash": {
          "*": "ask",
          "Get-ChildItem *": "allow",
          "git status *": "allow",
          "git diff *": "allow",
          "git log *": "allow",
          "npm": "deny", "npm *": "deny",
          "docker": "deny", "docker *": "deny",
          "ssh": "deny", "ssh *": "deny",
          "rm": "deny", "rm *": "deny",
          "rm -rf *": "deny"
        },
        "edit": "allow",
        "write": "allow"
      },
      "tools": {
        "engram*": true,
        "codebase-memory*": true
      }
    },
    "gentle-deep": {
      "description": "Arquitectura, diseno, codigo complejo (FREE)",
      "model": "opencode/nemotron-3-ultra-free",
      "mode": "primary",
      "prompt": "{file:prompts/gentle-deep.md}",
      "permission": {
        "bash": { "*": "deny" },
        "edit": "allow",
        "write": "allow"
      }
    },
    "gentle-codex": {
      "description": "Generacion de codigo, boilerplate (FREE)",
      "model": "opencode/deepseek-v4-flash-free",
      "mode": "primary",
      "prompt": "{file:prompts/gentle-codex.md}",
      "permission": {
        "bash": { "*": "deny" },
        "edit": "allow",
        "write": "allow"
      }
    },
    "gentle-quick": {
      "description": "Tareas rapidas, review simple (FREE)",
      "model": "opencode/mimo-v2.5-free",
      "mode": "primary",
      "prompt": "{file:prompts/gentle-quick.md}",
      "permission": {
        "bash": { "*": "deny" },
        "edit": "allow",
        "write": "allow"
      }
    },
    "gentle-security": {
      "description": "Analisis de vulnerabilidades (read-only, FREE)",
      "model": "opencode/nemotron-3-ultra-free",
      "mode": "primary",
      "prompt": "{file:prompts/gentle-security.md}",
      "permission": {
        "bash": { "*": "ask" },
        "edit": "deny",
        "write": "deny"
      }
    },
    "gentle-reviewer": {
      "description": "Code review 4R + Native Authority (STRONG)",
      "model": "claude-sonnet-4-6",
      "mode": "primary",
      "prompt": "{file:prompts/gentle-reviewer.md}\n\n{file:prompts/shared/_return-contract.md}",
      "permission": {
        "bash": { "*": "ask" },
        "edit": "deny",
        "write": "deny"
      },
      "tools": {
        "engram*": true,
        "codebase-memory*": true
      }
    },
    "sdd-orchestrator": {
      "description": "Orquestacion pipeline SDD",
      "model": "claude-sonnet-4-6",
      "mode": "primary",
      "prompt": "{file:prompts/sdd-orchestrator.md}",
      "permission": {
        "bash": { "*": "deny" },
        "edit": "allow",
        "write": "allow"
      }
    }
  }
}
```

---

## 10. Plan de Implementacion

### Fase 1: Foundation (Semanas 1-2)

| Tarea | Esfuerzo | Dependencias |
|-------|----------|--------------|
| Crear repo `gentle-agent-fused` | 1h | Ninguna |
| Copiar estructura de GH | 2h | Repo creado |
| Fusionar AGENTS.md (GH + Orch) | 4h | Estructura copiada |
| Crear prompts fusionados | 6h | AGENTS.md fusionado |
| Configurar opencode.json basico | 2h | Prompts creados |
| **Entregable**: Repo funcional con 5 agentes basicos | | |

### Fase 2: Agentes (Semanas 3-4)

| Tarea | Esfuerzo | Dependencias |
|-------|----------|--------------|
| Migrar 12 especialistas de GH | 8h | Fase 1 |
| Adaptar permisos por modo | 4h | Especialistas migrados |
| Crear subagentes (12) | 6h | Especialistas listos |
| Configurar SDD pipeline (9 agentes) | 4h | Subagentes listos |
| **Entregable**: 45 agentes configurados | | |

### Fase 3: Skills (Semanas 5-6)

| Tarea | Esfuerzo | Dependencias |
|-------|----------|--------------|
| Copiar 78 skills de GH | 2h | Fase 2 |
| Crear 5 nuevas skills de Orch | 6h | Skills copiadas |
| Configurar skill resolution BFS | 4h | Skills creadas |
| Validar con skill-validate.ps1 | 2h | Resolucion configurada |
| **Entregable**: 83 skills funcionales | | |

### Fase 4: Scripts (Semanas 7-8)

| Tarea | Esfuerzo | Dependencias |
|-------|----------|--------------|
| Migrar 91 scripts de GH | 4h | Fase 3 |
| Adaptar scripts a estructura fusionada | 6h | Scripts migrados |
| Configurar hooks de git | 2h | Scripts adaptados |
| Ejecutar smoke tests | 2h | Hooks configurados |
| **Entregable**: 91 scripts funcionales | | |

### Fase 5: Scoring y Auto-Mejora (Semanas 9-10)

| Tarea | Esfuerzo | Dependencias |
|-------|----------|--------------|
| Configurar score-auto.ps1 | 2h | Fase 4 |
| Crear primer CYCLE.md | 4h | Scoring configurado |
| Ejecutar primer ciclo de mejora | 8h | CYCLE.md creado |
| Documentar resultados | 2h | Ciclo ejecutado |
| **Entregable**: Sistema con auto-mejora activa | | |

### Fase 6: Native Review (Semanas 11-12)

| Tarea | Esfuerzo | Dependencias |
|-------|----------|--------------|
| Integrar Native Review Authority | 6h | Fase 5 |
| Configurar receipt-driven development | 4h | Native review integrado |
| Configurar lossless blocking | 4h | Receipt-driven configurado |
| Testing end-to-end | 4h | Todo integrado |
| **Entregable**: Sistema completo fusionado | | |

**Esfuerzo total estimado**: ~100 horas (12 semanas)

---

## 11. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|-------------|---------|------------|
| Conflicto entre permisos GH y Orch | Alta | Alto | Unificar en un solo `opencode.json` con herencia |
| Skills incompatibles | Media | Medio | Validacion con `skill-validate.ps1` en cada fase |
| Scripts que dependen de estructura GH | Alta | Medio | Adaptar paths en Fase 4 |
| Costo de modelos pago (reviewer, SDD) | Media | Alto | Configurar alternativas free para SDD |
| Complejidad de mantenimiento | Alta | Medio | Documentar todo en ADRs |
| Regresion en funcionalidad | Media | Alto | Smoke tests en cada fase |

---

## 12. Metricas de Exito

| Metrica | Target | Medicion |
|---------|--------|----------|
| Agentes funcionales | 45 | `opencode.json` |
| Skills instaladas | 83 | `skill-validate.ps1` |
| Scripts funcionales | 91 | `smoke-all.ps1` |
| Score inicial | >=8.5/10 | `score-auto.ps1` |
| Primer ciclo exitoso | inter>=30 | `inter-track.ps1` |
| Native review funcional | receipt generado | `gentle-ai review status` |
| Lossless blocking funcional | envelopes preservados | Testing manual |

---

## 13. Conclusion

La fusion de **gentleman-agent-gh** y **gentle-orchestrator** crea un sistema que es:

- **Completo**: 45 agentes, 83 skills, 91 scripts, scoring automatico
- **Seguro**: Native review authority, receipt-driven, lossless blocking
- **Auto-mejorable**: Ciclos continuos con backlog priorizado
- **Rentable**: ~60% de agentes en free tier
- **Mantenible**: Estructura clara, documentacion extensa, ADRs

**Recomendacion**: Proceder con la implementacion en fases, priorizando la foundation y los agentes basicos para obtener valor rapido.

---

*Propuesta generada por gentle-orchestrator | 2026-08-12*
*Repo de referencia: D:\gentleman-agent-gh*
