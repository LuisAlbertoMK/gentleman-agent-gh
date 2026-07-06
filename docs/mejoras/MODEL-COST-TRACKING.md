# Model Cost Tracking

> **Budget**: $10/mes
> **Period**: Julio 5 → Agosto 5, 2026
> **Strategy**: 90/10 Rule (90% cheap models, 10% expensive)

---

## Cost Estimates by Model

| Model | Cost/min | Cost/task (typical) | Tier |
|---|---|---|---|
| Qwen3.7 Max | ~$0.25 | $0.50-1.00 | High |
| Qwen3.7 Plus | ~$0.10 | $0.20-0.40 | Medium |
| GLM-5.2 | ~$0.20 | $0.40-0.80 | High |
| GLM-5.1 | ~$0.15 | $0.30-0.60 | Medium |
| Kimi K2.6 | ~$0.12 | $0.25-0.50 | Medium |
| MiMo V2.5 Pro | ~$0.05 | $0.10-0.20 | Low |
| DeepSeek V4 Pro | ~$0.08 | $0.15-0.30 | Low |
| DeepSeek V4 Flash | ~$0.02 | $0.05-0.10 | Very Low |
| MiMo V2.5 | ~$0.02 | $0.05-0.10 | Very Low |
| MiniMax M2.7 | ~$0.03 | $0.06-0.12 | Very Low |

---

## Cost by Task Type

### Analysis Tasks (Specialized Agents)

| Task | Agent | Model | Est. Cost |
|---|---|---|---|
| Security audit | gentleman-security | Qwen3.7 Max | $0.50-1.00 |
| SEO audit | gentleman-seo | Qwen3.7 Plus | $0.20-0.40 |
| Infrastructure audit | gentleman-infra | GLM-5.2 | $0.40-0.80 |
| Frontend audit | gentleman-frontend | Kimi K2.6 | $0.25-0.50 |
| Performance audit | gentleman-performance | Qwen3.7 Max | $0.50-1.00 |
| Data pipeline audit | gentleman-datascience | GLM-5.1 | $0.30-0.60 |
| Documentation audit | gentleman-docs | MiMo V2.5 Pro | $0.10-0.20 |

### Implementation Tasks

| Task | Agent | Model | Est. Cost |
|---|---|---|---|
| Implement plan (5 tasks) | gentleman-implementer | MiMo V2.5 Pro | $0.10-0.20 |
| Implement plan (10 tasks) | gentleman-implementer | MiMo V2.5 Pro | $0.20-0.40 |
| Implement plan (20 tasks) | gentleman-implementer | MiMo V2.5 Pro | $0.40-0.80 |

### Routine Tasks (90% of work)

| Task | Agent | Model | Est. Cost |
|---|---|---|---|
| Write function | gentleman-codex | DeepSeek V4 Flash | $0.05-0.10 |
| Quick edit | gentleman-quick | MiMo V2.5 | $0.05-0.10 |
| Generate README | gentleman-docs | MiMo V2.5 Pro | $0.10-0.20 |
| Write script | gentleman-codex | DeepSeek V4 Flash | $0.05-0.10 |

---

## Monthly Budget Tracking

### Julio 2026

| Date | Task | Agent | Model | Cost | Cumulative |
|---|---|---|---|---|---|
| 2026-07-05 | Plan setup | gentleman-vMK | (default) | $0.00 | $0.00 |
| | | | | | |
| | | | | **Total July**: | **$0.00** |

### Alerts

- [ ] **$5.00**: Review usage, consider more fallbacks to cheap models
- [ ] **$8.00**: Sniper mode strict, only critical tasks with expensive models
- [ ] **$10.00**: STOP, only cheap models until next month

---

## Cost Optimization Strategies

### 1. 90/10 Rule

**90% of tasks** → Use cheap models:
- DeepSeek V4 Flash ($0.02/min)
- MiMo V2.5 ($0.02/min)
- Qwen3.7 Plus ($0.10/min)

**10% of tasks** → Use expensive models:
- Qwen3.7 Max ($0.25/min)
- GLM-5.2 ($0.20/min)

### 2. Fallback to Cheaper Models

If expensive model not needed:
- Qwen3.7 Max → DeepSeek V4 Pro (saves ~$0.17/min)
- GLM-5.2 → DeepSeek V4 Pro (saves ~$0.12/min)
- Kimi K2.6 → MiMo V2.5 Pro (saves ~$0.07/min)

### 3. Batch Similar Tasks

Instead of:
- 10 separate calls to Qwen3.7 Max ($5.00)

Do:
- 1 batch call to Qwen3.7 Max with all 10 tasks ($2.00)

### 4. Use Free Tier for Non-Critical

For exploration, testing, learning:
- Use `opencode/*` free models
- Risk: may disappear
- Benefit: $0.00 cost

---

## Cost per Workflow

### Workflow 1: Security Audit + Implementation

```
1. Analysis (gentleman-security, Qwen3.7 Max, 2 min) = $0.50
2. Implementation (gentleman-implementer, MiMo V2.5 Pro, 5 min) = $0.25
Total: $0.75
```

### Workflow 2: SEO Audit + Implementation

```
1. Analysis (gentleman-seo, Qwen3.7 Plus, 3 min) = $0.30
2. Implementation (gentleman-implementer, MiMo V2.5 Pro, 10 min) = $0.50
Total: $0.80
```

### Workflow 3: Performance Optimization

```
1. Analysis (gentleman-performance, Qwen3.7 Max, 5 min) = $1.25
2. Implementation (gentleman-implementer, MiMo V2.5 Pro, 3 min) = $0.15
Total: $1.40
```

### Workflow 4: Routine Task (90% of work)

```
1. Write function (gentleman-codex, DeepSeek V4 Flash, 1 min) = $0.02
Total: $0.02
```

---

## Monthly Projection

### Scenario 1: Conservative (mostly routine tasks)

- 100 routine tasks × $0.05 = $5.00
- 5 analysis tasks × $0.50 = $2.50
- 5 implementations × $0.20 = $1.00
- **Total**: $8.50/mes ✅

### Scenario 2: Moderate (balanced)

- 80 routine tasks × $0.05 = $4.00
- 10 analysis tasks × $0.50 = $5.00
- 10 implementations × $0.20 = $2.00
- **Total**: $11.00/mes ⚠️ (over budget)

### Scenario 3: Aggressive (many complex tasks)

- 50 routine tasks × $0.05 = $2.50
- 20 analysis tasks × $0.50 = $10.00
- 20 implementations × $0.20 = $4.00
- **Total**: $16.50/mes ❌ (way over budget)

**Recommendation**: Stay in Scenario 1 (conservative) to maintain $10/mes budget.

---

## How to Track Costs

### Automatic (if available)

```bash
# Show token usage and cost statistics
opencode stats

# Export session data
opencode export [sessionID]
```

### Manual

Update this file after each significant task:

```markdown
| Date | Task | Agent | Model | Duration | Cost | Cumulative |
|---|---|---|---|---|---|---|
| 2026-07-05 | Security audit | gentleman-security | Qwen3.7 Max | 2 min | $0.50 | $0.50 |
| 2026-07-05 | Implement plan | gentleman-implementer | MiMo V2.5 Pro | 5 min | $0.25 | $0.75 |
```

---

## Cost Reduction Tips

1. **Use cheap models for 90% of tasks**
   - DeepSeek V4 Flash for scripts
   - MiMo V2.5 for quick edits
   - Qwen3.7 Plus for content

2. **Reserve expensive models for critical analysis**
   - Qwen3.7 Max only for security/performance
   - GLM-5.2 only for infrastructure
   - Kimi K2.6 only for large frontend analysis

3. **Batch similar tasks**
   - Combine multiple small tasks into one call
   - Reduces overhead and total cost

4. **Use fallbacks when possible**
   - If Qwen3.7 Max not needed, use DeepSeek V4 Pro
   - Saves ~$0.17/min

5. **Monitor weekly**
   - Check `opencode stats` weekly
   - Adjust strategy if approaching budget limit

---

## Last Updated

- **Date**: 2026-07-05
- **Updated by**: gentleman-vMK
- **Next review**: 2026-07-12 (weekly)
