# Plan de Mejora — PROMPT-auditoria-multiagente v2

> **Source**: `docs/PROMPT-auditoria-multiagente.md` (166 lines, current v1)
> **Target**: Apply this plan to produce v2 of that file.
> **Scope**: Research/analysis → implementation guide. NO code changes outside the .md.
> **Status**: Drafted from `!analisis` multi-agent exploration (explore subagent, very thorough).
> **Date**: 2026-07-05
> **Authority**: Any implementing agent MUST follow this document end-to-end without skipping sections.

---

## 0. How to use this document

This is a **spec-style execution plan**. The implementing agent (you) must:

1. Read sections 1–4 fully before touching the source `.md`.
2. Apply changes in the order listed in section 5 (Implementation Order). Do NOT reorder.
3. Respect the **Non-Goals** (section 6) — they are as binding as the goals.
4. Run the **Self-Verification Checklist** (section 7) before declaring done.
5. Produce a single commit named per section 8 if the user authorizes `!ship`.

**Hard rules:**
- Do NOT add more than 1 new subagent beyond the 24 existing (target ceiling: 25 total).
- Do NOT introduce dependencies on external tools that aren't already named in v1 or in section 3.4 (Tools Reference).
- Do NOT rewrite v1 from scratch — patch it surgically. The 9 existing categories stay.
- Do NOT change the 6-phase flow. Only enrich phases 2, 4, 5.
- Do NOT touch the severity rubric (🔴🟠🟡🟢) — only EXTEND it with ⚪ (section 3.3).

---

## 1. Current State (what v1 already covers — DO NOT remove)

### 1.1 Orchestration & rules
- Role: orchestrator that coordinates subagents via Task tool. Never modifies code.
- Rules: no fixes without approval; read-only analysis + documentation.
- Human gate: executive summary + approval question before continuing.

### 1.2 Categories audited (9 categories × 3 subagents = ~24 agents)
| Category | ID | Subagents |
|---|---|---|
| GAPS | 01 | functional vs requirements · tech debt/TODOs/stubs · business rules/edge cases |
| SEGURIDAD | 02 | auth/authz/escalation/IDOR · injection (SQLi/XSS/CSRF) · data/secrets |
| OPTIMIZACION | 03 | DB queries/N+1 · architecture/duplication/coupling · dependencies |
| UI/UX | 04 | flows/friction · visual consistency · responsive/mobile-first |
| RENDIMIENTO | 05 | backend latency · frontend load/assets · DB indexes/pooling |
| SEO | 06 | meta/title/headings/sitemap · HTML5 semantic/schema.org · robots/canonical |
| ACCESIBILIDAD | 07 | WCAG AA checklist · keyboard/screen reader/ARIA · contrast/forms |
| REVISION LINEAL | 08 | file-by-file (part 1 + part 2) · global consistency |
| OTROS | 09 | syntax/linting · dead code · unused imports · extras |

### 1.3 Output structure
`docs/` with 11 blocks: `00-resumen-ejecutivo`, `01-gaps/` (3 files), `02-seguridad/` (3), `03-optimizacion/` (3), `04-ui-ux/` (3), `05-rendimiento/` (3), `06-seo/` (3), `07-accesibilidad/` (3), `08-revision-lineal/` (3+1), `09-otros/` (4), `10-plan-implementacion.md`.

### 1.4 Severity rubric
- 🔴 Critical: blocking, active security risk, data loss.
- 🟠 High: breaks core functionality or severe UX.
- 🟡 Medium: significant improvement, non-blocking.
- 🟢 Low: cosmetic / nice-to-have.

### 1.5 Execution flow (6 phases)
1. Map project structure (`tree` + key files).
2. Launch ~24 subagents (parallel or batched).
3. Each subagent writes `docs/{category}/{focus}.md`.
4. Consolidate `00-resumen-ejecutivo.md` (top 10 criticals, severity counts, risk matrix).
5. Draft `10-plan-implementacion.md` (P0–P3 proposal only).
6. **STOP** + approval question ("P0 / P0+P1 / all?").

---

## 2. Identified Gaps (the why for every change)

Each gap is tagged `[G#]` and referenced in section 3 (changes) and section 5 (order).

| ID | Gap | Why it matters |
|---|-----|----------------|
| G1 | No supply chain / SBOM / license audit | Silent risk of malicious transitive deps (dependency confusion, typosquatting) and legal license risk |
| G2 | No observability (structured logs, OTel, SLOs/SLIs, error budgets) | A system without traces is not auditable during incidents |
| G3 | No DR / backups / RTO-RPO / multi-AZ | A backup bug = total incident; nothing covers it today |
| G4 | No compliance (GDPR/SOC2/CCPA, PII inventory, data residency) | Legal and regulatory exposure, especially for PII-heavy apps |
| G5 | No AI-agent governance (skill drift, engram poisoning, subagent isolation, token budget, cost-per-task, eval harness, hallucination detection) | This repo IS an agent system — auditing it without governance rules is auditing the wrong subject |
| G6 | No test-quality analysis (mutation, fuzz, property, branch coverage) | Only production code is audited, never test quality |
| G7 | No CI/CD safety (reproducibility, flaky rate, deploy rollback, PR SLA, branch protection) | Workflow not auditable; lead time and quality unmeasured |
| G8 | No ADRs / tech debt register / architecture diagrams freshness | Decisions not traceable; debt silently accrues |
| G9 | WCAG version unspecified (2.2 AA missing) + no i18n/RTL/motion/colorblind | a11y coverage outdated; multi-language audiences invisible |
| G10 | No reproducible evidence column + no adversarial counter-review | Single-agent-per-focus = bias; FPR unmeasured; findings not verifiable |

---

## 3. Changes to apply (what + why + how + pass criteria)

Each change is tagged `[C#]` and mapped to gaps `[G#]` and to implementation order in section 5.

### 3.1 C1 — Expand existing subagent scopes (NO new files)

**Why:** avoid bloating subagent count; reuse existing slots.
**How:** edit the focus descriptions of these existing subagents in v1.

| Subagent ID (current) | Current focus | New expanded focus |
|---|---|---|
| 02-C (Seguridad / Datos-Secretos) | hardcoded creds, weak hashing, PII exposure | + encryption at rest/in transit (TLS 1.2+, KMS, key rotation) + SBOM generation/validation (CycloneDX/SPDX) |
| 03-C (Optimizacion / Dependencias) | unnecessary/obsolete deps, bundle size | + supply chain (provenance, dependency confusion, typosquatting via `osv-scanner`) + license compliance (`license-checker`/`FOSSA`) |
| 05-A (Rendimiento / Backend) | latency, sync blocks | + observability: structured logging, correlation IDs, OpenTelemetry instrumentation, SLOs/SLIs, error budgets, burn-rate alerts |
| 05-C (Rendimiento / BD) | indexes, normalization, pooling | + DR: backup policy, restore tests, RTO/RPO definition, multi-AZ, third-party failure modes (circuit breakers, DLQ) |
| 08-C (Revision Lineal / Consistencia global) | naming, conventions, folders | + ADRs existence (`docs/adr/` Nygard template, status) + architecture diagrams freshness (C4 levels 1–2, last update < 6 months) + tech debt register (`docs/tech-debt.md` with owner + deadline) |

**Pass criteria:** each expanded subagent's prompt segment lists the new bullets under the heading "Tambien verificar:"; no existing bullet removed.

**Maps to:** G1, G2, G3, G8.

---

### 3.2 C2 — Add 2 new mandatory categories

**Why:** observability and AI-agent governance are core to modern systems and to THIS repo; cannot be folded into existing slots without overloading them.

#### 3.2.1 Category `11-observabilidad/` (3 files)

| File | Scope |
|---|---|
| `11-observabilidad/logging-trazas.md` | structured logging (JSON), correlation IDs, PII in logs, log levels per env, OpenTelemetry tracing, sampling strategy |
| `11-observabilidad/slo-error-budget.md` | SLIs defined (latency p95, error rate, availability), SLO targets, error budgets, burn-rate alerts, dashboards |
| `11-observabilidad/runbooks-incident-response.md` | runbook per critical alert, on-call rotation, postmortem cadence (last 90 days), chaos/fallback (timeouts, circuit breakers, DLQ) |

**Subagent prompt template:** copy the existing per-subagent header format (`[Categoría] · [Subagente] · [Proyecto] + Fecha`) and the findings table (`#, Severidad, Archivo:Línea, Descripción, Recomendación`).

**Pass criteria:** 3 files exist after v2; each file has at least the header + table + severity-count summary skeleton even if findings are "N/A — pendiente de ejecucion".

**Maps to:** G2.

#### 3.2.2 Category `12-ia-agent-governance/` (3 files) — CONDITIONAL

**Activation rule:** include ONLY if the target project matches ≥1 heuristic flag:
- Contains `.agents/`, `skills/`, or `AGENTS.md` at root.
- Contains prompt files (`*.prompt`, `SKILL.md`, `prompts/`).
- Uses LLM APIs (`anthropic`, `openai`, `langchain`, `llm` in deps).
- Repo name or README mentions "agent", "agentic", "LLM".

If NO flag matches → skip this category entirely and note in `00-resumen-ejecutivo.md`: "Categoria 12 omitida: target no es sistema agentic."

| File | Scope |
|---|---|
| `12-ia-agent-governance/skill-drift-prompt-regression.md` | skill drift (`check-skill-drift.ps1`, `skill-validate.ps1`), prompt regression suite (golden diffs), skill registry consistency |
| `12-ia-agent-governance/context-token-budget-isolation.md` | token budget enforcement per turn/session, L1/L2/L3 compression rules, subagent delegation rules (max depth 1, max concurrent 6, min steps ≥3), context partitioning, hallucination detection signals |
| `12-ia-agent-governance/memory-eval-cost.md` | engram/memory poisoning vectors (unvalidated `topic_key`, `mem_save` from untrusted prompts), eval harness in CI (`score-auto.ps1`, `docs/metricas/`), cost-per-task baseline, hallucination detector, dreaming cadence |

**Pass criteria:** if activated, 3 files exist with skeleton; if not activated, a single line in `00-resumen-ejecutivo.md` documents the skip + reason.

**Maps to:** G5.

---

### 3.3 C3 — Extend severity rubric with ⚪ N/A-probado

**Why:** today "not covered" is indistinguishable from "passed" — both produce no finding. This corrupts the executive summary's severity counts.

**How:** add a 5th row to the rubric table in v1:

| Symbol | Level | Definition |
|---|---|---|
| ⚪ | N/A probado | Punto verificado y deliberadamente no aplicable al target. Debe incluir justificacion de 1 linea. |

**Pass criteria:** rubric table has 5 rows; the findings table template gains an optional `Justificacion N/A` column used only for ⚪ rows.

**Maps to:** G10.

---

### 3.4 C4 — Reinforce findings format with Evidence column

**Why:** findings today list `Archivo:Línea` but no reproducible evidence. A future reader cannot verify.

**How:** change the per-subagent findings table header in v1 from:
```
#, Severidad, Archivo:Línea, Descripción, Recomendación
```
to:
```
#, Severidad, Archivo:Línea, Descripción, Evidence, Recomendación
```

`Evidence` accepts:
- `file:line` (already implied) — minimum.
- Command output snippet (e.g. `gitleaks:3 hits`, `axe-core:2 violations`) — preferred for 🔴/🟠.
- Link to `docs/evidence/{category}-{N}.txt` for long outputs.

**Also:** mandate that 100% of 🔴 and 🟠 findings carry reproducible evidence. 🟡/🟢 may use `file:line` only.

**Pass criteria:** table header updated; a new line in the format spec says "Todo 🔴 y 🟠 DEBE incluir evidence reproducible (comando o snippet). Sin evidence = degradar a 🟡."

**Maps to:** G10.

---

### 3.5 C5 — Add adversarial counter-review subagent (the 25th)

**Why:** single-agent-per-focus = bias. A second pass that tries to invalidate findings reduces false positives.

**How:** insert a new phase-4 sub-step BEFORE writing `00-resumen-ejecutivo.md`:

> **Fase 4a — Contra-revision adversarial:** un subagente ligero (id: `99-adversarial`) revisa TODOS los hallazgos 🟠 y 🔴 producidos en la fase 2. Para cada uno emite uno de: `CONFIRMED` (mantiene severidad), `DOWNGRADE` (baja severidad con razon), o `INVALIDATED` (falso positivo con razon). Solo los `CONFIRMED` y `DOWNGRADE` pasan al resumen ejecutivo. Los `INVALIDATED` se registran en `docs/evidence/fp-log.md` con el conteo final y el FPR (False Positive Rate = invalidated / total revisado).

**Subagent profile:** light — only reads the 🟠/🔴 findings and the referenced files; does NOT re-audit the whole project.

**Pass criteria:** `99-adversarial` subagent documented in v1; FPR formula documented; `docs/evidence/fp-log.md` mentioned in output structure.

**Maps to:** G10.

---

### 3.6 C6 — Conditional categories via target-type detection

**Why:** not every target needs compliance/DR/CI-CD depth. Conditional activation keeps the base prompt lean.

**How:** add a "Fase 0 — Deteccion de tipo de target" BEFORE phase 1, that sets boolean flags:

| Flag | True if | Activates |
|---|---|---|
| `HAS_PII` | target stores/processing PII (grep for `email`, `passport`, `gdpr`, `pii`, auth tables with user data) | `13-compliance-privacy/` (3 files: PII inventory + residency · GDPR/SOC2/CCPA rights endpoints · retention policy) |
| `IS_TIER1` | target has `workflows/`, deploy configs, or README mentions "production"/"Tier 1"/"SLA" | `14-resilience-dr/` (3 files: backups+RTO/RPO · multi-AZ/failover · third-party failure matrix) AND `15-ci-cd-dx/` (3 files: build reproducibility+flaky rate · deploy safety+rollback · branching+PR SLA) |
| `IS_AGENTIC` | (see C2.2 activation rule) | `12-ia-agent-governance/` |

If a flag is False → write a single line in `00-resumen-ejecutivo.md`: "Categoria NN omitida: flag X False."

**Pass criteria:** Fase 0 documented with the 3 flags + heuristics; the 3 conditional categories have skeletons but are only populated when their flag is True.

**Maps to:** G3, G4, G5, G7.

---

### 3.7 C7 — Enrich executive summary with coverage metrics

**Why:** today the summary counts severities but doesn't show coverage of standards (OWASP, SLO, WCAG). A reader can't tell "audited and clean" from "not audited".

**How:** in `00-resumen-ejecutivo.md` add a "Matriz de cobertura" section AFTER the severity counts:

```
## Matriz de cobertura
| Estandar / Dimension | Cobertura | Hallazgos | Estado |
|---|---|---|---|
| OWASP Top 10 (Web) | X/10 items | N | ✅/⚠️/❌ |
| OWASP API Top 10 | X/10 | N | ... |
| OWASP LLM Top 10 (si IS_AGENTIC) | X/10 | N | ... |
| WCAG 2.2 AA | X checkpoints | N | ... |
| SLOs definidos | si/no | N | ... |
| SLO violations (burn rate) | n/a o N | N | ... |
| FPR de la auditoria | % | N invalidados | ... |
| Cobertura de tests (branch) | % | N | ... |
```

**Pass criteria:** the matrix template exists in v1's spec for `00-resumen-ejecutivo.md`; each row has a value or `N/A — flag X False`.

**Maps to:** G2, G5, G6, G9, G10.

---

### 3.8 C8 — Make target type explicit in the Objective

**Why:** conditional categories (C6) need a declared target type; otherwise the agent guesses.

**How:** change the Objective line in v1 from:
> Auditar el proyecto `{PROJECT_PATH}`...

to:
> Auditar el proyecto `{PROJECT_PATH}` — tipo detectado: `{web app | API service | IA agent system | library}` — flags: `HAS_PII={bool}`, `IS_TIER1={bool}`, `IS_AGENTIC={bool}`.

The agent fills the placeholders during Fase 0.

**Pass criteria:** Objective line carries the 3 flags; Fase 0 sets them.

**Maps to:** G3, G4, G5.

---

## 4. Tools Reference (already-allowed external tools)

These are the ONLY external tools the implementing agent may name in v2. Do NOT introduce others.

| Tool | Purpose | Already in v1? |
|---|---|---|
| `tree` | project mapping | yes |
| ESLint / Pylint | linting | yes |
| `gitleaks` / `trufflehog` | secrets in git history | no — C1 (02-C) |
| `trivy` / `grype` | container/image vuln scan | no — C1 (02-C) |
| `cyclonedx-bom` / `syft` | SBOM generation | no — C1 (02-C) |
| `osv-scanner` | supply chain vuln | no — C1 (03-C) |
| `license-checker` / `FOSSA` | license compliance | no — C1 (03-C) |
| `axe-core` / `pa11y` | a11y automated | no — C1 (07-A) extension |
| `k6` / `locust` / Gatling | load testing | no — C1 (05-A) extension |
| `mutmut` / Stryker | mutation testing | no — C1 (08-C) extension |
| `hypothesis` / `afl` | fuzz/property testing | no — C1 (08-C) extension |
| `madge` / `dependency-cruiser` | coupling/cycles | no — C1 (08-C) extension |
| OpenTelemetry SDK | tracing | no — C2.1 |
| `check-skill-drift.ps1` / `skill-validate.ps1` | skill drift (this repo) | no — C2.2 |
| `score-auto.ps1` | eval/scoring (this repo) | no — C2.2 |

**Rule:** if a tool isn't in this table, do NOT add it to v2. If you believe one is missing, STOP and ask the user.

---

## 5. Implementation Order (MANDATORY sequence)

Execute in this exact order. Each step is a discrete edit. Do NOT batch unrelated steps.

| Step | Change | File region affected | Verifies |
|---|---|---|---|
| 1 | C8 — Objective line with flags | Top of v1 (Objective section) | target type declared |
| 2 | C6 — Insert "Fase 0 — Deteccion de tipo de target" before Fase 1 | Flow section | 3 flags + heuristics documented |
| 3 | C3 — Add ⚪ N/A-probado row to rubric | Severity rubric table | 5 rows total |
| 4 | C4 — Update findings table header + evidence mandate | Per-subagent format spec | `Evidence` column present; 🔴/🟠 evidence rule stated |
| 5 | C1 — Expand 5 existing subagent scopes (02-C, 03-C, 05-A, 05-C, 08-C) | Subagent focus descriptions | new bullets present, none removed |
| 6 | C2.1 — Add `11-observabilidad/` category (3 files) | Categories list + output structure | 3 file skeletons documented |
| 7 | C2.2 — Add `12-ia-agent-governance/` category (conditional, 3 files) | Categories list + output structure + activation rule | activation rule documented; 3 skeletons |
| 8 | C6 — Add 3 conditional categories `13-compliance-privacy/`, `14-resilience-dr/`, `15-ci-cd-dx/` | Categories list + output structure | 3 categories with flag-gated activation |
| 9 | C5 — Insert "Fase 4a — Contra-revision adversarial" before consolidation | Flow section (between current phase 3 and 4) | `99-adversarial` subagent + FPR formula documented |
| 10 | C7 — Add "Matriz de cobertura" section to `00-resumen-ejecutivo.md` spec | Output structure (executive summary block) | matrix template with OWASP/WCAG/SLO/FPR/test-coverage rows |
| 11 | Update output structure block to list new categories 11–15 | Output structure section | 11→15 directories listed with conditional markers |
| 12 | Update subagent count statement (~24 → ~25 base + conditional) | Top of v1 (wherever "24 subagentes" is mentioned) | count matches new total |

**Why this order:** C8 and C6 first because everything downstream depends on the target-type flags. C3 and C4 next because they change the format every subagent uses — must be settled before expanding subagent scopes (C1) and adding new categories (C2). C5 last among flow changes because it sits between phases 3 and 4 and references findings produced by all prior subagents.

---

## 6. Non-Goals (do NOT do these)

- ❌ Do NOT rewrite v1 from scratch. Patch surgically.
- ❌ Do NOT remove any of the 9 existing categories.
- ❌ Do NOT change the 6-phase flow order. Only enrich phases 0, 2, 4, 5 and insert 4a.
- ❌ Do NOT add a 26th subagent. Ceiling is 25 (24 + `99-adversarial`).
- ❌ Do NOT introduce tools outside section 4.
- ❌ Do NOT change the severity definitions of 🔴🟠🟡🟢. Only ADD ⚪.
- ❌ Do NOT auto-commit. Wait for `!ship` or explicit user approval.
- ❌ Do NOT touch any file other than `docs/PROMPT-auditoria-multiagente.md`.
- ❌ Do NOT translate existing Spanish sections to English. Match the source language.
- ❌ Do NOT add emoji beyond the 5 severity symbols (🔴🟠🟡🟢⚪).

---

## 7. Self-Verification Checklist (run before declaring done)

The implementing agent MUST verify ALL of the following. Any failure = NOT done.

- [ ] Objective line carries `{PROJECT_PATH}`, target type, and 3 flags (`HAS_PII`, `IS_TIER1`, `IS_AGENTIC`).
- [ ] "Fase 0 — Deteccion de tipo de target" exists with 3 flags and their heuristics.
- [ ] Severity rubric has exactly 5 rows (🔴🟠🟡🟢⚪).
- [ ] Findings table header includes `Evidence` column.
- [ ] A line states: "Todo 🔴 y 🟠 DEBE incluir evidence reproducible. Sin evidence = degradar a 🟡."
- [ ] Subagents 02-C, 03-C, 05-A, 05-C, 08-C have expanded focus bullets; no original bullet removed.
- [ ] Category `11-observabilidad/` is listed with 3 files.
- [ ] Category `12-ia-agent-governance/` is listed with activation rule + 3 files.
- [ ] Categories `13-compliance-privacy/`, `14-resilience-dr/`, `15-ci-cd-dx/` are listed with flag-gated activation.
- [ ] "Fase 4a — Contra-revision adversarial" exists with `99-adversarial` subagent + FPR formula.
- [ ] `00-resumen-ejecutivo.md` spec includes "Matriz de cobertura" with OWASP/WCAG/SLO/FPR/test-coverage rows.
- [ ] Output structure lists directories 11–15 with conditional markers.
- [ ] Subagent count statement updated to reflect new total.
- [ ] No tools outside section 4 are mentioned.
- [ ] No file other than `docs/PROMPT-auditoria-multiagente.md` was modified.
- [ ] Source language (Spanish) preserved in existing sections.

**Evidence rule:** each checkbox must be backed by a quote from the modified file. The implementing agent includes these quotes in its final report.

---

## 8. Commit (only if user authorizes `!ship`)

```
docs(mejora): expandir prompt de auditoria multiagente a v2

- Anadir Fase 0 deteccion de tipo de target (HAS_PII, IS_TIER1, IS_AGENTIC)
- Extender rubrica de severidad con ⚪ N/A-probado
- Anadir columna Evidence y mandar evidence reproducible para 🔴/🟠
- Expandir 5 subagentes existentes (02-C, 03-C, 05-A, 05-C, 08-C)
- Anadir categoria 11-observabilidad (obligatoria)
- Anadir categoria 12-ia-agent-governance (condicional IS_AGENTIC)
- Anadir categorias 13-compliance-privacy, 14-resilience-dr, 15-ci-cd-dx (condicionales)
- Anadir Fase 4a contra-revision adversarial (subagente 99-adversarial + FPR)
- Anadir Matriz de cobertura al resumen ejecutivo

Plan: docs/mejoras/PLAN-auditoria-multiagente-v2.md
```

---

## 9. Risk register for the implementing agent

| Risk | Mitigation |
|---|---|
| Agent over-expands and adds a 26th subagent | Section 6 hard rule; count check in section 7 |
| Agent introduces a tool not in section 4 | Section 4 is closed; "STOP and ask" rule |
| Agent rewrites v1 wholesale | Section 6: "patch surgically" |
| Agent skips Fase 0 and breaks conditional activation | Section 5 order: C8+C6 are steps 1–2, before everything else |
| Agent forgets ⚪ rows corrupt severity counts | C3 + C7 matrix make ⚪ visible and accounted |
| Agent adds emoji beyond the 5 severity symbols | Section 6 hard rule |
| Agent translates Spanish to English | Section 6: match source language |

---

## 10. Open question (escalate to user before implementing)

**Fork:** Should v2 specialize for agentic systems (assume `IS_AGENTIC=True` always, drop the flag) or stay generic-parametric (keep all 3 flags)?

- **Specialized** (recommended for THIS repo): simpler prompt, category 12 always active, drops the `IS_AGENTIC` heuristic. Loses reusability for non-agent targets.
- **Generic-parametric**: keeps all flags, reusable across project types, slightly more complex prompt.

Default if user doesn't answer: **generic-parametric** (matches v1's existing `{PROJECT_PATH}` parameterization philosophy).
