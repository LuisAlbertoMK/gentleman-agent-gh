# mejora-security — Playbooks de seguridad por tipo de proyecto

## Contexto

Los skills de seguridad del repo (auth-hardening, security-scanner, api-testing, container-security,
llm-security, infra-audit) son GENÉRICOS: cubren patrones universales pero no prescriben el flujo de
verificación por tipo de proyecto. Objetivo de esta mejora: playbooks accionables (tablas de decisión,
patrón delivery-harness — unidades con detección → verify → fix; NO prosa tutorial) por tipo.

Orden recomendado por el usuario: 1 API REST → 2 frontend SPA → 3 backend/servicios → 4 containers/IaC →
5 dispatch por tipo.

## Gate — SUBSTANTIAL

| Criterio | Valor | SMALL? |
|----------|-------|--------|
| Líneas | >50L acumulado (5 slices) | ✗ |
| Archivos | +1 (plan doc) en slice 1; multi-skill por slice | ✗ |
| Schema/auth/API | Docs de seguridad (contenido, no código) | ~ |
| External deps | Ningunas | ✓ |
| Tier RDD | 1 por slice (1-5 files, docs-only, sin código) | ✓ |
| Commits forecast | 5 (+0 plan doc — DENTRO del slice 1) | ✗ |

→ Multi-slice, multi-commit → **SUBSTANTIAL**: crear `odd/tasks/mejora-security.md` con slice plan.
(El plan doc se commitea DENTRO del slice 1 — sin SHAs propios.)

## Scope In

| # | Slice | Archivos est. | Outcome medible | Fase RDD | Checkpoint breaker |
|---|-------|---------------|-----------------|----------|--------------------|
| 1 | Playbook API REST (JWT, authZ BOLA/IDOR/BOPLA, rate-limit+lockout, OWASP API Top10 esencial 2023 [API1/2/3/4/7], input/injection por endpoint, errores sin filtrar, paginación/bulk) | 3 skills extendidos + plan doc (`.agents/skills/auth-hardening/SKILL.md`, `.agents/skills/api-testing/SKILL.md`, `.agents/skills/security-scanner/SKILL.md`, `odd/tasks/mejora-security.md`) | 5 vectores de ataque (BOLA, JWT alg=none, rate-limit bypass, SSRF vía webhook URL, mass assignment) cubiertos con file:line grep-able; `check-token-budget -Json` passed; regression 101/101; YAML válido; breaker APPROVED | freeze → tier 1 (3 files, docs-only) → 4R → breaker → receipt | Breaker lista los 5 ataques con file:line donde el playbook los cubre (verdict APPROVED) |
| 2 | Playbook frontend SPA (XSS/DOM, CSP, token storage, postMessage, third-party/supply chain, pinning) | ~3 (`.agents/skills/best-practices/SKILL.md`, `.agents/skills/security-scanner/SKILL.md`, reference) | Vectores SPA (XSS, CSP ausente, token en localStorage, postMessage sin origin check, dep sin pin) cubiertos con file:line; gate verde; breaker APPROVED | freeze → tier 1 → 4R → breaker → receipt | Breaker lista 4 ataques SPA (XSS almacenado, DOM clobbering, postMessage origin spoof, dep typosquat) con file:line |
| 3 | Playbook backend/servicios (injection chains, deserialización, secrets, dependencias, SSRF a servicios internos) | ~3 (`.agents/skills/security-scanner/SKILL.md`, `.agents/skills/container-security/SKILL.md`, reference) | Vectores backend (deserialización insegura, secrets en env, dependencias sin audit, SSRF interno) con file:line; gate verde; breaker APPROVED | freeze → tier 1 → 4R → breaker → receipt | Breaker lista 4 ataques backend con file:line |
| 4 | Playbook containers/IaC (image hardening, least-privilege, secrets en IaC, SBOM/pinning) | ~3 (`.agents/skills/container-security/SKILL.md`, `.agents/skills/infra-audit/SKILL.md`, reference) | Vectores container/IaC (root en imagen, secrets en tfvars/helm, tag mutable, cap excess) con file:line; gate verde; breaker APPROVED | freeze → tier 1 → 4R → breaker → receipt | Breaker lista 4 ataques container/IaC con file:line |
| 5 | Dispatch por tipo de proyecto (router: tipo → playbook) | ~1-2 (nuevo reference o sección en security-scanner — decisión en slice 5) | `security` dispatch resuelve tipo (REST/SPA/backend/container) → playbook correcto; prueba con 4 tipos; gate verde; breaker APPROVED | freeze → tier assessment (posible tier 2 si nuevo skill) → 4R → breaker → receipt | Breaker verifica que dispatch cubre los 4 tipos y no solapa triggers existentes |

Total est. files: ~13 (3 de slice 1 ya fijados).

## Scope Out

- Los **6 slices de gates del repo** (token budget, frontmatter, quality gates etc.) quedan **PARKEADOS** —
  NO son parte de esta mejora.
- NO tocar triggers ni frontmatter existente de ningún skill (salvo una línea de changelog por skill tocado —
  implementada como línea `> changelog:` en el body, sin tocar las keys YAML del frontmatter).
- NO cambiar comportamiento de otros tipos de proyecto (slices 2-5 son archivos separados).
- NO push, NO PR, NO merge a main. Rama `mejora-security` únicamente.

## Slice 1 — Verificación (receipt)

```powershell
# 1. YAML válido (frontmatter de los 4 archivos)
python -c "import yaml;[yaml.safe_load(open(f,encoding='utf-8')) for f in ['.agents/skills/auth-hardening/SKILL.md','.agents/skills/api-testing/SKILL.md','.agents/skills/security-scanner/SKILL.md']]"
# 2. Gate token budget
& ./scripts/check-token-budget.ps1 -Json    # expect "passed":true, 0 overBudgetFiles
& ./scripts/test-token-budget-regression.ps1 # expect 101/101 within 10%
# 3. Frontmatter intacto (name/description/triggers/token_budget sin cambios)
git diff -- .agents/skills | Select-String '^[+-](name|description|triggers|token_budget):'
# 4. LF-only (gate mide bytes del working tree)
# 5. Breaker: 5 ataques con file:line (BOLA, alg=none, rate-limit bypass, SSRF webhook, mass assignment)
```

Si el gate bloquea por headroom (file > token_budget*1.1): bump MÍNIMO del `token_budget` del skill
afectado, precedente `e47d202f` ("bump budgets safely, not trim") — desvío reportado.

## Review Log

| Date | Slice | Reviewer | Notes |
|------|-------|----------|-------|
| 2026-09-18 | 1 (API REST playbook) | plan-execution + adversarial-breaker | freeze `HEAD-a77a2c4a-e69de29b`; commit `feat(skills): add API REST security playbook` (SHA en `git log`); 3 skills extendidos, frontmatter intacto salvo desvío documentado: `security-scanner` token_budget 2750→2950 (gate-forced, precedente e47d202f "bump budgets safely, not trim"); YAML OK; check-token-budget passed; regression 101/101; breaker: 5/5 ataques con file:line — APPROVED |
| 2026-09-18 | 2 (frontend SPA playbook) | plan-execution + adversarial-breaker | freeze `HEAD-6631a2b2-e69de29b`; commit `feat(skills): add frontend SPA security playbook` (SHA en `git log`); 2 skills extendidos (auth-hardening: token storage/CSRF cookie-auth; best-practices: XSS/CSP/open-redirect/postMessage/deps); **desvío del plan**: no se tocó security-scanner (3199 B = 1 B del cap 3200) ni se creó reference — contenido SPA en otros skills por restricción heredada; frontmatter intacto salvo desvío gate-forced: auth-hardening token_budget 2750→3200, best-practices 2807→3450 (precedente e47d202f); YAML OK; check-token-budget passed; regression 101/101; breaker: 5/5 ataques SPA con file:line — APPROVED |
| 2026-09-18 | 3 (backend/servicios playbook) | plan-execution + adversarial-breaker | freeze `HEAD-a3057d71-e69de29b`; commit `feat(skills): add backend security playbook` (SHA en `git log`); 1 skill extendido (data-quality: secretos env/vault, authz deny-by-default+scopes+IDOR, inyección SQL/LDAP/OS-cmd, logging sin PII, errores sin filtrar, pinning deps); **desvío del plan (ubicación)**: security-scanner (3199 B, 1 B del cap 3200) y auth-hardening (3487 B, headroom real 33 B) sin espacio — playbook backend en data-quality, única con headroom real (444 B) y alineada a data-governance/PII, por instrucción "adaptá ubicación si el headroom lo exige"; frontmatter intacto salvo desvío gate-forced: data-quality token_budget 2850→3340 (precedente e47d202f, bump MÍNIMO ceil(3671/1.1)); YAML OK; check-token-budget passed; regression 101/101; breaker: 5/5 ataques (SQLi, secretos en logs, IDOR server-side, log forging/PII leak, dependency confusion) con file:line — APPROVED |
| 2026-09-18 | 4 (containers/IaC playbook) | plan-execution + adversarial-breaker | freeze `HEAD-b76fd0f7-e69de29b`; commit `feat(skills): add containers/IaC security playbook` (SHA en `git log`); 2 skills extendidos (container-security: non-root USER+runAsNonRoot+readOnlyRootFilesystem, drop ALL+add min sin cap-add ALL, secretos vía k8s Secret/mounts nunca ENV/ARG, digest @sha256 + trivy/grype CI; infra-audit: resource limits cpu/mem + NetworkPolicy default-deny) — ambos DENTRO del headroom (402/397 B) sin bumps, co-host infra-audit para las reglas IaC según el est. del plan (~3 files; sin reference); frontmatter intacto; YAML OK; check-token-budget passed; regression 101/101; breaker: 5/5 vectores (privileged escape, secret en ENV, latest tag, root container, sin limits) con file:line — APPROVED |

## Rollback

Slice 1 es un único commit `feat(skills): add API REST security playbook` (4 files: 3 skills + plan doc).
Revert: `git revert <hash>` restaura todos los archivos del slice 1 a la vez (los skills vuelven a su
estado genérico; el plan doc desaparece). Sin dependencias entre slices (archivos disjuntos).