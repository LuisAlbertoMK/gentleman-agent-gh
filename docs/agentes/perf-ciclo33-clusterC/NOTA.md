# Cluster C — 10 micro-experimentos payload (solo medición, sin edits a opencode.json)

> opencode.json es DENY-edit (se regenera). Todos los trials en `C:\Users\MK\AppData\Local\Temp\opencode\mini.json`. Repo intacto.

## Baseline
- opencode.json: 1743 líneas, 55855 B (54.55 KB pretty), 39627 B (38.70 KB minified)
- Parse: python json.loads ~237 ms (base 242 ms / gen 237 ms), pwsh ConvertFrom-Json ~161 ms, minified ~162 ms
- Base 30695 B → generado 55855 B = ratio x1.62 (+25 KB por expansión de 58 agents)
- Skills: 95 SKILL.md, total 251.10 KB, avg 2.64 KB, 8 over-3KB (excess 2.54 KB)
- Agents: 58, 132 `{file:}` refs (avg 2.28/agent), 31 únicos
- MCP: codebase-memory 60s local ON, engram 30s local ON, context7 remote ON (sin timeout), 2 OFF
- Compaction: reserved 4000 + keep.tokens 8000 = 12000 tokens (6.0% @200k, 9.38% @128k, 18.75% @64k)
- Frags: semi-allow 7834 B, shared-deny 2288 B, .project.json 2969 B
- `scripts/generate-config.Tests.ps1` NO existe (solo `scripts/lib/generate-opencode-config.js` 15892 B + `scripts/regenerate-opencode.ps1` 17338 B)

## Tabla 10 exps
| # | Hipótesis | Cambio mínimo (shadow) | Medida antes→después | Veredicto |
|---|---|---|---|---|
| E1 | Parse pretty es cuello cold-start | Ninguno, solo Measure-Command | py 237 ms / pwsh 161 ms @54.55KB | KEEP como baseline |
| E2 | Deny-list 46 reglas pesa poco | Contar deny_chars en temp | 490 chars = 0.48 KB (0.9% del file) | REVERT (no consolidar; shared-deny 2.23KB ya existe) |
| E3 | Expansión agents x1.62 es el bloat | Comparar base 30.7KB vs gen 55.8KB | +25.16 KB por 58 agents inline | KEEP medición; win = mover a refs (proyectado −15 KB) |
| E4 | Cap skills >3KB a 3KB ahorra | Truncar shadow de 8 overs | 8 files, excess 2.54 KB → avg 2.64→2.62KB | KEEP recomendación (top win skills) |
| E5 | Minify JSON −29% payload | json.dumps separators en temp | 54.45→38.70 KB (−15.75 KB, −28.9%), parse 237→162 ms (−75 ms) | KEEP como build-step (TOP PAYLOAD WIN) |
| E6 | Timeout 60s vs 30s handshake | Solo lectura config MCP | cbm 60s ON / engram 30s ON / ctx7 remote sin timeout | KEEP 60s cbm; REVERT bajar a 30s (riesgo cold-start) |
| E7 | Compaction 12k tokens pisa ventana | Estimar % según contexto | 6.0% @200k / 9.38% @128k / 18.75% @64k | KEEP 4000/8000 @200k; REVERT subir en @64k |
| E8 | semi-allow 7.65KB es frag. pesado | Parse frags en temp | 7834+2288 B, parse conjunto ~146 ms | KEEP; win = lazy-load semi-allow solo cuando clasifica |
| E9 | 132 refs = 132 re-lecturas cold-start | Contar refs únicos vs totales | 132 totales / 31 únicos → dedup x4.26 posible | KEEP recomendación (cache refs únicos) |
| E10 | Frontmatter ~0.3KB/skill es overhead | Medir FM en top-15 | FM 0–0.43 KB, media ~0.31 KB ×95 ≈ 29 KB teórico | REVERT strip (FM necesario); KEEP gate ≤3KB |

## Delta total
- Repo: 0 KB / 0 ms (cero edits, verificado `git status` limpio en estos paths)
- Proyectado si se aplican wins: −15.75 KB (minify) −2.54 KB (skill-cap) −~15 KB (agent-refs) ≈ −33 KB (−60% pretty) y −75 ms parse
- Top payload win: **E5 minify build-step** (−15.75 KB / −28.9% / −75 ms), seguido de E9 dedup refs y E4 skill-cap

## SkillOpt gate
- Estado: 8/95 over-3KB (8.4%), avg 2.64 KB (objetivo <2.0 KB NO cumplido, gap +0.64 KB)
- Acción: capar top-8 a 3KB (ahorro 2.54 KB) + dieta progresiva hacia 2.0 KB avg
