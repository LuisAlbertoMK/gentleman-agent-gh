# Perf Bench: Q4_K_M vs big-pickle (small_model) — 2026-08-28

Ciclo P2 — bench local de cuantizacion Q4_K_M/Q5_K_M para `small_model`
(title generation) contra el estado actual (`big-pickle` como small_model).

## 1. Resumen Presenc 2026 (quantization landscape)

Tabla de referencia GGUF/llama.cpp (mem total, valores aproximados):

| Quant | 8B mem | 70B mem | ppl (vs FP16) | MMLU | speedup |
|---|---|---|---|---|---|
| FP16 | ~16 GB | ~140 GB | 0 (base) | base | 1.0× |
| Q8_0 | ~8.5 GB | ~73 GB | +0.1% | ~0.1% | ~1.6× |
| Q5_K_M | ~5.4 GB | ~47 GB | +0.6% | ~0.5% | ~2.5× |
| Q4_K_M | ~4.9 GB | ~40 GB | +1.9% | -1.5% | 3.7× |
| Q3_K_M | ~3.9 GB | ~31 GB | +4.5% | -4.0% | ~4.6× |

**Conclusion**: Q4_K_M es el sweet spot — ppl +1.9% y MMLU -1.5% (imperceptible
para titulos cortos) con 3.7× speedup vs FP16 y ~4.9 GB en 8B: cabe en
13.94 GB de RAM compartida (iGPU Vega). Q5_K_M (+0.6% ppl, -0.5% MMLU, 2.5×)
es el alternativo si el gap de ppl molesta en reasoning.

## 2. small_model — SmartAD ACL26

- Distillation 1.5B-3B: tool-use/function-calling **ok** en tareas ligeras;
  gap real en reasoning complejo (multi-hop, planeacion).
- **Recomendacion**: `qwen2.5:3b` via **Ollama local** (no cloud) para
  `small_model`. Refuerzo previo en
  `docs/mejoras/2026-08-14-resource-optimization-investigation.md:208`
  ("Recomienda qwen2.5:3b para low-memory on-device inference").
- Estado actual: `small_model` usa el mismo `opencode/big-pickle` que el
  modelo principal — NO es un small model real (ver §4).

## 3. Plan bench local (Ryzen 3700U, Vega, 13.94 GB total)

1. `ollama pull qwen2.5:3b` (default Q4_K_M). Check previo de Ollama:
   `docs/mejoras/2026-08-27-ollama-cloud-investigation.md:45` (GET
   `http://127.0.0.1:11434/api/version`) y `:173` (winget install si falta).
2. Medir VRAM/RAM: `nvidia-smi` si hay GPU dedicada; si no, `tasklist`/
   `Get-Process WorkingSet64` como proxy (iGPU comparte la RAM del sistema).
3. Latencia title-gen: `qwen2.5:3b` (Q4_K_M) vs `big-pickle` (FP16) con
   `Measure-Command`, prompt de titulo corto, N≥3 mediciones (mediana).
4. Metricas de prompt: ~3.5 chars/token (prompts cortos del repo).
5. Baseline de contexto: `compaction.keep.tokens = 6000` no debe cambiar
   con small_model local (titulos < 1-2k chars).

**Stub de medicion**: `scripts/bench-q4.ps1` (params `-ModelQ4 -ModelFP16`).

## 4. Metricas base (estado actual, citado file:line)

| Metrica | Valor | Cite |
|---|---|---|
| `model` | `opencode/big-pickle` | `opencode.json:2` |
| `small_model` | `opencode/big-pickle` (== principal) | `opencode.json:1988` |
| `watcher.ignore` | 9 patrones (node_modules, .git, dist, temp, build, .next, coverage, .codebase-memory, experiments) | `opencode.json:1989-2001` |
| `compaction` | auto+prune, reserved 4000, **keep.tokens 6000** | `opencode.json:243-250` (6000 en `:248`) |
| `subagent_depth` | 2 | `opencode.json:2002` |
| Ollama local base | `http://127.0.0.1:11434` | `docs/mejoras/2026-08-27-ollama-cloud-investigation.md:45` |
| G1 previo: small_model para title-gen | gap detectado en ciclo C14 | `docs/mejoras/2026-08-14-resource-optimization-investigation.md:270` |

## 5. Criterio de exito

- qwen2.5:3b Q4_K_M title-gen latencia <= big-pickle actual en AGENTES locales
  (Ryzen 3700U) — objetivo comprobable con `scripts/bench-q4.ps1`.
- Small model real (3B) sustituye a big-pickle en `small_model` si el gap
  ppl +1.9% no degrada la calidad del titulo (eval cualitativa N≥10).