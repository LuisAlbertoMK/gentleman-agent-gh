# execution-mode — Reference Materials

> **Externalized from** .agents/skills/execution-mode/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains the decision table and worked examples.

## Decision Table (auto-detect)
| Scope | Risk | Familiarity | Keywords | Mode |
|---|---|---|---|---|
| 1 file | Typo | Known (3x+) | "fix","typo" | QUICK |
| 1-2 | Minor bug | Known | "bug","error" | QUICK |
| 1-3 | Config change | Known | "update","bump" | QUICK |
| 3-5 | Logic change | Some | "refactor","change" | QUICK→THOROUGH |
| 5+ | Data loss | Known | "migrate" | THOROUGH |
| 5+ | Security | Any | "auth","permissions" | THOROUGH |
| Multi-pkg | API change | New | "redesign","rearchitect" | THOROUGH |
| Unknown | Unknown | New | "explore","prototype","idea" | DRAFT |
| Any | Any | Any | "research","investigate" | DRAFT |
| 1 file | High (data loss) | Known | "delete","drop","rm" | THOROUGH (override) |

## Examples
1. "typo in submit button" → 1 file, known → QUICK. 2. "migrate to JWT" → 5+ files, data loss, security → THOROUGH 9-phase. 3. "redesign API" → multi-package, new → THOROUGH, spec first. 4. "prototype Zustand vs Redux" → DRAFT, notes only.

## Testing
1. Mode detection covers all 11 table rows. 2. Override: "careful" on QUICK → THOROUGH; "quick" on THOROUGH → QUICK. 3. Zones: 45%→YELLOW applied; 75%→ORANGE+mem_save.

## Edge Cases
1. "delete production database" → 1 file but data loss → THOROUGH override (row 11). 2. Zone shift mid-task → re-evaluate, apply L2+L3, continue or compact. 3. User contradicts auto-detect → honor override, log, mem_save rationale.