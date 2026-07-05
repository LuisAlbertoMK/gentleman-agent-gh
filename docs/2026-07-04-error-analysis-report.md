# Error Analysis Report — 2026-07-04

> Generated from `opencode-errors.md` + `opencode-analysis-session.md` + codebase investigation.
> Cross-referenced against `packages/core/src/`, `packages/opencode/src/`.

---

## 1. 🟡 YAML Parsing Error (Recurrente)

### Error
```
YAMLException: incomplete explicit mapping pair; a key node is missed
  Location: Line 3, Column 87
```

### Source Code Trace
```
packages/core/src/config/markdown.ts:7    → gray-matter.parse(content)  [js-yaml]
packages/opencode/src/skill/index.ts:107  → ConfigMarkdown.parse(match) [loads SKILL.md]
packages/opencode/src/config/markdown.ts:17 → reads file, calls core.parse
packages/core/src/config/markdown.ts:27   → sanitize() retry (doesn't fix all cases)
```

### Root Cause
A `SKILL.md` file (likely in `.vmk-config/skills/` or global `.opencode/`) has malformed YAML frontmatter — `description` field with unescaped special characters or nested quotes.

The `sanitize()` function only wraps values containing colons in block scalars, but cannot handle missing keys or structural YAML errors.

### Effect Cascade
```
YAMLException → skill fails to load → agent retries
  → context7 MCP timeout (3000ms)
  → sequential-thinking MCP timeout (30000ms)
  → retry loop → 26.4% CPU
  → 26K tokens consumed in retries
```

### Fix Applied
- **`packages/core/src/config/markdown.ts`**: Added optional `label` parameter to `parse()` for source identification in error logs
- **`packages/opencode/src/config/markdown.ts`**: Forwards `filePath` as label to core.parse()
- **Remaining**: Identify the specific `SKILL.md` file with broken frontmatter and fix its YAML

---

## 2. 🔴 SQLite Column Error (Session Bloqueado)

### Error
```
SQLiteError: no such column: replacement_seq
  Stack: SessionPrompt → createUserMessage → prepare
```

### Source Code Trace
```
packages/core/src/session/sql.ts:176           → Drizzle schema: replacement_seq: integer()
packages/core/src/database/schema.gen.ts:155    → Generated schema
packages/core/src/database/migration/20260605003541_*.ts:14  → CREATE TABLE (not ALTER)
packages/core/src/session/context-epoch.ts:87    → CRASH: stored.replacement_seq === null
packages/core/src/session/context-epoch.ts:166   → UPDATE: .set({ replacement_seq: seq })
```

### Root Cause
The table `session_context_epoch` exists in the user's DB from an older schema version, but lacks the `replacement_seq` column. The migration `20260605003541_add_session_context_snapshot` does `CREATE TABLE` (assumes table doesn't exist), so it cannot fix existing databases.

### Migration Runner (`packages/core/src/database/migration.ts`)
1. `apply()` detects `session` table → calls `applyOnly()`
2. `applyOnly()` runs only uncompleted migrations (tracked in `migration` table)
3. If migration 20260605003541 is already marked completed but column is missing → no ALTER TABLE exists to fix

### Fix Applied
- **NEW migration**: `20260704120000_fix_missing_replacement_seq.ts` — checks `PRAGMA table_info` and runs `ALTER TABLE ADD COLUMN` only if `replacement_seq` is missing
- **Registered** in `packages/core/src/database/migration.gen.ts`

---

## 3. ⏱️ MCP Timeouts (Contextual)

### MCP Status (from analysis-session)
| MCP | Status | Timeout |
|-----|--------|---------|
| codebase-memory | ✅ Connected | — |
| context7 | ⏱️ Timed out | 3,000ms |
| sequential-thinking | ⏱️ Timed out | 30,000ms |

These timeouts are **cascading effects** of the YAML retry loop, not primary errors.

---

## 4. 🔗 Relationship Map

```
┌─────────────────────────────┐
│   YAML PARSING ERROR        │ ◄── Recurrente, loop de reintento
│   (SKILL.md frontmatter)    │
└────────┬────────────────────┘
         │ consume contexto + CPU
         ▼
┌──────────────────┐   ┌─────────────────────┐
│  SQLITE ERROR    │   │  MCP TIMEOUTS       │
│  (columna falta) │   │  (context7 + seq-th)│
│  Independiente   │   │  Por saturación     │
└──────────────────┘   └─────────────────────┘
```

- **YAML ↔ SQLite**: No relation
- **YAML → Timeouts**: Direct cascade
- **SQLite → Timeouts**: Indirect (retry loop consumes agent attention)

---

## 5. Database Config (vMK)

From `vmk.cmd`:
- `OPENCODE_DB=D:\opencode\vmk-data\opencode.db`
- `OPENCODE_CONFIG_DIR=D:\opencode\.vmk-config`
- `OPENCODE_CHANNEL=vMK-dev`
- `OPENCODE_CACHE_DIR=D:\opencode\vmk-cache`

---

## 6. Files Modified

| File | Change |
|------|--------|
| `packages/core/src/config/markdown.ts` | Added `label` param to `parse()`, improved error logging |
| `packages/opencode/src/config/markdown.ts` | Forwards `filePath` as label to core.parse; added `parseContent()` |
| `packages/core/src/database/migration/20260704120000_fix_missing_replacement_seq.ts` | NEW: ALTER TABLE ADD COLUMN with PRAGMA check |
| `packages/core/src/database/migration.gen.ts` | Registered new migration |

---

## 7. Remaining Work

| Priority | Action | Owner |
|----------|--------|-------|
| P0 | Identify the specific SKILL.md with malformed YAML (check .vmk-config/skills/) | Agent |
| P1 | Increase context7 timeout (3000ms → 10000ms) in opencode.jsonc | User |
| P1 | Improve sanitize() to handle missing YAML keys | Agent |
| P2 | Add graceful degradation when skill parse fails (don't retry infinitely) | Agent |
