# metricas — Reference Materials

> **Externalized from** .agents/skills/metricas/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
---

## Examples (5)

### 1. Git Diff — Feature Branch vs Main

```bash
metricas git-diff --base main --head feature/auth-refactor --paths "src/**/*.ts"
```

**Output**:
```
┌──────────────────────┬────────┬────────┬──────────┬─────────┬──────────┬─────────┐
│ File                 │ Lang   │ Before │ After    │ Δ Tokens│ Δ %      │ Status  │
├──────────────────────┼────────┼────────┼──────────┼─────────┼──────────┼─────────┤
│ src/auth.ts          │ ts     │ 1,240  │ 1,456    │ +216    │ +17.4%   │ modified│
│ src/middleware.ts    │ ts     │ 890    │ 890      │ 0       │ 0.0%     │ same    │
│ src/types.ts         │ ts     │ 340    │ 512      │ +172    │ +50.6%   │ modified│
│ tests/auth.test.ts   │ ts     │ 2,100  │ 2,380    │ +280    │ +13.3%   │ modified│
└──────────────────────┴────────┴────────┴──────────┴─────────┴──────────┴─────────┘
Summary: 4 files, +668 tokens (+14.2%), +144 lines
Flagged: src/types.ts (+50.6%), src/auth.ts (+17.4%)
```

### 2. Bookmark — Save Baseline Before Refactor

```bash
metricas bookmark --save-baseline pre-refactor --paths "src/**/*.py"
```

**Output**:
```
Baseline 'pre-refactor' saved: 18 files, 42,310 tokens
```

### 3. Bookmark — Compare After Refactor

```bash
metricas bookmark --compare-baseline pre-refactor --paths "src/**/*.py"
```

**Output**:
```
┌──────────────────────┬────────┬────────┬────────┬─────────┬─────────┐
│ File                 │ Lang   │ Before │ After  │ Δ Tokens│ Δ %     │
├──────────────────────┼────────┼────────┼────────┼─────────┼─────────┤
│ src/models.py        │ py     │ 3,240  │ 2,890  │ -350    │ -10.8%  │
│ src/services.py      │ py     │ 5,100  │ 4,720  │ -380    │ -7.5%   │
│ src/utils.py         │ py     │ 1,850  │ 1,850  │ 0       │ 0.0%    │
└──────────────────────┴────────┴────────┴────────┴─────────┴─────────┘
Summary: 3 files, -730 tokens (-1.7%), -42 lines (net)
```

### 4. Multi-Language Repo — Full Diff with Language Breakdown

```bash
metricas git-diff --base v1.2.0 --head HEAD --format json
```

**Output** (truncated):
```json
{
  "mode": "git-diff",
  "base": "v1.2.0",
  "head": "a1b2c3d",
  "summary": { "files_changed": 47, "tokens_before": 184200, "tokens_after": 198750, "delta_tokens": 14550, "delta_pct": 7.9 },
  "by_language": {
    "typescript": { "before": 98400, "after": 106200, "delta_pct": 7.9 },
    "python": { "before": 52100, "after": 55800, "delta_pct": 7.1 },
    "go": { "before": 23400, "after": 24500, "delta_pct": 4.7 },
    "rust": { "before": 10300, "after": 12250, "delta_pct": 18.9 }
  },
  "flagged": ["src/rust/parser.rs:18.9%"]
}
```

### 5. CI Gate — Threshold Enforcement

```bash
metricas git-diff --base main --head HEAD --threshold 15 --format json | jq -r '.flagged[]'
```

**Exit codes**: `0` = all under threshold, `1` = flagged files exist, `2` = error

---

## Testing Patterns (3)

### Pattern 1: Golden File Token Counts

```python
# tests/fixtures/token_counts.json
{
  "src/auth.ts": 1240,
  "src/middleware.ts": 890,
  "src/types.ts": 340
}

# tests/test_tokenization.py
def test_token_counts_match_golden():
    from metricas import tokenize_file
    import json

    with open("tests/fixtures/token_counts.json") as f:
        golden = json.load(f)

    for path, expected in golden.items():
        actual = tokenize_file(path, lang="typescript")
        assert actual == expected, f"{path}: expected {expected}, got {actual}"
```

### Pattern 2: Delta Accuracy — Known Change Injection

```python
def test_delta_calculation_accuracy(tmp_path):
    from metricas import compute_delta, tokenize_file

    # Create baseline
    (tmp_path / "sample.py").write_text("def foo():\n    return 42\n")
    baseline_tokens = tokenize_file(tmp_path / "sample.py", lang="python")

    # Modify: add 2 lines, ~15 tokens
    (tmp_path / "sample.py").write_text("def foo():\n    x = 10\n    y = 20\n    return x + y\n")
    after_tokens = tokenize_file(tmp_path / "sample.py", lang="python")

    delta = compute_delta(baseline_tokens, after_tokens)
    assert delta.delta_tokens == pytest.approx(15, abs=3)  # Allow tokenizer variance
    assert delta.delta_pct == pytest.approx((15/baseline_tokens)*100, rel=0.1)
```

### Pattern 3: Bookmark Round-Trip Persistence

```python
def test_bookmark_save_and_compare(tmp_path, monkeypatch):
    from metricas import BookmarkManager

    monkeypatch.chdir(tmp_path)
    (tmp_path / "src").mkdir()
    (tmp_path / "src" / "main.py").write_text("x = 1\n")

    mgr = BookmarkManager(tmp_path / ".metricas_baselines")
    mgr.save("baseline1", ["src/**/*.py"])

    # Modify
    (tmp_path / "src" / "main.py").write_text("x = 1\ny = 2\nz = 3\n")

    result = mgr.compare("baseline1", ["src/**/*.py"])
    assert result.summary.delta_tokens > 0
    assert len(result.by_file) == 1
    assert result.by_file[0].path == "src/main.py"
```

---

## Edge Cases (4)

### 1. Binary / Non-Text Files in Diff

**Problem**: `git diff` includes images, fonts, compiled assets → tokenizer crashes.

**Handling**:
```python
def should_tokenize(path: Path) -> bool:
    # Skip by extension
    BINARY_EXTS = {'.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico',
                   '.woff', '.woff2', '.ttf', '.eot', '.otf',
                   '.pdf', '.zip', '.gz', '.tar', '.7z',
                   '.pyc', '.class', '.o', '.so', '.dll', '.exe'}
    if path.suffix.lower() in BINARY_EXTS:
        return False
    # Heuristic: check first 8KB for null bytes
    try:
        with open(path, 'rb') as f:
            return b'\x00' not in f.read(8192)
    except OSError:
        return False
```

**Test**: Add `.png` to tracked files → verify skipped, not crashed.

### 2. Renamed Files — Token Continuity

**Problem**: `git diff -M` shows rename as delete+add → false 100% delta.

**Handling**: Use `git diff --find-renames --name-status` to detect renames, map old→new path, compute delta on *content* not path.

```python
def resolve_renames(diff_output: str) -> Dict[str, str]:
    """Return {old_path: new_path} for renamed files."""
    renames = {}
    for line in diff_output.splitlines():
        if line.startswith('R'):
            _, old, new = line.split('\t', 2)
            renames[old] = new
    return renames
```

### 3. Large Files — Memory/Time Budget

**Problem**: 500KB+ source files → tokenization OOM or timeout.

**Handling**:
- Stream tokenization (line-by-line for lexical, chunked for AST)
- Hard cap: `--max-file-tokens 50000` (default), skip with warning
- Progress reporting for >100 files

```python
MAX_FILE_TOKENS = 50_000

def tokenize_file_streaming(path: Path, lang: str) -> int:
    if lang in AST_LANGS:
        return tokenize_ast_chunked(path, lang, max_tokens=MAX_FILE_TOKENS)
    return tokenize_lexical_streaming(path, max_tokens=MAX_FILE_TOKENS)
```

### 4. Mixed-Language Files — Tokenizer Selection

**Problem**: `.tsx` (TS+JSX), `.vue` (TS+HTML+CSS), `.svelte` — single file, multiple languages.

**Handling**:
- Primary lang by extension (`.tsx` → `typescript`)
- Sub-language regions: extract `<script>`, `<template>`, `<style>` blocks, tokenize each with appropriate tokenizer, sum
- Fallback: primary lang tokenizer on whole file

```python
def tokenize_mixed(path: Path, primary_lang: str) -> int:
    if primary_lang == "typescript" and path.suffix == ".tsx":
        return tokenize_tsx(path)
    if primary_lang == "vue":
        return tokenize_vue(path)
    # ... other mixed formats
    return tokenize_file(path, primary_lang)
```

---

## Anti-Patterns (2)

### ❌ Anti-Pattern 1: Line Count as Proxy for Complexity

```bash
# WRONG: Using lines changed as metric
git diff --stat main..HEAD | tail -1
# "47 files changed, 2341 insertions(+), 1892 deletions(-)"
```

**Why it fails**:
- Verbose vs concise styles: `if (x) { return y; }` (3 lines) vs `if (x) return y;` (1 line) — same tokens
- Generated code: 1000 lines of boilerplate ≠ 1000 lines of logic
- Reformatting: Prettier run = 5000 lines changed, 0 semantic change

**Correct**: Token count (AST nodes) correlates with cognitive complexity. Use `metricas` not `git diff --stat`.

---

### ❌ Anti-Pattern 2: Comparing Unnormalized Baselines

```bash
# WRONG: Different tokenizer versions, different config
metricas bookmark --save-baseline v1  # tokenizer v1.2
# ... upgrade metricas to v1.3 with different token rules ...
metricas bookmark --compare-baseline v1  # INVALID comparison
```

**Why it fails**: Token counts are **not comparable across tokenizer versions**. A 5% delta could be tokenizer change, not code change.

**Correct**:
```bash
# Embed tokenizer version in baseline metadata
metricas bookmark --save-baseline v1 --meta '{"tokenizer_version": "1.3.0", "tokenizer_config": {"include_comments": false}}'

# On compare: validate compatibility
if baseline.meta.tokenizer_version != CURRENT_VERSION:
    warn("Baseline tokenizer version mismatch — re-save baseline")
    exit(2)
```

---

## Commit + Verify Hash

```bash
# 1. Stage the skill
git add .agents/skills/metricas/SKILL.md

# 2. Commit with conventional message
git commit -m "feat(metricas): add comprehensive skill with examples, tests, edge cases

- 5 usage examples (git-diff, bookmark save/compare, multi-lang, CI gate)
- 3 testing patterns (golden files, delta injection, bookmark round-trip)
- 4 edge cases (binary files, renames, large files, mixed-language)
- 2 anti-patterns (line-count proxy, unnormalized baselines)
- Tokenization strategies for 6 languages
- JSON/table/markdown output formats
- CI threshold enforcement with exit codes"

# 3. Verify hash
git rev-parse HEAD
# Example: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
```

**Verification**:
```bash
git show --stat HEAD
# commit a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
# Author: ...
# Date: ...
#
#     feat(metricas): add comprehensive skill...
#
#  .agents/skills/metricas/SKILL.md | 500 ++++++++++++++++++++++++++++++
#  1 file changed, 500 insertions(+)
```

---

## Quick Reference Card

| Task | Command |
|------|---------|
| Diff last 3 commits | `metricas git-diff --base HEAD~3` |
| Diff specific files | `metricas git-diff --paths "src/auth.ts,tests/**"` |
| Save baseline | `metricas bookmark --save-baseline before-refactor` |
| Compare to baseline | `metricas bookmark --compare-baseline before-refactor` |
| CI gate (fail >15%) | `metricas git-diff --threshold 15 \|\| exit 1` |
| JSON for scripting | `metricas git-diff --format json \| jq '.summary.delta_pct'` |
| List baselines | `metricas bookmark --list-baselines` |
| Delete baseline | `metricas bookmark --delete-baseline old-baseline` |

## Externalized Sections (ADR-007 compression)
## Output Schema
```json
{
  "mode": "git-diff|bookmark", "base": "abc1234", "head": "def5678",
  "summary": {"files_changed": 12, "tokens_before": 45230, "tokens_after": 47891,
    "delta_tokens": 2661, "delta_pct": 5.88, "lines_added": 342, "lines_removed": 198},
  "by_file": [{"path": "src/auth.ts", "lang": "typescript", "tokens_before": 1240,
    "tokens_after": 1456, "delta_pct": 17.42, "status": "modified"}],
  "by_language": {"typescript": {"before": 28400, "after": 30100, "delta_pct": 5.99}},
  "flagged": ["src/auth.ts:17.42%"]
}
```
