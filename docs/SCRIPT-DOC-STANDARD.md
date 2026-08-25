# Script Documentation Standard

Minimal comment-based help standard for PowerShell scripts in `scripts/`.
Addresses improvement-gap #5 (ICE 280): script documentation inconsistency.
Enforced by `tests/script-documentation.Tests.ps1` in the pre-commit gate
([12/22] Pester checks) — a registered script without full help blocks every commit.

## Mandatory help block

Place a comment-based help block directly ABOVE the first parameter
statement (before `[CmdletBinding()]` / `param()`). Do not put any logic
above the help block. Every parameter in the `param()` block must have its
own `.PARAMETER` entry, named exactly as declared.

```
<#
.SYNOPSIS
  One sentence describing what the script does.
.DESCRIPTION
  Context: what it checks or changes, exit codes, side effects.
.PARAMETER Name
  Purpose and accepted values for this parameter.
.PARAMETER OtherName
  Purpose for this parameter too.
.EXAMPLE
  ./scripts/script-name.ps1 -Name value
#>
param(
  [string]$Name,
  [switch]$OtherName
)
```

## Required tags (all four, in this order)

1. `.SYNOPSIS` — one sentence, what the script does.
2. `.DESCRIPTION` — context: behavior, exit codes, side effects.
3. `.PARAMETER` — one entry per declared parameter, name must match exactly.
4. `.EXAMPLE` — at least one realistic invocation.

## One-line guidance

- English, ASCII only, no emojis; indent under each tag to match the file's
  existing style (2 or 4 spaces).
- Document behavior, not implementation.
- Never omit a declared parameter; never document a parameter that does not
  exist.
- New scripts include the full block from day one; already-registered scripts
  must stay complete when parameters change.
- PowerShell 7 comment-based help syntax only (the `<# ... #>` block above).

## Script registry

Scripts that MUST keep full help (enforced by the Pester test). Register a
script here ONLY after its help is fully compliant — adding a script without
help blocks every commit.

- scripts/switch-mode.ps1
- scripts/health-check.ps1
- scripts/validate-write-scope.ps1

## Enforcement

- `tests/script-documentation.Tests.ps1` (Pester 5) reads the registry bullets
  from this section and asserts, per registered script:
  1. the file exists,
  2. it declares a script/function block (`[CmdletBinding()]`, `param(`, or
     `function`),
  3. it contains all four tags (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`,
     `.EXAMPLE`),
  4. the help block is not duplicated.
- To add a script to the registry: fix its help first, then add the
  `- scripts/name.ps1` bullet above. The bullet format is parsed by the test —
  do not change it.
