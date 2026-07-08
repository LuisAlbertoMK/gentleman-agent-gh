# Pattern Guard & Detection System

> Cross-project pattern matching engine. Detects project type → loads relevant patterns → runs heuristics → reports proactively. Integrates with Pre-Flight Gate (Rung 0b).

## Architecture Overview

```
[Session Start / Pre-Task]
       │
       ▼
┌──────────────────┐
│ 1. Classification │◄── project-mapper signals (package.json, go.mod, Dockerfile, HTML)
│    Engine         │    Returns: {tech_layer, biz_type, confidence}
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ 2. Pattern Store  │◄── mem_search(query="patterns/{biz_type}/*", all_projects=true)
│    Query          │    Returns: [Pattern{id, type, priority, tags, detection_logic}]
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ 3. Detection     │◄── For each pattern: run detection heuristic
│    Runner        │    (grep, Playwright, static analysis, or manual)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ 4. Priority      │◄── Rank results: critical > important > nice-to-have
│    Sorter        │    Factors: confidence, project signals match, history
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ 5. Report        │◄── Present to user (on-demand or pre-flight)
│    Engine        │    Suggestions auto-fixable? Ask first.
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ 6. Feedback Loop │◄── "doesn't apply" → suppress | "fix it" → trigger
│    & Learn       │    "wrong" → downgrade score
└──────────────────┘
```

---

## 1. Project Classification Algorithm

### Input Signals (weighted)

| Signal | Weight | Source | Example |
|--------|--------|--------|---------|
| `package.json` → `dependencies` | 30% | project-mapper | `next`, `react`, `gatsby` → landing page |
| `go.mod` → `module` | 25% | project-mapper | `cli`, `cmd` → CLI tool |
| `Dockerfile` | 10% | project-mapper | `nginx`, `node` → web service |
| `index.html` / `*.html` count | 10% | glob | >5 HTML files → web project |
| `openapi.yml` / `swagger` | 10% | grep | → API project |
| `Cargo.toml` / `pyproject.toml` | 5% | project-mapper | framework detect |
| Directory structure | 5% | static analysis | `cmd/`, `internal/` → Go CLI |
| `docker-compose.yml` services | 5% | grep | `db`, `redis` → infra-heavy |

### Classification Output

```json
{
  "tech_layer": "frontend" | "backend" | "fullstack" | "cli" | "desktop" | "mobile" | "infra",
  "biz_type": "web" | "api" | "ecom" | "saas" | "erp" | "landing" | "cli" | "desktop" | "mobile" | "library",
  "confidence": 0.0..1.0,
  "signals": [
    {"signal": "package.json", "matched": ["next", "react"], "confidence": 0.8},
    {"signal": "html_files", "count": 12, "confidence": 0.6}
  ]
}
```

### Confidence Scoring

- **> 0.8**: Strong — auto-proceed, no confirmation needed
- **0.5 - 0.8**: Moderate — show classification, ask "is this correct?"
- **< 0.5**: Weak — ask user to classify manually

**Algorithm**: Weighted sum of signal confidences, clamped to [0, 1]. If top-2 types within 0.15 of each other → show both as options.

---

## 2. Pattern Matching Query Design

### Engram Schema

Patterns stored as engram observations with topic_key format:

```
patterns/{biz_type}/{pattern-name}
```

Example:
```
patterns/api/missing-rate-limiting
patterns/api/no-openapi-spec
patterns/web/missing-csp-headers
patterns/landing/no-analytics
patterns/ecom/no-structured-data
patterns/erp/missing-audit-log
```

### Query Strategy

```
mem_search(query="patterns/{biz_type}/*", all_projects=true, limit=50)
```

Fallback: if `< 3` results, expand:
```
mem_search(query="patterns/{tech_layer}/*", all_projects=true, limit=20)
```

### Pattern Storage Format

Each pattern stored as an engram observation:

```json
{
  "topic_key": "patterns/api/missing-rate-limiting",
  "type": "pattern",
  "content": {
    "id": "api-rate-limit",
    "title": "Rate limiting is missing",
    "type": "api",
    "priority": "critical",
    "tags": ["security", "api", "production"],
    "severity": "high",
    "detection": {
      "method": "grep",
      "pattern": "rate.?lim|throttl|429",
      "include": "*.go,*.ts,*.py,*.js",
      "exclude": "node_modules,vendor",
      "expected": "match >= 1",
      "on_fail": "No rate limiting detected — API is vulnerable to abuse"
    },
    "auto_fixable": false,
    "suggestion": "Add rate limiting middleware (e.g., express-rate-limit, go.chrisp.ru/limiter)",
    "docs_url": "https://example.com/api-security/rate-limit"
  }
}
```

### Ranking by Relevance

Multi-factor scoring for each matched pattern:

```
relevance = (biz_type_match * 0.5) 
          + (tech_layer_match * 0.2) 
          + (tag_overlap * 0.15) 
          + (priority_bonus * 0.1) 
          + (history_bonus * 0.05)
```

Where:
- **biz_type_match**: 1.0 if exact, 0.5 if related (ecom → web), 0 otherwise
- **tech_layer_match**: 1.0 if exact, 0.3 otherwise
- **tag_overlap**: intersection of pattern tags vs project signals
- **priority_bonus**: critical=0.3, high=0.2, medium=0.1, low=0
- **history_bonus**: +0.05 if previously useful for similar projects

### False Positive Prevention

1. **Signal threshold**: Pattern only activates if ≥1 detection signal has confidence > 0.3
2. **Project size gate**: If project has < 3 source files → skip (too small to classify reliably)
3. **Type exclusion list**: Pattern can declare `exclude_types: ["library", "monorepo_root"]`
4. **User override**: Once user says "doesn't apply" → `mem_save` with `suppressed: true` + auto-downgrade
5. **Cooldown**: Same pattern not re-reported within same session unless user asks

---

## 3. Detection Execution Strategy

### Detection Methods

| Method | When | Cost | Example |
|--------|------|------|---------|
| **grep** | Always (cheap) | O(n) | `grep -r "rate.?lim" --include="*.go"` |
| **glob** | Always (cheap) | O(1) | Check `openapi.yml` exists |
| **static analysis** | On-demand (medium) | O(nd) | Parse imports, count HTML files |
| **Playwright** | Frontend only (expensive) | Slow | Render audit, WCAG check |
| **npm audit** | Node projects (medium) | Slow | Dependency vulnerability scan |
| **User confirm** | Pattern needs judgment | 1 question | "Do you have a CSP policy?" |

### Execution Modes

```
LAZY (default)     → grep + glob only (sub-100ms)
                  → run immediately after classification
                  
BATCH             → grep + glob + static analysis
                  → run in background, collect results
                  → report on session start
                  
ON_DEMAND         → Playwright + npm audit
                  → run only when user asks or pre-flight gate needs it
```

### Efficiency

- **grep patterns cached** per session (same project doesn't re-grep)
- **Static analysis memoized**: classify once, reuse results
- **Heavy detections** (Playwright, audit) deferred to `!audit` command
- **Parallel execution**: independent grep/glob detections run in parallel via `ctx_batch_execute`

### Detection Result

```json
{
  "pattern_id": "api-rate-limit",
  "status": "fail" | "pass" | "skip" | "manual_needed",
  "evidence": "No matches for 'rate.?lim|throttl|429' in 47 source files",
  "confidence": 0.95,
  "auto_fixable": false,
  "suggestion": "Add rate limiting middleware..."
}
```

---

## 4. User Interaction Flow

### When to Alert

```
Session Start:
  └── Run LAZY detection (grep+glob)
  └── If any CRITICAL findings → alert immediately
  └── Else → store for on-demand report

Pre-Flight Gate (Rung 0b):
  └── Only if task touches pattern-related area
  └── e.g., "add new endpoint" → trigger API patterns
  └── e.g., "update home page" → trigger web/landing patterns

On-Demand:
  └── !guard → full report with all findings
  └── !guard <type> → report for specific type (e.g. !guard security)
  └── !guard run <pattern-id> → run single pattern detection

Silent:
  └── Patterns that pass → logged to engram, not reported
  └── Patterns with confidence < 0.5 → suppressed
```

### Report Format

```
═══ Pattern Guard Report ═══
Project: my-app (landing page · confidence: 0.85)

🔴 CRITICAL (2)
  • CSP headers missing → src/index.html:0 | grep:no "Content-Security-Policy"
    Fix: Add <meta http-equiv="Content-Security-Policy"> or server header
    [s] suppress | [f] auto-fix | [i] ignore this type

🟡 HIGH (3)
  • No analytics → no GA/Plausible snippet detected
  • No meta tags → missing description, OG, Twitter card
  • No sitemap.xml → missing at /sitemap.xml
    [s] suppress | [?] tell me more | [i] ignore this type

🟢 INFO (1)
  • Lighthouse not run → use !audit to evaluate performance

[Enter # to act, or Enter to dismiss]
```

### Autonomy Levels

| Level | Behavior |
|-------|----------|
| **Suggest** (default) | Report findings, ask before acting |
| **Auto-fix trivial** | Fix automatically only if fix is idempotent + reversible (e.g., add missing meta tags) |
| **Auto-fix safe** | Fix patterns with `auto_fixable: true` — always show diff first |
| **Manual only** | Never auto-fix, only report |

---

## 5. Pre-Flight Gate Extension

### Current Rungs (from AGENTS.md)

```
0. Factibilidad (INBYPASSABLE) — logical/physical constraints
1. YAGNI
2. Stdlib
3. Native
4. Dep
...
```

### Proposed: Rung 0b — Pattern Cross-Check

Inserted between Rung 0 and Rung 1:

```
0b. Pattern Cross-Check (INBYPASSABLE if pattern-related task)
  └── Classification: What type is this project? (reuse rung 0a if already classified)
  └── Load patterns for this type
  └── Run LAZY detection (grep+glob only — sub-100ms)
  └── If task area has known patterns → show them
  └── If task contradicts a known pattern → BLOCK with explanation
```

### Performance Protection

- **Skip if**: project already classified this session + no new files changed → reuse previous results
- **Skip if**: explicit `!ponytail off` (debug mode)
- **Lazy-only**: never run expensive detections in the gate path
- **Cache key**: `{project_root_hash + modified_timestamp}` — busted only on file changes
- **Timeout**: 200ms max — if detection takes longer, defer to background

### Task Relevance Detection

Not every task needs pattern cross-check. Trigger only when:

```
task_description matches any pattern tag
  └── "add endpoint" → tags: ["api", "security"] → check rate-limit, auth patterns
  └── "update homepage" → tags: ["web", "ui"] → check CSP, meta tags patterns
  └── "fix bug in payment" → tags: ["ecom", "payment"] → check validation patterns
  └── "refactor database" → tags: ["api", "data"] → check migration patterns
```

Task relevance detection: simple keyword overlap between task description and pattern tags. If overlap ≥ 1 tag → run cross-check for those patterns only.

---

## 6. Feedback Loop Design

### User Actions → System Reactions

```
User says "doesn't apply":
  └── mem_save(topic_key="patterns/{biz_type}/{pattern-id}/suppressed", 
                type="feedback", content={reason, date})
  └── Downgrade pattern priority by 1 level for this type
  └── If suppressed 3x for same type → auto-disable pattern for this type

User says "fix it":
  └── If auto_fixable → run fix, show diff, ask to confirm
  └── If not auto_fixable → show instructions / open docs
  └── mem_save(topic_key="patterns/{biz_type}/{pattern-id}/fixed",
                type="feedback", content={date, fix_applied})

User says "wrong pattern" (false positive):
  └── mem_save(topic_key="patterns/{biz_type}/{pattern-id}/false-positive",
                type="bugfix", content={reason, evidence})
  └── Reduce detection confidence by -0.2
  └── If same false positive 2x → add exclusion rule to pattern
  └── If same false positive 3x → flag pattern for review

Pattern fix was rolled back:
  └── mem_save(topic_key="patterns/{biz_type}/{pattern-id}/reverted",
                type="bugfix", content={reason})
  └── Downgrade pattern to INFO only
```

### Anti-Pattern Catalog Integration

When a pattern causes harm (wrong fix applied, wasted time):

```
1. immune-system DETECT: "this pattern was wrong"
2. DIAGNOSE: Why was it wrong? (wrong type match? weak detection? outdated?)
3. DOCUMENT: Add entry in ANTI-PATTERN-CATALOG.md
4. IMMUNIZE: Update pattern guard config to exclude this scenario
```

### Pattern Health Scoring

Each pattern maintains a health score:

```
health = (total_triggers * 0.3) 
       - (suppressed_count * 0.2) 
       - (false_positive_count * 0.4) 
       + (fix_applied_count * 0.3)

Thresholds:
  > 5: Healthy — keep
  0 to 5: Warning — reduce priority
  < 0: Broken — flag for human review / auto-disable
```

---

## 7. Implementation Roadmap

### Phase 1: Foundation (Week 1)
- [ ] Pattern store schema (engram topic_key convention)
- [ ] Classification engine (reuse project-mapper, add confidence)
- [ ] LAZY runner (grep + glob)
- [ ] `!guard` command — on-demand report

### Phase 2: Integration (Week 2)
- [ ] Rung 0b in Pre-Flight Gate (AGENTS.md update)
- [ ] Task relevance detection (keyword overlap)
- [ ] Session-start auto-classification
- [ ] Cache layer (avoid re-classifying per task)

### Phase 3: Advanced (Week 3)
- [ ] BATCH runner (static analysis)
- [ ] Auto-fix for trivial patterns
- [ ] Playwright integration for frontend types
- [ ] Feedback loop full implementation

### Phase 4: Learning (Week 4)
- [ ] Pattern health scoring
- [ ] Auto-disable broken patterns
- [ ] Cross-project pattern mining (find new patterns automatically)
- [ ] `!dream` integration — harvest patterns from session summaries

---

## 8. Key Files

| File | Purpose |
|------|---------|
| `.agents/skills/pattern-guard/SKILL.md` | Pattern Guard skill definition |
| `docs/design/pattern-guard.md` | This document |
| `scripts/pattern-guard.ps1` | CLI entry point |
| `scripts/pattern-detect.ps1` | Detection runner |
| `scripts/pattern-classify.ps1` | Classification engine |
| `.agents/skills/pattern-guard/patterns/` | Default pattern library (optional, can live wholly in engram) |

---

## Appendix: Example Pattern Catalog

### Web / Landing Page

| Pattern | Detection | Priority | Auto-fix |
|---------|-----------|----------|----------|
| Missing CSP headers | grep `Content-Security-Policy` in HTML/nginx | critical | No |
| Missing meta tags | grep `og:title`, `twitter:card`, `description` | high | Yes |
| No analytics | grep `gtag\|plausible\|umami\|clarity` | medium | No |
| No sitemap | glob `sitemap.xml` | low | No |
| No robots.txt | glob `robots.txt` | low | Yes |
| Missing favicon | glob `favicon.ico` | low | Yes |

### API / Backend

| Pattern | Detection | Priority | Auto-fix |
|---------|-----------|----------|----------|
| Missing rate limiting | grep `rate.?lim\|throttl\|429` | critical | No |
| No OpenAPI spec | glob `openapi.yml\|swagger.json` | high | No |
| Missing input validation | grep `validate\|sanitize\|schema` in handlers | critical | No |
| No health endpoint | glob `health.go\|health.ts\|/health` | high | No |
| Hardcoded secrets | grep `apiKey\|password=` in source | critical | No |
| No request logging | grep `log.*req\|middleware.*log` | medium | No |

### E-commerce

| Pattern | Detection | Priority | Auto-fix |
|---------|-----------|----------|----------|
| Missing structured data | grep `application/ld+json` | critical | No |
| No CSRF tokens | grep `csrf\|_token` in forms | critical | No |
| Missing checkout validation | grep `validate.*cart\|checkout` | critical | No |
| No order confirmation email | grep `send.*email\|mail.*order` | high | No |

### Desktop App

| Pattern | Detection | Priority | Auto-fix |
|---------|-----------|----------|----------|
| No crash reporting | grep `sentry\|crashlytics\|telemetry` | critical | No |
| No auto-update | grep `update\|updater\|sparkle\|electron-updater` | high | No |
| No offline handling | grep `offline\|network.*error\|connectivity` | high | No |
| No native menus | grep `Menu\|Tray\|tray` | medium | No |

### CLI Tool

| Pattern | Detection | Priority | Auto-fix |
|---------|-----------|----------|----------|
| No `--help` flag | grep `help\|usage` | critical | Yes |
| No exit codes | grep `os.Exit\|process.exit\|exit(` | high | No |
| No color/no-color flag | grep `no-color\|NO_COLOR` | medium | Yes |
| No `--version` flag | grep `version\|--version` | medium | Yes |
| No progress indicator | grep `progress\|spinner\|loading` | low | No |
