# ADR-030: ConfigValidator — node-free config validation (G3)

- **Status**: Accepted · **Date**: 2026-08-13 · **Type**: architecture / CI
- **Context**: G3 — `opencode.json` is the runtime config consumed by `gentle-orchestrator`
  via `generate-opencode-config.js` (Node). ADR-003 documented that `ConvertTo-Json`
  silently unwraps single-element arrays to scalars (e.g. `skills.paths: [".agents/skills"]`
  → `"paths": ".agents/skills"`), breaking config resolution. `generate-opencode-config.js`
  cannot run in CI when Node is denied in the orchestrator scope — we need a **node-free**
  validation gate that runs on `ubuntu-latest` via `pwsh`.
- **Decision**: **Enfoque A (Minimal)** — `scripts/lib/ConfigValidator.psm1` with three
  focused checks + one orchestrator entry point (`Test-OpencodeConfig`):

  1. **`Test-SkillsPaths`** — `skills.paths` must be a `[string[]]` (G1 regression guard).
     A bare string means `ConvertTo-Json` unwrapped a single-element array.
  2. **`Test-PromptRefs`** — every `{file:...}` reference in agent `prompt`/`description`
     must resolve to an existing file relative to the config directory (ref-integrity).
  3. **`Test-AgentDefinitions`** — agent section must include `gentleman-*`, `sdd-*`, and
     `gentle-orchestrator` (G3 regression guard: 50 agents total — 40 gentleman + 10 sdd).
  4. **`Test-OpencodeConfig`** — runs all three, returns `0` (pass) / `1` (fail).

  CI workflow: `.github/workflows/ci.yml` — `ubuntu-latest`, `shell: pwsh`, relative paths
  only (no `D:\...`). Runs `Import-Module ./scripts/lib/ConfigValidator.psm1` then
  `Test-OpencodeConfig -Path ./opencode.json`.

- **Alternatives evaluated**:
  - **A (Minimal — chosen)** — 184-line PSM1, 3 focused tests, zero Node dependency.
    +184 lines, low surface area, CI-native on ubuntu-latest.
  - **B (Pester-only)** — write 50 `It` blocks validating structure. Brittle: tests assert
    exact agent count (fragile against new skills), no reusable gate. Rejected.
  - **C (Node + Jest)** — reuse `generate-opencode-config.js --validate`. Rejected: Node
    is denied in orchestrator scope; adds ~200MB container bloat to CI.

- **Tests**: `scripts/tests/config-validator.Tests.ps1` — **12 tests** covering:
  - `Test-SkillsPaths`: valid array → pass; bare string → fail; missing → fail; empty entries → fail
  - `Test-PromptRefs`: valid ref → pass; missing ref → fail; no refs → pass; non-rooted path
  - `Test-AgentDefinitions`: 50 agents with all types → pass; missing orchestra → fail;
    missing sdd → fail; count mismatch → fail
  - `Test-OpencodeConfig`: valid config → 0; missing file → 1; invalid JSON → 1; aggregation
    - **12/12 PASS** (verified with Pester on 2026-08-13)

- **`AddRange` bug note**: Initial implementation used `$all.AddRange([string[]]@(...))` which
  throws `MethodInvocationException` when the sub-function returns `$null` (empty list cast).
  Fixed with pipeline: `(Test-...) | Where-Object { $_ } | ForEach-Object { $all.Add($_) }` —
  this is **anti-pattern #19** in `ANTI-PATTERN-CATALOG.md` (`AddRange` null-safety).

- **Consequences**: `ci.yml` now runs on every `pull_request` to `main` and `push` to
  `experimento/**`. Config drift (G1 array unwrapping, G3 agent drift) is caught at PR time
  with no Node dependency. `sync-vmk.ps1` and `use-gentleman.ps1` remain the source-of-truth
  for runtime config generation; ConfigValidator is the CI gate that guards them.

- **Refs**: ADR-003 (array unwrapping); ADR-028 (json-utils); `scripts/lib/ConfigValidator.psm1`;
  `scripts/tests/config-validator.Tests.ps1`; `.github/workflows/ci.yml`; commit `0d80b1a3`.
