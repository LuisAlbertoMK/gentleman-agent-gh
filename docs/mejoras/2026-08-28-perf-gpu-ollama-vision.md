# Perf Exp GPU — Ollama vision offline fallback + WebP fast-path

- **Date**: 2026-08-28
- **Branch**: `feat/perf-ram-cpu-opt-2026-08-28`
- **Experiment**: P2-P3 GPU tuning (Ollama offline-first + image pipeline)
- **topic_key**: `perf/exp-gpu-2026-08-28`
- **Status**: audit + verification done, doc-only (no code change viable in allowed paths)

## 1. Audit (task 1) — vision analysis & image pipeline

| Item | Finding | Confidence |
|---|---|---|
| `scripts/vision-analyze/` | **Does not exist** in repo | high (glob) |
| Ollama vision logic | Lives in `scripts/analyze-screenshot.ps1` (195 lines) + `scripts/analyze-page.ps1` (wrapper) | high (read+grep) |
| Vision model | `moondream:latest` default; options `moondream`, `llava:7b`, `llava:13b` | high (read, analyze-screenshot.ps1:26) |
| Endpoint | `http://localhost:11434` `/api/chat`, base64 image, `stream=$false` | high (read :158) |
| num_thread / num_ctx / keep_alive | **Not set anywhere** — body sends only model/messages/stream | high (read :144-154) |
| GPU requirement 4-8GB VRAM | N/A on this machine — no Ollama, no dedicated GPU; tier = **medium** (integrated GPU, shared RAM) | high (hardware-profile detect) |
| `scripts/image-pipeline/` | **Does not exist** — skill is global `~/.config/opencode/skills/image-pipeline`; repo has only `docs/skills/image-pipeline/reference.md` | high (glob) |
| AVIF/WebP logic | `reference.md`: `cwebp -q 80` batch + `avifenc --speed 4 --quality 50` + responsive-set generating both | high (grep reference.md) |

## 2. Offline-first fallback (task 2) — ALREADY EXISTS, VERIFIED

`analyze-screenshot.ps1:107-127` implements graceful degradation:

1. `Invoke-RestMethod /api/tags` with 5s timeout — if unreachable → warning + "Falling back to visual analysis (Read tool)..." + **exit 0** (no gate failure).
2. Model missing from available list → hint `ollama pull <model>` + exit 1.
3. API error during chat → warning + fallback hint + exit 1.

`ui-specialist-pairing.ps1` also degrades offline-first ("Ollama not reachable — degraded to audit/variants only"), and `ui-offline-audit.ps1` needs no Ollama at all.

**Live verification (2026-08-28, Ollama NOT installed on this machine):**
- Screenshot captured → Ollama check failed → graceful message → **EXIT_CODE 0**. confidence: high (bash run)

**Gap**: no Iris Xe profile is applied anywhere (`OLLAMA_NUM_GPU`, `num_thread`, `num_ctx`, `keep_alive` absent). Not implemented because `scripts/analyze-screenshot.ps1` is **outside allowed write paths** for this experiment.

### Recommended Iris Xe profile (16GB shared RAM, integrated GPU)

Apply when Ollama is installed and the GPU is integrated:

```powershell
$env:OLLAMA_NUM_GPU = "0"    # disable GPU offload — Iris Xe shares RAM with CPU;
                             # offload thrashes bandwidth and risks OOM on 16GB total
# Per-model Modelfile / runtime options (equivalent):
#   num_thread = 2-4   (reserve threads for the host; shared memory contention)
#   num_ctx    = 2048-4096  (moondream needs little context; keep memory flat)
#   keep_alive = 5m    (warm model between calls, avoids re-load churn)
```

Rationale (confidence: medium — parameter guidance based on Ollama runtime docs + integrated-GPU shared-memory physics, not measured locally since Ollama is absent):
- Iris Xe / UHD Graphics share the system memory bus → GPU offload can be *slower* than CPU for small models like moondream (1.8B).
- `num_ctx` dominates KV-cache RAM: 4096 on a 1.8B model ≈ ~0.5-1GB resident; fine within 16GB.
- `keep_alive=5m` amortizes cold-start on repeated screenshot analysis without pinning RAM forever.

## 3. WebP fast-path vs AVIF batch (task 3)

`reference.md` already ships both paths (`cwebp -q 80` and `avifenc --speed 4`). No runtime code exists in repo to branch on; decision is **pipeline strategy**, benchmark-backed:

| Metric | WebP (cwebp -q 80) | AVIF (avifenc --speed 4-6) | Ratio |
|---|---|---|---|
| Encode time, single image | ~10-20 ms | ~200-500 ms | **5-20x slower** |
| File size vs PNG | ~60-75% smaller | ~75-85% smaller | AVIF ~10-25% smaller than WebP |
| Memory during encode | low | high (multi-thread) | — |
| Best use | **real-time / dev-loop / screenshot analysis** | **batch / static delivery** | — |

Reference: dev.to image-format benchmarks (WebP encode ms-scale vs AVIF hundreds-of-ms at practical speed/quality settings). confidence: medium (external benchmark, **not measured locally** — no `cwebp`/`avifenc` binaries on this machine, no image fixtures in repo).

**Recommendation**: real-time path → WebP only; AVIF reserved for batch/delivery. This already matches `reference.md`'s design intent (responsive-set emits both; nothing to change in allowed paths).

## 4. Measurements

| Check | Result |
|---|---|
| `ollama list` / `ollama --version` | **Not installed** (`ollama: not recognized`) — confidence high |
| hardware-profile tier | **medium** (4-8GB RAM, 4 cores, integrated GPU = Iris Xe profile) — confidence high |
| Fallback with Ollama down | **exit 0**, graceful hint, no gate failure — confidence high |
| WebP vs AVIF local timing | not measurable (no binaries/fixtures) — confidence: unvalidated locally |

## 5. Decision

No code change in allowed paths was viable: the offline fallback already exists and passes, and the profile/table gaps are documentation by nature. Changed only `docs/mejoras/` (allowed). Committed locally, **no push**.

## 6. Follow-ups (out of scope)

- If a future experiment may touch `scripts/`: apply the Iris Xe env/modelfile profile to `analyze-screenshot.ps1` (add `OLLAMA_NUM_GPU=0` + `num_ctx`/`keep_alive` to the chat body) and set `moondream` as the verified model.
- Consider adding `cwebp` to `ensure-tools.ps1` for real-time WebP fast-path.