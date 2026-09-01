package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"
)

var (
	reSkillHeader = regexp.MustCompile(`(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$`)
	reBoldToken   = regexp.MustCompile(`(?i)\*\*([a-z][a-z0-9_-]+)\*\*`)
	reBoldClean   = regexp.MustCompile(`(?i)\*\*[a-z][a-z0-9_-]+\*\*(\s*\([^)]*\))?`)
	reSplitDelim  = regexp.MustCompile(`\s*[·|,]\s*`)
	reStrictSkill = regexp.MustCompile(`^[a-z][a-z0-9_-]+$`)
	reAntiPattern = regexp.MustCompile(`(?i)Anti-Patterns:\s*(.+)`)
	reConfigRef   = regexp.MustCompile(`(?i)config_refs:\s*(.+)`)
)

func main() {
	args := os.Args[1:]
	hasBench := contains(args, "--bench")
	hasCrossRef := contains(args, "--cross-ref") || contains(args, "--cross-ref-check") || contains(args, "--check")
	hasTokenBudget := contains(args, "--token-budget")
	hasGate := contains(args, "--gate")
	hasQuiet := contains(args, "--quiet") || contains(args, "-q")
	hasJSON := contains(args, "--json") || contains(args, "-json")
	showHelp := contains(args, "--help") || contains(args, "-h") || contains(args, "/?")

	// --gate takes precedence: single-process combined check
	if hasGate {
		repoRoot := detectRepoRoot(args)
		// gate always JSON (combined), but respect --quiet
		code := runGate(repoRoot, hasQuiet, true)
		os.Exit(code)
	}
	if hasTokenBudget {
		repoRoot := detectRepoRoot(args)
		// --token-budget outputs JSON when --json present, human otherwise; task says JSON output
		// if --json not specified, still do JSON if gate expects? but spec says flag produces JSON
		// we treat --token-budget without --json as JSON if hasJSON or default to JSON for machine parity;
		// however keep human fallback when explicitly not json: use hasJSON flag
		jsonOut := hasJSON
		// If no explicit --json, default to JSON for programmatic use but allow human if quiet not json?
		// For compatibility, if neither --json nor --quiet, output JSON as well (task defines JSON salida)
		// To preserve both, if hasTokenBudget alone without --json we still output JSON (makes verification easy)
		if !hasJSON && !hasQuiet {
			// task says JSON salida; default to JSON
			jsonOut = true
		}
		if hasJSON {
			jsonOut = true
		}
		code := runTokenBudget(repoRoot, jsonOut, hasQuiet)
		os.Exit(code)
	}

	// backwards compat: if --bench present, do bench (even if --cross-ref also present, bench takes precedence if alone)
	if hasBench && !hasCrossRef {
		runBench()
		return
	}
	if hasCrossRef || (!hasBench && !showHelp && len(args) == 0) {
		if hasCrossRef {
			repoRoot := detectRepoRoot(args)
			code := runCrossRef(repoRoot, hasQuiet, hasJSON)
			os.Exit(code)
		}
	}
	if hasBench && hasCrossRef {
		runBench()
		repoRoot := detectRepoRoot(args)
		code := runCrossRef(repoRoot, hasQuiet, hasJSON)
		os.Exit(code)
	}
	if showHelp || (!hasBench && !hasCrossRef) {
		printHelp()
		if hasBench {
			runBench()
			return
		}
		return
	}
}

func contains(arr []string, s string) bool {
	for _, v := range arr {
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

func detectRepoRoot(args []string) string {
	if v := getArgValue(args, "--repo-root"); v != "" {
		return v
	}
	if v := getArgValue(args, "--repoRoot"); v != "" {
		return v
	}
	if cwd, err := os.Getwd(); err == nil {
		if ok := hasOpenCode(cwd); ok {
			return cwd
		}
		p := cwd
		for i := 0; i < 4; i++ {
			p = filepath.Dir(p)
			if hasOpenCode(p) {
				return p
			}
		}
	}
	if exe, err := os.Executable(); err == nil {
		dir := filepath.Dir(exe)
		candidate := filepath.Dir(dir)
		if hasOpenCode(candidate) {
			return candidate
		}
		if hasOpenCode(dir) {
			return dir
		}
		p := dir
		for i := 0; i < 4; i++ {
			p = filepath.Dir(p)
			if hasOpenCode(p) {
				return p
			}
		}
	}
	if cwd, err := os.Getwd(); err == nil {
		return cwd
	}
	return "."
}

func hasOpenCode(dir string) bool {
	_, err := os.Stat(filepath.Join(dir, "opencode.json"))
	return err == nil
}

func printHelp() {
	fmt.Println("fast.exe - Go helper for cross-ref + bench")
	fmt.Println("Usage:")
	fmt.Println("  fast.exe --bench              # backwards compat bench dummy (prints bench ok)")
	fmt.Println("  fast.exe --cross-ref          # hot-path cross-ref check (<300ms)")
	fmt.Println("  fast.exe --cross-ref --json   # JSON output")
	fmt.Println("  fast.exe --cross-ref --quiet  # quiet (JSON implies quiet)")
	fmt.Println("  fast.exe --cross-ref --repo-root <path>")
	fmt.Println("  fast.exe --token-budget       # token budget check (<80ms)")
	fmt.Println("  fast.exe --token-budget --json # JSON output")
	fmt.Println("  fast.exe --gate               # combined gate crossRef+tokenBudget (<150ms)")
	fmt.Println("  fast.exe --gate --json        # JSON combined output")
}

func runBench() {
	start := time.Now()
	sum := 0
	for i := 0; i < 100000; i++ {
		sum += i * i
	}
	_ = sum
	elapsed := time.Since(start)
	fmt.Println("bench ok")
	_ = elapsed
}

// ---------- Cross-ref ----------

func runCrossRef(repoRoot string, quiet bool, jsonOut bool) int {
	start := time.Now()
	if jsonOut {
		quiet = true
	}
	errors := []string{}
	warnings := []string{}

	skillsDir := filepath.Join(repoRoot, ".agents", "skills")
	readmePath := filepath.Join(repoRoot, "README.md")
	opencodePath := filepath.Join(repoRoot, "opencode.json")

	if _, err := os.Stat(skillsDir); err != nil {
		msg := fmt.Sprintf("missing skills dir %s", skillsDir)
		errors = append(errors, msg)
		if !quiet {
			fmt.Fprintln(os.Stderr, "FATAL: "+msg)
		}
		return outputResult(quiet, jsonOut, 0, errors, warnings, 0, start, 1)
	}

	entries, err := os.ReadDir(skillsDir)
	if err != nil {
		errors = append(errors, fmt.Sprintf("read skillsDir: %v", err))
		return outputResult(quiet, jsonOut, 0, errors, warnings, 0, start, 1)
	}
	var skillNames []string
	var skillDirs []string
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		if e.Name() == "_shared" {
			continue
		}
		skillNames = append(skillNames, strings.ToLower(e.Name()))
		skillDirs = append(skillDirs, filepath.Join(skillsDir, e.Name()))
	}
	sort.Strings(skillNames)
	allSkillSet := make(map[string]bool, len(skillNames))
	for _, n := range skillNames {
		allSkillSet[n] = true
	}
	actualCount := len(skillNames)

	var ocAgents []string
	var ocAgentsAll []string
	if data, err := os.ReadFile(opencodePath); err == nil {
		var raw map[string]json.RawMessage
		if err := json.Unmarshal(data, &raw); err == nil {
			if agRaw, ok := raw["agent"]; ok {
				var agents map[string]json.RawMessage
				if err := json.Unmarshal(agRaw, &agents); err == nil {
					for k := range agents {
						ocAgentsAll = append(ocAgentsAll, k)
						if !strings.HasPrefix(k, "sdd-") {
							ocAgents = append(ocAgents, strings.ToLower(k))
						}
					}
				}
			}
		} else {
			warnings = append(warnings, fmt.Sprintf("opencode.json parse error: %v", err))
		}
	} else {
		warnings = append(warnings, fmt.Sprintf("opencode.json missing: %v", err))
	}

	if data, err := os.ReadFile(readmePath); err == nil {
		readmeLower := strings.ToLower(string(data))
		for _, ag := range ocAgents {
			if !strings.Contains(readmeLower, ag) {
				errors = append(errors, fmt.Sprintf("README missing agent '%s' from opencode.json", ag))
			}
		}
	} else {
		warnings = append(warnings, "README.md missing")
	}

	brokenRefs := []string{}
	missingConfig := []string{}
	missingSkills := []string{}
	var mu sync.Mutex
	var wg sync.WaitGroup
	origMap := map[string]string{}
	for _, e := range entries {
		if e.Name() == "_shared" {
			continue
		}
		origMap[strings.ToLower(e.Name())] = e.Name()
	}
	for i, dir := range skillDirs {
		wg.Add(1)
		go func(idx int, d string) {
			defer wg.Done()
			name := skillNames[idx]
			origName := origMap[name]
			if origName == "" {
				origName = name
			}
			mdPath := filepath.Join(d, "SKILL.md")
			contentBytes, err := os.ReadFile(mdPath)
			if err != nil {
				mu.Lock()
				missingSkills = append(missingSkills, fmt.Sprintf("Missing SKILL.md: %s", origName))
				mu.Unlock()
				return
			}
			content := string(contentBytes)
			localBroken := []string{}
			localMissing := []string{}
			refs := extractSkillRefs(content, reSkillHeader)
			for _, ref := range refs {
				if !allSkillSet[ref] {
					localBroken = append(localBroken, fmt.Sprintf("%s cross-refs '%s' missing", origName, ref))
				}
			}
			anti := extractSkillRefs(content, reAntiPattern)
			for _, ref := range anti {
				if !allSkillSet[ref] {
					localBroken = append(localBroken, fmt.Sprintf("%s anti-refs '%s' missing", origName, ref))
				}
			}
			cRefs := extractConfigRefs(content)
			for _, ref := range cRefs {
				refPath := filepath.Join(repoRoot, filepath.FromSlash(ref))
				if _, err := os.Stat(refPath); err != nil {
					localMissing = append(localMissing, fmt.Sprintf("%s config_refs '%s' missing at %s", origName, ref, refPath))
				}
			}
			if len(localBroken) > 0 || len(localMissing) > 0 {
				mu.Lock()
				brokenRefs = append(brokenRefs, localBroken...)
				missingConfig = append(missingConfig, localMissing...)
				mu.Unlock()
			}
		}(i, dir)
	}
	wg.Wait()
	if len(missingSkills) > 0 {
		warnings = append(warnings, missingSkills...)
	}

	if len(brokenRefs) > 0 {
		errors = append(errors, brokenRefs...)
	}
	if len(missingConfig) > 0 {
		errors = append(errors, missingConfig...)
	}

	return outputResult(quiet, jsonOut, actualCount, errors, warnings, len(brokenRefs), start, len(ocAgentsAll))
}

func extractSkillRefs(content string, pattern *regexp.Regexp) []string {
	m := pattern.FindStringSubmatch(content)
	if m == nil {
		return nil
	}
	raw := ""
	if len(m) > 1 {
		raw = m[1]
	}
	headerFull := m[0]
	if strings.TrimSpace(raw) == "" && strings.HasSuffix(strings.TrimSpace(headerFull), ":") {
		idx := strings.Index(content, headerFull)
		if idx >= 0 {
			after := content[idx+len(headerFull):]
			lines := strings.Split(after, "\n")
			for _, l := range lines {
				t := strings.TrimSpace(l)
				t = strings.Trim(t, "\r")
				if t != "" {
					raw = t
					break
				}
			}
		}
	}
	boldMatches := reBoldToken.FindAllStringSubmatch(raw, -1)
	boldTokens := []string{}
	for _, bm := range boldMatches {
		if len(bm) > 1 {
			boldTokens = append(boldTokens, strings.ToLower(bm[1]))
		}
	}
	hasBold := len(boldTokens) > 0
	clean := reBoldClean.ReplaceAllString(raw, " ")
	splitTokens := []string{}
	if reSplitDelim.MatchString(clean) || !hasBold {
		parts := reSplitDelim.Split(clean, -1)
		for _, p := range parts {
			t := strings.TrimSpace(p)
			t = strings.ToLower(t)
			if t == "" {
				continue
			}
			if reStrictSkill.MatchString(t) {
				splitTokens = append(splitTokens, t)
			}
		}
	}
	seen := map[string]bool{}
	out := []string{}
	for _, tok := range append(boldTokens, splitTokens...) {
		if !seen[tok] {
			seen[tok] = true
			out = append(out, tok)
		}
	}
	return out
}

func extractConfigRefs(content string) []string {
	m := reConfigRef.FindStringSubmatch(content)
	if m == nil {
		return nil
	}
	raw := ""
	if len(m) > 1 {
		raw = m[1]
	}
	parts := reSplitDelim.Split(raw, -1)
	out := []string{}
	for _, p := range parts {
		t := strings.TrimSpace(p)
		if t != "" {
			out = append(out, t)
		}
	}
	return out
}

func outputResult(quiet, jsonOut bool, canonicalSkills int, errors, warnings []string, broken int, start time.Time, agentsCount int) int {
	elapsed := time.Since(start)
	allClean := len(errors) == 0 && len(warnings) == 0
	exitCode := 0
	if len(errors) > 0 {
		exitCode = 1
	}
	if jsonOut {
		res := map[string]interface{}{
			"timestamp":       time.Now().Format(time.RFC3339),
			"canonicalSkills": canonicalSkills,
			"agents":          agentsCount,
			"errors":          errors,
			"warnings":        warnings,
			"brokenCrossRefs": broken,
			"allClean":        allClean,
			"elapsedMs":       elapsed.Milliseconds(),
		}
		b, _ := json.MarshalIndent(res, "", "  ")
		fmt.Println(string(b))
		return exitCode
	}
	if quiet {
		return exitCode
	}
	if allClean {
		fmt.Printf("OK ALL CHECKS PASSED (%d skills, %d agents) in %dms\n", canonicalSkills, agentsCount, elapsed.Milliseconds())
	} else {
		if len(errors) > 0 {
			fmt.Printf("ERRORS (%d):\n", len(errors))
			for _, e := range errors {
				fmt.Printf(" * %s\n", e)
			}
		}
		if len(warnings) > 0 {
			fmt.Printf("WARNINGS (%d):\n", len(warnings))
			for _, w := range warnings {
				fmt.Printf(" * %s\n", w)
			}
		}
		fmt.Printf("checked %d skills in %dms\n", canonicalSkills, elapsed.Milliseconds())
	}
	return exitCode
}

// ---------- Token budget ----------

type SkillStats struct {
	Count           int  `json:"count"`
	Average         int  `json:"average"`
	Budget          int  `json:"budget"`
	UnderBudget     int  `json:"underBudget"`
	OverBudgetFiles int  `json:"overBudgetFiles"`
	Passed          bool `json:"passed"`
}

type PromptStats struct {
	Count             int      `json:"count"`
	Average           int      `json:"average"`
	Budget            int      `json:"budget"`
	UnderBudget       int      `json:"underBudget"`
	OverBudgetFiles   int      `json:"overBudgetFiles"`
	Passed            bool     `json:"passed"`
	CmdCount          int      `json:"cmdCount"`
	CmdOver3KB        int      `json:"cmdOver3KB"`
	CmdOver5KB        int      `json:"cmdOver5KB"`
	PrOver3KB         int      `json:"prOver3KB"`
	PrOver5KB         int      `json:"prOver5KB"`
	OverweightPenalty int      `json:"overweightPenalty"`
	OverweightFiles   []string `json:"overweightFiles"`
	H019Passed        bool     `json:"h019Passed"`
}

type tokenBudgetInternal struct {
	Skills     *SkillStats  `json:"skills,omitempty"`
	Prompts    *PromptStats `json:"prompts,omitempty"`
	Passed     bool         `json:"passed"`
	Budget     int          `json:"budget"`
	Violations []string     `json:"violations"`
	ElapsedMs  int64        `json:"elapsedMs"`
	Stats      map[string]interface{} `json:"stats,omitempty"`
}

func computeTokenBudget(repoRoot string) (SkillStats, *SkillStats, PromptStats, *PromptStats, []string, map[string]interface{}) {
	const BudgetBytes = 3200
	const PromptBudgetBytes = 4000

	violations := []string{}
	statsMap := make(map[string]interface{})

	// --- skills ---
	skillsPath := filepath.Join(repoRoot, ".agents", "skills")
	var skillSizes []int64
	if fi, err := os.Stat(skillsPath); err == nil && fi.IsDir() {
		_ = filepath.WalkDir(skillsPath, func(path string, d os.DirEntry, err error) error {
			if err != nil {
				return nil
			}
			if !d.IsDir() && strings.EqualFold(filepath.Base(path), "SKILL.md") {
				if info, err := d.Info(); err == nil {
					skillSizes = append(skillSizes, info.Size())
				} else if info2, err2 := os.Stat(path); err2 == nil {
					skillSizes = append(skillSizes, info2.Size())
				}
			}
			return nil
		})
	}

	var skillStats *SkillStats
	var skillVal SkillStats
	if len(skillSizes) > 0 {
		var sum int64
		for _, s := range skillSizes {
			sum += s
		}
		avg := int(math.Round(float64(sum) / float64(len(skillSizes))))
		over := 0
		under := 0
		for _, s := range skillSizes {
			if s > BudgetBytes {
				over++
			} else {
				under++
			}
		}
		skillVal = SkillStats{
			Count: len(skillSizes), Average: avg, Budget: BudgetBytes,
			UnderBudget: under, OverBudgetFiles: over, Passed: avg <= BudgetBytes,
		}
		skillStats = &skillVal
		statsMap["skills"] = skillVal
		if avg > BudgetBytes {
			violations = append(violations, fmt.Sprintf("skills avg %dB exceeds %d B budget (%d files over)", avg, BudgetBytes, over))
		}
	}

	// --- prompts + commands ---
	promptsPath := filepath.Join(repoRoot, "prompts")
	commandsPath := filepath.Join(repoRoot, "commands")

	promptFileInfos := collectMdPromptFiles(promptsPath)
	cmdFileInfos := collectMdPromptFiles(commandsPath)

	var promptStats *PromptStats
	var promptVal PromptStats
	if len(promptFileInfos) > 0 {
		var sum int64
		for _, f := range promptFileInfos {
			sum += f.size
		}
		avgPrompt := int(math.Round(float64(sum) / float64(len(promptFileInfos))))
		overBudgetPrompt := 0
		underBudgetPrompt := 0
		for _, f := range promptFileInfos {
			if f.size > PromptBudgetBytes {
				overBudgetPrompt++
			} else {
				underBudgetPrompt++
			}
		}
		cmdOver3KB := 0
		cmdOver5KB := 0
		for _, f := range cmdFileInfos {
			if f.size > 3072 {
				cmdOver3KB++
			}
			if f.size > 5120 {
				cmdOver5KB++
			}
		}
		prOver3KB := 0
		prOver5KB := 0
		for _, f := range promptFileInfos {
			if f.size > 3072 {
				prOver3KB++
			}
			if f.size > 5120 {
				prOver5KB++
			}
		}
		overweightPenalty := 0
		if cmdOver5KB > 0 || prOver5KB > 0 {
			overweightPenalty = 2
		} else if cmdOver3KB > 2 || prOver3KB > 1 {
			overweightPenalty = 1
		}
		// overweightFiles: union where >3072, relative to repoRoot
		var overweightFiles []string
		allOver := append([]fileInfo{}, promptFileInfos...)
		allOver = append(allOver, cmdFileInfos...)
		for _, f := range allOver {
			if f.size > 3072 {
				rel, err := filepath.Rel(repoRoot, f.path)
				if err != nil {
					rel = f.path
				}
				rel = filepath.ToSlash(rel)
				overweightFiles = append(overweightFiles, rel)
			}
		}
		if overweightFiles == nil {
			overweightFiles = []string{}
		}
		sort.Strings(overweightFiles)

		promptVal = PromptStats{
			Count: len(promptFileInfos), Average: avgPrompt, Budget: PromptBudgetBytes,
			UnderBudget: underBudgetPrompt, OverBudgetFiles: overBudgetPrompt, Passed: avgPrompt <= PromptBudgetBytes,
			CmdCount: len(cmdFileInfos), CmdOver3KB: cmdOver3KB, CmdOver5KB: cmdOver5KB,
			PrOver3KB: prOver3KB, PrOver5KB: prOver5KB,
			OverweightPenalty: overweightPenalty, OverweightFiles: overweightFiles,
			H019Passed: overweightPenalty == 0,
		}
		promptStats = &promptVal
		statsMap["prompts"] = promptVal
		if avgPrompt > PromptBudgetBytes {
			violations = append(violations, fmt.Sprintf("prompts avg %dB exceeds %d B budget (%d files over)", avgPrompt, PromptBudgetBytes, overBudgetPrompt))
		}
		if overweightPenalty > 0 {
			// replicate PS overweightFiles join
			filesJoined := strings.Join(overweightFiles, ", ")
			violations = append(violations, fmt.Sprintf("H-019 overweight penalty %d — prompts>3072: %d, cmds>3072: %d, >5120: pr %d/cmd %d; files: %s", overweightPenalty, prOver3KB, cmdOver3KB, prOver5KB, cmdOver5KB, filesJoined))
		}
	} else {
		// still need to populate cmd counts even if no prompts? PS only does prompt block if promptFiles.Count>0,
		// so if zero prompts, prompts stats nil. But we still want cmd counts reflected? Keep nil.
	}

	return skillVal, skillStats, promptVal, promptStats, violations, statsMap
}

type fileInfo struct {
	path string
	size int64
}

func collectMdPromptFiles(root string) []fileInfo {
	var out []fileInfo
	if fi, err := os.Stat(root); err != nil || !fi.IsDir() {
		return out
	}
	_ = filepath.WalkDir(root, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if d.IsDir() {
			return nil
		}
		ext := strings.ToLower(filepath.Ext(path))
		if ext == ".md" || ext == ".prompt" {
			if info, err := d.Info(); err == nil {
				out = append(out, fileInfo{path: path, size: info.Size()})
			} else if info2, err2 := os.Stat(path); err2 == nil {
				out = append(out, fileInfo{path: path, size: info2.Size()})
			}
		}
		return nil
	})
	return out
}

func runTokenBudget(repoRoot string, jsonOut bool, quiet bool) int {
	start := time.Now()
	skillVal, skillStats, promptVal, promptStats, violations, statsMap := computeTokenBudget(repoRoot)
	passed := len(violations) == 0
	elapsed := time.Since(start)

	// violations nil -> empty slice for JSON
	if violations == nil {
		violations = []string{}
	}

	exitCode := 0
	if !passed {
		exitCode = 1
	}

	if jsonOut {
		// Build output matching PS shape plus top-level convenience fields
		// PS: {passed, budget, violations, stats:{skills,prompts}}
		// plus task spec: {skills,prompts,passed,elapsedMs}
		out := map[string]interface{}{
			"passed":     passed,
			"budget":     3200,
			"violations": violations,
			"stats":      statsMap,
			"elapsedMs":  elapsed.Milliseconds(),
			"timestamp":  time.Now().Format(time.RFC3339),
		}
		// top-level convenience (task spec)
		if skillStats != nil {
			out["skills"] = skillVal
		} else {
			// empty skills
			out["skills"] = SkillStats{Count: 0, Average: 0, Budget: 3200, Passed: true}
		}
		if promptStats != nil {
			out["prompts"] = promptVal
		} else {
			out["prompts"] = PromptStats{Count: 0, Average: 0, Budget: 4000, Passed: true, OverweightFiles: []string{}, H019Passed: true}
		}
		b, _ := json.Marshal(out)
		fmt.Println(string(b))
		return exitCode
	}
	if quiet {
		return exitCode
	}
	// human-readable (mirrors PS)
	if passed {
		avgS := 0
		avgP := 0
		penalty := 0
		if skillStats != nil {
			avgS = skillStats.Average
		}
		if promptStats != nil {
			avgP = promptStats.Average
			penalty = promptStats.OverweightPenalty
		}
		budgetP := 4000
		if promptStats != nil {
			budgetP = promptStats.Budget
		}
		fmt.Printf("OK   Token budget: skills %dB/3200 (avg), prompts %dB/%d (avg), H-019 overweight penalty %d\n", avgS, avgP, budgetP, penalty)
	} else {
		fmt.Println("FAIL Token budget exceeded (skills 3200 avg / H-019 overweight):")
		for _, v := range violations {
			fmt.Printf("   X  %s\n", v)
		}
	}
	return exitCode
}

// ---------- Gate ----------

func runGate(repoRoot string, quiet bool, jsonOut bool) int {
	start := time.Now()

	// Run cross-ref internal (without printing) and token budget internal
	// We need to capture crossRef data without duplicate print
	crossStart := time.Now()
	crossRes := computeCrossRefForGate(repoRoot, crossStart)
	tokenStart := time.Now()
	skillVal, skillStats, promptVal, promptStats, violations, statsMap := computeTokenBudget(repoRoot)
	tokenElapsed := time.Since(tokenStart)
	if violations == nil {
		violations = []string{}
	}
	tokenPassed := len(violations) == 0

	// build tokenBudget object similar to runTokenBudget JSON but nested
	tokenBudgetObj := map[string]interface{}{
		"passed":     tokenPassed,
		"budget":     3200,
		"violations": violations,
		"stats":      statsMap,
		"elapsedMs":  tokenElapsed.Milliseconds(),
	}
	if skillStats != nil {
		tokenBudgetObj["skills"] = skillVal
	} else {
		tokenBudgetObj["skills"] = SkillStats{Count: 0, Average: 0, Budget: 3200, Passed: true}
	}
	if promptStats != nil {
		tokenBudgetObj["prompts"] = promptVal
	} else {
		tokenBudgetObj["prompts"] = PromptStats{Count: 0, Average: 0, Budget: 4000, Passed: true, OverweightFiles: []string{}, H019Passed: true}
	}

	gatePassed := crossRes.AllClean && tokenPassed
	elapsed := time.Since(start)

	if jsonOut {
		// crossRef object mirroring outputResult JSON shape
		crossObj := map[string]interface{}{
			"timestamp":       crossRes.Timestamp,
			"canonicalSkills": crossRes.CanonicalSkills,
			"agents":          crossRes.Agents,
			"errors":          crossRes.Errors,
			"warnings":        crossRes.Warnings,
			"brokenCrossRefs": crossRes.BrokenCrossRefs,
			"allClean":        crossRes.AllClean,
			"elapsedMs":       crossRes.ElapsedMs,
		}
		combined := map[string]interface{}{
			"crossRef":    crossObj,
			"tokenBudget": tokenBudgetObj,
			"passed":      gatePassed,
			"elapsedMs":   elapsed.Milliseconds(),
			"timestamp":   time.Now().Format(time.RFC3339),
		}
		// Ensure errors/warnings are not nil
		b, _ := json.Marshal(combined)
		fmt.Println(string(b))
		if gatePassed {
			return 0
		}
		return 1
	}
	if quiet {
		if gatePassed {
			return 0
		}
		return 1
	}
	// human
	if gatePassed {
		fmt.Printf("OK GATE passed (crossRef %d skills, tokenBudget) in %dms\n", crossRes.CanonicalSkills, elapsed.Milliseconds())
	} else {
		fmt.Printf("FAIL GATE in %dms\n", elapsed.Milliseconds())
		if !crossRes.AllClean {
			fmt.Printf(" crossRef errors: %d warnings: %d\n", len(crossRes.Errors), len(crossRes.Warnings))
		}
		if !tokenPassed {
			for _, v := range violations {
				fmt.Printf(" tokenBudget: %s\n", v)
			}
		}
	}
	if gatePassed {
		return 0
	}
	return 1
}

type gateCrossRef struct {
	Timestamp       string
	CanonicalSkills int
	Agents          int
	Errors          []string
	Warnings        []string
	BrokenCrossRefs int
	AllClean        bool
	ElapsedMs       int64
}

func computeCrossRefForGate(repoRoot string, start time.Time) gateCrossRef {
	errors := []string{}
	warnings := []string{}
	skillsDir := filepath.Join(repoRoot, ".agents", "skills")
	readmePath := filepath.Join(repoRoot, "README.md")
	opencodePath := filepath.Join(repoRoot, "opencode.json")

	if _, err := os.Stat(skillsDir); err != nil {
		msg := fmt.Sprintf("missing skills dir %s", skillsDir)
		errors = append(errors, msg)
		elapsed := time.Since(start)
		if errors == nil {
			errors = []string{}
		}
		if warnings == nil {
			warnings = []string{}
		}
		return gateCrossRef{Timestamp: time.Now().Format(time.RFC3339), CanonicalSkills: 0, Agents: 0, Errors: errors, Warnings: warnings, BrokenCrossRefs: 0, AllClean: false, ElapsedMs: elapsed.Milliseconds()}
	}
	entries, err := os.ReadDir(skillsDir)
	if err != nil {
		errors = append(errors, fmt.Sprintf("read skillsDir: %v", err))
		elapsed := time.Since(start)
		return gateCrossRef{Timestamp: time.Now().Format(time.RFC3339), Errors: errors, Warnings: warnings, AllClean: false, ElapsedMs: elapsed.Milliseconds()}
	}
	var skillNames []string
	var skillDirs []string
	for _, e := range entries {
		if !e.IsDir() || e.Name() == "_shared" {
			continue
		}
		skillNames = append(skillNames, strings.ToLower(e.Name()))
		skillDirs = append(skillDirs, filepath.Join(skillsDir, e.Name()))
	}
	sort.Strings(skillNames)
	allSkillSet := make(map[string]bool, len(skillNames))
	for _, n := range skillNames {
		allSkillSet[n] = true
	}
	actualCount := len(skillNames)

	var ocAgents []string
	var ocAgentsAll []string
	if data, err := os.ReadFile(opencodePath); err == nil {
		var raw map[string]json.RawMessage
		if err := json.Unmarshal(data, &raw); err == nil {
			if agRaw, ok := raw["agent"]; ok {
				var agents map[string]json.RawMessage
				if err := json.Unmarshal(agRaw, &agents); err == nil {
					for k := range agents {
						ocAgentsAll = append(ocAgentsAll, k)
						if !strings.HasPrefix(k, "sdd-") {
							ocAgents = append(ocAgents, strings.ToLower(k))
						}
					}
				}
			}
		} else {
			warnings = append(warnings, fmt.Sprintf("opencode.json parse error: %v", err))
		}
	} else {
		warnings = append(warnings, fmt.Sprintf("opencode.json missing: %v", err))
	}
	if data, err := os.ReadFile(readmePath); err == nil {
		readmeLower := strings.ToLower(string(data))
		for _, ag := range ocAgents {
			if !strings.Contains(readmeLower, ag) {
				errors = append(errors, fmt.Sprintf("README missing agent '%s' from opencode.json", ag))
			}
		}
	} else {
		warnings = append(warnings, "README.md missing")
	}
	brokenRefs := []string{}
	missingConfig := []string{}
	missingSkills := []string{}
	var mu sync.Mutex
	var wg sync.WaitGroup
	origMap := map[string]string{}
	for _, e := range entries {
		if e.Name() == "_shared" {
			continue
		}
		origMap[strings.ToLower(e.Name())] = e.Name()
	}
	for i, dir := range skillDirs {
		wg.Add(1)
		go func(idx int, d string) {
			defer wg.Done()
			name := skillNames[idx]
			origName := origMap[name]
			if origName == "" {
				origName = name
			}
			mdPath := filepath.Join(d, "SKILL.md")
			contentBytes, err := os.ReadFile(mdPath)
			if err != nil {
				mu.Lock()
				missingSkills = append(missingSkills, fmt.Sprintf("Missing SKILL.md: %s", origName))
				mu.Unlock()
				return
			}
			content := string(contentBytes)
			localBroken := []string{}
			localMissing := []string{}
			refs := extractSkillRefs(content, reSkillHeader)
			for _, ref := range refs {
				if !allSkillSet[ref] {
					localBroken = append(localBroken, fmt.Sprintf("%s cross-refs '%s' missing", origName, ref))
				}
			}
			anti := extractSkillRefs(content, reAntiPattern)
			for _, ref := range anti {
				if !allSkillSet[ref] {
					localBroken = append(localBroken, fmt.Sprintf("%s anti-refs '%s' missing", origName, ref))
				}
			}
			cRefs := extractConfigRefs(content)
			for _, ref := range cRefs {
				refPath := filepath.Join(repoRoot, filepath.FromSlash(ref))
				if _, err := os.Stat(refPath); err != nil {
					localMissing = append(localMissing, fmt.Sprintf("%s config_refs '%s' missing at %s", origName, ref, refPath))
				}
			}
			if len(localBroken) > 0 || len(localMissing) > 0 {
				mu.Lock()
				brokenRefs = append(brokenRefs, localBroken...)
				missingConfig = append(missingConfig, localMissing...)
				mu.Unlock()
			}
		}(i, dir)
	}
	wg.Wait()
	if len(missingSkills) > 0 {
		warnings = append(warnings, missingSkills...)
	}
	if len(brokenRefs) > 0 {
		errors = append(errors, brokenRefs...)
	}
	if len(missingConfig) > 0 {
		errors = append(errors, missingConfig...)
	}
	if errors == nil {
		errors = []string{}
	}
	if warnings == nil {
		warnings = []string{}
	}
	elapsed := time.Since(start)
	allClean := len(errors) == 0 && len(warnings) == 0
	return gateCrossRef{
		Timestamp: time.Now().Format(time.RFC3339), CanonicalSkills: actualCount, Agents: len(ocAgentsAll),
		Errors: errors, Warnings: warnings, BrokenCrossRefs: len(brokenRefs), AllClean: allClean, ElapsedMs: elapsed.Milliseconds(),
	}
}
