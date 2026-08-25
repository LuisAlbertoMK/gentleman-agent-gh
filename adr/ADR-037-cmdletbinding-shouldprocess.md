# ADR-037: CmdletBinding/ShouldProcess for Destructive PowerShell Operations

**Status**: Accepted
**Date**: 2026-08-19
**Deciders**: gentleman-agent-gh team
**Technical Story**: PowerShell quality improvements — C4 (CmdletBinding/ShouldProcess)

## Context

The repository contains 100+ PowerShell scripts in `scripts/` that perform various operations including:
- File system modifications (Create, Write, Remove, Copy)
- Git operations (commit, push, checkout)
- Registry modifications
- Environment variable changes
- Process management (Start-Process, Stop-Process)
- Network operations (Invoke-WebRequest, Invoke-RestMethod)

Without `[CmdletBinding(SupportsShouldProcess=$true)]` and `ShouldProcess()`/`ShouldContinue()` calls, these scripts cannot:
- Support `-WhatIf` and `-Confirm` parameters
- Provide safety guarantees for destructive operations
- Integrate properly with PowerShell's risk mitigation framework
- Pass PSScriptAnalyzer rule `PSUseShouldProcessForStateChangingFunctions`

## Decision

**Add `[CmdletBinding(SupportsShouldProcess=$true)]` to all scripts that perform state-changing operations, and add `ShouldProcess()` calls around every destructive action.**

### Scripts Modified

| Script | Operations Requiring ShouldProcess |
|--------|-----------------------------------|
| `use-gentleman.ps1` | File writes (opencode.json, .gentleman-mode), directory creation |
| `babyagi-loop.ps1` | File writes (callback scripts, result files), file cleanup, process registration |
| `delegation-registry.ps1` | Registry file writes, prune marker, re-prompt files |

### Implementation Pattern

```powershell
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Force,
    [switch]$DryRun
)

# For each destructive operation:
if ($DryRun) {
    Write-Host "[DryRun] Would perform: <action>"
} elseif ($PSCmdlet.ShouldProcess($target, "Description of action")) {
    # Actual destructive operation
    Remove-Item -Path $target -Force
}
```

### Functions with State-Changing Verbs

Functions using verbs that imply state changes (New, Set, Remove, Add, Register, Start, Stop, Clear) must also declare `[CmdletBinding(SupportsShouldProcess=$true)]` and use `$PSCmdlet.ShouldProcess()`.

## Consequences

### Positive
- Scripts now support `-WhatIf` for safe preview of changes
- Scripts support `-Confirm` for interactive confirmation
- PSScriptAnalyzer rule `PSUseShouldProcessForStateChangingFunctions` passes
- Consistent safety model across all destructive scripts
- Better integration with CI/CD pipelines (dry-run support)

### Negative
- Slightly more verbose code
- Functions calling `ShouldProcess` must themselves have `CmdletBinding(SupportsShouldProcess)`
- Existing callers must be aware of the new parameter set

### Neutral
- No behavioral changes when `-WhatIf`/`-Confirm` not used
- `-Force` and `-DryRun` parameters remain as additional safety layers
- All existing tests pass without modification

## Validation

- PSScriptAnalyzer: 0 errors on modified scripts
- Pester tests: All pass (122 passed, 3 pre-existing failures unrelated)
- Manual `-WhatIf` testing: Correctly shows what would happen without executing

## Related

- ADR-038: PSSA CI + Coverage Gate
- C4 task: CmdletBinding/ShouldProcess
- mejora-log.md: C4+C5 entry
