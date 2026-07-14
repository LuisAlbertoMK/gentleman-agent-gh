# Adaptive Review Profile (Engram-backed)

## Before review: Load profile
```
mem_search("review-profile/{project}")
```

Tracks per-project:
- **Most common R failure**: Which R scores lowest most often → prioritize that R in review
- **Recurring patterns**: Issues found 2+ times (e.g., "missing context timeout on DB calls")
- **Sensitive files**: Files with repeated findings (e.g., `handler.go` → Risk: input validation)
- **Override history**: Which 4R scores were overridden by user and why
- **Last review score**: Previous 4R summary for trend comparison

## After review: Save profile
```
mem_save(
  topic_key: "review-profile/{project}",
  type: "pattern",
  content: "
    **What**: Review profile update for {project}
    **Why**: Accumulate review patterns across sessions
    **Findings**:
    - Most frequent R failure: {R}
    - New patterns: {issue 1}, {issue 2}
    - Files flagged: {file1}, {file2}
    - Score trend: {previous}/10 → {current}/10
  "
)
```
