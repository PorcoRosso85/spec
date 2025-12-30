#!/usr/bin/env bash
set -euo pipefail

# spec-check: CUE contract executor (NO RULES ALLOWED)
# Design: Read contract from CUE, execute mechanical checks only
# SSOT: spec/ci/contract/*.cue

REPO_ROOT="${1:-.}"
MODE="${2:-fast}"

cd "$REPO_ROOT"

# Validate repo structure
[[ -f "cue.mod/module.cue" ]] || { echo "ERROR: Not a CUE repo root"; exit 1; }
[[ -d "spec/" ]] || { echo "ERROR: Missing spec/"; exit 1; }

# Load contract from CUE (SSOT)
CONTRACT_JSON=$(cue export ./spec/ci/contract/... -e contract 2>/dev/null || echo "{}")

if [[ "$CONTRACT_JSON" == "{}" ]]; then
    echo "ERROR: Failed to load CUE contract"
    exit 1
fi

echo "INFO: Loaded contract from CUE"
echo "INFO: Mode: $MODE"

ERRORS=0

# Check 1: CUE validation (format + vet)
echo "INFO: Running CUE validation..."
cue fmt --check ./spec || { echo "ERROR: CUE format check failed"; ((ERRORS++)); }
cue vet ./spec/... || { echo "ERROR: CUE vet failed"; ((ERRORS++)); }

if [[ "$MODE" == "fast" ]]; then
    echo "INFO: Fast mode - dedup + naming only"
    
    # Check 2: Extract features and check duplicates
    echo "INFO: Checking feat-id uniqueness..."
    FEAT_IDS=$(cue eval ./spec/urn/feat/... -e feature --out json 2>/dev/null | jq -r '.id // empty' | sort)
    FEAT_COUNT=$(echo "$FEAT_IDS" | grep -c . || true)
    DUP_COUNT=$(echo "$FEAT_IDS" | uniq -d | grep -c . || true)
    
    if [[ "$FEAT_COUNT" -eq 0 ]]; then
        echo "ERROR: No features extracted (cannot verify dedup)"
        ((ERRORS++))
    elif [[ "$DUP_COUNT" -gt 0 ]]; then
        echo "ERROR: Duplicate feat-ids detected:"
        echo "$FEAT_IDS" | uniq -d
        ((ERRORS++))
    else
        echo "INFO: ✅ No feat-id duplicates ($FEAT_COUNT unique)"
    fi
    
    # Check 3: Validate naming (kebab-case from contract)
    echo "INFO: Validating feat slugs..."
    SLUGS=$(cue eval ./spec/urn/feat/... -e feature --out json 2>/dev/null | jq -r '.slug // empty')
    INVALID_SLUGS=$(echo "$SLUGS" | grep -Ev '^[a-z0-9]+(-[a-z0-9]+)*$' || true)
    
    if [[ -n "$INVALID_SLUGS" ]]; then
        echo "ERROR: Invalid slugs (not kebab-case):"
        echo "$INVALID_SLUGS"
        ((ERRORS++))
    else
        echo "INFO: ✅ All feat slugs valid (kebab-case)"
    fi
    
elif [[ "$MODE" == "slow" ]]; then
    echo "INFO: Slow mode - fast + refs + circular"
    
    # Run fast checks first
    "$0" "$REPO_ROOT" fast || ((ERRORS++))
    
    # Check 4: Broken references (placeholder - needs full implementation)
    echo "INFO: Checking broken references..."
    echo "INFO: ⚠️  Reference check not yet implemented"
    
    # Check 5: Circular dependencies (placeholder)
    echo "INFO: Checking circular dependencies..."
    echo "INFO: ⚠️  Circular deps check not yet implemented"
fi

# Summary
echo ""
if [[ "$ERRORS" -eq 0 ]]; then
    echo "✅ spec-check: ALL CHECKS PASSED"
    exit 0
else
    echo "❌ spec-check: $ERRORS ERROR(S) FOUND"
    exit 1
fi
