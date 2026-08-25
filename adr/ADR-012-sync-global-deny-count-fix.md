# ADR-012: sync-global deny-count fix (member-enumeration quirk)

- **Status**: Accepted · **Date**: 2026-08-04 · **Type**: bugfix
- **Context**: `sync-global.ps1` SEC-F2 port printed a misleading warning "The property 'Count' cannot be found" on PS 7.6.4 despite the port succeeding. Repro showed `$obj.PSObject.Properties.Count` on a 61-property PSCustomObject returns an array of 61 "1" values (member-enumeration quirk) — unreliable as a count.
- **Decision**: Use an explicit `$ported` counter incremented inside the foreach loop (commit da9907a6) instead of `.Properties.Count`.
- **Alternatives**: Rely on the `.Count` member — rejected: member-enumeration returns a per-element array, not an aggregate.
- **Consequences**: Clean "Ported 61 deny-floor rules (SEC-F2)" output; port verified 61/61 rules present in global config top-level `permission.bash`; regression risk ~0 (logic unchanged).
- **Refs**: `scripts/sync-global.ps1`; commit `da9907a6`.
