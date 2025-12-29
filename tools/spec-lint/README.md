# spec-lint

Automated linting for spec repository - detects reference integrity issues.

## Implementation

- **Go binary** (`spec-lint`): Core implementation using CUE Go API
- **Bash wrapper** (`spec-lint.sh`): Entry point that calls the Go binary

## Usage

```bash
./tools/spec-lint/spec-lint.sh [SPEC_ROOT] [--mode MODE]
```

### Modes

- `fast` - feat-id/env-id dedup only (quick, suitable for PR checks)
- `slow` - fast + refs + circular-deps (thorough, suitable for main branch)

### Examples

```bash
# Check current directory with fast mode
./tools/spec-lint/spec-lint.sh . --mode fast

# Check specific directory with slow mode
./tools/spec-lint/spec-lint.sh /path/to/spec-repo --mode slow

# Default mode is 'fast'
./tools/spec-lint/spec-lint.sh .
```

## Checks Performed

### Fast Mode
1. **Feat-ID Duplicates**: Scans `spec/urn/feat/*/feature.cue` for duplicate `id` fields
2. **Environment-ID Duplicates**: Scans `spec/urn/env/*/environment.cue` for duplicate `envId` fields

### Slow Mode (includes Fast + additional checks)
3. **Broken References**: Validates all `urn:feat:*` references in `spec/adapter/*` and `spec/mapping/*` against defined feat-ids
4. **Circular Dependencies**: Detects cycles using the `deps` field in features

## Implementation Details

### Go Binary (`cmd/main.go`)

- Uses CUE Go API (`cuelang.org/go/cue`) to parse feature files
- Falls back to regex parsing when CUE API fails
- DFS-based cycle detection for circular dependency checking
- Clean separation of concerns with dedicated methods for each check

### Architecture

```
spec-lint.sh (bash wrapper)
    ↓
    spec-lint (Go binary)
        ├── Fast mode checks
        │   ├── scanFeatIDs()
        │   └── scanEnvIDs()
        └── Slow mode checks
            ├── checkBrokenReferences()
            └── checkCircularDeps()
```

## Building

```bash
# Navigate to tools/spec-lint directory
cd tools/spec-lint

# Download dependencies
go mod tidy

# Build binary
go build -o spec-lint cmd/main.go
```

## Exit Codes

- `0`: All checks passed
- `1`: One or more checks failed

## Output

- `INFO: ...` messages to stderr (informational)
- `ERROR: ...` messages to stderr (actual failures)
- Summary to stdout

## Testing

```bash
# Test fast mode
nix develop -c bash tools/spec-lint/spec-lint.sh . --mode fast

# Test slow mode
nix develop -c bash tools/spec-lint/spec-lint.sh . --mode slow
```

## Phase 1 Integration

This is Phase 1 Step 5 implementation:
- ✅ Fast mode (feat-id/env-id dedup)
- ✅ Slow mode (refs + circular-deps)
- ✅ Go implementation using CUE API
- ⏳ Next: Phase 1 Step 6 (kebab-case naming validation)
