package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

const (
	modeFast = "fast"
	modeSlow = "slow"
)

// Checker holds the checker state
type Checker struct {
	specRoot string
	mode     string
	errors   []string
}

// NewChecker creates a new checker instance
// PRECONDITION: specRoot must be repo root (contains cue.mod/module.cue and spec/)
func NewChecker(specRoot, mode string) *Checker {
	// Validate specRoot is a real repo root
	// This catches WD mistakes early (KISS: fail fast with clear message)
	cueModPath := filepath.Join(specRoot, "cue.mod", "module.cue")
	specPath := filepath.Join(specRoot, "spec")
	
	if _, err := os.Stat(cueModPath); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "ERROR: Missing cue.mod/module.cue at %s\n", cueModPath)
		fmt.Fprintf(os.Stderr, "spec-lint requires repo root path (containing cue.mod/module.cue)\n")
		fmt.Fprintf(os.Stderr, "Usage: spec-lint <repo-root> --mode <fast|slow>\n")
		os.Exit(1)
	}
	if _, err := os.Stat(specPath); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "ERROR: Missing spec/ directory at %s\n", specPath)
		fmt.Fprintf(os.Stderr, "spec-lint requires repo root path (containing spec/)\n")
		fmt.Fprintf(os.Stderr, "Usage: spec-lint <repo-root> --mode <fast|slow>\n")
		os.Exit(1)
	}

	return &Checker{
		specRoot: specRoot,
		mode:     mode,
		errors:   []string{},
	}
}

// execCueEval runs cue eval with proper error handling
func (c *Checker) execCueEval(args ...string) ([]byte, error) {
	cuePath, err := exec.LookPath("cue")
	if err != nil {
		return nil, fmt.Errorf("cue not found in PATH: %w (run via 'nix develop -c')", err)
	}

	cmd := exec.Command(cuePath, args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	cmd.Dir = c.specRoot

	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("cue eval failed: %w (stderr: %s)", err, stderr.String())
	}

	return stdout.Bytes(), nil
}

// logError adds an error message
func (c *Checker) logError(msg string) {
	c.errors = append(c.errors, msg)
	fmt.Fprintf(os.Stderr, "ERROR: %s\n", msg)
}

// logInfo outputs informational message
func (c *Checker) logInfo(msg string) {
	fmt.Fprintf(os.Stderr, "INFO: %s\n", msg)
}

// Run executes the appropriate check mode
func (c *Checker) Run() error {
	switch c.mode {
	case modeFast:
		return c.runFast()
	case modeSlow:
		return c.runSlow()
	default:
		return fmt.Errorf("unknown mode: %s", c.mode)
	}
}

// runFast performs fast checks: feat-id/env-id dedup + naming validation
func (c *Checker) runFast() error {
	c.logInfo("Mode: FAST (feat-id/env-id dedup + naming validation)")

	// Collect feat-ids and validate slugs
	c.logInfo("Scanning feat-ids...")
	featIDs := make(map[string][]string) // id -> []files
	err := c.scanFeatIDs(featIDs)
	if err != nil {
		c.logError(fmt.Sprintf("Failed to scan feat-ids: %v", err))
		return err
	}

	// CRITICAL: featCount == 0 means extraction failed (cannot verify dedup)
	featCount := len(featIDs)
	if featCount == 0 {
		c.logError("No feat-ids extracted (CUE eval failed, fallback exhausted)")
		c.logError("Cannot verify dedup check - inspection required")
		return nil // Continue to report other errors, but this is a FAIL
	}

	// Check for duplicates
	for id, files := range featIDs {
		if len(files) > 1 {
			c.logError(fmt.Sprintf("feat-id '%s' defined in multiple files: %v", id, files))
		}
	}

	if len(c.errors) == 0 {
		c.logInfo(fmt.Sprintf("✅ No feat-id duplicates (%d unique)", featCount))
	}

	// Validate feat slugs (kebab-case)
	c.logInfo("Validating feat slug naming...")
	err = c.validateFeatSlugs()
	if err != nil {
		c.logError(fmt.Sprintf("Failed to validate feat slugs: %v", err))
		return err
	}

	if len(c.errors) == 0 {
		c.logInfo("✅ All feat slugs are valid (kebab-case)")
	}

	// Collect env-ids
	c.logInfo("Scanning env-ids...")
	envIDs := make(map[string][]string) // id -> []files
	err = c.scanEnvIDs(envIDs)
	if err != nil {
		c.logError(fmt.Sprintf("Failed to scan env-ids: %v", err))
		return err
	}

	// Check for duplicates
	for id, files := range envIDs {
		if len(files) > 1 {
			c.logError(fmt.Sprintf("env-id '%s' defined in multiple files: %v", id, files))
		}
	}

	if len(c.errors) == 0 {
		c.logInfo("✅ No env-id duplicates")
	}

	return nil
}

// runSlow performs slow checks: fast + broken refs + circular deps
func (c *Checker) runSlow() error {
	c.logInfo("Mode: SLOW (feat-id/env-id dedup + refs + circular-deps)")

	// Run fast mode first
	if err := c.runFast(); err != nil {
		return err
	}

	// Check for broken references
	c.logInfo("Scanning for broken references...")
	err := c.checkBrokenReferences()
	if err != nil {
		c.logError(fmt.Sprintf("Failed to check references: %v", err))
		return err
	}

	if len(c.errors) == 0 {
		c.logInfo("✅ No broken references found")
	}

	// Check for circular dependencies
	c.logInfo("Scanning for circular dependencies...")
	err = c.checkCircularDeps()
	if err != nil {
		c.logError(fmt.Sprintf("Failed to check circular deps: %v", err))
		return err
	}

	if len(c.errors) == 0 {
		c.logInfo("✅ No circular dependencies found")
	}

	return nil
}

// scanFeatIDs scans spec/urn/feat/ for feat-ids using cue eval
func (c *Checker) scanFeatIDs(featIDs map[string][]string) error {
	featPath := filepath.Join(c.specRoot, "spec", "urn", "feat")
	if _, err := os.Stat(featPath); os.IsNotExist(err) {
		return nil // No feat directory, that's ok
	}

	// Use cue eval to extract all features at once (more reliable than file-by-file parsing)
	features, err := c.evalFeaturesViaCue()
	if err != nil {
		c.logInfo(fmt.Sprintf("cue eval failed (reason: %v), trying fallback", err))
		// Fallback: walk directory and extract via regex
		walkErr := c.scanFeatIDsViaWalk(featIDs)
		if walkErr != nil {
			c.logInfo(fmt.Sprintf("fallback also failed: %v", walkErr))
		}
		return walkErr
	}

	c.logInfo(fmt.Sprintf("cue eval extracted %d features via canonical approach", len(features)))

	for id, filepath := range features {
		if id != "" {
			featIDs[id] = append(featIDs[id], filepath)
		}
	}

	return nil
}

// evalFeaturesViaCue uses cue eval to extract all features (canonical approach)
func (c *Checker) evalFeaturesViaCue() (map[string]string, error) {
	features := make(map[string]string)

	// Run: cue eval ./spec/urn/feat/... -e 'feature' --out json
	output, err := c.execCueEval("eval", "./spec/urn/feat/...", "-e", "feature", "--out", "json")
	if err != nil {
		return nil, err
	}

	// Parse NDJSON output (newline-delimited JSON, not array)
	decoder := json.NewDecoder(bytes.NewReader(output))
	for decoder.More() {
		var feat struct {
			ID   string `json:"id"`
			Slug string `json:"slug"`
		}
		if err := decoder.Decode(&feat); err != nil {
			return nil, fmt.Errorf("failed to parse cue eval output: %w", err)
		}
		if feat.ID != "" {
			// Store slug as filepath indicator (not exact, but indicates source)
			features[feat.ID] = filepath.Join(c.specRoot, "spec/urn/feat", feat.Slug, "feature.cue")
		}
	}

	return features, nil
}

// scanFeatIDsViaWalk fallback: walk directory tree
func (c *Checker) scanFeatIDsViaWalk(featIDs map[string][]string) error {
	featPath := filepath.Join(c.specRoot, "spec", "urn", "feat")

	err := filepath.WalkDir(featPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.Name() == "feature.cue" && !d.IsDir() {
			id, err := c.extractIDRegex(path, `^\s*id:\s*"([^"]+)"`)
			if err != nil {
				return err
			}
			if id != "" {
				featIDs[id] = append(featIDs[id], path)
			}
		}
		return nil
	})

	return err
}

// scanEnvIDs scans spec/urn/env/ for env-ids using cue eval
func (c *Checker) scanEnvIDs(envIDs map[string][]string) error {
	envPath := filepath.Join(c.specRoot, "spec", "urn", "env")
	if _, err := os.Stat(envPath); os.IsNotExist(err) {
		return nil // No env directory, that's ok
	}

	// Use cue eval to extract all environments (more reliable)
	environments, err := c.evalEnvironmentsViaCue()
	if err != nil {
		c.logInfo(fmt.Sprintf("cue eval failed for env, trying fallback: %v", err))
		// Fallback: walk directory and extract via regex
		return c.scanEnvIDsViaWalk(envIDs)
	}

	for id, filepath := range environments {
		if id != "" {
			envIDs[id] = append(envIDs[id], filepath)
		}
	}

	return nil
}

// evalEnvironmentsViaCue uses cue eval to extract all environments (canonical approach)
func (c *Checker) evalEnvironmentsViaCue() (map[string]string, error) {
	environments := make(map[string]string)

	// Run: cue eval ./spec/urn/env/... -e 'environment' --out json
	output, err := c.execCueEval("eval", "./spec/urn/env/...", "-e", "environment", "--out", "json")
	if err != nil {
		return nil, err
	}

	// Parse NDJSON output (newline-delimited JSON, not array)
	decoder := json.NewDecoder(bytes.NewReader(output))
	for decoder.More() {
		var env struct {
			EnvID string `json:"envId"`
		}
		if err := decoder.Decode(&env); err != nil {
			return nil, fmt.Errorf("failed to parse cue eval output: %w", err)
		}
		if env.EnvID != "" {
			environments[env.EnvID] = "spec/urn/env"
		}
	}

	return environments, nil
}

// scanEnvIDsViaWalk fallback: walk directory tree
func (c *Checker) scanEnvIDsViaWalk(envIDs map[string][]string) error {
	envPath := filepath.Join(c.specRoot, "spec", "urn", "env")

	err := filepath.WalkDir(envPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.Name() == "environment.cue" && !d.IsDir() {
			id, err := c.extractIDRegex(path, `^\s*envId:\s*"([^"]+)"`)
			if err != nil {
				return err
			}
			if id != "" {
				envIDs[id] = append(envIDs[id], path)
			}
		}
		return nil
	})

	return err
}





// extractIDRegex extracts ID using regex as fallback
func (c *Checker) extractIDRegex(filePath string, pattern string) (string, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return "", err
	}

	re := regexp.MustCompile(pattern)
	matches := re.FindStringSubmatch(string(content))
	if len(matches) > 1 {
		return matches[1], nil
	}
	return "", nil
}

// validateFeatSlugs validates that all feature slugs are in kebab-case
func (c *Checker) validateFeatSlugs() error {
	featPath := filepath.Join(c.specRoot, "spec", "urn", "feat")
	if _, err := os.Stat(featPath); os.IsNotExist(err) {
		return nil // No feat directory
	}

	// Use cue eval to get all slugs
	slugs, err := c.evalSlugsViaCue()
	if err != nil {
		c.logInfo(fmt.Sprintf("cue eval failed for slugs, trying fallback: %v", err))
		// Fallback: walk directory
		return c.validateFeatSlugsViaWalk()
	}

	// Kebab-case pattern: lowercase letters, digits, and hyphens
	kebabCasePattern := regexp.MustCompile(`^[a-z0-9]+(-[a-z0-9]+)*$`)

	for slug, filePath := range slugs {
		if slug != "" && !kebabCasePattern.MatchString(slug) {
			c.logError(fmt.Sprintf("feat slug '%s' is not in kebab-case format (file: %s)", slug, filePath))
		}
	}

	return nil
}

// evalSlugsViaCue extracts all feature slugs via cue eval
func (c *Checker) evalSlugsViaCue() (map[string]string, error) {
	slugs := make(map[string]string)

	// Run: cue eval ./spec/urn/feat/... -e 'feature' --out json
	output, err := c.execCueEval("eval", "./spec/urn/feat/...", "-e", "feature", "--out", "json")
	if err != nil {
		return nil, err
	}

	// Parse NDJSON output (newline-delimited JSON, not array)
	decoder := json.NewDecoder(bytes.NewReader(output))
	for decoder.More() {
		var feat struct {
			Slug string `json:"slug"`
		}
		if err := decoder.Decode(&feat); err != nil {
			return nil, fmt.Errorf("failed to parse cue eval output: %w", err)
		}
		if feat.Slug != "" {
			slugs[feat.Slug] = filepath.Join(c.specRoot, "spec/urn/feat", feat.Slug, "feature.cue")
		}
	}

	return slugs, nil
}

// validateFeatSlugsViaWalk fallback: walk directory tree
func (c *Checker) validateFeatSlugsViaWalk() error {
	featPath := filepath.Join(c.specRoot, "spec", "urn", "feat")
	kebabCasePattern := regexp.MustCompile(`^[a-z0-9]+(-[a-z0-9]+)*$`)

	err := filepath.WalkDir(featPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.Name() == "feature.cue" && !d.IsDir() {
			slug, err := c.extractIDRegex(path, `^\s*slug:\s*"([^"]+)"`)
			if err != nil {
				return err
			}
			if slug != "" && !kebabCasePattern.MatchString(slug) {
				c.logError(fmt.Sprintf("feat slug '%s' is not in kebab-case format (file: %s)", slug, path))
			}
		}
		return nil
	})

	return err
}

// checkBrokenReferences checks for broken urn:feat:* references
func (c *Checker) checkBrokenReferences() error {
	// First, collect all valid feat-ids using cue eval
	validFeatMap, err := c.evalFeaturesViaCue()
	if err != nil {
		c.logInfo(fmt.Sprintf("cue eval failed for refs check, trying fallback: %v", err))
		validFeatMap = make(map[string]string)
	}
	validFeats := make(map[string]bool)
	for id := range validFeatMap {
		validFeats[id] = true
	}

	// Now scan for references in adapter/ and mapping/
	pathsToScan := []string{
		filepath.Join(c.specRoot, "spec", "adapter"),
		filepath.Join(c.specRoot, "spec", "mapping"),
	}

	refPattern := regexp.MustCompile(`urn:feat:([a-z0-9-]+)`)

	for _, scanPath := range pathsToScan {
		if _, err := os.Stat(scanPath); os.IsNotExist(err) {
			continue // Skip if path doesn't exist
		}

		err := filepath.WalkDir(scanPath, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}

			if !d.IsDir() && strings.HasSuffix(path, ".cue") {
				content, err := os.ReadFile(path)
				if err != nil {
					return err
				}

				matches := refPattern.FindAllStringSubmatch(string(content), -1)
				for _, match := range matches {
					ref := "urn:feat:" + match[1]
					if !validFeats[ref] {
						c.logError(fmt.Sprintf("Broken reference to '%s' in file '%s'", ref, path))
					}
				}
			}
			return nil
		})

		if err != nil {
			return err
		}
	}

	return nil
}

// checkCircularDeps checks for circular dependencies using the deps field
func (c *Checker) checkCircularDeps() error {
	// Collect all features with their dependencies
	features := make(map[string][]string) // feat-id -> []deps

	featPath := filepath.Join(c.specRoot, "spec", "urn", "feat")
	if _, err := os.Stat(featPath); os.IsNotExist(err) {
		return nil // No feat directory
	}

	// Use cue eval to extract features with dependencies
	features, err := c.evalFeaturesWithDepsViaCue()
	if err != nil {
		c.logInfo(fmt.Sprintf("cue eval failed for deps, trying fallback: %v", err))
		// Fallback: walk directory (less reliable for deps extraction)
		features = make(map[string][]string)
	}

	if err != nil {
		return err
	}

	// Check for circular dependencies using DFS
	visited := make(map[string]bool)
	recStack := make(map[string]bool)

	for featID := range features {
		if !visited[featID] {
			if c.hasCycle(featID, features, visited, recStack) {
				c.logError(fmt.Sprintf("Circular dependency detected involving feature '%s'", featID))
			}
		}
	}

	return nil
}

// hasCycle checks if there's a cycle starting from a given feature using DFS
func (c *Checker) hasCycle(node string, graph map[string][]string, visited, recStack map[string]bool) bool {
	visited[node] = true
	recStack[node] = true

	deps, ok := graph[node]
	if !ok {
		recStack[node] = false
		return false
	}

	for _, dep := range deps {
		if !visited[dep] {
			if c.hasCycle(dep, graph, visited, recStack) {
				recStack[node] = false
				return true
			}
		} else if recStack[dep] {
			recStack[node] = false
			return true
		}
	}

	recStack[node] = false
	return false
}

// evalFeaturesWithDepsViaCue extracts features with their deps via cue eval
func (c *Checker) evalFeaturesWithDepsViaCue() (map[string][]string, error) {
	features := make(map[string][]string)

	// Run: cue eval ./spec/urn/feat/... -e 'feature' --out json
	output, err := c.execCueEval("eval", "./spec/urn/feat/...", "-e", "feature", "--out", "json")
	if err != nil {
		return nil, err
	}

	// Parse NDJSON output (newline-delimited JSON, not array)
	decoder := json.NewDecoder(bytes.NewReader(output))
	for decoder.More() {
		var feat struct {
			ID   string   `json:"id"`
			Deps []string `json:"deps"`
		}
		if err := decoder.Decode(&feat); err != nil {
			return nil, fmt.Errorf("failed to parse cue eval output: %w", err)
		}
		if feat.ID != "" {
			features[feat.ID] = feat.Deps
		}
	}

	return features, nil
}

// PrintSummary prints the final summary
func (c *Checker) PrintSummary() int {
	fmt.Println("")
	if len(c.errors) == 0 {
		fmt.Println("✅ spec-lint: ALL CHECKS PASSED")
		return 0
	} else {
		fmt.Printf("❌ spec-lint: %d ERROR(S) FOUND\n", len(c.errors))
		return 1
	}
}

func main() {
	// Parse command-line flags
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: spec-lint [SPEC_ROOT] [--mode MODE]\n")
		fmt.Fprintf(os.Stderr, "\nModes:\n")
		fmt.Fprintf(os.Stderr, "  fast - feat-id/env-id dedup only (quick)\n")
		fmt.Fprintf(os.Stderr, "  slow - fast + refs + circular-deps (thorough)\n")
		fmt.Fprintf(os.Stderr, "\nExamples:\n")
		fmt.Fprintf(os.Stderr, "  spec-lint . --mode fast\n")
		fmt.Fprintf(os.Stderr, "  spec-lint /path/to/spec-repo --mode slow\n")
	}

	specRoot := "."
	mode := modeFast

	// Simple argument parsing (mimics bash script)
	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--mode":
			if i+1 < len(args) {
				mode = args[i+1]
				i++
			}
		default:
			if !strings.HasPrefix(args[i], "--") {
				specRoot = args[i]
			}
		}
	}

	// Validate mode
	if mode != modeFast && mode != modeSlow {
		fmt.Fprintf(os.Stderr, "Unknown mode: %s\n", mode)
		flag.Usage()
		os.Exit(1)
	}

	// Create and run checker
	checker := NewChecker(specRoot, mode)
	err := checker.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: %v\n", err)
	}

	// Print summary and exit
	exitCode := checker.PrintSummary()
	os.Exit(exitCode)
}
