// ADR-049: PS orchestration, Go hot paths, PS fallback mandatory.
// This gate shim is a FAST-PATH pre-filter: it runs the subset of checks
// that do not require PowerShell and escalates to pre-commit-gate.ps1
// ONLY when staged files match PS-only triggers. The SSOT for all gate
// semantics remains .githooks/pre-commit-gate.ps1 — this file mirrors its
// behavior (regexes, budgets, fail-closed rules) and must be updated if
// the PS gate changes. It never replaces the PS gate; the PS fallback is
// mandatory per ADR-049.

package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"time"
)

// version: keep header comment citing ADR-049

var (
	// Secrets regex EXACTLY as PS line 178:
	// (ghp_|gho_|github_pat_|AKIA|ctx7sk_|-----BEGIN\s+(RSA|EC|DSA|PRIVATE)\s+KEY|GH_TOKEN\s*=|GITHUB_TOKEN\s*=|password\s*=|api[_-]?key\s*=|secret\s*=|token\s*=)
	secretsRe = regexp.MustCompile(`(ghp_|gho_|github_pat_|AKIA|ctx7sk_|-----BEGIN\s+(RSA|EC|DSA|PRIVATE)\s+KEY|GH_TOKEN\s*=|GITHUB_TOKEN\s*=|password\s*=|api[_-]?key\s*=|secret\s*=|token\s*=)`)

	// PS-only escalation triggers (regex on staged paths, from PS gate conditions).
	// Compiled individually to keep behavior identical to PS -match.
	triggerPS1            = regexp.MustCompile(`\.ps1$`)
	triggerSkillMD        = regexp.MustCompile(`\.agents/skills/[^/]+/SKILL\.md$`)
	triggerProjectJSON    = regexp.MustCompile(`\.project\.json$`)
	triggerReviewRules    = regexp.MustCompile(`review-rules\.jsonc$`)
	triggerSkills         = regexp.MustCompile(`\.agents/skills/`)
	triggerOpencodeConfig = regexp.MustCompile(`scripts/opencode-config/`)
	triggerLibOrOpencode  = regexp.MustCompile(`^(scripts/lib/|opencode\.json$)`)
	triggerTestsPS1       = regexp.MustCompile(`\.Tests\.ps1$`)
	triggerAgentsMD       = regexp.MustCompile(`AGENTS\.md`)
)

const configSizeBudget = 98304

type checkResult struct {
	Name   string `json:"name"`
	Status string `json:"status"` // "ok" | "warn" | "blocking" | "error"
	Detail string `json:"detail,omitempty"`
	Ms     int64  `json:"ms"`
}

func main() {
	args := os.Args[1:]
	hasHook := contains(args, "--hook")
	hasStagedReport := contains(args, "--staged-report")
	hasJSON := contains(args, "--json")
	repoRootFlag := getArgValue(args, "--repo-root")
	if repoRootFlag == "" {
		repoRootFlag = getArgValue(args, "--repoRoot")
	}

	// Default mode: if no explicit mode flag, treat as --hook (invoked by git hook)
	if !hasHook && !hasStagedReport {
		// If any gate-specific flag is present without --hook, still assume hook
		// unless --staged-report was requested. This makes `gate.exe` with no args behave as hook.
		hasHook = true
	}

	// --staged-report mode: print ONLY compact JSON then exit 0
	if hasStagedReport {
		repoRoot := resolveRepoRoot(repoRootFlag)
		staged, err := getStaged(repoRoot)
		if err != nil {
			// On git failure, report empty but not error — classification without commit shouldn't fail.
			// Emit valid JSON with empty staged and fastPath true.
			staged = []string{}
		}
		if staged == nil {
			staged = []string{}
		}
		psTriggers := classifyTriggers(staged)
		if psTriggers == nil {
			psTriggers = []string{}
		}
		fastPath := len(psTriggers) == 0
		out := map[string]interface{}{
			"staged":     staged,
			"psTriggers": psTriggers,
			"fastPath":   fastPath,
		}
		b, _ := json.Marshal(out)
		fmt.Println(string(b))
		os.Exit(0)
	}

	if hasHook {
		repoRoot := resolveRepoRoot(repoRootFlag)
		code := runHook(repoRoot, hasJSON)
		os.Exit(code)
	}
}

func runHook(repoRoot string, wantJSON bool) int {
	start := time.Now()
	// repoRoot must be absolute for later joins
	if !filepath.IsAbs(repoRoot) {
		if abs, err := filepath.Abs(repoRoot); err == nil {
			repoRoot = abs
		}
	}

	staged, err := getStaged(repoRoot)
	if err != nil {
		// Any unexpected error → escalate to pwsh path, never exit 2 silently.
		return escalateToPS(repoRoot, "git diff --cached failed, escalating to PS gate")
	}
	if staged == nil {
		staged = []string{}
	}

	var checks []checkResult
	blocked := false
	// Count passed for summary: each check that is not blocking counts as passed (WARN counts as passed per PS)
	passed := 0

	// 1) fast gate (cross-ref + token-budget)
	{
		cs := time.Now()
		status := "ok"
		detail := ""
		// Determine if skills staged
		skillsStaged := false
		for _, p := range staged {
			if triggerSkills.MatchString(p) {
				skillsStaged = true
				break
			}
		}
		fastExe := filepath.Join(repoRoot, "bin", "fast.exe")
		// On non-Windows, the fast binary may be bin/fast without .exe; check both.
		if _, err := os.Stat(fastExe); err != nil && runtime.GOOS != "windows" {
			alt := filepath.Join(repoRoot, "bin", "fast")
			if _, err2 := os.Stat(alt); err2 == nil {
				fastExe = alt
			}
		}
		if _, err := os.Stat(fastExe); err != nil {
			// Treat as unavailable, don't block. Silently skip.
			status = "ok"
			detail = "fast.exe unavailable — skipped (PS fallback covers when needed)"
		} else {
			cmd := exec.Command(fastExe, "--gate", "--json")
			cmd.Dir = repoRoot
			out, execErr := cmd.CombinedOutput()
			if execErr != nil {
				// Treat as unavailable, don't block. Keep output for debug but don't fail.
				status = "ok"
				detail = "fast.exe execution failed — treated as unavailable"
			} else {
				var parsed struct {
					CrossRef struct {
						AllClean *bool `json:"allClean"`
						Passed   *bool `json:"passed"`
					} `json:"crossRef"`
					TokenBudget struct {
						Passed *bool `json:"passed"`
					} `json:"tokenBudget"`
					Passed *bool `json:"passed"`
				}
				// The fast gate output is a single JSON object. It may contain trailing newline.
				trimmed := strings.TrimSpace(string(out))
				// If fast prints extra lines, try to extract JSON object (last line that is JSON)
				jsonStr := trimmed
				if !strings.HasPrefix(trimmed, "{") {
					// try to find last JSON object
					idx := strings.LastIndex(trimmed, "{")
					if idx >= 0 {
						jsonStr = trimmed[idx:]
					}
				}
				if jerr := json.Unmarshal([]byte(jsonStr), &parsed); jerr != nil {
					status = "ok"
					detail = "fast.exe output unparseable — treated as unavailable"
				} else {
					// Determine crossRef pass: prefer allClean, fallback to passed if present
					crossAllClean := true
					crossPresent := false
					if parsed.CrossRef.AllClean != nil {
						crossAllClean = *parsed.CrossRef.AllClean
						crossPresent = true
					} else if parsed.CrossRef.Passed != nil {
						crossAllClean = *parsed.CrossRef.Passed
						crossPresent = true
					} else if parsed.Passed != nil {
						// top-level passed as proxy if crossRef missing
						crossAllClean = *parsed.Passed
					}
					tokenPassed := true
					if parsed.TokenBudget.Passed != nil {
						tokenPassed = *parsed.TokenBudget.Passed
					}
					_ = crossPresent
					if skillsStaged && !crossAllClean {
						status = "blocking"
						detail = "cross-ref validation failed (fast gate crossRef.allClean==false)"
						blocked = true
					} else if !tokenPassed {
						status = "warn"
						detail = "token budget exceeded (WARN only)"
					} else {
						status = "ok"
						if skillsStaged {
							detail = "cross-ref OK"
						}
					}
				}
			}
		}
		ms := time.Since(cs).Milliseconds()
		checks = append(checks, checkResult{Name: "fast-gate", Status: status, Detail: detail, Ms: ms})
		if status == "blocking" {
			fmt.Printf("  BLOCKING: %s\n", detail)
		} else if status == "warn" {
			fmt.Printf("  WARN %s\n", detail)
			passed++
		} else {
			// For ok with detail about unavailable, don't print BLOCKING; use OK or info
			if detail != "" && strings.Contains(detail, "unavailable") {
				fmt.Println("  OK (fast gate unavailable — skipped)")
			} else {
				fmt.Println("  OK")
			}
			passed++
		}
		// If fast-gate was blocking, we still continue to collect other fast checks for reporting,
		// but final exit will be 1 regardless of escalation.
	}

	// 2) trailing whitespace: git diff --cached --check
	{
		cs := time.Now()
		if len(staged) == 0 {
			// Fast-path optimization: no staged files means no whitespace errors;
			// skip spawning git diff --check (saves ~120ms on Windows) while preserving semantics.
			ms := time.Since(cs).Milliseconds()
			fmt.Println("  OK")
			checks = append(checks, checkResult{Name: "trailing-whitespace", Status: "ok", Ms: ms})
			passed++
		} else {
			cmd := exec.Command("git", "diff", "--cached", "--check")
			cmd.Dir = repoRoot
			out, _ := cmd.CombinedOutput()
			// git diff --check exits non-zero when whitespace errors found, and prints to stdout/stderr.
			// PS filters empty lines: $wsLines = $wsOut | Where-Object { $_ -notmatch '^\s*$' }
			text := string(out)
			lines := strings.Split(text, "\n")
			var nonEmpty []string
			for _, l := range lines {
				if strings.TrimSpace(l) != "" {
					nonEmpty = append(nonEmpty, l)
				}
			}
			ms := time.Since(cs).Milliseconds()
			if len(nonEmpty) > 0 {
				for _, l := range nonEmpty {
					fmt.Printf("    %s\n", l)
				}
				fmt.Println("  WARN fix trailing whitespace before push")
				checks = append(checks, checkResult{Name: "trailing-whitespace", Status: "warn", Detail: "trailing whitespace", Ms: ms})
				passed++
			} else {
				fmt.Println("  OK")
				checks = append(checks, checkResult{Name: "trailing-whitespace", Status: "ok", Ms: ms})
				passed++
			}
		}
	}

	// 3) secrets scan
	{
		cs := time.Now()
		if len(staged) == 0 {
			ms := time.Since(cs).Milliseconds()
			fmt.Println("  OK")
			checks = append(checks, checkResult{Name: "secrets", Status: "ok", Ms: ms})
			passed++
		} else {
			// git diff --cached --diff-filter=ACM -- ':!.githooks' ':!*.Tests.ps1' ':!scripts/check-mcp-security.ps1' ':!.agents/skills/*/references/*' ':!.gitleaks.toml' ':!docs/mejoras/*'
			args := []string{"diff", "--cached", "--diff-filter=ACM", "--", ":!.githooks", ":!*.Tests.ps1", ":!scripts/check-mcp-security.ps1", ":!.agents/skills/*/references/*", ":!.gitleaks.toml", ":!docs/mejoras/*", ":!cmd/gate/*"}
			cmd := exec.Command("git", args...)
			cmd.Dir = repoRoot
			out, err := cmd.CombinedOutput()
		if err != nil {
			// If git diff fails (e.g., not a git repo), escalate to PS rather than silently pass.
			// But don't exit here; treat as indeterminate and escalate after collecting what we can.
			// For now mark as error and will escalate later.
			ms := time.Since(cs).Milliseconds()
			checks = append(checks, checkResult{Name: "secrets", Status: "error", Detail: "git diff for secrets scan failed", Ms: ms})
			// Escalate immediately — indeterminate
			return escalateToPS(repoRoot, "secrets scan git diff failed, escalating")
		}
		text := string(out)
		lines := strings.Split(text, "\n")
		currentFile := ""
		lineInFile := 0
		type hit struct {
			File string
			Line int
			Text string
		}
		var hits []hit
		// Regexes for hunk parsing EXACTLY like PS lines 171-182
		rePlusPlus := regexp.MustCompile(`^\+\+\+ b/(.+)$`)
		reHunk := regexp.MustCompile(`^@@ -\d+,\d+ \+(\d+),\d+ @@`)
		rePlusLine := regexp.MustCompile(`^\+([^\+].*)$`)
		for _, dl := range lines {
			if m := rePlusPlus.FindStringSubmatch(dl); m != nil {
				currentFile = m[1]
				continue
			}
			if m := reHunk.FindStringSubmatch(dl); m != nil {
				// PS: [int]$Matches[1] - 1
				var n int
				fmt.Sscanf(m[1], "%d", &n)
				lineInFile = n - 1
				continue
			}
			if m := rePlusLine.FindStringSubmatch(dl); m != nil {
				lineInFile++
				txt := m[1]
				if secretsRe.MatchString(txt) {
					hits = append(hits, hit{File: currentFile, Line: lineInFile, Text: txt})
				}
			}
		}
		ms := time.Since(cs).Milliseconds()
		if len(hits) > 0 {
			for _, h := range hits {
				line := strings.TrimSpace(h.Text)
				if len(line) > 80 {
					line = line[:77] + "..."
				}
				fmt.Printf("    %s:%d %s\n", h.File, h.Line, line)
			}
			fmt.Println("  BLOCKING: potential secrets found in staged diff")
			checks = append(checks, checkResult{Name: "secrets", Status: "blocking", Detail: "potential secrets found", Ms: ms})
			blocked = true
		} else {
			fmt.Println("  OK")
			checks = append(checks, checkResult{Name: "secrets", Status: "ok", Ms: ms})
			passed++
		}
		}
	}

	// 4) config size
	{
		cs := time.Now()
		configPath := filepath.Join(repoRoot, "opencode.json")
		info, err := os.Stat(configPath)
		ms := time.Since(cs).Milliseconds()
		if err != nil {
			fmt.Printf("  BLOCKING: opencode.json not found at %s\n", configPath)
			checks = append(checks, checkResult{Name: "config-size", Status: "blocking", Detail: "opencode.json not found", Ms: ms})
			blocked = true
		} else {
			sz := info.Size()
			if sz > configSizeBudget {
				fmt.Printf("  BLOCKING: opencode.json exceeds %d B budget (ADR-007): %d B\n", configSizeBudget, sz)
				checks = append(checks, checkResult{Name: "config-size", Status: "blocking", Detail: fmt.Sprintf("opencode.json %d B exceeds budget", sz), Ms: ms})
				blocked = true
			} else {
				fmt.Println("  OK")
				checks = append(checks, checkResult{Name: "config-size", Status: "ok", Detail: fmt.Sprintf("%d B", sz), Ms: ms})
				passed++
			}
		}
	}

	// 5) async-result
	{
		cs := time.Now()
		pattern := filepath.Join(repoRoot, "*.async-result.json")
		matches, _ := filepath.Glob(pattern)
		var stale []string
		for _, p := range matches {
			data, err := os.ReadFile(p)
			if err != nil {
				stale = append(stale, fmt.Sprintf("%s: unparseable (read error)", filepath.Base(p)))
				continue
			}
			// Parse as generic JSON
			var raw json.RawMessage
			if err := json.Unmarshal(data, &raw); err != nil {
				stale = append(stale, fmt.Sprintf("%s: unparseable JSON: %v", filepath.Base(p), err))
				continue
			}
			// Check if array-wrapped
			var arr []interface{}
			if err := json.Unmarshal(data, &arr); err == nil {
				// If it unmarshals as array and the original was an array (check first char)
				trimmed := strings.TrimSpace(string(data))
				if strings.HasPrefix(trimmed, "[") {
					stale = append(stale, fmt.Sprintf("%s: array-wrapped (not passed)", filepath.Base(p)))
					continue
				}
			}
			// Check object has passed field that is strictly bool true
			var obj map[string]json.RawMessage
			if err := json.Unmarshal(data, &obj); err != nil {
				stale = append(stale, fmt.Sprintf("%s: unparseable", filepath.Base(p)))
				continue
			}
			passedRaw, ok := obj["passed"]
			if !ok {
				stale = append(stale, fmt.Sprintf("%s: missing passed", filepath.Base(p)))
				continue
			}
			var b bool
			if err := json.Unmarshal(passedRaw, &b); err != nil {
				// Could be string, number, etc. -> not passed
				stale = append(stale, fmt.Sprintf("%s: passed not bool true", filepath.Base(p)))
				continue
			}
			// Ensure strictly bool true (json bool true)
			// Also ensure raw was exactly "true" not something else that unmarshals to true
			if strings.TrimSpace(string(passedRaw)) != "true" || !b {
				stale = append(stale, fmt.Sprintf("%s: passed != true", filepath.Base(p)))
				continue
			}
			if !b {
				stale = append(stale, fmt.Sprintf("%s: passed false", filepath.Base(p)))
			}
		}
		ms := time.Since(cs).Milliseconds()
		if len(stale) > 0 {
			for _, s := range stale {
				fmt.Printf("    %s\n", s)
			}
			fmt.Println("  BLOCKING: unresolved subagent failure(s) — fix checks / re-run monitor or remove stale *.async-result.json")
			checks = append(checks, checkResult{Name: "async-result", Status: "blocking", Detail: strings.Join(stale, "; "), Ms: ms})
			blocked = true
		} else {
			fmt.Println("  OK")
			checks = append(checks, checkResult{Name: "async-result", Status: "ok", Ms: ms})
			passed++
		}
	}

	// Escalation decision
	psTriggers := classifyTriggers(staged)
	elapsed := time.Since(start).Milliseconds()
	total := len(checks)
	// passed counts non-blocking checks; blocked determines overall passed
	overallPassed := !blocked

	// If any staged matches PS-only triggers → escalate
	if len(psTriggers) > 0 {
		// Also need to report summary before escalation? PS gate will print its own summary.
		// We forward to PS; but print escalation notice.
		fmt.Printf("Escalating to PS gate (%d trigger(s)): %s\n", len(psTriggers), strings.Join(psTriggers, ", "))
		// For JSON mode, we still need to output JSON line after escalation? Spec says when --json present a final compact JSON line
		// But when escalating we exec pwsh and exit with ITS code, so JSON would be lost. We should print JSON before exec if requested.
		if wantJSON {
			j := map[string]interface{}{
				"passed":    overallPassed,
				"blocked":   blocked,
				"checks":    checks,
				"escalated": true,
				"elapsedMs": elapsed,
			}
			b, _ := json.Marshal(j)
			fmt.Println(string(b))
		}
		return escalateToPS(repoRoot, "")
	}

	// No triggers: fast path complete
	// Output summary like "=== Gate: N/N passed ==="
	// Our passed counts WARN as passed per PS logic; we tracked passed accordingly.
	// Need total checks = len(checks) ; failed is blocked? In PS, failed counts blocking only.
	failed := 0
	if blocked {
		failed = 1 // at least one blocking; but for summary, count blocking checks
		// Count actual blocking checks
		c := 0
		for _, ch := range checks {
			if ch.Status == "blocking" {
				c++
			}
		}
		if c > 0 {
			failed = c
		}
	}
	// Recompute passed for summary as total - failed (WARN counts as passed)
	summaryPassed := total - failed
	fmt.Printf("\n=== Gate: %d/%d passed ===\n", summaryPassed, total)
	if blocked {
		fmt.Println("  BLOCKED")
	} else {
		fmt.Println("  ALL CLEAR")
	}

	if wantJSON {
		j := map[string]interface{}{
			"passed":    overallPassed,
			"blocked":   blocked,
			"checks":    checks,
			"escalated": false,
			"elapsedMs": elapsed,
		}
		b, _ := json.Marshal(j)
		fmt.Println(string(b))
	}

	if blocked {
		return 1
	}
	return 0
}

func escalateToPS(repoRoot string, reason string) int {
	if reason != "" {
		fmt.Fprintln(os.Stderr, reason)
	}
	psFile := filepath.Join(repoRoot, ".githooks", "pre-commit-gate.ps1")
	// Use pwsh; on Windows it is pwsh, elsewhere pwsh as well
	cmd := exec.Command("pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", psFile, "-RepoRoot", repoRoot)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	// Forward environment
	cmd.Env = os.Environ()
	err := cmd.Run()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			return exitErr.ExitCode()
		}
		// If pwsh not found or failed to start, report and block
		fmt.Fprintf(os.Stderr, "ERROR: failed to escalate to PS gate: %v\n", err)
		return 1
	}
	return 0
}

func classifyTriggers(staged []string) []string {
	var triggers []string
	for _, p := range staged {
		if triggerPS1.MatchString(p) ||
			triggerSkillMD.MatchString(p) ||
			triggerProjectJSON.MatchString(p) ||
			triggerReviewRules.MatchString(p) ||
			triggerSkills.MatchString(p) ||
			triggerOpencodeConfig.MatchString(p) ||
			triggerLibOrOpencode.MatchString(p) ||
			triggerTestsPS1.MatchString(p) ||
			triggerAgentsMD.MatchString(p) {
			triggers = append(triggers, p)
		}
	}
	return triggers
}

func getStaged(repoRoot string) ([]string, error) {
	cmd := exec.Command("git", "diff", "--cached", "--name-only", "--diff-filter=ACM")
	cmd.Dir = repoRoot
	out, err := cmd.Output()
	if err != nil {
		return nil, err
	}
	text := strings.TrimSpace(string(out))
	if text == "" {
		return []string{}, nil
	}
	lines := strings.Split(text, "\n")
	var res []string
	for _, l := range lines {
		trim := strings.TrimSpace(l)
		if trim != "" {
			// Normalize to forward slashes for regex matching
			trim = filepath.ToSlash(trim)
			res = append(res, trim)
		}
	}
	return res, nil
}

func resolveRepoRoot(flag string) string {
	if flag != "" {
		if abs, err := filepath.Abs(flag); err == nil {
			return abs
		}
		return flag
	}
	cwd, err := os.Getwd()
	if err != nil {
		return "."
	}
	// Walk up looking for go.mod
	dir := cwd
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	// Fallback to git toplevel
	cmd := exec.Command("git", "rev-parse", "--show-toplevel")
	cmd.Dir = cwd
	if out, err := cmd.Output(); err == nil {
		trim := strings.TrimSpace(string(out))
		if trim != "" {
			return filepath.FromSlash(trim)
		}
	}
	return cwd
}

func contains(arr []string, s string) bool {
	for _, v := range arr {
		if v == s {
			return true
		}
	}
	return false
}

func getArgValue(args []string, name string) string {
	for i, v := range args {
		if v == name && i+1 < len(args) {
			return args[i+1]
		}
		if strings.HasPrefix(v, name+"=") {
			return strings.TrimPrefix(v, name+"=")
		}
	}
	return ""
}
