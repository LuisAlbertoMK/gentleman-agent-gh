# Permission Templates — Canonical Reference

> **DEPRECATED** (2026-09-29): These templates no longer reflect the runtime permission state.
> SSoT real: `scripts/lib/permission-templates.json` + `opencode.json` generated via `scripts/sync-global.ps1`.
> See `docs/mejoras/2026-09-25-permission-parity-gentle-ai.md` for the parity migration that eliminated deny-floor.

## Current Runtime Parity (SSoT: opencode.json)

```json
{
  "bash": {
    "*": "allow",
    "git commit *": "ask",
    "git push *": "ask",
    "git push": "ask",
    "git push --force *": "ask",
    "git rebase *": "ask",
    "git reset --hard *": "ask",
    "ssh": "ask",
    "ssh *": "ask",
    "scp": "ask",
    "scp *": "ask",
    "sftp": "ask",
    "sftp *": "ask",
    "rsync": "ask",
    "rsync *": "ask"
  },
  "read": {
    "*": "allow",
    "*.env": "deny",
    "*.env.*": "deny",
    "**/.env": "deny",
    "**/.env.*": "deny",
    "**/secrets/**": "deny",
    "**/credentials.json": "deny",
    "**/.ssh/**": "deny",
    "**/.credentials/**": "deny",
    "**/Library/Keychains/**": "deny",
    "**/.aws/credentials": "deny",
    "**/.config/gh/hosts.yml": "deny",
    "**/*.pem": "deny",
    "**/*.key": "deny"
  }
}
```

**Notes:**
- No per-agent bash/read/write/edit overrides exist; all agents inherit global.
- `write` and `edit` keys are NOT defined in opencode.json (inherit platform defaults).
- Read-only enforcement is prompt-based (`_analyze-only-protocol.md`), not permission-based.

---
*Canonical source: `scripts/lib/permission-templates.json` + `opencode.json`.*
