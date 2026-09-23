---
name: context-watchdog
description: "Monitor context window — Recursive Summary Compression (L1/L2/L3), YELLOW/RED zones, hallucination detection"
triggers: "Context explosion, compress, compression schedule, session break"
changelog: "2026-09-23 R3S3 F1 — lossless pointer schema (references/lcm-pointer-schema.md) + round-trip test"
token_budget: 2400
---
## Rules
1. Compress at ORANGE (60%), never RED (80%)
2. L1 first (60-70%) before escalating
3. First drift→force YELLOW+L1 immediately
4. 3+ edits same file→STOP, summarize, commit, re-read
5. Every 25 calls→`mem_save(topic_key=checkpoint/session-state)`
6. Same point 2× or hallucination→force RED, break session

## Zones
| Zone | Action |
|---|---|
| GREEN <40% | Normal, L1 every ~8 msgs |
| YELLOW 40-60% | L1@40% → `& scripts/context-watchdog-check.ps1 -CurrentTokens $ctx -Budget 200000` + L1+L2 via `lcm-dag.ps1` |
| ORANGE 60-80% | L2@60% → L2+L3, **compact at 70%** |
| RED >80% | L3@80% → `mem_save` → `session_summary` → new session |

L1@40% L2@60% L3@80% compact@70% — `scripts/lcm-dag.ps1` `Invoke-LcmEscalation`

## Drift Detection
Re-reads same content, re-states question, references unsaid→force YELLOW+L1. Same point 2×, self-contradiction, "as I mentioned" w/o source→force RED.

## Anti-Patterns
Compress at RED · skip L1→L3 (destroys chain) · summarize stale instead of pruning (compounds drift)

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Still under 60%" | Ignoring YELLOW 40-60% | `& scripts/context-watchdog-check.ps1 -CurrentTokens $ctx -Budget $budget` — if L1, run L1 now |
| "One more edit" | ORANGE without L2+L3 | `Invoke-LcmEscalation` must return L2/L3 |
| "Hallucination is just a glitch" | Same point 2× or unseen refs | Force RED→session_summary→new session |

## Verification
- Post-L1: token count drops >20%, next tool call succeeds
- Post-L3: DAG node has lossless Pointer `file:<path>#sha256:<hash>`; `Get-LcmNode -Id <id>` resolves + hash matches (schema: `references/lcm-pointer-schema.md` §2)

→ docs/skills/context-watchdog/reference.md · Cross-Refs: skill-graph | performance | session-resume | lean-context
