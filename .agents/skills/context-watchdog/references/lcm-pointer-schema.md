# LCM Lossless Pointer Schema — Ronda 3 Slice 3 (F1)

> **Status:** F1 design + schema + first wired component. Full rollout (L1/L2/L3 migration
> + compression measurement vs YELLOW>40%→RED>80%) → Ronda 4. Paper: arxiv 2605.04050 §2.1.
> Runtime: `scripts/lcm-dag.ps1` (`Add-LcmNode`, `Get-LcmNode`, `Invoke-LcmEscalation`).
> Round-trip proof: `scripts/tests/lcm-dag.Tests.ps1` ("round-trips lossless").

## 1. Hierarchical summary DAG (design)

```
L1 (40-60% ctx) ──parent──▶ L2 (60-80%) ──parent──▶ L3 (>80%)
section summary        decisions 1-2 lines       1-liner + lossless Pointer
~20% tokens            + Engram IDs              (content lives OUTSIDE the DAG)
```

- **Nodes:** `{id, level, parent, content≤500ch, pointer, tokens, createdAt, cycle}`.
- **Edges:** `{from: parentId, to: childId}` — one parent per node (chain, not tree).
- **Escalation** (`Invoke-LcmEscalation`, thresholds = watchdog zones):
  `NONE<40% · L1 40-60 · L2 60-80 · L3>80` (compact at 70% — SKILL.md ORANGE rule).
- **Storage:** `.learnings/lcm-dag.json {nodes, edges, meta{cycle,budget}}`, per-cycle
  (cycle id from `inter-track.json`). GC: not yet → Ronda 4.
- **Lossless invariant:** L1/L2 summaries are lossy; **every L3 node MUST carry a
  `pointer` that resolves to the byte-identical source** (hash-verified). A DAG
  without a resolvable L3 pointer is just Résumé-Driven Compression — rejected.

## 2. Lossless pointer schema

```
pointer = kind ":" ref [ "#sha256:" hex64 ]
kind    = "file" | "engram" | "diff"
```

| Kind | `ref` | Resolves via | Example |
|------|-------|--------------|---------|
| `file` | repo-relative path (or abs temp in tests) | `Get-Content -LiteralPath` + sha256 | `file:.agents/skills/context-watchdog/SKILL.md#sha256:9f2c…` |
| `engram` | observation id | `mem_get_observation` | `engram:engram-obs-42` |
| `diff` | commit range | `git diff <range>` | `diff:6d104c73..HEAD` |

- **Canonical form** includes `#sha256:` (64 lowercase hex). Bare `file:<path>`
  (no hash) is accepted but counts as **unverified** — resolvable, not proven.
- `Add-LcmNode -Level L3` without `-Pointer` warns (`L3 without Pointer is not
  lossless`) — the warning IS the schema enforcement until R4 wiring.
- **Resolver contract** (any client, 3 steps):
  1. `Get-LcmNode -Id <id>` → node; parse `pointer` with
     `^file:(?<ref>.+)#sha256:(?<hash>[0-9a-f]{64})$` (file kind).
  2. Read `ref`, sha256 the bytes.
  3. Equal → **lossless proven**; mismatch/missing → node is corrupt, re-capture.

## 3. Worked round-trip (copy-paste, pwsh 7)

```powershell
. ./scripts/lcm-dag.ps1
'critical decision text' | Set-Content /tmp/src.md -NoNewline
$h = (Get-FileHash /tmp/src.md -Algorithm SHA256).Hash.ToLower()
$n = Add-LcmNode -Level L3 -Content 'one-line summary' -Pointer "file:/tmp/src.md#sha256:$h"
$g = Get-LcmNode -Id $n.id
# verify: re-hash ref, compare with hash embedded in pointer → must match
$m = [regex]::Match($g.pointer, '^file:(?<ref>.+)#sha256:(?<hash>[0-9a-f]{64})$')
(Get-FileHash $m.Groups['ref'].Value -Algorithm SHA256).Hash.ToLower() -eq $m.Groups['hash'].Value
# → True = lossless round-trip (Add → Get → resolve → hash match)
```

## 4. First wired component (this slice)

- `Invoke-LcmEscalation` thresholds already match watchdog zones (tested 35/45/65/85%).
- `SKILL.md` Verification row now points L3 at this schema (`file:…#sha256:…` +
  `Get-LcmNode` resolves + hash matches) — the wire is doc-contract, enforced by test.
- Explicitly NOT in F1: auto-escalation hook (`session-checkpoint.ps1`), GC of old
  cycles, L1/L2 migration, compression-ratio measurement → Ronda 4.
