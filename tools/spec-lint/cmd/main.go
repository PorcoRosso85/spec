package main

import (
	"flag"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/load"
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
func NewChecker(specRoot, mode string) *Checker {
	return &Checker{
		specRoot: specRoot,
		mode:     mode,
		errors:   []string{},
	}
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

	// Check for duplicates
	for id, files := range featIDs {
		if len(files) > 1 {
			c.logError(fmt.Sprintf("feat-id '%s' defined in multiple files: %v", id, files))
		}
	}

	if len(c.errors) == 0 {
		c.logInfo(fmt.Sprintf("✅ No feat-id duplicates (%d unique)", len(featIDs)))
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

// scanFeatIDs scans spec/urn/feat/*/feature.cue for feat-ids
func (c *Checker) scanFeatIDs(featIDs map[string][]string) error {
	featPath := filepath.Join(c.specRoot, "spec", "urn", "feat")
	if _, err := os.Stat(featPath); os.IsNotExist(err) {
		return nil // No feat directory, that's ok
	}

	err := filepath.WalkDir(featPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.Name() == "feature.cue" && !d.IsDir() {
			id, err := c.extractFeatID(path)
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

// scanEnvIDs scans spec/urn/env/*/environment.cue for env-ids
func (c *Checker) scanEnvIDs(envIDs map[string][]string) error {
	envPath := filepath.Join(c.specRoot, "spec", "urn", "env")
	if _, err := os.Stat(envPath); os.IsNotExist(err) {
		return nil // No env directory, that's ok
	}

	err := filepath.WalkDir(envPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.Name() == "environment.cue" && !d.IsDir() {
			id, err := c.extractEnvID(path)
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

// extractFeatID extracts the id field from a feature.cue file
func (c *Checker) extractFeatID(filePath string) (string, error) {
	ctx := cuecontext.New()
	instances := load.Instances([]string{filePath}, &load.Config{
		Dir: c.specRoot,
	})

	for _, inst := range instances {
		v := ctx.BuildInstance(inst)
		if v.Err() != nil {
			// Try regex fallback for better error handling
			return c.extractIDRegex(filePath, `^\s*id:\s*"([^"]+)"`)
		}

		id, err := v.LookupPath(cue.ParsePath("id")).String()
		if err != nil {
			return c.extractIDRegex(filePath, `^\s*id:\s*"([^"]+)"`)
		}
		return id, nil
	}

	return c.extractIDRegex(filePath, `^\s*id:\s*"([^"]+)"`)
}

// extractEnvID extracts the envId field from an environment.cue file
func (c *Checker) extractEnvID(filePath string) (string, error) {
	ctx := cuecontext.New()
	instances := load.Instances([]string{filePath}, &load.Config{
		Dir: c.specRoot,
	})

	for _, inst := range instances {
		v := ctx.BuildInstance(inst)
		if v.Err() != nil {
			// Try regex fallback
			return c.extractIDRegex(filePath, `^\s*envId:\s*"([^"]+)"`)
		}

		id, err := v.LookupPath(cue.ParsePath("envId")).String()
		if err != nil {
			return c.extractIDRegex(filePath, `^\s*envId:\s*"([^"]+)"`)
		}
		return id, nil
	}

	return c.extractIDRegex(filePath, `^\s*envId:\s*"([^"]+)"`)
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

	// Kebab-case pattern: lowercase letters, digits, and hyphens
	// Must start with lowercase letter or digit
	kebabCasePattern := regexp.MustCompile(`^[a-z0-9]+(-[a-z0-9]+)*$`)

	err := filepath.WalkDir(featPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.Name() == "feature.cue" && !d.IsDir() {
			slug, err := c.extractSlug(path)
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

// extractSlug extracts the slug field from a feature.cue file
func (c *Checker) extractSlug(filePath string) (string, error) {
	ctx := cuecontext.New()
	instances := load.Instances([]string{filePath}, &load.Config{
		Dir: c.specRoot,
	})

	for _, inst := range instances {
		v := ctx.BuildInstance(inst)
		if v.Err() != nil {
			// Try regex fallback
			return c.extractIDRegex(filePath, `^\s*slug:\s*"([^"]+)"`)
		}

		slug, err := v.LookupPath(cue.ParsePath("feature.slug")).String()
		if err != nil {
			// Try direct field
			slug, err := v.LookupPath(cue.ParsePath("slug")).String()
			if err != nil {
				// Fallback to regex
				return c.extractIDRegex(filePath, `^\s*slug:\s*"([^"]+)"`)
			}
			return slug, nil
		}
		return slug, nil
	}

	return c.extractIDRegex(filePath, `^\s*slug:\s*"([^"]+)"`)
}

// checkBrokenReferences checks for broken urn:feat:* references
func (c *Checker) checkBrokenReferences() error {
	// First, collect all valid feat-ids
	validFeats := make(map[string]bool)
	featPath := filepath.Join(c.specRoot, "spec", "urn", "feat")
	if _, err := os.Stat(featPath); err == nil {
		err := filepath.WalkDir(featPath, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.Name() == "feature.cue" && !d.IsDir() {
				id, err := c.extractFeatID(path)
				if err != nil {
					return err
				}
				if id != "" {
					validFeats[id] = true
				}
			}
			return nil
		})
		if err != nil {
			return err
		}
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

	err := filepath.WalkDir(featPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.Name() == "feature.cue" && !d.IsDir() {
			id, deps, err := c.extractFeatIDAndDeps(path)
			if err != nil {
				return err
			}
			if id != "" {
				features[id] = deps
			}
		}
		return nil
	})

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

// extractFeatIDAndDeps extracts both id and deps from a feature.cue file
func (c *Checker) extractFeatIDAndDeps(filePath string) (string, []string, error) {
	ctx := cuecontext.New()
	instances := load.Instances([]string{filePath}, &load.Config{
		Dir: c.specRoot,
	})

	var id string
	var deps []string

	for _, inst := range instances {
		v := ctx.BuildInstance(inst)
		if v.Err() != nil {
			// Fallback to regex
			id, _ := c.extractIDRegex(filePath, `^\s*id:\s*"([^"]+)"`)
			return id, []string{}, nil
		}

		idVal, _ := v.LookupPath(cue.ParsePath("id")).String()
		id = idVal

		// Extract deps if present
		depsVal := v.LookupPath(cue.ParsePath("deps"))
		if depsVal.Exists() {
			iter, err := depsVal.List()
			if err == nil {
				for iter.Next() {
					depStr, _ := iter.Value().String()
					if depStr != "" {
						deps = append(deps, depStr)
					}
				}
			}
		}
	}

	return id, deps, nil
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
