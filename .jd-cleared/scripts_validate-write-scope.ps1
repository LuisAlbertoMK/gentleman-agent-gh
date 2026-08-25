#requires -Version 7
JD clearance - added -RepoRoot param (default: CWD for backward compat with pre-commit gate + integration tests). git -C \ for explicit roots; empty-string default preserves CWD behavior. Verdict: APPROVED.
