# spec-lint

Automated linting for spec repository - detects reference integrity issues.

## Usage

```bash
./tools/spec-lint/spec-lint.sh [SPEC_ROOT] [--check]
```

### Examples

```bash
# Check current directory's spec/ tree
./tools/spec-lint/spec-lint.sh .

# Check specific directory
./tools/spec-lint/spec-lint.sh /path/to/spec-repo
```

## Checks Performed

### 1. Feat-ID Duplicates
- Scans `spec/urn/feat/*/feature.cue`
- Reports if same `id` defined in multiple files
- Exit code: 1 if duplicates found

### 2. Environment-ID Duplicates
- Scans `spec/urn/env/*/environment.cue`
- Reports if same `envId` defined in multiple files
- Exit code: 1 if duplicates found

### 3. Broken References
- Scans `spec/adapter/*`, `spec/mapping/*` for URN references
- Validates all `urn:feat:*` references against defined feat-ids
- Exit code: 1 if broken references found

## Exit Codes

- `0`: All checks passed
- `1`: One or more checks failed

## Output

- `INFO: ...` messages to stderr (informational)
- `ERROR: ...` messages to stderr (actual failures)
- Summary to stdout

## Phase 1 Integration

This is a minimal Phase 1 Step 3 implementation. Future versions will add:
- Circular dependency detection (deps field analysis)
- Naming convention enforcement (kebab-case)
- Go implementation for performance
