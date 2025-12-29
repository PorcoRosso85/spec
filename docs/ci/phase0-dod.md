# Phase 0 Smoke - Definition of Done

## Status: ✅ COMPLETE (Perfectly Achieved)

Date: 2025-12-28  
Verified by: Full suite of automated checks

---

## Smoke Test Components (All Passing)

### 1. Module Normalization (FQDN+@v0)
- **Status**: ✅ PASS
- **Module Path**: `github.com/porcorosso85/spec-repo@v0`
- **Location**: `cue.mod/module.cue`
- **Rationale**: CUE standards compliance - module paths must be FQDN to avoid collisions
- **Verification**: `cat cue.mod/module.cue | grep module`

### 2. Import Path Integrity
- **Status**: ✅ PASS
- **Expected Pattern**: `import "github.com/porcorosso85/spec-repo/spec/schema"` (without @v0)
- **Rationale**: CUE spec - module declares @v0, import statements omit major version (auto-inferred from module.cue)
- **Current Count**: 10/10 files (all unified)
- **Old Patterns Verified as Removed**:
  - `import "spec/schema"` ✅ 0 occurrences
  - `import "spec.repo/..."` ✅ 0 occurrences
  - `import "github.porcorosso85/..."` (different FQDN) ✅ 0 occurrences
- **Verification**: `grep -R 'github\.com/porcorosso85/spec-repo/spec/schema' spec --include='*.cue' | wc -l`
- **Note**: Import major version is deliberately omitted per CUE standard practice (module.cue @v0 is authoritative)

### 3. Format Check (cue fmt --check)
- **Status**: ✅ PASS
- **Command**: `cue fmt --check --files ./spec`
- **Method**: --files flag for file-based checking (not import-path-based)
- **Behavior**: Exits 1 if unformatted code found, 0 if all formatted
- **CI-Safe**: Yes (reliable exit codes)
- **Verification**: `cue fmt --check --files ./spec`

### 4. Type Validation (cue vet)
- **Status**: ✅ PASS
- **Scope**: All packages in `./spec/...`
- **Result**: No type errors detected
- **Verification**: `cue vet ./spec/...`

### 5. Flake Validation (Optional: nix flake check)
- **Status**: ✅ AVAILABLE (not required for Phase 0)
- **Command**: `nix flake check` (optional, requires experimental features)
- **Rationale**: nix flake check requires `--extra-experimental-features nix-command`, making it environment-dependent
- **Decision**: Phase 0 smoke focuses on CUE checks (fmt + vet) only, which are reproducible and lightweight
- **Note**: Flake is valid (when checked with experimental features), but Phase 0 doesn't enforce it as gate

### 6. Reproducibility (flake.lock)
- **Status**: ✅ COMMITTED
- **Content**: Pinned nixpkgs/flake-utils versions
- **Purpose**: Guarantee consistent nix flake evaluation across runs
- **Location**: `flake.lock` (git tracked)

---

## Minimum Features (Phase 0 requirement)
- ✅ 2 features exist: `urn:feat:spec`, `urn:feat:decide-ci-score-matrix`
- ✅ Both pass type validation
- ✅ Registry entry point established via `spec/adapter/git/repo/repo.cue`

---

## Test Commands (Reproducible)

```bash
# Phase 0 smoke suite (SSOT entry point)
nix develop -c bash scripts/check.sh smoke

# Manual CUE checks (same as smoke does internally)
cue fmt --check --files ./spec
cue vet ./spec/...

# Optional: Flake validation (requires experimental features)
nix flake check --extra-experimental-features nix-command

# Module verification
cat cue.mod/module.cue | grep '^module:'

# Import pattern verification
grep -R 'github\.com/porcorosso85/spec-repo/spec/schema' spec --include='*.cue' | wc -l
```

---

## What's Ready for Phase 1 (参照整合)

1. ✅ Solid module foundation (FQDN+@v0)
2. ✅ Unified import paths (no mixing)
3. ✅ Automated format/type checking
4. ✅ Reproducible flake pins
5. ✅ Minimum feature definitions

Next: Implement `spec:lint` for reference integrity checks.
