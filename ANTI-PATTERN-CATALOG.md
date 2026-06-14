# ANTI-PATTERN CATALOG

> Every documented failure = permanent immunity.
> Loaded at start of every session. Updated after every corrected mistake.

---

## 2026-05-26: Premature solution without understanding
**Symptom**: Started coding before fully understanding the user's requirement. Wasted tokens on wrong approach.
**Root cause**: Not asking clarifying questions. Assumed intent.
**Fix**: STOP → re-read user message → ask ONE confirmation question before ANY code.
**Prevention**: No code before user confirms understanding. Use "¿Entendí bien?" gate.
**Files**: AGENTS.md (Rules), karpathy-prompt/SKILL.md

## 2026-05-26: Over-explaining tool output
**Symptom**: Ran a tool, got output, then re-explained the output in text. Wasted tokens.
**Root cause**: Not trusting tool output to speak for itself.
**Fix**: Tool output = sufficient. Only add text to interpret or highlight.
**Prevention**: "Don't echo the tool. Add value or add silence."
**Files**: karpathy-prompt/SKILL.md, AGENTS.md

## 2026-05-26: Context restatement before answering
**Symptom**: "You asked about X... well..." before the actual answer. Users know what they asked.
**Root cause**: Over-politeness, treating conversation as human-human.
**Fix**: Zero restatement. Answer assumes question context.
**Prevention**: "User knows what they asked. Jump to answer."
**Files**: AGENTS.md, KARPATHY-IMPROVEMENT-LOG.md

## 2026-05-26: Filler words and pleasantries
**Symptom**: "Sure!", "Great question!", "Let me...", "I think", "I believe" — zero signal, pure noise.
**Root cause**: Default conversational style leaking into tech communication.
**Fix**: Zero pleasantries. Zero hedging. Direct statements only.
**Prevention**: "If it doesn't add information → delete it."
**Files**: AGENTS.md, KARPATHY-IMPROVEMENT-LOG.md

## 2026-05-28: Multiple examples for same concept
**Symptom**: Providing 2-3 examples when 1 suffices. Redundant.
**Root cause**: Not trusting the user to generalize from one example.
**Fix**: 1 example per concept. Amplify only if user asks.
**Prevention**: "One example. Max."
**Files**: karpathy-prompt/SKILL.md

## 2026-05-28: Self-assessment without evidence
**Symptom**: Declaring "done" or "correct" without running tests or verifying output.
**Root cause**: Overconfidence, skipping verification step.
**Fix**: Always produce evidence (test output, screenshot, log). Default-FAIL contract.
**Prevention**: "If it's not verified, it's not done."
**Files**: quality-gate/SKILL.md, AGENTS.md (Default-FAIL)

---

## 2026-06-03: Pre-Flight Gate design flaw — Engram check after creation
**Symptom**: Engram check (step 4) executed after skill creation, defeating its purpose.
**Root cause**: Gate design flaw — step 2 said "create first", but Engram should inform creation.
**Fix**: Reordered gate: check Engram BEFORE creating. Steps 3-4 gather context; step 5 creates with full info.
**Prevention**: "Any check that informs a decision must happen BEFORE the decision, not after."
**Files**: AGENTS.md (Pre-Flight Gate)

## 2026-06-05: TDZ bug — require placed AFTER its first use
**Symptom**: Render deploy failed with `ReferenceError: Cannot access 'initSentry' before initialization` on `backend-misServicios/index.js:32`. Service exited before binding port. Production down.
**Root cause**: Latent bug from commit `d164436` (feat Sentry). `const { initSentry } = require('./utils/sentry')` was placed BELOW the line that called `initSentry(env.NODE_ENV)`. In CommonJS, `const` is NOT hoisted (only the binding is created on scope entry; initialization happens at the require line). The bug only manifested in clean installs — Render's `pnpm install` triggered it, local dev's cached `node_modules` hid it for weeks.
**Fix**: Move ALL `require()` calls to the top of the file. If a function uses a module at module scope (not inside a callback), that module's `require` MUST be above the function definition AND above any call to it.
**Prevention**:
1. **Order rule**: imports/requires → schema/types → constants → top-level calls. Never the reverse.
2. **Self-check before committing any file with top-level calls**: `grep -n "^[a-z_].*(" file.js | head -5` and verify all referenced names appear in `require()` lines above.
3. **Smoke test**: a `node --require <mock>` pre-commit script that loads `index.js` with external deps stubbed.
**Files**: `backend-misServicios/index.js` (lines 15-16 require moved to top; warning comment added)

## 2026-06-07: PowerShell string sort+join concatenates names without separator
**Symptom**: After bulk-applying `ChangeDetectionStrategy` import to 19 files via PowerShell regex+sort+join, 5 files had `import { ComponentChangeDetectionStrategy } from '@angular/core';` — symbol names concatenated without comma. Build failed with TS2724.
**Root cause**: Used `Sort-Object -Unique` to dedupe import members, then `($items -join ', ')`. When the original import had a single member like `Component` and the regex captured only that one token, the join logic produced the correct result for that path — but the FALLBACK branch (when no `@angular/core` import existed) used a different replacement that REPLACED the first import of ANY package and inserted the new import line after, leaving the old single-member import to be processed by the same dedupe logic. PowerShell's `-split` on a single-token string returns the token as-is, but the regex capture `$Matches[1]` for files with `import { Component } from '@angular/core'` lost the comma boundary, causing the join to glue tokens directly.
**Fix**: Manual `Edit` tool applied to the 5 corrupted files. Replaced `ComponentChangeDetectionStrategy` with `ChangeDetectionStrategy, Component` in each. Build green.
**Prevention**:
1. **NEVER use `Sort-Object -Unique` + `-join` to manipulate TypeScript import statements.** PowerShell's string handling is hostile to comma-separated lists with spaces. Use the `Edit` tool with a precise `oldString`/`newString` per file, or write a one-shot sed/awk command, or use `ts-morph` if doing this systematically.
2. **Build INCREMENTALLY when applying bulk changes**: after editing 2-3 files, run `pnpm build` to catch syntax errors before propagating them to 19 files. Detecting TS2724 at file 5 of 19 is OK; detecting it at file 19 means 14 wasted operations.
3. **Pre-bulk-change smoke test**: if a script MUST be used, dry-run on 1 file first, read the diff manually, THEN apply to the rest.
**Files**: `misServicios/src/app/{shared/footer,pages/pedidos,pages/pedidos-shein,pages/personalizados,admin/register-service}/*.ts` (5 files corrupted, all fixed).

## 2026-06-11: PS 5.1 Join-Path positional limit
**Symptom**: `Join-Path $repo 'prompts' 'sdd'` fails with "No positional parameter found". Script crashes with null $sddDir.
**Root cause**: PowerShell 5.1 `Join-Path` only accepts 2 positional parameters (Path + ChildPath). Passing 3 args throws ParameterBindingException. Common on cross-platform scripts written with PS 7 assumptions (where `-AdditionalChildPaths` exists).
**Fix**: Use `Join-Path -Path $repo -ChildPath 'prompts\sdd'` with named parameters, or use `"$repo\prompts\sdd"`, or chain `Join-Path (Join-Path $repo 'prompts') 'sdd'`.
**Prevention**:
1. Always use named parameters with `Join-Path`: `-Path` and `-ChildPath`
2. Never pass more than 2 positional args to any PS cmdlet unless you've verified it supports it in 5.1
3. Test cross-platform scripts on the actual target shell before relying on them
**Files**: N/A (pattern, no specific file)

## 2026-06-11: Trigger regex assumes quote immediately after colon
**Symptom**: Test suite shows `trig:WARN` for skills that clearly have `Trigger: Task completion, "score"...`. Regex `Trigger:\s*"` returns False.
**Root cause**: The regex `Trigger:\s*"` matches `Trigger:` + whitespace + `"`. But trigger text is `Trigger: Task completion, "score"` — the `"` is NOT immediately after whitespace; there's text between. `\s*` only matches whitespace, then `"` expects the next character to be a quote, but it's `T` (from `Task`).
**Fix**: Use `Trigger:[^"]*"\w` — "Trigger:" then any non-quote chars, then a quote, then a word char.
**Prevention**: When writing regex to find a pattern after `Key:`, always consider that there may be text between the colon and the target token. Use `.*?` or `[^"]*` to bridge the gap.
**Files**: scripts/skill-test-suite.ps1 (line 70)

## 2026-06-13: Knowledge skills with verbose inline examples waste context
**Symptom**: Loading a web-quality skill (accessibility, performance, SEO) consumes +67% tokens without proportional quality gain. 70% of skill content is redundant code examples that duplicate reference files.
**Root cause**: Skills from addyosmani/web-quality-skills were designed as standalone tutorials, not as runtime agent skills. Every criterion has 3-5 code variations inline when 1 example + reference link suffices.
**Fix**: Compact SKILL.md by moving verbose code examples to `references/`. Keep only: POUR/framework structure, criterion numbers, threshold tables, checklists, and severity matrices. Verified via 3-trial validation: quality loss -1.2% (within ≤5% threshold), lines reduced -67.6%.
**Prevention**: 
1. Before adding any skill, compact it first: max 150 lines for knowledge skills, 80 lines for utility skills
2. Code examples belong in `references/`, not inline. One illustrative snippet per criterion max
3. Run Skill Validation Protocol (3-trial benchmark) before/after compaction to verify ≤5% loss
4. Update both `.agents/skills/{name}/SKILL.md` and `skills/{name}/SKILL.md` to keep in sync
**Files**: `.agents/skills/{accessibility,performance,best-practices,seo,core-web-vitals}/SKILL.md`, `auto-metrics/SKILL.md` (Skill Validation Protocol)

## TEMPLATE for new entries
```
## YYYY-MM-DD: Short title
**Symptom**: 
**Root cause**: 
**Fix**: 
**Prevention**: 
**Files**: 
```
