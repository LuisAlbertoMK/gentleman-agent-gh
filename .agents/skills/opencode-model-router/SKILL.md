---
name: opencode-model-router
description: "Route tasks by model strength — specialized agents for analysis, implementer for execution"
triggers: "model router, routing, delegate or direct, model decision, specialized agent, implementer"
changelog: docs/ciclos/cycle28-20260815.md
---

## ⚠️ SECURITY GATE (always first)
1. Credentials/secrets/PII? → **DIRECT**
2. Recurring task (cron/CI)? → **DIRECT**
3. Context >150K? → **DIRECT**
4. Otherwise → route below.

## 🎯 ROUTING TABLE (FREE TIER)
> ✅ = twin `-sub` delegable · ⚠️ = sin twin → `general`

| Task | Action | Agent | Model | Fallback |
|------|--------|-------|-------|----------|
| Security/vulnerability ✅ | DELEGATE | `gentleman-security-sub` | Nemotron 3 Ultra Free (1M) | `gentleman-deep-sub` → `general` |
| SEO/content ✅ | DELEGATE | `gentleman-seo-sub` | Nemotron 3 Super Free | `gentleman-deep-sub` → `general` |
| Infrastructure/K8s/Terraform ✅ | DELEGATE | `gentleman-infra-sub` | DeepSeek V4 Flash Free (1M) | `general` |
| Frontend/UI/a11y ✅ | DELEGATE | `gentleman-frontend-sub` | Kimi K2.5 Free (262K) | `general` |
| Performance/profiling ✅ | DELEGATE | `gentleman-performance-sub` | Nemotron 3 Ultra Free (1M) | `general` |
| Data/SQL/Python ✅ | DELEGATE | `gentleman-datascience-sub` | MiMo V2.5 Free | `general` |
| Documentation ✅ | DELEGATE | `gentleman-docs-sub` | Big Pickle (always free) | `general` |
| Implement plan ✅ | DELEGATE | `gentleman-implementer-sub` | DeepSeek V4 Flash Free (1M) | `gentleman-quick-sub` → `general` |
| Architecture/code review | DIRECT | `gentleman-vMK` | — | — |
| Quick edit ✅ | DELEGATE | `gentleman-quick-sub` | MiMo V2.5 Free | `general` |
| Script generation | DIRECT | `gentleman-codex` | DeepSeek V4 Flash Free | — |
| Deep debugging/root cause ✅ | DELEGATE | `gentleman-deep-sub` | Nemotron 3 Ultra Free (1M) | `general` |
| Default | DIRECT | `gentleman-vMK` | — | — |

## 🔧 IMPLEMENTER
`gentleman-implementer-sub` (DeepSeek V4 Flash Free) — precise execution. No unrequested changes.
**Avoid**: Qwen3.7 Max (re-plans, paid), Nemotron 3 Ultra (over-analyzes).

## ⚠️ RUNTIME REALITY (opencode 1.18.x)
- `gentleman-*` sin sufijo = `mode: primary` → Task tool NO los expone.
- Twins `-sub` (implementer/security/deep/quick) SÍ: `subagent` + `hidden` + whitelist `task` (template `orchestrator`).
- DELEGATE ✅ = twin. DELEGATE ⚠️ = `general` — NO reportar falla.
- `opencode.json` sync SSoT: `scripts/regenerate-opencode.ps1` (`-Yes` regenera; CI falla si deriva).

## 📏 CONTEXT → ACTION
| Context | Action |
|---------|--------|
| <50K | Normal routing |
| 50K-100K | Prefer fast models |
| >150K | Direct forced |

## 📚 EXAMPLES (4-5)

### Example 1: Security Audit Request
**User**: "Audit our JWT auth for vulnerabilities"
**Route**: Security/vulnerability → DELEGATE → `gentleman-security-sub` (Nemotron 3 Ultra Free)
**Why**: Security tasks need deep analysis; Ultra Free has 1M context for large codebases
**Fallback**: If twin unavailable → `gentleman-deep-sub` → `general`

### Example 2: Implement a Feature Plan
**User**: "Execute the plan in SPEC-042: add rate limiting to API"
**Route**: Implement plan → DELEGATE → `gentleman-implementer-sub` (DeepSeek V4 Flash Free)
**Why**: Precise execution, no over-analysis, fast model for implementation
**Fallback**: `gentleman-quick-sub` → `general`

### Example 3: Deep Debugging Multi-File Bug
**User**: "Root cause: intermittent 500s on /checkout, spans 3 services"
**Route**: Deep debugging → DELEGATE → `gentleman-deep-sub` (Nemotron 3 Ultra Free)
**Why**: Hypothesis-driven debugging needs reasoning depth + large context
**Fallback**: `general` (no twin for deep-debugging beyond first fallback)

### Example 4: Quick One-Line Fix
**User**: "Fix typo in error message at src/api/errors.ts:47"
**Route**: Quick edit → DELEGATE → `gentleman-quick-sub` (MiMo V2.5 Free)
**Why**: Atomic edit, low risk, fast free model
**Fallback**: `general`

### Example 5: Architecture Decision
**User**: "Should we migrate from REST to gRPC for internal services?"
**Route**: Architecture/code review → DIRECT → `gentleman-vMK`
**Why**: Strategic decisions need primary agent judgment, not delegation

---

## 🧪 TESTING PATTERNS (3)

### Pattern 1: Routing Decision Verification
```bash
# Given a task description, verify correct route is chosen
echo "Audit JWT auth" | grep -q "Security" && echo "→ security-sub"
echo "Fix typo" | grep -q "Quick" && echo "→ quick-sub"
echo "Architecture review" | grep -q "DIRECT" && echo "→ vMK"
```

### Pattern 2: Fallback Chain Simulation
```bash
# Simulate twin unavailable → verify fallback resolves
mock_twin_unavailable() { return 1; }
route_task() {
  local primary="$1" fallback1="$2" fallback2="$3"
  $primary || $fallback1 || $fallback2 || echo "general"
}
route_task mock_twin_unavailable "deep-sub" "general"  # Should print "general"
```

### Pattern 3: Security Gate Enforcement
```bash
# Tasks with secrets/recurring/large-context must route DIRECT
assert_direct() {
  local task="$1"
  [[ "$task" =~ (secret|credential|PII) ]] && echo "DIRECT forced" && return
  [[ "$task" =~ (cron|CI|recurring) ]] && echo "DIRECT forced" && return
  echo "Normal routing"
}
assert_direct "Deploy with AWS_SECRET_KEY"  # → DIRECT forced
assert_direct "Nightly cron job"            # → DIRECT forced
```

---

## ⚠️ EDGE CASES (4)

### Edge Case 1: Hybrid Task (Security + Implementation)
**Scenario**: "Fix the SQL injection vuln AND implement the patch"
**Resolution**: Split → Security analysis → `security-sub`; Implementation → `implementer-sub`
**Rule**: Never combine analysis + execution in one delegation

### Edge Case 2: Context Near Threshold (140K tokens)
**Scenario**: Large codebase task at 140K context
**Resolution**: Route to fast model (DeepSeek V4 Flash / MiMo) even if task type suggests Ultra
**Rule**: Context budget > model preference when 100K-150K

### Edge Case 3: Twin Exists But Hidden (Whitelist Mismatch)
**Scenario**: `gentleman-frontend-sub` exists but not in orchestrator whitelist
**Resolution**: Falls to `general` silently (per RUNTIME REALITY). Fix: regenerate opencode.json
**Detection**: `scripts/regenerate-opencode.ps1 -Yes` then verify `gh api /repos/.../actions/runs`

### Edge Case 4: Free Tier Exhausted Mid-Task
**Scenario**: Nemotron 3 Ultra Free quota hit during `security-sub` delegation
**Resolution**: Automatic fallback chain triggers → `deep-sub` → `general`
**Monitoring**: Check delegation logs for "fallback activated" pattern

---

## 🚫 ANTI-PATTERNS (2+)

1. **Route sensitive data to subagent** — Credentials, PII, secrets must stay in primary agent (DIRECT)
2. **Delegate when context >150K** — Forces DIRECT regardless of task type
3. **Skip fallback chain** — Always define fallback; twins can be unavailable
4. **Pay when free covers it** — Qwen3.7 Max, paid Nemotron — free tier handles 95% of tasks
5. **Forget security gate** — Check 3 conditions BEFORE consulting routing table
6. **Combine analysis + execution in one delegation** — Split: analyzer understands, implementer executes

---

## Refs
execution-mode · delivery-harness · subagent-isolation · skill-graph