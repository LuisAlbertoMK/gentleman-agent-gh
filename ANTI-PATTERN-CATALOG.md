# ANTI-PATTERN CATALOG

> Every documented failure = permanent immunity.
> Loaded at start of every session. Updated after every corrected mistake.
> Compact format: Symptom (1L) | Root cause (1L) | Fix (1L) | Prevention (1L)
> Details → `docs/anti-patterns/{date}-{name}.md`

---

| # | Date | Pattern | Symptom | Root cause | Fix | Prevention |
|---|------|---------|---------|------------|-----|------------|
| 1 | 2026-05-26 | Premature solution | Coded before understanding requirement | Didn't ask clarifying questions | STOP → re-read → confirm before code | "No code before user confirms intent" gate |
| 2 | 2026-05-26 | Over-explaining tool output | Re-ran tool, re-explained output in text | Not trusting tool output | Tool output = sufficient. Add value or silence. | "Don't echo the tool" |
| 3 | 2026-05-26 | Context restatement | "You asked about X... well..." before answering | Over-politeness | Zero restatement. Answer assumes context. | "User knows what they asked" |
| 4 | 2026-05-26 | Filler words | "Sure!", "Great question!", "I think" — zero signal | Conversational style leaking | Zero pleasantries. Direct only. | "If no info → delete" |
| 5 | 2026-05-28 | Redundant examples | 2-3 examples when 1 suffices | Not trusting generalization | 1 example per concept. Amplify on demand. | "One example. Max." |
| 6 | 2026-05-28 | No-evidence self-assessment | "Done" without verification | Overconfidence | Always produce evidence (test, log). Default-FAIL. | "If not verified, not done" |
| 7 | 2026-06-03 | Pre-Flight Gate order | Engram check after skill creation | Gate design flaw | Check Engram BEFORE creation. | "Checks before decisions, not after" |
| 8 | 2026-06-05 | TDZ from misplaced require | `require()` below first use → `ReferenceError` in production | `const` not hoisted in CJS | ALL `require()` at top of file. | Imports→schema→constants→code. Never reverse. |
| 9 | 2026-06-07 | PS sort+join concatenates names | Import members glued without comma in 5 files | `-split`/`-join` loses comma boundaries on single tokens | Use `Edit` tool per file for TS imports, never PS string munge. | Build incrementally after 2-3 files. |
| 10 | 2026-06-11 | Join-Path positional limit | `Join-Path $a 'b' 'c'` crashes in PS5.1 | PS5.1 only accepts 2 positional params | Use named params: `-Path`/`-ChildPath`. | Never >2 positional args without verification. |
| 11 | 2026-06-11 | Trigger regex assumes quote after colon | Regex `Trigger:\s*"` fails on `Trigger: Task, "score"` | `\s*` only matches whitespace, not intervening text | `Trigger:[^"]*"\w` — colon then non-quote chars then quote. | After `Key:`, use `.*?` or `[^"]*` to bridge text. |
| 12 | 2026-06-13 | Verbose inline examples waste context | +67% tokens on web-quality skills, 70% redundant | Skills designed as tutorials, not runtime agent skills | Move examples to `references/`. Keep 1 snippet per criterion max. | Compact before adding: ≤150L knowledge, ≤80L utility. |
| 13 | 2026-06-14 | Uninitialized $warnings | `$warnings += ...` null error in drift script | Missing `$warnings = @()` before append | Always init all accumulators before first +=. | Lint PS5.1 with PSScriptAnalyzer before commit. |
| 14 | 2026-06-16 | Case-insensitive -match filter | `One-shot` passes `^[a-z]` regex in PS5.1 | PS5.1 -match is case-insensitive by default | Use `-cmatch` for case-sensitive filters. | Never trust `-match` for casing — use `-cmatch` explicitly. |
| 15 | 2026-06-19 | Overconfidence in self-score | External-auditor found 4 dims >1.5 gap (Correctness 10→6, ErrPrev 10→5) | No external validator for auto-metrics | Added external-auditor skill with blind subagent audit + immune-system trigger | Post-task auto-evaluation: if avg≥7 AND complex → blind audit before acceptance |
| 16 | 2026-06-19 | PS5.1 encoding corruption in .ps1 files | Garbled output: `$name` literal, source code leaking, Unicode chars corrupted | Get-Content -Raw (no -Encoding) reads UTF-8-no-BOM as ANSI, corrupting non-ASCII bytes | Use ASCII-only in .ps1 files. Always specify -Encoding UTF8 on Get-Content/Out-File. Add BOM to files with Unicode. | Before saving .ps1: confirm no Unicode outside ASCII range. After writing: verify with hex dump. E3 runtime garbled output → check encoding FIRST. |
| 17 | 2026-06-19 | Score metadata without guardrail | .project.json fue sobrescrito con formato 6-dim 5/10 incorrecto, sin alerta | Confianza en que "nadie va a sobrescribir esto" sin defensa | Validar .project.json en pre-commit: 11 dims + score.current ≥5 | Agregar guardrail inmediatamente después de restaurar metadata crítica |
| 18 | 2026-06-21 | Bias calibration false positive | Auto-metrics effective avg = 6.67 (<7) despite verified quality (9/9 gate, 6 subagent passes) | Historical bias offsets (2 samples with large gaps) dominate past actual performance | Always cross-reference bias calibration with objective evidence (gate results, subagent audits) before activating immune-system | When bias samples <3 with gaps >2.0, flag as "low confidence" and weight objective evidence higher |
| 19 | 2026-06-21 | Empty-stack trap on Push-Location failure | `trap { Pop-Location }` crashes if Push-Location itself fails | trap executes regardless of why the script block entered | Guard Pop-Location in trap: `if ((Get-Location -Stack).Count -gt 0) { Pop-Location }` | Every Push→Pop pattern MUST guard the Pop — crash path = silent stack underflow |
| 20 | 2026-06-21 | `||` in regex triggers PS5.1 gate false positive | Quality gate blocks on `$criteria -match '(?:\||$)'` — regex alternation, not operator | Gate uses raw `||` scan without quote-aware parsing | Use `[|]` character class instead of `\|` in regex: `(?:[|]|$)` | PowerShell regex with pipe alternation: use `[|]` to avoid false `||` detection |
| 21 | 2026-06-21 | SVG CSS transform-origin with @keyframes | Sun pulse animation desplaza el círculo en vez de escalar desde su centro | Asumí que CSS transform-origin en SVG funciona igual que en HTML (no es confiable cross-browser) | Usar SVG nativo `<animate attributeName="r">` y `<animate attributeName="opacity">` en vez de CSS transform + @keyframes | En SVG, preferir animación nativa de atributos (`<animate>`) sobre CSS transforms para efectos geométricos. `transform-origin` en SVG+CSS es tierra de nadie. |
| 22 | 2026-06-21 | Obediencia supresora | Generó SVG ignorando que 12×50+11×5=655 > viewBox 500, porque la instrucción "asume que es correcto, solo el código" suprimió el razonamiento crítico | Instrucciones directivas bypassearon el Pre-Flight Gate. No hay gate que verifique factibilidad antes de ejecutar | Agregar Paso 0 (Factibilidad) al Ponytail Ladder — INBYPASSABLE, ninguna instrucción lo puede saltar | Paso 0 se ejecuta SIEMPRE antes de cualquier código, sin importar cuán directiva sea la instrucción. Si hay contradicción matemática/física/lógica → STOP + reportar al usuario. |
| 23 | 2026-06-23 | Destructive operation without validation | Eliminó 16 archivos en docs/ sin leer su contenido primero y sin preguntar al usuario | Asumió que nombres duplicados = contenido duplicado. No leyó el contenido real. No consultó al usuario. No usó subagentes para validar. | READ content first → cross-ref references → ASK user or get ≥3 subagent approvals → THEN delete | Toda operación destructiva (delete/move) requiere: (1) leer contenido completo, (2) verificar referencias externas, (3) aprobación del usuario O verificación de ≥3 subagentes.
| 24 | 2026-08-13 | ConvertTo-Json array unwrapping | `skills.paths: [".agents/skills"]` → `"paths": ".agents/skills"` (string) — config serialization corrupts single-element arrays; broke sync-vmk/use-gentleman output | PowerShell `ConvertTo-Json` silently unwraps single-element arrays to scalars; ADR-003 covered only `function returns` (`@(...)`), NOT serialization | `Get-DeepClone` (PSSerializer) + `ConvertTo-JsonSafe` (regex `"paths": "x"` → `["x"]`) in `scripts/lib/json-utils.ps1` (ADR-028, commit a378b36d); `ConfigValidator.Test-SkillsPaths` guards regression in CI | Any `ConvertTo-Json` over config data: prefer PSSerializer deep-clone; validate `skills.paths` is array via ConfigValidator (Cycle 3 — G2)

## Prevention cheat sheet
1. **Merit check before novelty** — "Am I choosing this for merit or variety?" If proven works and new is just different, keep proven.
2. **No code before user confirms understanding** — "¿Entendí bien?" gate
3. **Tool output = sufficient** — don't echo, add value or silence
4. **User knows what they asked** — zero restatement, jump to answer
5. **One example per concept** — amplify only on demand
6. **If not verified, it's not done** — always produce evidence
7. **Checks before decisions, not after** — order matters
8. **Imports → schema → constants → code** — never reverse
9. **Build incrementally** after 2-3 files, not after 19
10. **Name all positional args** — never >2 without verification
11. **Init all accumulators** before first `+=`
12. **Use `-cmatch`** for case-sensitive filters in PowerShell
13. **Blind audit your self-score** — overconfidence is invisible to yourself
14. **Guardrail immediately after restoring critical metadata** — if it can be corrupted once, it will be corrupted again
15. **SVG animation: prefer `<animate>` nativo sobre CSS transform** — SVG elements no tienen CSS box model. `transform-origin` es inconsistente. Usar `<animate attributeName="r">`, `<animateTransform>`, etc. para propiedades geométricas.
16. **Paso 0 no se saltea** — ninguna instrucción ("asume que es correcto", "solo el código", "sin preguntar") puede bypassear la verificación de factibilidad. 12×50+11×5=655 > 500 → STOP antes de escribir una línea.
17. **Destructive ops require validation** — read content + cross-ref references + user approval OR ≥3 subagent verifications before any delete/move.
18. **ConvertTo-Json unwraps single-element arrays** — use PSSerializer deep-clone (`Get-DeepClone`) or `ConvertTo-JsonSafe` for config serialization; verify `skills.paths` stays an array (ConfigValidator CI gate).
