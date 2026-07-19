# Permission Templates — Canonical Reference

These are the canonical permission blocks used across all agents. CI verifies consistency.

## Read-Only Specialist (security, seo, infra, frontend, performance, datascience, docs)

```json
{
  "bash": {
    "*": "deny"
  },
  "edit": "deny",
  "read": "allow",
  "write": "deny"
}
```

## Write-Capable Agent (quick, codex, deep, implementer)

```json
{
  "bash": {
    "*": "ask",
    "rm *": "deny",
    "rm -rf *": "deny",
    "curl *": "deny",
    "wget *": "deny",
    "Invoke-WebRequest *": "deny",
    "Invoke-RestMethod *": "deny",
    "Invoke-Expression *": "deny",
    "irm *": "deny",
    "iwr *": "deny",
    "iex *": "deny",
    "Remove-Item *": "deny",
    "Start-BitsTransfer *": "deny",
    "nc *": "deny",
    "ncat *": "deny",
    "telnet *": "deny",
    "Test-NetConnection *": "deny"
  },
  "edit": "allow",
  "read": "allow",
  "write": "allow"
}
```

## Orchestrator (gentleman-vMK)

```json
{
  "bash": {
    "*": "allow",
    "python *": "deny",
    "python3 *": "deny",
    "node *": "deny",
    "ruby *": "deny",
    "perl *": "deny",
    "php *": "deny",
    "rm *": "deny",
    "rm -rf *": "deny",
    "curl *": "deny",
    "wget *": "deny",
    "Invoke-WebRequest *": "deny",
    "Invoke-RestMethod *": "deny",
    "Invoke-Expression *": "deny",
    "irm *": "deny",
    "iwr *": "deny",
    "iex *": "deny",
    "Remove-Item *": "deny",
    "Start-BitsTransfer *": "deny",
    "nc *": "deny",
    "ncat *": "deny",
    "telnet *": "deny",
    "Test-NetConnection *": "deny"
  },
  "edit": "allow",
  "write": "allow"
}
```

## Global Read/Write/Edit Protection

```json
{
  "read": {
    "*": "allow",
    "**/.env": "deny",
    "**/.env.*": "deny",
    "**/.env*": "deny",
    "**/credentials.json": "deny",
    "**/secrets/**": "deny",
    "**/*secret*": "deny",
    "**/.ssh/**": "deny",
    "*.env": "deny",
    "*.env.*": "deny",
    "*.env*": "deny"
  }
}
```

---
*Canonical source for CI permission consistency check.*
