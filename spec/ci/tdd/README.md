# TDD-RED Verification

## Purpose

This directory contains RED phase tests for spec-repo's core DoD (Definition of Done).
RED tests verify that detectors correctly fail when `report: _|_` (unimplemented).

## DoD Coverage

| DoD | Specification | Verification Command |
|-----|--------------|---------------------|
| DoD1 | Responsibility boundaries (3 forbidden categories) | `nix build .#verify-red-01-responsibility` |
| DoD2 | Consumer minimum API (6 required attributes) | `nix build .#verify-red-02-consumer-api` |
| DoD3 | Outputs manifest consistency | `nix build .#verify-red-03-outputs-manifest` |
| DoD4 | Uniqueness enforcement (feat ID/slug) | `nix build .#verify-red-04-uniq` |

## Verification Protocol

### Expected Behavior (RED Phase)

All `verify-red-*` commands **MUST FAIL** with:
```
error: builder for '/nix/store/...' failed with exit code 1
explicit error (_|_ literal) in source:
    ../../../detector/<name>.cue:<line>:10
```

**Failure = Success** (detector is correctly unimplemented)

### When to Run

1. **Before Review**: Verify all REDs fail correctly
2. **After Detector Changes**: Ensure RED still fails (prevent accidental GREEN)
3. **CI Integration** (future): Automated verification on PRs

### Running All REDs

```bash
# Quick verification script
for dod in 01-responsibility 02-consumer-api 03-outputs-manifest 04-uniq; do
  echo "=== verify-red-$dod ==="
  nix build .#verify-red-$dod 2>&1 | grep -E "(explicit error|error:)" | head -2
  echo ""
done
```

## File Structure

```
spec/ci/
├── detector/           # Detector definitions (all with report: _|_)
│   ├── consumer-api.cue
│   ├── outputs-manifest.cue
│   ├── responsibility.cue
│   └── uniq.cue
└── tdd/red/           # RED tests (input + expected + test)
    ├── 01-responsibility/
    │   ├── input.cue      # Test input (violations)
    │   ├── expected.cue   # Expected report
    │   └── test.cue       # Unify detector with input/expected
    ├── 02-consumer-api/
    ├── 03-outputs-manifest/
    └── 04-uniq/
```

## Design Principles

### CUE (SSOT)
- Detectors define schema only (`report: _|_` in RED)
- Tests specify expected behavior (input/expected separation)
- No hardcoded module paths (dynamic extraction via Nix)

### Nix (Mechanical Verification)
- `mkDerivation` + `src = self` (standard pattern)
- Direct `cue vet` execution (no shell logic)
- Exit code = verification result (no inversion)

### TDD Workflow
1. **RED**: Write failing tests (this phase) ✅
2. **Review**: Validate RED specifications
3. **GREEN**: Implement detectors (`report: _|_` → actual logic)
4. **Refactor**: Optimize after GREEN passes

## Transition to GREEN

After review approval:

1. Remove `verify-red-*` from packages
2. Implement detector logic (replace `report: _|_`)
3. Add GREEN checks to `nix/checks.nix`
4. Verify with `nix flake check`

**Current Phase**: RED (awaiting review)
