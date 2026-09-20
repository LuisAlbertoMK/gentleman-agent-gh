// Package main implements the "sync" CLI for gentleman-agent-gh.
//
// It generates and updates opencode.json configs from the SSoT chain
// (opencode-base.json + permission-templates.json + agent-overrides.json),
// applying the security deny floor and CBM_ALLOWED_ROOT scoping.
//
// Build (Go 1.26, stdlib only):
//
//	go build -o bin/sync.exe ./cmd/sync
//
// Interface consumed by PowerShell wrappers:
//
//	sync install  --target <dir> [--default-agent gentle-MK] [--chain-root <dir>] [--force] [--dry-run] [--json]
//	sync update   --project <dir> [--chain-root <dir>] [--mode chain-wins|project-wins] [--dry-run] [--json]
//	sync update-all --manifest <projects.json> [--chain-root <dir>] [--mode chain-wins] [--parallel 4] [--dry-run] [--json]
//
// Exit codes: 0 = ok, 1 = failure.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"sync"
)

// ─── Flag helpers (same pattern as cmd/fast/main.go) ───────────────────────────

func contains(args []string, s string) bool {
	for _, v := range args {
		if v == s {
			return true
		}
		if strings.HasPrefix(v, s+"=") {
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

// detectChainRoot walks up from cwd looking for the SSoT chain marker file
// (scripts/lib/opencode-base.json), same as cmd/gate's resolveRepoRoot pattern.
func detectChainRoot() string {
	if cwd, err := os.Getwd(); err == nil {
		dir := cwd
		for i := 0; i < 6; i++ {
			if _, err := os.Stat(filepath.Join(dir, "scripts", "lib", "opencode-base.json")); err == nil {
				return dir
			}
			parent := filepath.Dir(dir)
			if parent == dir {
				break
			}
			dir = parent
		}
	}
	if exe, err := os.Executable(); err == nil {
		dir := filepath.Dir(exe)
		for i := 0; i < 6; i++ {
			if _, err := os.Stat(filepath.Join(dir, "scripts", "lib", "opencode-base.json")); err == nil {
				return dir
			}
			parent := filepath.Dir(dir)
			if parent == dir {
				break
			}
			dir = parent
		}
	}
	return "."
}

func detectRepoRoot() string {
	if cwd, err := os.Getwd(); err == nil {
		if _, err := os.Stat(filepath.Join(cwd, "go.mod")); err == nil {
			return cwd
		}
		dir := cwd
		for i := 0; i < 6; i++ {
			parent := filepath.Dir(dir)
			if parent == dir {
				break
			}
			dir = parent
			if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
				return dir
			}
		}
	}
	if cwd, err := os.Getwd(); err == nil {
		return cwd
	}
	return "."
}

func printHelp() {
	fmt.Println("sync - generate/update opencode.json from the SSoT chain")
	fmt.Println()
	fmt.Println("Commands:")
	fmt.Println("  install  --target <dir> [flags]   Generate opencode.json from chain")
	fmt.Println("  update   --project <dir> [flags]  Regenerate + merge project overrides")
	fmt.Println("  update-all --manifest <file> [flags]  Batch update multiple projects")
	fmt.Println()
	fmt.Println("Flags:")
	fmt.Println("  --default-agent <name>   Agent to set as default (default: gentle-MK)")
	fmt.Println("  --chain-root <dir>       Root of the SSoT chain (auto-detected)")
	fmt.Println("  --mode <chain-wins|project-wins>  Merge strategy for update (default: chain-wins)")
	fmt.Println("  --force                  Overwrite existing .gentleman-mode")
	fmt.Println("  --dry-run                Report what would be written without writing")
	fmt.Println("  --json                   Output JSON report instead of human text")
	fmt.Println("  --parallel <n>           Max concurrent updates for update-all (default: 4)")
}

// ─── JSON report output ───────────────────────────────────────────────────────

type syncReport struct {
	Status string   `json:"status"`
	Target string   `json:"target"`
	Mode   string   `json:"mode,omitempty"`
	DryRun bool     `json:"dry_run"`
	Written bool    `json:"written"`
	Notes  []string `json:"notes"`
}

func outputJSON(report syncReport, exitCode int) {
	b, _ := json.Marshal(report)
	fmt.Println(string(b))
	os.Exit(exitCode)
}

func outputHuman(report syncReport, exitCode int) {
	icon := "✅ OK"
	if report.Status == "fail" {
		icon = "❌ FAIL"
	}
	fmt.Printf("  Target  : %s\n", report.Target)
	if report.Mode != "" {
		fmt.Printf("  Mode    : %s\n", report.Mode)
	}
	fmt.Printf("  Written : %v\n", report.Written)
	fmt.Printf("  Dry-run : %v\n", report.DryRun)
	fmt.Printf("  Status  : %s\n", icon)
	for _, n := range report.Notes {
		fmt.Printf("  Note    : %s\n", n)
	}
	os.Exit(exitCode)
}

// ─── Template detection (mirrors PS template-detection.ps1 SSoT) ──────────────

// agentTemplateMap maps agent names to their permission template names.
// Derived from permission-templates.json _used_by section (SSoT guard).
var agentTemplateMap = map[string]string{
	// orchestrator
	"gentle-MK":          "orchestrator",
	"gentle-MK-auto":     "orchestrator",
	"gentle-MK-sub":      "orchestrator",
	"gentle-MK-sub-auto": "orchestrator",
	// readwrite
	"gentleman-aem":          "readwrite",
	"gentleman-aem-sub":      "readwrite",
	"gentleman-codex":        "readwrite",
	"gentleman-codex-sub":    "readwrite",
	"gentleman-deep":         "readwrite",
	"gentleman-deep-sub":     "readwrite",
	"gentleman-implementer":  "readwrite",
	"gentleman-implementer-sub": "readwrite",
	"gentleman-quick":        "readwrite",
	"gentleman-quick-sub":    "readwrite",
	"sdd-apply":              "readwrite",
	"sdd-archive":            "readwrite",
	"sdd-design":             "readwrite",
	"sdd-explore":            "readwrite",
	"sdd-init":               "readwrite",
	"sdd-propose":            "readwrite",
	"sdd-spec":               "readwrite",
	"sdd-tasks":              "readwrite",
	"sdd-verify":             "readwrite",
	// readonly
	"gentleman-datascience":      "readonly",
	"gentleman-datascience-sub":  "readonly",
	"gentleman-docs":             "readonly",
	"gentleman-docs-sub":         "readonly",
	"gentleman-frontend":         "readonly",
	"gentleman-frontend-sub":     "readonly",
	"gentleman-infra":            "readonly",
	"gentleman-infra-sub":        "readonly",
	"gentleman-performance":      "readonly",
	"gentleman-performance-sub":  "readonly",
	"gentleman-security":         "readonly",
	"gentleman-security-sub":     "readonly",
	"gentleman-seo":              "readonly",
	"gentleman-seo-sub":          "readonly",
	// sddorchestrator
	"gentle-orchestrator":    "sddorchestrator",
	"sdd-orchestrator":       "sddorchestrator",
	// reviewer
	"gentleman-reviewer":     "reviewer",
	"gentleman-reviewer-sub": "reviewer",
	// auto
	"gentleman-aem-auto":          "auto",
	"gentleman-codex-auto":        "auto",
	"gentleman-deep-auto":         "auto",
	"gentleman-implementer-auto":  "auto",
	"gentleman-quick-auto":        "auto",
	// auto-sub
	"gentleman-aem-sub-auto":      "auto-sub",
	"gentleman-codex-sub-auto":    "auto-sub",
	"gentleman-deep-sub-auto":     "auto-sub",
	"gentleman-implementer-sub-auto": "auto-sub",
	"gentleman-quick-sub-auto":    "auto-sub",
	// reasoning / code-review / initializer (newer agents — fallback to readwrite)
	"gentleman-reasoning":          "readwrite",
	"gentleman-reasoning-sub":      "readwrite",
	"gentleman-reasoning-sub-auto": "readwrite",
	"gentleman-code-review":        "reviewer",
	"gentleman-code-review-sub":    "reviewer",
	"gentleman-code-review-sub-auto": "reviewer",
	"gentleman-initializer":        "readwrite",
	"gentleman-initializer-sub":    "readwrite",
	"gentleman-initializer-sub-auto": "readwrite",
}

// ─── {file:...} reference rewriting (mirrors PS Convert-ConfigFileRef) ─────────

var reFileRef = regexp.MustCompile(`\{file:([^}]+)\}`)

// rewriteFileRefs walks the JSON tree recursively and rewrites relative {file:...}
// paths to absolute paths rooted at chainRoot. Already-absolute paths are left untouched.
func rewriteFileRefs(v interface{}, chainRoot string) interface{} {
	switch val := v.(type) {
	case string:
		return reFileRef.ReplaceAllStringFunc(val, func(match string) string {
			m := reFileRef.FindStringSubmatch(match)
			if m == nil {
				return match
			}
			p := m[1]
			if filepath.IsAbs(p) || strings.HasPrefix(p, "~/") || strings.HasPrefix(p, "/") {
				return match
			}
			return "{file:" + filepath.Join(chainRoot, filepath.FromSlash(p)) + "}"
		})
	case map[string]interface{}:
		out := make(map[string]interface{}, len(val))
		for k, child := range val {
			out[k] = rewriteFileRefs(child, chainRoot)
		}
		return out
	case []interface{}:
		out := make([]interface{}, len(val))
		for i, child := range val {
			out[i] = rewriteFileRefs(child, chainRoot)
		}
		return out
	default:
		return v
	}
}

// ─── Chain config generation (mirrors PS Get-ChainConfig) ─────────────────────

// getChainConfig reads opencode-base.json, applies permission templates + agent
// overrides, and returns the raw chain config as a map.
func getChainConfig(chainRoot string) (map[string]interface{}, error) {
	basePath := filepath.Join(chainRoot, "scripts", "lib", "opencode-base.json")
	tplPath := filepath.Join(chainRoot, "scripts", "lib", "permission-templates.json")
	ovrPath := filepath.Join(chainRoot, "scripts", "lib", "agent-overrides.json")

	baseData, err := os.ReadFile(basePath)
	if err != nil {
		return nil, fmt.Errorf("chain base not found: %s — run setup-machine.ps1 first", basePath)
	}
	var base map[string]interface{}
	if err := json.Unmarshal(baseData, &base); err != nil {
		return nil, fmt.Errorf("chain base parse error: %v", err)
	}

	tplData, err := os.ReadFile(tplPath)
	if err != nil {
		return nil, fmt.Errorf("permission templates not found: %s", tplPath)
	}
	var templates map[string]interface{}
	if err := json.Unmarshal(tplData, &templates); err != nil {
		return nil, fmt.Errorf("permission templates parse error: %v", err)
	}

	var overrides map[string]interface{}
	if ovrData, err := os.ReadFile(ovrPath); err == nil {
		_ = json.Unmarshal(ovrData, &overrides)
	}

	// Build agents with permission templates (mirrors PS L191-218).
	agents, _ := base["agent"].(map[string]interface{})
	agentOverrides := overrides
	outAgents := make(map[string]interface{})
	for name, agentDef := range agents {
		def, _ := agentDef.(map[string]interface{})
		tplName, ok := agentTemplateMap[name]
		if !ok {
			tplName = "readwrite" // safe fallback
		}
		tplRaw, ok := templates[tplName]
		if !ok {
			return nil, fmt.Errorf("template %q missing from permission-templates.json (agent %q)", tplName, name)
		}
		// Deep-clone the template
		tplBytes, _ := json.Marshal(tplRaw)
		var tpl map[string]interface{}
		json.Unmarshal(tplBytes, &tpl)

		// Apply agent overrides (hidden, extraPermKeys)
		if ovrDefs := agentOverrides; ovrDefs != nil {
			if ovr, ok := ovrDefs[name]; ok {
				ovrMap, _ := ovr.(map[string]interface{})
				if hidden, ok := ovrMap["hidden"]; ok {
					def["hidden"] = hidden
				}
				if extra, ok := ovrMap["extraPermKeys"]; ok {
					extraMap, _ := extra.(map[string]interface{})
					for k, v := range extraMap {
						tpl[k] = v
					}
				}
			}
		}

		// Build agent object in canonical order
		agent := make(map[string]interface{})
		for _, key := range []string{"description", "model", "hidden", "mode", "prompt"} {
			if val, ok := def[key]; ok {
				agent[key] = val
			}
		}
		agent["permission"] = tpl
		if val, ok := def["tools"]; ok {
			agent["tools"] = val
		}
		outAgents[name] = agent
	}
	base["agent"] = outAgents
	return base, nil
}

// ─── Security deny floor (mirrors PS Assert-SecurityFloor) ────────────────────

func loadDenyRules(chainRoot string) (map[string]interface{}, error) {
	denyPath := filepath.Join(chainRoot, "scripts", "opencode-config", "shared-deny-rules.json")
	data, err := os.ReadFile(denyPath)
	if err != nil {
		return nil, fmt.Errorf("shared deny rules not found: %s", denyPath)
	}
	var deny map[string]interface{}
	if err := json.Unmarshal(data, &deny); err != nil {
		return nil, fmt.Errorf("shared deny rules parse error: %v", err)
	}
	return deny, nil
}

// applySecurityFloor re-asserts the shared deny rules on the config.
// Mirrors PS Assert-SecurityFloor: global permission.bash, per-agent bash,
// and write-deny to ~/.config/opencode/** on edit/write.
func applySecurityFloor(config map[string]interface{}, denyRules map[string]interface{}) {
	// Ensure top-level permission exists
	perm, _ := config["permission"].(map[string]interface{})
	if perm == nil {
		perm = make(map[string]interface{})
		config["permission"] = perm
	}

	// bash deny floor
	bash, _ := perm["bash"].(map[string]interface{})
	if bash == nil {
		bash = make(map[string]interface{})
		perm["bash"] = bash
	}
	for rule := range denyRules {
		bash[rule] = "deny"
	}

	// write-deny to ~/.config/opencode/** on edit + write
	for _, key := range []string{"edit", "write"} {
		section, _ := perm[key].(map[string]interface{})
		if section == nil {
			section = make(map[string]interface{})
			perm[key] = section
		}
		section["~/.config/opencode/**"] = "deny"
	}

	// Per-agent floor (mirrors PS FIX 2)
	agents, _ := config["agent"].(map[string]interface{})
	for _, agentVal := range agents {
		agent, _ := agentVal.(map[string]interface{})
		if agent == nil {
			continue
		}
		aperm, _ := agent["permission"].(map[string]interface{})
		if aperm == nil {
			continue
		}
		abash, _ := aperm["bash"].(map[string]interface{})
		if abash != nil {
			for rule := range denyRules {
				abash[rule] = "deny"
			}
		}
		for _, key := range []string{"edit", "write"} {
			asection, _ := aperm[key].(map[string]interface{})
			if asection != nil {
				asection["~/.config/opencode/**"] = "deny"
			}
		}
	}
}

// ─── CBM_ALLOWED_ROOT scoping (mirrors PS FIX 5) ─────────────────────────────

func applyCBMScope(config map[string]interface{}, target string, chainRoot string) {
	targetFull, _ := filepath.Abs(target)
	chainFull, _ := filepath.Abs(chainRoot)
	if strings.EqualFold(filepath.Clean(targetFull), filepath.Clean(chainFull)) {
		return // target IS the chain repo — don't override
	}
	mcp, _ := config["mcp"].(map[string]interface{})
	if mcp == nil {
		return
	}
	cbm, _ := mcp["codebase-memory-mcp"].(map[string]interface{})
	if cbm == nil {
		return
	}
	env, _ := cbm["environment"].(map[string]interface{})
	if env == nil {
		env = make(map[string]interface{})
		cbm["environment"] = env
	}
	env["CBM_ALLOWED_ROOT"] = target
}

// ─── Install command ──────────────────────────────────────────────────────────

func runInstall(args []string) int {
	target := getArgValue(args, "--target")
	if target == "" {
		fmt.Fprintln(os.Stderr, "ERROR: --target is required")
		return 1
	}
	target, _ = filepath.Abs(target)

	defaultAgent := getArgValue(args, "--default-agent")
	if defaultAgent == "" {
		defaultAgent = "gentle-MK"
	}
	chainRoot := getArgValue(args, "--chain-root")
	if chainRoot == "" {
		chainRoot = detectChainRoot()
	}
	force := contains(args, "--force")
	dryRun := contains(args, "--dry-run")
	jsonOut := contains(args, "--json") || contains(args, "-json")

	// Create target dir if it doesn't exist (mirrors PS L284-291)
	if _, err := os.Stat(target); os.IsNotExist(err) {
		if !dryRun {
			if err := os.MkdirAll(target, 0o755); err != nil {
				if jsonOut {
					outputJSON(syncReport{Status: "fail", Target: target, DryRun: true, Notes: []string{fmt.Sprintf("mkdir failed: %v", err)}}, 1)
				}
				fmt.Fprintf(os.Stderr, "ERROR: failed to create target: %v\n", err)
				return 1
			}
		}
	}

	// Check if opencode.json already exists — respect unless --force
	existingPath := filepath.Join(target, "opencode.json")
	if _, err := os.Stat(existingPath); err == nil && !force {
		notes := []string{"opencode.json already exists (use --force to overwrite)"}
		if jsonOut {
			outputJSON(syncReport{Status: "ok", Target: target, DryRun: dryRun, Written: false, Notes: notes}, 0)
		}
		for _, n := range notes {
			fmt.Printf("  %s\n", n)
		}
		return 0
	}

	// Generate config from chain
	chain, err := getChainConfig(chainRoot)
	if err != nil {
		notes := []string{err.Error()}
		if jsonOut {
			outputJSON(syncReport{Status: "fail", Target: target, DryRun: dryRun, Notes: notes}, 1)
		}
		fmt.Fprintf(os.Stderr, "ERROR: %v\n", err)
		return 1
	}

	// Set default_agent
	chain["default_agent"] = defaultAgent
	chain["$schema"] = "https://opencode.ai/config.json"

	// Apply security deny floor (ALWAYS)
	denyRules, err := loadDenyRules(chainRoot)
	if err != nil {
		notes := []string{err.Error()}
		if jsonOut {
			outputJSON(syncReport{Status: "fail", Target: target, DryRun: dryRun, Notes: notes}, 1)
		}
		fmt.Fprintf(os.Stderr, "ERROR: %v\n", err)
		return 1
	}
	applySecurityFloor(chain, denyRules)

	// CBM scope
	applyCBMScope(chain, target, chainRoot)

	// {file:...} rewriting for external targets
	targetFull, _ := filepath.Abs(target)
	chainFull, _ := filepath.Abs(chainRoot)
	if !strings.EqualFold(filepath.Clean(targetFull), filepath.Clean(chainFull)) {
		chain = rewriteFileRefs(chain, chainRoot).(map[string]interface{})
	}

	// Write opencode.json
	var notes []string
	written := false
	if dryRun {
		notes = append(notes, fmt.Sprintf("WOULD create %s", existingPath))
	} else {
		data, _ := json.MarshalIndent(chain, "", "  ")
		if err := os.WriteFile(existingPath, append(data, '\n'), 0o644); err != nil {
			notes = []string{fmt.Sprintf("write failed: %v", err)}
			if jsonOut {
				outputJSON(syncReport{Status: "fail", Target: target, DryRun: dryRun, Notes: notes}, 1)
			}
			fmt.Fprintf(os.Stderr, "ERROR: %v\n", err)
			return 1
		}
		written = true
		notes = append(notes, fmt.Sprintf("Created %s", existingPath))
		notes = append(notes, fmt.Sprintf("default_agent: %s", defaultAgent))
		notes = append(notes, "security deny floor re-asserted (shared-deny-rules.json)")
	}

	// Write .gentleman-mode (mirrors PS L389-410)
	modeFile := filepath.Join(target, ".gentleman-mode")
	if dryRun {
		if _, err := os.Stat(modeFile); os.IsNotExist(err) {
			notes = append(notes, "WOULD create .gentleman-mode='manual'")
		} else if force {
			notes = append(notes, "WOULD overwrite .gentleman-mode to 'manual' (-Force)")
		} else {
			notes = append(notes, ".gentleman-mode exists (respected)")
		}
	} else {
		if _, err := os.Stat(modeFile); os.IsNotExist(err) {
			if err := os.WriteFile(modeFile, []byte("manual"), 0o644); err == nil {
				notes = append(notes, ".gentleman-mode: 'manual' (default for external projects)")
			}
		} else if force {
			if err := os.WriteFile(modeFile, []byte("manual"), 0o644); err == nil {
				notes = append(notes, ".gentleman-mode: overwritten to 'manual' (-Force)")
			}
		} else {
			existing, _ := os.ReadFile(modeFile)
			notes = append(notes, fmt.Sprintf(".gentleman-mode: '%s' (existing, respected)", strings.TrimSpace(string(existing))))
		}
	}

	report := syncReport{
		Status:  "ok",
		Target:  target,
		DryRun:  dryRun,
		Written: written,
		Notes:   notes,
	}
	if jsonOut {
		outputJSON(report, 0)
	}
	outputHuman(report, 0)
	return 0
}

// ─── Update command ───────────────────────────────────────────────────────────

func runUpdate(args []string) int {
	project := getArgValue(args, "--project")
	if project == "" {
		fmt.Fprintln(os.Stderr, "ERROR: --project is required")
		return 1
	}
	project, _ = filepath.Abs(project)

	// Validate project dir exists (fail-fast, even in --dry-run)
	if _, err := os.Stat(project); os.IsNotExist(err) {
		notes := []string{fmt.Sprintf("project dir does not exist: %s", project)}
		if contains(args, "--json") || contains(args, "-json") {
			outputJSON(syncReport{Status: "fail", Target: project, DryRun: contains(args, "--dry-run"), Notes: notes}, 1)
		}
		fmt.Fprintf(os.Stderr, "ERROR: %s\n", notes[0])
		return 1
	}

	chainRoot := getArgValue(args, "--chain-root")
	if chainRoot == "" {
		chainRoot = detectChainRoot()
	}
	mode := getArgValue(args, "--mode")
	if mode == "" {
		mode = "chain-wins"
	}
	dryRun := contains(args, "--dry-run")
	jsonOut := contains(args, "--json") || contains(args, "-json")

	projectCfgPath := filepath.Join(project, "opencode.json")

	// Read existing project config (if any)
	var existing map[string]interface{}
	if data, err := os.ReadFile(projectCfgPath); err == nil {
		_ = json.Unmarshal(data, &existing)
	}

	// Generate fresh config from chain
	chain, err := getChainConfig(chainRoot)
	if err != nil {
		if jsonOut {
			outputJSON(syncReport{Status: "fail", Target: project, Mode: mode, DryRun: dryRun, Notes: []string{err.Error()}}, 1)
		}
		fmt.Fprintf(os.Stderr, "ERROR: %v\n", err)
		return 1
	}

	var notes []string

	if existing != nil {
		// Sections ALWAYS preserved from project (never overwritten by chain)
		// Matches PS L348: compaction, tool_output, experimental, tools, plugin
		for _, section := range []string{"mcp", "compaction", "tool_output", "experimental", "tools", "plugin"} {
			if _, ok := existing[section]; ok {
				chain[section] = existing[section]
			}
		}

		// Merge agent + permission based on mode
		if mode == "project-wins" {
			// project-wins: merge — project values win for agent/permission/skills/default_agent
			// Matches PS L343-345: Merge-ProjectSection with project overriding chain
			if existingAgents, ok := existing["agent"].(map[string]interface{}); ok {
				chainAgents, _ := chain["agent"].(map[string]interface{})
				if chainAgents == nil {
					chainAgents = make(map[string]interface{})
				}
				// Deep merge: for each existing agent, check if it has permission overrides
				for name, existAgent := range existingAgents {
					existDef, _ := existAgent.(map[string]interface{})
					if existDef == nil {
						continue
					}
					chainAgent, _ := chainAgents[name].(map[string]interface{})
					if chainAgent == nil {
						// Agent only exists in project — keep it
						chainAgents[name] = existAgent
						continue
					}
					// Merge: project agent.permission keys override chain agent.permission keys
					if existPerm, ok := existDef["permission"].(map[string]interface{}); ok {
						chainPerm, _ := chainAgent["permission"].(map[string]interface{})
						if chainPerm == nil {
							chainPerm = make(map[string]interface{})
							chainAgent["permission"] = chainPerm
						}
						for k, v := range existPerm {
							chainPerm[k] = v
						}
					}
				}
				chain["agent"] = chainAgents
			}
			// skills + default_agent: project wins
			for _, key := range []string{"skills", "default_agent"} {
				if val, ok := existing[key]; ok {
					chain[key] = val
				}
			}
			notes = append(notes, "project-wins merge applied (agent/permission/skills/default_agent)")
		} else {
			// chain-wins: chain agent/permission/skills/default_agent override project
			// But project mcp/tool_output/compaction/experimental/tools/plugin already preserved above
			notes = append(notes, "chain-wins merge applied (agent/permission from chain, project sections preserved)")
		}
	} else {
		notes = append(notes, "no existing config found — generated from chain")
	}

	// Apply security deny floor (ALWAYS re-applied)
	denyRules, err := loadDenyRules(chainRoot)
	if err != nil {
		notes = append(notes, fmt.Sprintf("security floor skip: %v", err))
	} else {
		applySecurityFloor(chain, denyRules)
		notes = append(notes, "security deny floor re-asserted")
	}

	// CBM scope
	applyCBMScope(chain, project, chainRoot)

	// {file:...} rewriting for external targets
	projectFull, _ := filepath.Abs(project)
	chainFull, _ := filepath.Abs(chainRoot)
	if !strings.EqualFold(filepath.Clean(projectFull), filepath.Clean(chainFull)) {
		chain = rewriteFileRefs(chain, chainRoot).(map[string]interface{})
	}

	// Check if output would change
	written := false
	if existing != nil {
		existingBytes, _ := json.Marshal(existing)
		newBytes, _ := json.Marshal(chain)
		if string(existingBytes) == string(newBytes) {
			notes = append(notes, "config unchanged")
		}
	}

	if dryRun {
		notes = append(notes, fmt.Sprintf("WOULD update %s", projectCfgPath))
	} else {
		data, _ := json.MarshalIndent(chain, "", "  ")
		if err := os.WriteFile(projectCfgPath, append(data, '\n'), 0o644); err != nil {
			notes = []string{fmt.Sprintf("write failed: %v", err)}
			if jsonOut {
				outputJSON(syncReport{Status: "fail", Target: project, Mode: mode, DryRun: dryRun, Notes: notes}, 1)
			}
			fmt.Fprintf(os.Stderr, "ERROR: %v\n", err)
			return 1
		}
		written = true
		notes = append(notes, fmt.Sprintf("Updated %s", projectCfgPath))
	}

	status := "ok"
	if !written && !dryRun {
		status = "ok" // config unchanged is ok
	}

	report := syncReport{
		Status:  status,
		Target:  project,
		Mode:    mode,
		DryRun:  dryRun,
		Written: written,
		Notes:   notes,
	}
	if jsonOut {
		outputJSON(report, 0)
	}
	outputHuman(report, 0)
	return 0
}

// ─── Update-all command ───────────────────────────────────────────────────────

type manifestProject struct {
	Path         string `json:"path"`
	DefaultAgent string `json:"defaultAgent"`
}

type manifestFile struct {
	Projects []manifestProject `json:"projects"`
}

func runUpdateAll(args []string) int {
	manifestPath := getArgValue(args, "--manifest")
	if manifestPath == "" {
		fmt.Fprintln(os.Stderr, "ERROR: --manifest is required")
		return 1
	}
	manifestPath, _ = filepath.Abs(manifestPath)

	chainRoot := getArgValue(args, "--chain-root")
	if chainRoot == "" {
		chainRoot = detectChainRoot()
	}
	mode := getArgValue(args, "--mode")
	if mode == "" {
		mode = "chain-wins"
	}
	parallel := 4
	if p := getArgValue(args, "--parallel"); p != "" {
		fmt.Sscanf(p, "%d", &parallel)
	}
	if parallel < 1 {
		parallel = 1
	}
	if parallel > runtime.NumCPU() {
		parallel = runtime.NumCPU()
	}
	dryRun := contains(args, "--dry-run")
	jsonOut := contains(args, "--json") || contains(args, "-json")

	// Parse manifest
	manifestData, err := os.ReadFile(manifestPath)
	if err != nil {
		if jsonOut {
			outputJSON(syncReport{Status: "fail", Target: manifestPath, Mode: mode, DryRun: dryRun, Notes: []string{fmt.Sprintf("manifest read error: %v", err)}}, 1)
		}
		fmt.Fprintf(os.Stderr, "ERROR: manifest read error: %v\n", err)
		return 1
	}
	var manifest manifestFile
	if err := json.Unmarshal(manifestData, &manifest); err != nil {
		if jsonOut {
			outputJSON(syncReport{Status: "fail", Target: manifestPath, Mode: mode, DryRun: dryRun, Notes: []string{fmt.Sprintf("manifest parse error: %v", err)}}, 1)
		}
		fmt.Fprintf(os.Stderr, "ERROR: manifest parse error: %v\n", err)
		return 1
	}
	if len(manifest.Projects) == 0 {
		if jsonOut {
			outputJSON(syncReport{Status: "ok", Target: manifestPath, Mode: mode, DryRun: dryRun, Notes: []string{"manifest contains no projects"}}, 0)
		}
		fmt.Println("  No projects in manifest")
		return 0
	}

	// Process projects in parallel
	type projectResult struct {
		Project string   `json:"project"`
		Status  string   `json:"status"`
		Written bool     `json:"written"`
		Notes   []string `json:"notes"`
	}

	results := make([]projectResult, len(manifest.Projects))
	sem := make(chan struct{}, parallel)
	var wg sync.WaitGroup

	// Pre-generate chain config once (shared read-only)
	chain, err := getChainConfig(chainRoot)
	if err != nil {
		if jsonOut {
			outputJSON(syncReport{Status: "fail", Target: manifestPath, Mode: mode, DryRun: dryRun, Notes: []string{err.Error()}}, 1)
		}
		fmt.Fprintf(os.Stderr, "ERROR: %v\n", err)
		return 1
	}
	denyRules, err := loadDenyRules(chainRoot)
	if err != nil {
		if jsonOut {
			outputJSON(syncReport{Status: "fail", Target: manifestPath, Mode: mode, DryRun: dryRun, Notes: []string{err.Error()}}, 1)
		}
		fmt.Fprintf(os.Stderr, "ERROR: %v\n", err)
		return 1
	}

	for i, proj := range manifest.Projects {
		wg.Add(1)
		go func(idx int, p manifestProject) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()

			projectDir, _ := filepath.Abs(p.Path)

			// Validate project dir exists (fail-fast, even in --dry-run)
			if _, err := os.Stat(projectDir); os.IsNotExist(err) {
				results[idx] = projectResult{
					Project: projectDir,
					Status:  "fail",
					Notes:   []string{fmt.Sprintf("project dir does not exist: %s", projectDir)},
				}
				return
			}

			defaultAgent := p.DefaultAgent
			if defaultAgent == "" {
				defaultAgent = "gentle-MK"
			}

			// Deep-clone chain for this project
			chainBytes, _ := json.Marshal(chain)
			var projConfig map[string]interface{}
			json.Unmarshal(chainBytes, &projConfig)

			projectCfgPath := filepath.Join(projectDir, "opencode.json")
			var existing map[string]interface{}
			if data, err := os.ReadFile(projectCfgPath); err == nil {
				_ = json.Unmarshal(data, &existing)
			}

			var notes []string
			written := false

			// Apply existing project sections (always preserved)
			if existing != nil {
				for _, section := range []string{"mcp", "compaction", "tool_output", "experimental", "tools", "plugin"} {
					if _, ok := existing[section]; ok {
						projConfig[section] = existing[section]
					}
				}

				if mode == "project-wins" {
					if existingAgents, ok := existing["agent"].(map[string]interface{}); ok {
						projAgents, _ := projConfig["agent"].(map[string]interface{})
						if projAgents == nil {
							projAgents = make(map[string]interface{})
						}
						for name, existAgent := range existingAgents {
							existDef, _ := existAgent.(map[string]interface{})
							if existDef == nil {
								continue
							}
							chainAgent, _ := projAgents[name].(map[string]interface{})
							if chainAgent == nil {
								projAgents[name] = existAgent
								continue
							}
							if existPerm, ok := existDef["permission"].(map[string]interface{}); ok {
								chainPerm, _ := chainAgent["permission"].(map[string]interface{})
								if chainPerm == nil {
									chainPerm = make(map[string]interface{})
									chainAgent["permission"] = chainPerm
								}
								for k, v := range existPerm {
									chainPerm[k] = v
								}
							}
						}
						projConfig["agent"] = projAgents
					}
					for _, key := range []string{"skills", "default_agent"} {
						if val, ok := existing[key]; ok {
							projConfig[key] = val
						}
					}
				}
			}

			projConfig["default_agent"] = defaultAgent

			// Security floor
			applySecurityFloor(projConfig, denyRules)
			// CBM scope
			applyCBMScope(projConfig, projectDir, chainRoot)
			// {file:...} rewriting
			projectFull, _ := filepath.Abs(projectDir)
			chainFull, _ := filepath.Abs(chainRoot)
			if !strings.EqualFold(filepath.Clean(projectFull), filepath.Clean(chainFull)) {
				projConfig = rewriteFileRefs(projConfig, chainRoot).(map[string]interface{})
			}

			if dryRun {
				notes = append(notes, fmt.Sprintf("WOULD update %s", projectCfgPath))
			} else {
				data, _ := json.MarshalIndent(projConfig, "", "  ")
				if err := os.MkdirAll(projectDir, 0o755); err != nil {
					notes = append(notes, fmt.Sprintf("mkdir failed: %v", err))
				} else if err := os.WriteFile(projectCfgPath, append(data, '\n'), 0o644); err != nil {
					notes = append(notes, fmt.Sprintf("write failed: %v", err))
				} else {
					written = true
					notes = append(notes, fmt.Sprintf("Updated %s", projectCfgPath))
				}
			}

			status := "ok"
			if len(notes) > 0 && notes[0] != "" {
				for _, n := range notes {
					if strings.Contains(n, "failed") || strings.Contains(n, "error") {
						status = "fail"
						break
					}
				}
			}

			results[idx] = projectResult{
				Project: projectDir,
				Status:  status,
				Written: written,
				Notes:   notes,
			}
		}(i, proj)
	}
	wg.Wait()

	// Aggregate
	allOk := true
	var allNotes []string
	for _, r := range results {
		if r.Status != "ok" {
			allOk = false
		}
		allNotes = append(allNotes, fmt.Sprintf("%s: %s", r.Project, r.Status))
		for _, n := range r.Notes {
			allNotes = append(allNotes, fmt.Sprintf("  %s", n))
		}
	}

	status := "ok"
	if !allOk {
		status = "fail"
	}

	report := syncReport{
		Status:  status,
		Target:  manifestPath,
		Mode:    mode,
		DryRun:  dryRun,
		Written: !dryRun,
		Notes:   allNotes,
	}
	if jsonOut {
		b, _ := json.Marshal(struct {
			syncReport
			Projects []projectResult `json:"projects"`
		}{report, results})
		fmt.Println(string(b))
		if allOk {
			return 0
		}
		return 1
	}
	// Human output
	fmt.Printf("  Manifest : %s (%d projects)\n", manifestPath, len(manifest.Projects))
	fmt.Printf("  Mode     : %s\n", mode)
	fmt.Printf("  Dry-run  : %v\n", dryRun)
	for _, r := range results {
		icon := "✅"
		if r.Status != "ok" {
			icon = "❌"
		}
		fmt.Printf("  %s %s\n", icon, r.Project)
		for _, n := range r.Notes {
			fmt.Printf("    %s\n", n)
		}
	}
	if allOk {
		return 0
	}
	return 1
}

// ─── Main ─────────────────────────────────────────────────────────────────────

func main() {
	args := os.Args[1:]

	if len(args) == 0 || contains(args, "--help") || contains(args, "-h") || contains(args, "/?") {
		printHelp()
		return
	}

	subcmd := args[0]
	rest := args[1:]

	switch subcmd {
	case "install":
		os.Exit(runInstall(rest))
	case "update":
		os.Exit(runUpdate(rest))
	case "update-all":
		os.Exit(runUpdateAll(rest))
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n\n", subcmd)
		printHelp()
		os.Exit(1)
	}
}
