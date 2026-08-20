# context-watchdog - Reference Materials

> **Externalized from** .agents/skills/context-watchdog/SKILL.md to keep the skill under the 2KB token budget (ADR-007).

## Examples
"compress" → `ctx_stats` → map % to zone → compress at 70% max, never RED. Same point restated 2x → force RED.


## Testing
1. `ctx_stats` → zone row dictates action. 2. After ≥8 msgs L1-summarize → 60-70% savings band. 3. Restate point 2x → drift flag + force RED within 2 turns.



## Externalized Sections (ADR-007 compression)
## Compression Levels
| L | Trigger | Action | Savings |
|---|---|---|---|
| **L1** | ~8 msgs / ~15 calls | Oldest block ≥8 msgs → summary | 60-70% |
| **L2** | ~20 msgs / ≥3 L1s | Decisions → 1-2 lines + Engram ID | 40-50% |
| **L3** | YELLOW+ | 1-liner/topic + `Ref: engram-obs-{id}` | 80-90% |

```
<40% <8 → Normal | <40% ≥8 → L1 | 40-60% ≥20 → L1+L2
60-80% any → L2+L3 compact@70% | >80% any → mem_save + break
```


## Stale Content Detection (DCP)
30-40% waste = stale, not excess. Prune at L1: scan >25 calls old · Before L2: check engram supersedes · Pre-commit: verify file re-reads.

| Signal | Action |
|---|---|
| Stale ref (A read, B edited, still ref A) | Re-read before using |
| Superseded decision (mem_save X, user Y) | Check engram → L1 + update |
| Echo chamber (re-stating own output) | Force YELLOW + fresh observation |
| Chunk >50 calls no re-read | Exclude from next summary |
| Repeated quote (same excerpt 2+) | Keep only freshest copy |


