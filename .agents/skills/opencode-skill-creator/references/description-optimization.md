# Description Optimization

Post-creation, optional. Run after skill is functional.

1. Create 20 trigger eval queries (8-10 should-trigger + 8-10 should-not, concrete contexts)
2. User reviews via `templates/eval-review.html` → exports `eval_set.json`
3. `skill_optimize_loop(evalSetPath, skillPath, model, maxIterations: 5)` → auto-splits 60/40, evaluates 3×/query, returns `best_description`
4. Update frontmatter description, show before/after + scores

OpenCode only consults skills for non-trivial tasks. Make eval queries substantive.
