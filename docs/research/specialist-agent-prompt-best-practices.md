# Specialist Agent Prompt Engineering — Research Synthesis

> Generated: 2026-07-18 | Sources: 40+ articles, repos, papers, and frameworks from 2025-2026

---

## Part I: Universal Patterns (All Agent Types)

### 1. System Prompt Architecture (5-Layer Model)

Every production agent prompt follows this skeleton:

```
1. Identity      — "You are <role> for <domain>." (~100 tokens)
2. Capabilities  — What you can do. Tools available. Scope boundaries.
3. Constraints   — Hard rules, safety, refusal conditions, what NOT to do.
4. Format        — Output schema, section headers, length bounds.
5. Termination   — When to stop. Stopping conditions.
```

**Key findings:**
- Put load-bearing rules FIRST (primacy bias) and restate the most critical rule LAST (recency bias) — models attend unevenly across context length.
- XML/delimiter tags separate instruction blocks from data. Claude especially respects `<section>` boundaries.
- Aim for 200-800 tokens for most agents. Past 2000 tokens, instruction-following degrades in the middle ("lost in the middle" problem).
- The system prompt is the DURABLE CONTRACT. Per-request data goes in the user turn. If a value differs between two consecutive requests, it does NOT belong in the system prompt.

### 2. Role Isolation: One Agent, One Job

The #1 structural improvement: **stop giving a single agent multiple roles**.

- A planner agent gets a planner prompt. An executor gets an executor prompt. A critic gets a critic prompt.
- Each prompt has a narrow, unambiguous job description.
- "You are a planner, an executor, and a validator" → inconsistent behavior. The model has no signal about which mode it should be in.
- When a planner says "your output is always a JSON array of steps and nothing else" → structured output you can route on.

### 3. Constraints Must Be Operational, Not Aspirational

| BAD (aspirational) | GOOD (operational) |
|---|---|
| "Be careful with data" | "Do not write any value from users table to a file" |
| "Be professional" | "Max 5 bullets, max 12 words per bullet, in order: cause, evidence, fix" |
| "Don't guess" | "If the answer isn't in provided context, respond: 'I don't have that information'" |

### 4. Explicit Stopping Conditions (Most Neglected Rule)

Without clear stopping conditions, agents either:
- Stop too early (nothing told them to keep going)
- Run forever (nothing told them when to quit)

Good examples:
- "The task is complete when output.txt is written. Do not continue after that."
- "Stop and ask the user before any destructive action."
- "Maximum 15 inline comments. Prioritize the most important findings."

### 5. Tool Description Engineering

Tool descriptions are the **highest-leverage prompt surface**. A well-written tool description prevents more errors than pages of behavioral instructions.

Every tool description must answer:
1. **What** the tool does (one sentence)
2. **When** to use it (specific triggers)
3. **When NOT** to use it (explicit exclusions)
4. **What the output looks like** (helps model interpret results)
5. **Known limitations or failure modes**

### 6. Failure-Mode Instructions (Non-Negotiable)

Every agent prompt needs a section answering:
1. What should the agent do when input is malformed?
2. What should it do when it can't complete its task?
3. What should it return so the orchestrator can handle the failure?

Include a structured error response schema:
```json
{
  "status": "blocked",
  "reason": "<specific constraint violated>",
  "confidence": 0.0-1.0
}
```

### 7. Versioned, Tested Artifact

Prompts are code that happens to be English.
- Store in repo, not pasted into dashboard
- Label versions
- Gate changes behind eval sets
- A prompt change that fixes one case and silently breaks five others is the DEFAULT outcome without evals

---

## Part II: Domain-Specific Patterns

---

### A. Security Agent

**Methodologies to embed:**
- **OWASP Top 10** (Web + LLM + Agentic 2026)
- **STRIDE** (Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation of Privilege)
- **CWE** mapping with specific IDs (CWE-89 SQL Injection, CWE-22 Path Traversal, etc.)
- **OWASP ASVS** v5.0 for verification requirements
- **MITRE ATLAS** for ML-specific adversary techniques
- **CSA MAESTRO** 7-layer framework for multi-agent threat modeling

**Prompt should instruct the agent to:**
1. Use "Assume breach, design for defense" mindset
2. Produce evidence-based findings with CWE/CVE references, file locations, line numbers
3. Include quantified impact ("affects 3 API endpoints handling 50K requests/day")
4. Classify every finding as Critical/High/Medium/Low with explicit criteria
5. Map to OWASP categories and provide OpenCRE cross-references
6. Apply STRIDE analysis at every trust boundary
7. Check for: SQL injection, XSS, auth bypass, secrets in code, overly permissive IAM, SSRF, path traversal

**Structured output format:**
```markdown
## Finding: [Title]
- **CWE:** CWE-89
- **OWASP:** A03:2021 Injection
- **Severity:** Critical
- **Location:** `src/auth/login.js:42`
- **Impact:** Attacker can extract users table
- **Evidence:** [code snippet]
- **Fix:** [specific remediation with code]
```

**Threat model format:**
```markdown
## STRIDE Analysis
| Threat | Category | Impact | Likelihood | Mitigation |
|--------|----------|--------|------------|------------|
| Input manipulation | Tampering | H | M | Input validation + WAF |
```

**Common mistakes to prevent:**
- Vague warnings without specific CWE references
- Findings without file locations and line numbers
- Missing quantified impact assessment
- Not checking for dependency CVEs
- Missing Post-Implementation Verification (PIV) — security review is TWO-PHASE

---

### B. SEO Agent

**Methodologies to embed:**
- **Google E-E-A-T** (Experience, Expertise, Authoritativeness, Trustworthiness)
- **Core Web Vitals** thresholds: LCP ≤2.5s, INP ≤200ms, CLS ≤0.1
- **Schema.org** JSON-LD structured data validation
- **Technical SEO** checklist: crawlability, indexation, canonical tags, hreflang
- **Content quality** gates: word count, keyword density, heading structure
- **GEO** (Generative Engine Optimization) for AI search visibility

**Script + LLM two-layer architecture:**
- Layer 1: Python scripts handle deterministic checks (HTTP status, XML parsing, string matching) → structured JSON
- Layer 2: LLM handles semantic judgment (keyword intent alignment, content quality assessment, E-E-A-T signals)
- `llm_review_required` flag ensures LLM only intervenes when script cannot make the call

**Prompt should instruct the agent to:**
1. Always produce two artifacts: `FULL-AUDIT-REPORT.md` (detailed) + `ACTION-PLAN.md` (prioritized fixes)
2. Include confidence labels: Confirmed / Likely / Unknown (missing data)
3. Prioritize by impact × effort, tied to a specific KPI
4. Flag schema detection limitations (JS-injected schema invisible to fetch/curl)
5. Score across categories with explicit weights: Technical SEO (25%), Content Quality (20%), On-Page (15%), Schema (15%), Performance (10%), Images (10%), GEO (5%)

**Recommended output structure:**
```markdown
| # | Category | Finding | Severity | Confidence | Evidence | Impact | Fix | Effort |
|---|----------|---------|----------|------------|----------|--------|-----|--------|
```

**Common mistakes to prevent:**
- Reporting "no schema found" based on static fetch (misses JS-injected JSON-LD)
- Generic advice not tied to the site's actual stack
- Missing platform-specific issues (Laravel vs WordPress vs SPA)
- Not distinguishing lab data from field data (CrUX)
- Never reference FID (deprecated, replaced by INP March 2024)

---

### C. Infrastructure / DevOps Agent

**Methodologies to embed:**
- **Terraform/OpenTofu** best practices: pin versions with `~>`, use `for_each` over `count`, state isolation per environment
- **Kubernetes** manifests: resource limits, health checks, security context (non-root, read-only FS, drop capabilities), PodDisruptionBudgets, NetworkPolicies
- **Docker**: multi-stage builds, distroless/Alpine runtime, non-root USER, .dockerignore
- **CIS benchmarks** for cloud hardening
- **GitOps** awareness (ArgoCD, Flux)

**Agent architecture pattern (3-agent pipeline):**
1. **Planner** → Translates NL requirements into architecture plan
2. **Validator** → Security/compliance review (data-driven rules from YAML, not hardcoded)
3. **Executor** → Applies approved config with human-in-the-loop gate

**Prompt should instruct the agent to:**
1. ALWAYS generate: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
2. Never hardcode ARNs/IDs — use data sources
3. Tag all resources with `Name`, `Environment`, `ManagedBy = "terraform"`
4. Block `AdministratorAccess` policies and wildcard `"Action": "*"` via regex
5. Validate output contains `provider` and `resource` blocks with balanced braces
6. Run `terraform validate` / `kubectl --dry-run` before presenting output
7. Present cost estimates BEFORE deployment (Infracost or equivalent)

**Security scanning checklist:**
```markdown
## Security Review
- [ ] No `0.0.0.0/0` on SSH, RDP, MySQL, PostgreSQL
- [ ] Encryption at rest on S3/RDS/EBS
- [ ] No hardcoded credentials or API keys
- [ ] Least-privilege security groups
- [ ] No wildcard IAM actions
- [ ] Container: no privileged mode, no root user
```

**Common mistakes to prevent:**
- Running `terraform apply` without human approval
- Missing version pins on providers/modules
- Hardcoded secrets in .tf files
- Not checking for `ForceNew` attribute implications
- Missing `prevent_destroy` lifecycle on critical resources

---

### D. Frontend Accessibility Agent

**Methodologies to embed:**
- **WCAG 2.2 Level AA** (current standard, ISO/IEC 40500:2025)
- **WAI-ARIA Authoring Practices** (APG) for custom widgets
- **Two-pass audit**: (1) automated tools clear ~57% of issues, (2) manual prompts hunt the rest
- **axe-core + keyboard walkthrough + screen-reader walkthrough** as the triple verification

**WCAG 2.2 new criteria agents MUST check (often missed):**
| Criterion | What it requires |
|---|---|
| 2.4.11 Focus Not Obscured (AA) | Focused element not hidden by sticky headers |
| 2.5.7 Dragging Movements (AA) | Single-pointer alternative for drag interactions |
| 2.5.8 Target Size Minimum (AA) | Touch targets ≥24×24 CSS px |
| 3.2.6 Consistent Help (AA) | Help mechanism in same relative order across pages |
| 3.3.7 Redundant Entry (AA) | Pre-fill info already provided in multi-step forms |
| 3.3.8 Accessible Authentication (AA) | No cognitive puzzles for login |

**Prompt should instruct the agent to:**
1. Walk the page TWICE: once as keyboard-only user, once as screen-reader user
2. Map EVERY finding to a specific WCAG 2.2 criterion + one-line fix
3. Check custom widgets against WAI-ARIA APG patterns (verify ARIA roles against spec, not memory)
4. Flag: focus traps, missing skip-links, color-only error states, empty links/buttons
5. Classify: CRITICAL (blocks access), MAJOR (significant barrier), MINOR (inconvenience)
6. Produce Playwright test files for regression prevention

**Output format:**
```markdown
### Issue 1: [Title]
**WCAG Criterion:** 2.4.7 Focus Visible (Level AA)
**Severity:** Critical
**Location:** `src/components/Modal.tsx:42`
**Element:** `<div class="modal-overlay">`
**Problem:** Modal traps keyboard focus but not screen-reader focus
**Impact:** Screen-reader users can navigate away from modal into background content
**Fix:** Add `role="dialog"` and `aria-modal="true"` to the overlay
**Testing:** Tab through modal with VoiceOver on macOS
```

**Common mistakes to prevent:**
- Treating axe-core green as "audit done" (automation catches only ~57%)
- Building custom tabs/combobox/menu without checking APG patterns
- Error states conveyed by color alone
- Modal trapping screen-reader focus but not keyboard focus (or vice versa)
- Live regions announcing decorative updates
- Trusting AI's ARIA roles from memory (models hallucinate role names)

---

### E. Performance Optimization Agent

**Methodologies to embed:**
- **Profile → Patch → Verify** inner loop (not just code inspection)
- **PERFOPT-Bench** methodology: verified speedup + hidden correctness tests
- **ISO-Bench** evaluation: hard metrics (execution perf) + soft metrics (bottleneck targeting)
- **Context profiling**: understand where token budget goes (system prompt, tool defs, tool results, conversation history)

**The core insight from research:** "Agents often identify correct bottlenecks but fail to execute working solutions." The execution gap is the primary failure mode, not understanding.

**Prompt should instruct the agent to:**
1. ALWAYS run a baseline benchmark BEFORE optimization
2. Profile actual executions, don't just read code
3. Identify the bottleneck through measurement, not guessing
4. Make ONE change at a time and verify
5. Distinguish between genuine optimization and measurement artifacts
6. Document: before/after metrics, what was changed, why it helps
7. Verify correctness is preserved after optimization

**Agent profiling dimensions (from agentpprof/contextspy):**
- Token consumption by category (system prompt, tools, results, conversation)
- Wall-clock duration per step
- Tool result token amplification (large payloads)
- Context composition analysis

**Common mistakes to prevent:**
- Optimizing without measuring (guessing at bottlenecks)
- Micro-optimizations that don't move the needle
- Breaking correctness while optimizing
- Not accounting for platform-specific behavior
- Raw speedup without correctness verification

---

### F. Data Science / Analysis Agent

**Methodologies to embed:**
- **StatGuard Agent** pattern: LLM routes, deterministic engine computes, cross-validated against scipy/statsmodels
- **Assumption-aware routing**: normality/variance checks route between parametric and non-parametric tests
- **Anti-fabrication claims ledger**: LLM references verified results by ID, never invents statistics
- **Multi-phase pipeline**: Understanding → Planning → Generation → Self-Reflection

**The key design principle:** A general-purpose LLM asked to "compare these groups" may silently pick the wrong test, skip assumption checks, or report numbers it did not actually compute. **Remove statistical computation from the LLM entirely.**

**Agent architecture (CoDA pattern):**
| Phase | Agent | Responsibility |
|---|---|---|
| Understanding | QueryAnalyzer | Parses intent, produces structured TODO checklist |
| Understanding | DataProcessor | Loads data, infers schema and statistics |
| Planning | VisualizationMappingAgent | Maps data columns to visual roles, selects chart type |
| Generation | CodeGenerator | Produces runnable code grounded in design spec |
| Self-Reflection | DebugAgent | Executes code, diagnoses errors, applies fixes |
| Self-Reflection | VisualEvaluator | Scores readability/aesthetics, triggers refinement if below threshold |

**Prompt should instruct the agent to:**
1. ALL insights must include numerical evidence
2. Use statistical validation where applicable
3. Run assumption checks before selecting tests (normality, variance homogeneity)
4. Produce structured, reproducible outputs (plots, dashboards, reports)
5. Separate confirmed findings from hypotheses
6. Include confidence intervals for estimates
7. Document data preparation steps including SQL provenance

**Common mistakes to prevent:**
- LLM computing statistics directly (non-reproducible across runs)
- Skipping assumption checks before parametric tests
- Cherry-picking p-values
- Visualization without accessibility (color-blind palettes)
- Overfitting to specific datasets

---

### G. Technical Documentation Agent

**Methodologies to embed:**
- **Diátaxis framework**: Tutorials (learning), How-to (task), Reference (info), Explanation (understanding)
- **Docs-as-code**: version control, CI checks, PR-based review
- **AGENTS.md** as cross-tool source of truth for AI consumption
- **AID** (Agent Interface Document) format: token-efficient, zero-prose, machine-checkable constraints
- **Layer Pyramid**: README → business-logic → service-logic → specs

**LLM-first documentation rules:**
1. Treat doc updates as part of the feature PR, not follow-up
2. One subject = one canonical doc. Derived docs link, never restate.
3. Stale docs are a distinct bug category — they cause agents to generate code that doesn't match reality
4. Anti-fluff gate: explicit audience, measurable statements, source links, no "future ideas" without tracked decisions

**ADR (Architecture Decision Record) for agents:**
- Constraints must be explicit and measurable
- Decisions specific enough to act on ("use PostgreSQL 16 with pgvector" not "use a database")
- Must include Implementation Plan: which files to touch, patterns to follow, tests to write
- Verification criteria as checkboxes an agent can programmatically check

**Prompt should instruct the agent to:**
1. Identify documentation type using Diátaxis taxonomy
2. Follow existing repo conventions; find and match local patterns
3. Assign ownership + review cadence for critical docs
4. Run documentation QA (links, formatting, spelling) before presenting
5. Keep docs token-efficient — every token competes for attention

**Common mistakes to prevent:**
- README gravity (information accumulates in README, other docs stay empty)
- Floating pronouns, "etc." without full lists, broken links
- Two documents describing the same thing differently (non-deterministic for LLMs)
- Marketing copy in technical docs
- Missing error conditions in API reference

---

## Part III: Structured Output Patterns (All Agents)

### Universal Output Contract

Every agent MUST return structured output. The format depends on use case:

**For findings/reviews (JSON):**
```json
{
  "agent": "<role>",
  "summary": "One-line assessment",
  "findings": [
    {
      "id": "<PREFIX>-<NNN>",
      "severity": "critical|high|medium|low|info",
      "category": "security|performance|correctness|maintainability",
      "file": "relative/path.ext",
      "line": 42,
      "title": "Short title (<80 chars)",
      "description": "Detailed explanation",
      "suggestion": "Fix suggestion",
      "effort": "5min|15min|30min|1h|2h+"
    }
  ],
  "stats": { "files_reviewed": 0, "critical": 0, "high": 0, "medium": 0, "low": 0 },
  "verdict": "approve|request-changes|needs-discussion"
}
```

**For reports (markdown):**
```markdown
# [Agent Type] Report

## Executive Summary
[2-3 sentences]

## Critical Issues
[Must fix before proceeding]

## Warnings
[Should fix soon]

## Recommendations
[Optional improvements]

## Positives
[What's done well]
```

### Schema Design Principles

1. **Name fields for application meaning**, not prompt convenience: `sentiment_label` not `result`
2. **Describe each field with a decision rule**: "Set to true only if input includes explicit refund request"
3. **Use enums** whenever downstream logic branches
4. **Allow null** for unsupported values (reduces hallucinated field filling)
5. **Separate evidence from inference**: include `evidence` array with source spans
6. **Keep optional narrative fields small**
7. **State output-only rules explicitly**: "Return only JSON"

### Validation Pipeline

```
Syntax validation → Schema validation → Constraint validation → Semantic validation → Execution validation
```

### Recovery on Invalid Output

1. Automatic repair pass (re-prompt with schema + invalid output)
2. Retry with reduced complexity (drop optional fields)
3. Ask for abstention (`"unknown"`, `null`, `"needs_review"`)
4. Fallback to more reliable model for hard cases
5. Route to human review queue

---

## Part IV: Code Review Agent (Cross-Cutting)

Code review agents combine all domains. The multi-agent approach is winning:

### Multi-Agent Review Architecture

| Agent | Focus | Category Prefix |
|---|---|---|
| Security Auditor | OWASP, secrets, injection | SEC |
| Performance Analyst | N+1, memory leaks, bottlenecks | PERF |
| Correctness Checker | Bugs, logic errors, edge cases | BUG |
| Maintainability Reviewer | DRY, SOLID, complexity | MAINT |
| Test Generator | Coverage gaps, missing tests | TEST |
| Accessibility Reviewer | WCAG, keyboard, screen reader | A11Y |
| **Oracle/Coordinator** | Dedup, validate, score, finalize | — |

### Two-Stage Prompting Protocol (Key Innovation)

**Stage 1:** Reasoning chain — agent reasons out loud without committing to JSON
**Stage 2:** Structured extraction — agent receives its own reasoning back, extracts findings as JSON

The reasoning trace survives into the coordinator's context so it can see WHY a specialist flagged something, not just WHAT.

### Severity Classification

```
🔴 Must Fix (Blockers) — PR should not merge
├─ Security vulnerabilities (OWASP Top 10)
├─ Data loss risks
├─ Silent failures masking bugs
└─ Breaking changes without migration

🟡 Should Fix (Improvements) — Fix before next release
├─ SOLID violations
├─ DRY violations (>3 duplicates)
├─ Performance bottlenecks
└─ Missing error handling

🟢 Can Skip (Nice-to-haves) — Optional
├─ Style inconsistencies (if no linter)
├─ Minor naming improvements
└─ Documentation gaps
```

### Anti-Hallucination Protocol

1. **Verify before asserting** — never claim patterns exist without checking with Grep/Glob
2. **Occurrence rule**: >10 = established, 3-10 = emerging, <3 = not established
3. **Read full file** — never review just diff lines
4. **Uncertainty markers**: ❓ to verify, 💡 consider, 🔴 must fix

---

## Part V: Key Takeaways

### The 10 Commandments of Specialist Agent Prompts

1. **One agent, one job.** Split planner/executor/critic into separate prompts.
2. **Constraints must be testable.** "Max 5 bullets" beats "be concise."
3. **Always include stopping conditions.** "Done when X is produced."
4. **Restate critical rules at the end.** Recency bias is real.
5. **Include failure-mode instructions.** What happens when things go wrong.
6. **Use structured output with explicit schemas.** JSON with enums, not free text.
7. **Separate evidence from inference.** Claims must reference verified data.
8. **Version and test prompts.** They're code, not prose.
9. **On-demand loading.** Don't load all tools/skills/context into every prompt.
10. **Treat the prompt as software.** PR reviews, eval sets, rollback capability.

### Output Format Matrix

| Agent Type | Primary Format | Key Fields | Delivery |
|---|---|---|---|
| Security | JSON + Markdown report | CWE, OWASP ref, severity, evidence, fix | Finding cards + executive summary |
| SEO | Markdown tables | severity, confidence, evidence, impact, fix, effort | FULL-AUDIT-REPORT.md + ACTION-PLAN.md |
| Infrastructure | HCL/YAML + Security report | resources, findings, cost estimate | Generated files + review table |
| Accessibility | WCAG-criterion findings | criterion, severity, location, impact, fix, test | Issue cards + Playwright tests |
| Performance | Before/after metrics | baseline, optimization, verified speedup, correctness | Metric tables + profiling data |
| Data Science | Structured report + visualizations | findings with numerical evidence, confidence intervals | Plots + narrative + data tables |
| Documentation | Diátaxis-typed docs | type, audience, ownership, review cadence | Template-filled documents |
| Code Review | JSON findings + Summary | id, severity, category, file, line, suggestion | Review summary + inline comments |

---

## Sources

- Zylos Research: Prompt Engineering for AI Agent Systems (2026)
- AgentsCamp: Designing System Prompts for LLM Apps
- SuperPrompts: Agentic AI Prompt Engineering Best Practices 2026
- Agentbrisk: Prompt Engineering for AI Agents 2026 Guide
- Inflectra: AI Agent Prompt Engineering Best Practices 2026
- OWASP: Secure Agent Playbook, AI Agent Security Cheat Sheet
- STRIDE-AI: Threat Modeling Framework for Generative AI (arXiv 2605.17163)
- Christian Schneider: Threat Modeling Agentic AI
- Multiple SEO audit skills and frameworks (Agentic-SEO, seo-audit-skill, google-seo-audit, seo-technical)
- KubeTofu, DojOps, InfraSquad, TerraBot, xops.bot (Infra agent frameworks)
- Accessibility prompts from AI Tools Guidebook, a11y-plugin, WCAG audit commands
- PERFOPT-Bench and ISO-Bench (performance optimization benchmarks)
- StatGuard-Agent, CoDA, DataPilot-AI, DeepAnalyze, DatawiseAgent (data science agents)
- docs-codebase skill, doc-pipeline, AID format, ADR skill (documentation patterns)
- Promptly.cloud, Claude Agent SDK, LangChain, OpenAI structured output docs
- Code Review Agent blueprint, comprehensive review patterns, multi-agent review frameworks
