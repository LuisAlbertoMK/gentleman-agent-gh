# command-wrapper - Reference Materials

> **Externalized from** .agents/skills/command-wrapper/SKILL.md to keep the skill under the 2KB token budget (ADR-007).

## Examples
`node --version` → `v22.14.0` regex PASS→proceed · exit 127→ERROR HANDLING row 1 · malformed `2.14`→flagged, never silently accepted.


## Testing
1. `git push --force --dry-run`→BLOCK+ask. 2. `ghostcmd`/locked-file/missing path → mapped action fires. 3. `gh issue list --json` → fields AND warnings extracted.

