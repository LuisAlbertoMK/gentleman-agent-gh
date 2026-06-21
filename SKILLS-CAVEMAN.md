# Skills — Descripciones Caveman

> 62 skills · Caveman-style + espacio para comentarios.
> Si algo necesita cambio, anotalo en la columna **✏️ Cambio**.

---

## 🔧 SDD — Spec-Driven Development (10)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **sdd** | Pipeline único. 9 fases. Init→Archive. Carga skills, orquesta. | |
| **sdd-init** | Escanea proyecto. Detecta stack. Inicializa config SDD. | |
| **sdd-explore** | Explora codebase. Busca entry points, patrones, deps. | |
| **sdd-propose** | Define qué cambiar. Scope + riesgos + rollback. | |
| **sdd-spec** | Escribe specs Given/When/Then. RFC 2119. | |
| **sdd-design** | Diseño técnico. Diagramas, archs, plan de cambios. | |
| **sdd-tasks** | Parte specs en tareas. Workload + PR split. | |
| **sdd-apply** | Implementa desde tasks. TDD primero. | |
| **sdd-verify** | Valida contra specs. Compliance + build. | |
| **sdd-archive** | Archiva cambios. Merge a main. Rollback snapshot. | |

---

## 🔍 Review & Quality (6)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **quality-gate** | Pre-commit. Tests + secrets + PSSA. Gate autoritario. | |
| **code-review-agent** | 4R review. Risk/Readability/Reliability/Resilience. + evidencia. | |
| **judgment-day** | Dual review. 2 code-review-agent con perfiles distintos. Síntesis. | |
| **review-pipeline** | Pipeline: quality-gate → 4R → commit-crafter. Gatillado. | |
| **triple-verify** | 3 enfoques: testing + estático + build. Por zona ROJA/AMAR/VERDE. | |
| **security-scanner** | Escanea secrets, injection, vulns, APIs peligrosas. Pre-commit. | |

---

## 📐 Arquitectura & Diseño (4)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **senior-engineer** | 15 competencias senior. System design, trade-offs, delegación. | |
| **cognitive-doc-design** | Docs que no queman contexto. READMEs, RFCs, guías. | |
| **gap-analysis** | 8 dims. Score 1-10. Priority scoring. 7 templates por tipo. | |
| **refactoring-planner** | Plan de refactor. Impacto + deps + migración paso a paso. | |

---

## 🚀 Entrega & Git (5)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **commit-crafter** | Commits convencionales desde diff. | |
| **branch-pr** | PR workflow. Issue-first + branch naming + validación. | |
| **chained-pr** | PRs apilados. Split >400L. Deps claras. Rebase cascade. | |
| **work-unit-commits** | Commits revisables. 1 deliverable por commit. Clean rollback. | |
| **ci-cd** | Setup CI/CD. GitHub Actions + pre-push gate + SDD spec coverage. | |

---

## 🧪 Testing (2)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **go-testing** | Patrones Go. Table-driven, teatest, golden files, mocks. | |
| **python-async** | Async/await Python. gather vs TaskGroup. Deadlock prevention. | |

---

## 🌐 Web Quality (6)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **performance** | Optimiza web. Lighthouse + CWV + caching + images + fonts. (Mergeó core-web-vitals). | |
| **accessibility** | WCAG 2.2 AA. Patrones ARIA, focus trap, skip links. | |
| **seo** | Technical SEO + on-page + structured data + crawlability. | |
| **web-quality-audit** | Auditoría completa. Performance + A11y + SEO + Best practices. | |
| **baseline-ui** | Anti-slop UI. Spacing, jerarquía, tipografía. CSS/Tailwind. | |
| **performance-tracker** | Score y trend de performance. 6 dims. | |

---

## 🤖 Prompting & Compresión (4)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **karpathy-loop** | Loop write→measure→cut→repeat. Reglas de estilo absorbidas de karpathy-prompt. | |
| **lean-context** | 3 niveles: LEAN/ULTRA/CAVEMAN. Comprime respuestas. | |
| **prompt-engineering** | SPEARS + ReAct + Multi-Agent + Security. Framework completo. | |
| **research** | Research estructurado. Scope→evidence→synthesis→document. | |

---

## 🧠 Memoria & Persistencia (5)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **code-memory** | Memoria entre sesiones. Task state + handoff + auto-save. | |
| **bitacora** | Log histórico de requests. BITACORA.md. Búsqueda + fechas. | |
| **decision-capture** | Captura decisiones técnicas. Structured mem_save. | |
| **dreaming** | Pattern extraction cross-session. 5 modos. Engram mining. | |
| **session-resume** | Resume seguro. Git state gate + skill pre-load + Engram recall. | |

---

## 🧰 Meta-Skills (9)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **skill-creator** | Crea skills nuevas. Bootstrap + SKILL.md + register. | |
| **skill-improver** | Audita y mejora skills. Frontmatter, reglas, usage tracking. (Mergeó skill-refresher) | |
| **skill-testing** | Testea skills. Syntax, coverage, integration, token budget. | |
| **skill-graph** | Sparse loading. Skills relevantes por task via dependency graph. | |
| **skill-digestion** | Digiere skills on load. Context budget. Auto-improvement trigger. | |
| **skill-registry** | Catálogo de skills. Scan + dedup + compact + persist. | |
| **self-improvement** | Ciclo macro. Diagnose→fix→verify→learn. inter(30). | |
| **self-reflection** | Loop por-task. Reflect→learn→improve. Inner loop de self-improvement. | |
| **immune-system** | Inmunidad contra errores repetidos. Anti-pattern catalog + reglas. | |

---

## 🎯 Ejecución & Contexto (6)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **execution-mode** | QUICK/THOROUGH/DRAFT. Auto-detecta según scope/riesgo. | |
| **context-watchdog** | Monitorea contexto. L1/L2/L3 compression. Zones GREEN→RED. | |
| **development-mode** | Prioriza recursos. RAM, CPU, GPU, file I/O. | |
| **opencode-model-router** | Rutea tasks por modelo. Directo vs delegado vs subagente. | |
| **subagent-isolation** | Aísla subagentes. Previene hallucination cascade + cross-contamination. | |
| **delivery-harness** | Multi-agent orchestrator. Goals→work units→delegate→collect. | |

---

## 🔬 Auditoría & Métricas (4)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **auto-metrics** | Post-task self-eval. 7 dims + skill validation multi-trial. | |
| **metricas** | Before/after comparison. Delta + % + tokenization. | |
| **external-auditor** | Blind second opinion via subagent. Contra overconfidence. | |
| **project-mapper** | Escanea estructura. Tech stack + arch + dependency map. Auto-chain a gap-analysis. | |

---

## 🛡️ Seguridad & Recuperación (3)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **security-scanner** | Secrets + injection + vulns + dangerous APIs. Pre-commit. | |
| **recovery-protocol** | Stop→diagnose→correct→learn. Errores de agente. | |
| **immune-system** | Error repetido → inmunidad permanente. Anti-pattern + rule. | |

---

## 🧩 Utilidades (3)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **command-wrapper** | Ejecuta comandos safe. Descripción + error handling + parseo. | |
| **best-practices** | Web dev best practices. Security + compat + quality. | |
| **comment-writer** | Comentarios warm + directos. PR feedback, issues, reviews. | |

---

## 📋 Issues & Documentación (3)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **issue-creation** | GitHub issues con templates. Bug reports + feature requests. | |
| **cognitive-doc-design** | Docs de bajo esfuerzo cognitivo. READMEs, RFCs, onboarding. | |
| **comment-writer** | Escribe comentarios colaborativos. PRs, Slack, issues. | |

---

## 📦 Shared (1)

| Skill | Caveman | ✏️ Cambio |
|-------|---------|-----------|
| **_shared** | No invocable. Reference docs para pipeline SDD. | |

---

> **Total: 62 skills** · Creado 2026-06-21 post-audit (compresión + fusión + cleanup)
