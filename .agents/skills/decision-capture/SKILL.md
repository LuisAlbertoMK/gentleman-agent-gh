---
name: decision-capture
description: "Capture every technical decision with structured format"
triggers: "decision capture, trade-off, architecture choice, technology comparison"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.0"
  changelog: "1.1->2.0: added scoring framework"
---

## When
Library/framework choice | Architecture decision | Trade-off evaluation | Pattern/structure change | Risk-bearing upgrades

## Rules

### 1. Auto Capture via mem_save
Scope: Library/tool selection | Architecture pattern | DB/storage engine | API design | Testing approach | Config/env | Project structure | Dependency pinning

### 2. Format
title: "{Verb} {what}" | type: decision | Content: **What** (1 sentence), **Why** (problem+constraints), **Options** (max 3), **Chosen** (why+downsides), **Where** (files/dirs), **Learned** (gotchas)

### 3. Scoring (append to every capture)
**Confidence**: 1(guess) to 5(certain) | **Reversibility**: low|medium|high | **Review date**: YYYY-MM-DD (3mo for high reversibility, 1mo for low)

### 4. Trend Detection (every 5th decision)
mem_search(type="decision") for patterns. 3+ same direction -> mem_save trend observation. Reversal -> link via topic_key.

### 5. Conflict Detection
Check topic_key for prior decision. If reversing: keep both + **Supersedes**: [ID] + **Reason for reversal**: [what changed]

### 6. Retroactive Capture
Before new dependent decisions. Mark **Retroactive**: true. Scan: git log --oneline -20 | grep -iE "feat|change|upgrade|migrate"

### 7. Session-end Check
Before mem_session_summary: verify via mem_search(type="decision")

## Decision Tree
Alternatives? -> mem_save | NO -> skip (trivial) | Same topic? -> update existing | Conflict? -> supersedes + reversal reason | Every 5th -> trend check

## Scoring Reference
1: Pure guess | 2: Educated guess | 3: Reasonable, needs review | 4: Strong, minor unknowns | 5: Certain, known pattern

## Commands
```
mem_save(title="Chose {X} over {Y}" type="decision" content="**What**: ...")
mem_search(type="decision" limit=10)
git log --oneline -20 | grep -iE "feat|change|upgrade"
```