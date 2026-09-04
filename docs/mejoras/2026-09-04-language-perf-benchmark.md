# Language Performance Benchmark — PS vs Python vs Go (2026-09-04)

## Context

Question: with limited hardware resources, which language yields the best speed/resource
tradeoff for this repo's file operations, and is a full migration from PowerShell advisable?

Machine profile (this benchmark ran on it):

| Component | Value | Implication |
|---|---|---|
| CPU | AMD Ryzen 7 3700U, 4C/8T @ 2.3GHz (mobile) | modest CPU ceiling |
| RAM | 14.9 GB total, ~6.4 GB free | memory-conscious (repo profile: `medium-resource`) |
| Storage | 2x SATA SSD (ADATA SU650, ~500 MB/s) — NOT NVMe | file IO is disk-bound |
| OS | Windows 11 Home | PS 5.1/7 dual runtime |
| Toolchains | Go 1.26.5, Python 3.14.7 | all three candidates available |

## Methodology

- Fixture: real repo data — `.agents/skills` subtree copied to temp (169 files, 95 SKILL.md)
- Identical operations implemented in pwsh 7.6.5 (`-NoProfile`), Python 3.14.7, Go 1.26.5 (compiled)
- Ops: `read` (all SKILL.md, sum bytes) · `write100` (100 files x 3KB) · `edit100` (read-modify-write) · `scan` (metadata walk)
- 3 runs each, median reported; child-process peak WorkingSet64 polled at 12ms intervals
- Spawn cost: median of 5 process spawns per runtime (CLI-per-op realism)
- Harness: temp `lang-bm/{go,py,ps,run.ps1}` (ephemeral, not committed)

## Results

### File operations (median ms, lower is better)

| Op | PowerShell | Python | Go | Go vs PS | Python vs PS |
|---|---|---|---|---|---|
| read (95 files) | 579 | 135 | **80** | **7.2x (-86%)** | 4.3x (-77%) |
| write100 (300KB) | 521 | 222 | **146** | **3.6x (-72%)** | 2.3x (-57%) |
| edit100 (RMW) | 846 | 272 | **153** | **5.5x (-82%)** | 3.1x (-68%) |
| scan (169 files) | 124 | 61 | **50** | **2.5x (-60%)** | 2.0x (-51%) |

### Memory (peak child WorkingSet)

| PowerShell | Python | Go |
|---|---|---|
| 88.8 MB | 12.7 MB | **8.5 MB** (-90% vs PS) |

### Process spawn cost (CLI-per-op tax)

| pwsh -NoProfile | python | Go binary |
|---|---|---|
| **1355 ms** | 110 ms | **33 ms** (41x faster) |

### End-to-end per invocation (spawn + edit-class op)

| PS | Python | Go |
|---|---|---|
| ~2201 ms | 382 ms | **186 ms** → **11.8x (-91.5%)** vs PS |

### Real-world gate (measured, this session)

`bin/fast.exe --gate` (cross-ref 94 skills + 58 agents concurrent + token-budget): **92 ms, passed**.
PS fallback equivalent: ≥1355 ms spawn + interpretation ≈ 2–4 s → **~95–97% reduction** on that path.

## Key findings

1. **This machine is IO/disk-bound** (SATA): Go and Python converge on `scan` (50 vs 61 ms)
   because both hit the same disk ceiling. Language CPU advantages saturate at the disk —
   Rust would gain single-digit % here.
2. **pwsh spawn tax (1355 ms) dominates single-script invocations** on this hardware —
   bigger than the file-op itself. Any CLI-per-op design pays it per process.
3. **PS overhead is per-cmdlet interpretation**, not disk: 2.5–7x gap vs Go on identical IO.
4. **Go wins every axis simultaneously**: speed, memory, spawn — no tradeoff needed.
5. AI-workflow-specific: the scarcest resource is LLM context/tokens and model round-trips,
   not milliseconds. Go tools emitting one compact JSON line also cut agent context cost.

## Approaches analyzed (12)

| # | Approach | Speed gain | Resource cost | Effort | Verdict |
|---|---|---|---|---|---|
| 1 | Status quo (PS everywhere) | baseline | 88.8 MB/tool + 1.35 s/spawn | — | keep as orchestration host |
| 2 | PS micro-optimized ([IO.File] API, -NoProfile, no pipelines) | ~20–40% ops; 0% spawn | same RAM | low | apply opportunistically |
| 3 | Python for file ops | 3–4.3x ops, 12x spawn | 12.7 MB | low | reject: second runtime for middle-ground gains |
| 4 | Go CLI per-op (fast.exe pattern) | 3.6–7.2x ops, 41x spawn | 8.5 MB | low | ✅ extend (proven) |
| 5 | Go mega-CLI (one binary, subcommands) | same + single artifact/1 build | 8.5 MB | medium | ✅ target state |
| 6 | Go daemon + named-pipe IPC | +33 ms saved vs #5 | daemon RAM always-on | high | reject: complexity > gain |
| 7 | Rust hot paths | ≤5–10% over Go (IO-bound) | lowest | high | reject: overkill, disk-bound |
| 8 | Hybrid: PS orchestration + Go hot paths + PS fallback | realized 92 ms gate | low | low | ✅ **winner (ADR-049)** |
| 9 | Manifest cache layer (skill/agent tree JSON) | ~50 ms/op saved | small file | medium | optional, low priority |
| 10 | PS ForEach-Object -Parallel | 2–4x CPU-bound batches | RAM spike (runspaces) | low | situational only |
| 11 | Committed binaries vs source+build | — | git bloat + staleness | — | ✅ source-only (done: 94e914ad); bins are frozen, source is upstreamable/modifiable |
| 12 | Token-aware tool design (Go emits compact JSON) | agent round-trips ↓ | less context | low | ✅ apply to new tools |

## Decision summary

Full migration: **NO** (91 PS orchestration scripts stay — they glue Windows/git/hooks where PS is
domain-king and the bottleneck is IO/process spawn, not language). Surgical: **YES** — any new or
measured-hot file/CPU path goes to Go behind the existing mega-CLI, with PS fallback, source in git.

---

## Phase 2 — Spawn reduction: Go pre-gate shim (same day)

Finding: the 26-check quality gate (`pre-commit-gate.ps1`) was **never wired locally**
(no `core.hooksPath`, no `.git/hooks` shim, no installer wiring) — local commits ran
ungated. Enabling it as-is would tax every commit with one pwsh spawn (1355 ms) + full
gate even for docs-only commits whose PS checks are all staging-skipped.

Implementation (commit d3fdbe66):

- `cmd/gate/main.go` — Go shim: runs repo-portable checks natively (fast-gate via
  `bin/fast.exe --gate`, trailing whitespace, secrets scan, config size budget,
  async-result fail-closed), classifies staged paths against the PS-gate trigger
  regexes, escalates to the full PS gate ONLY when PS-only checks are relevant, and
  falls back to pwsh on any error/missing exe (fail-safe, never blocks silently).
- `.githooks/pre-commit` — prefers `bin/gate(.exe)`, one-time silent `go build`
  self-heal, pwsh fallback preserved.
- Gate enablement: `git config core.hooksPath .githooks` (local — installer wiring
  still pending, see follow-ups).
- Latent defects surfaced by the now-live gate, fixed in the same commit:
  `check-skill-drift.ps1` crashed on partial global skill dirs (dir without SKILL.md);
  `ps-compat` skill 231 B over its token budget (trimmed to 3283 B ≤ 3300);
  `cmd/*` missing from write-scope allowed_paths; self-scan exclusion for the
  secrets-scanner's own regex definition (`cmd/gate/*` pathspec, mirrors the
  existing `.githooks` exclusion convention).

Measured (this machine, warm cache):

| Path | Before | After | Gain |
|---|---|---|---|
| Docs-class commit (no PS triggers) | ~3.4 s (spawn 1355 + full gate) | **254–317 ms** | **~11x (-90%)** |
| PS-triggered commit | ~3.4 s + full gate | full gate + ~200 ms shim overhead | ~unchanged (correct: those need PS) |
| Empty staging | n/a (paid full spawn) | **~230 ms** internal | — |

Escalation verified live: staged `.ps1`/skills → shim printed `Escalating to PS gate
(3 trigger(s))`, ran 26/26 checks, commit accepted. Blocking semantics verified:
secrets regex hit → exit 1; async-result `passed:false` → exit 1.

Follow-ups status (updated same day):

1. ~~Installer wiring~~ **DONE** (confidence: high) — `scripts/setup-install.ps1:42`
   and `scripts/install.sh:51` wire `core.hooksPath .githooks` (build the gate
   binary when Go is present, else announce pwsh fallback, ADR-049). Fresh clones
   are gated from install.
2. ~~Pre-push gate spawns pwsh unconditionally~~ **RESOLVED by inspection**
   (confidence: high) — `.githooks/pre-push:38-40` re-runs pre-commit, which
   prefers `bin/gate(.exe)` (`.githooks/pre-commit:22-24`); no unconditional pwsh
   spawn.
3. Post-commit ~885 ms no-op: **NOT REMEDIATED**, exact figure not re-measured
   (measuring would require a real commit) — low priority. Structure verified:
   `.githooks/post-commit:21-29` classifies skill triggers before spawning pwsh.
   confidence: low (number) / high (structure).
4. ~~PS-CI-03~~ **CLOSED** (confidence: high) — commit 24200d2d dot-sources
   `Get-Cache`/`Set-Cache` directly (`scripts/check-skill-drift.ps1:18,22,88`),
   dropping the breaker-marker dependency.
5. Global skills dir drift — **EVOLVED** (confidence: high): `accessibility` is no
   longer GLOBAL_MISSING. Current state: 95 global vs 94 canonical skills; the only
   global skill without SKILL.md is `_shared` (by design,
   `scripts/check-skill-drift.ps1:41`); 4 GLOBAL_NOT_JUNCTION (warn):
   `accessibility`, `cancel-ralph`, `help`, `ralph-loop`. Re-junction only with an
   explicit decision — do NOT run sync.
6. **NEW gap** (confidence: medium): the Go fast path skips the PS gate's
   always-run checks — `cmd/gate/main.go:548-564` (9 triggers) vs
   `pre-commit-gate.ps1:303-312`: [19/26] backlog Runs ALWAYS, and [16/26], [24/26],
   [25/26] have no staged guard — so docs-only commits bypass
   backlog/write-scope/async/token-regression checks. Recommendation: document as
   an accepted gap, or escalate if CYCLE.md/scope changes.
7. `checkpoint/harness-2026-09-01` (confidence: high): single commit e51f40cc,
   superseded by 29 commits on main (merge-base 44214d05) — keep as archive, do
   NOT merge (binary must not enter the repo, `.gitignore:102`), do NOT delete
   without an explicit decision.
