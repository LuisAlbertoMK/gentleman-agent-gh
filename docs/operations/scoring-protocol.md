# Scoring Protocol — gentleman-agent-gh

> **Purpose**: Any agent, with zero session memory, can compute the project score reproducibly.
> **Run**: `powershell ./scripts/score-auto.ps1`
> **Format**: Returns JSON matching `.project.json` schema.

## Dimensions (13)

> **Note**: This protocol covers 9 core dimensions. The current scoring system (`score-auto.ps1`) measures 13: Dead Code, Script Performance, Bitacora, Orthography, Project Artifacts, Cycle Activity, Metrics, Backlog Integrity, Security, Skill Effectiveness, Clean Code, Best Practices, and Score Depth. See `.project.json` for the complete up-to-date taxonomy. For the authoritative score, always run `scripts/score-auto.ps1`.

---

### 1. Project Artifacts

**What**: Repo structure completeness — skills, scripts, indexes, docs, cross-refs.

| Score | Criteria |
|-------|----------|
| 10 | All artifacts present + cross-ref passes + SKILLS-INDEX matches |
| 7 | All major artifacts present, minor gaps in cross-ref |
| 4 | Missing critical artifacts (no SKILLS-INDEX, no .agents/skills/) |
| 0 | No project structure |

**Evidence commands**:
```powershell
# Count skills (should be 69)
(Get-ChildItem -Directory ".\.agents\skills").Count

# Verify SKILLS-INDEX count matches
(Select-String -Path "SKILLS-INDEX.md" -Pattern "^\d+\.\s+\*\*").Count

# Cross-ref check
.\scripts\cross-ref-check.ps1
```

---

### 2. Security

**What**: No hardcoded secrets, PSSA passes with 0 security violations, no weak crypto.

| Score | Criteria |
|-------|----------|
| 10 | PSSA gate: 0 security violations + secrets scan passes + no weak crypto |
| 8 | PSSA passes info-level only, no security/warning errors |
| 5 | PSSA has warnings or security violations |
| 0 | No security checks at all |

**Evidence commands**:
```powershell
# PSSA gate check
.\scripts\pssa-gate.ps1 -Mode Check

# Secrets scan (grep for keys, tokens, passwords)
Select-String -Path ".\.agents\skills\*" -Pattern "(?i)(api[_-]?key|secret|password|token)\s*[=:]\s*['""][^'""]{8,}" | ForEach-Object { $_.Filename }

# Weak crypto scan
Select-String -Path ".\scripts\*.ps1" -Pattern "MD5|SHA1" -SimpleMatch
```

---

### 3. Dead Code

**What**: No orphan scripts, no unused exports, no stale junctions, no commented-out code.

| Score | Criteria |
|-------|----------|
| 10 | No orphan skills, no dead scripts, junctions match live skills |
| 7 | Minor orphans (≤3 resource files), junction drift acceptable |
| 4 | Multiple dead scripts or broken junctions |
| 0 | Significant dead code, no cleanup mechanism |

**Evidence commands**:
```powershell
# Orphan skills in workspace: if "skills\" has files not in .agents\skills\
$skills = Get-ChildItem -Directory ".\.agents\skills" -Name
$orphans = Get-ChildItem ".\skills" -File -Name | Where-Object { $_ -notin $skills }
# Should be empty (resource files are exceptions)

# Dead junction check
# Should: each skill has a junction in skills/
# Should NOT: junction pointing to nonexistent skill
```

---

### 4. Clean Code

**What**: Consistent naming, SRP per script, no magic numbers, no long functions.

| Score | Criteria |
|-------|----------|
| 10 | All scripts have help headers, consistent naming, no obvious violations |
| 7 | Most scripts clean, minor naming inconsistencies |
| 4 | Several scripts violate conventions |
| 0 | Chaotic structure |

**Evidence commands**:
```powershell
# Scripts missing help header
Get-ChildItem ".\scripts\*.ps1" | Where-Object { (Get-Content $_ -TotalCount 3) -notmatch "^<#" }

# Token lengths (proxy for function complexity)
.\scripts\token-count.ps1
```

---

### 5. Best Practices

**What**: PowerShell conventions, error handling, parameter validation, workflow standards.

| Score | Criteria |
|-------|----------|
| 10 | All scripts: param blocks, error handling, pipeline-aware, comment-based help |
| 7 | Most scripts have param + help, occasional missing error handling |
| 4 | Several scripts without param blocks or help |
| 0 | No conventions |

**Evidence commands**:
```powershell
# Scripts missing param block
Get-ChildItem ".\scripts\*.ps1" | Where-Object { (Get-Content $_) -notmatch "^\s*param\(" }

# Scripts missing Set-StrictMode
Get-ChildItem ".\scripts\*.ps1" | Where-Object { (Get-Content $_) -notmatch "Set-StrictMode" }
```

---

### 6. Orthography

**What**: Zero typos, no encoding corruption (Windows-1252→UTF-8), consistent language.

| Score | Criteria |
|-------|----------|
| 10 | Zero encoding artifacts, no spelling errors in skill names/descriptions |
| 7 | Minor encoding issues (≤5 files affected) |
| 4 | Widespread encoding corruption (>10 files) |
| 0 | Severe corruption or no Spanish/English consistency |

**Evidence commands**:
```powershell
# Encoding corruption markers (Windows-1252→UTF-8 ghosts)
Select-String -Path ".\.agents\skills\*\SKILL.md" -Pattern "[\x00-\x08\x0E-\x1F]" -SimpleMatch

# Known corruption patterns
Select-String -Path ".\.agents\skills\*\SKILL.md" -Pattern "â|Â|€|†|™|—|–|‹|›|Œ|œ|Ž|ž|Š|š|Ÿ|¨|©|®|´|¸|¼|½|¾|×|÷" -SimpleMatch
# Should return zero matches
```

---

### 7. Bitácora

**What**: Session log maintained, consistent format, captures all significant changes.

| Score | Criteria |
|-------|----------|
| 10 | BITACORA.md exists, chronological entries, recent session logged |
| 7 | BITACORA.md exists, last entry ≤30 days |
| 4 | BITACORA.md exists but outdated (>60 days) |
| 0 | No BITACORA.md |

**Evidence commands**:
```powershell
# Exists and has entries
Test-Path "BITACORA.md"
(Get-Content "BITACORA.md").Count -gt 5

# Last entry recency (check for current date)
Select-String -Path "BITACORA.md" -Pattern "\d{4}-\d{2}-\d{2}" | Select-Object -First 1
```

---

### 8. Metrics

**What**: Before/after tracking, error capture, trend data, quality gate logging.

| Score | Criteria |
|-------|----------|
| 10 | `docs/metricas/` structured, LATEST_error.json present, quality gate runners log |
| 7 | Metrics directory exists, partial logging |
| 4 | Some metrics but no structure |
| 0 | No metrics at all |

**Evidence commands**:
```powershell
# Metrics directory structure
Test-Path "docs/metricas/errors/LATEST_error.json"
Get-ChildItem "docs/metricas/" -Recurse -File | Select-Object FullName
```

---

### 9. Script Performance

**What**: Script size efficiency, execution time, token count awareness.

| Score | Criteria |
|-------|----------|
| 10 | 40 scripts, average ≤12KB, no script >50KB, tokenize-all runs clean |
| 7 | Scripts exist but some >50KB or tokenization issues |
| 4 | Bloated scripts or missing token awareness |
| 0 | No scripts or all oversized |

**Evidence commands**:
```powershell
# Script sizes
Get-ChildItem ".\scripts\*.ps1" | Select-Object Name, @{N="KB";E={[math]::Round($_.Length/1KB,1)}}

# Token count awareness
.\scripts\token-count.ps1 -Average
```

---

### 10. Skill Effectiveness

**What**: Skills are lean (≤3KB preferred), valid YAML frontmatter, no broken dependencies.

| Score | Criteria |
|-------|----------|
| 10 | All skills <4KB (except justified), frontmatter valid, no broken deps, benchmark passes |
| 7 | Most skills lean, ≤3 skills >3KB, minor frontmatter issues |
| 4 | Many oversized skills or broken frontmatter |
| 0 | Skills unusable |

**Evidence commands**:
```powershell
# Skills >3KB
Get-ChildItem ".\.agents\skills\*\SKILL.md" | Where-Object { $_.Length -gt 3072 } | Select-Object DirectoryName, @{N="KB";E={[math]::Round($_.Length/1KB,1)}}

# Benchmark comparison
.\scripts\benchmark.ps1
```

---

## Composite Score

Final = average of all 13 dimensions (each 0-10), rounded to 1 decimal.

```text
Σ(dim_scores) / 13 = final_score
```

---

## Script

The authoritative scorer is `scripts/score-auto.ps1`. Run it from repo root:

```bash
git clone <repo> && cd gentleman-agent-gh
powershell ./scripts/score-auto.ps1
```

The script returns JSON that can be diffed against `.project.json` for drift.
