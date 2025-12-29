#!/usr/bin/env bash
set -euo pipefail

# spec check script - Phase 0/1 automated checks
# SSOT: nix develop -c bash scripts/check.sh [fast|slow|smoke]
# All checks are invoked through this single entry point
# Usage: check.sh [fast|slow|smoke]

PHASE="${1:-fast}"

# Helper: invoke spec-lint with mode
spec_lint() {
  local mode="${1:-fast}"
  ./tools/spec-lint/spec-lint.sh . --mode "$mode"
}

# Helper: format and type check
cue_check() {
  echo "  ② cue fmt --check --files ./spec"
  cue fmt --check --files ./spec
  
  echo "  ③ cue vet ./spec/..."
  cue vet ./spec/...
}

case "$PHASE" in
  smoke)
    echo "🔍 Phase 0: Running smoke checks (baseline)..."
    echo ""
    
    echo "  ① cue fmt --check --files ./spec"
    cue fmt --check --files ./spec
    
    echo "  ② cue vet ./spec/..."
    cue vet ./spec/...
    
    echo "  ③ nix flake check"
    nix flake check
    
    echo ""
    echo "✅ Phase 0 smoke PASS"
    ;;
    
  fast)
    echo "🏃 Phase 1: Running fast checks (PR mode)..."
    echo ""
    
    echo "  ① spec-lint --mode fast (feat-id/env-id dedup only)"
    spec_lint fast
    
    cue_check
    
    echo ""
    echo "✅ Phase 1 fast PASS"
    ;;
    
  slow)
    echo "🐢 Phase 1: Running slow checks (main mode)..."
    echo ""
    
    echo "  ① spec-lint --mode slow (refs + circular-deps)"
    spec_lint slow
    
    cue_check
    
    echo ""
    echo "✅ Phase 1 slow PASS"
    ;;
    
  *)
    echo "Usage: check.sh [fast|slow|smoke]"
    echo ""
    echo "  fast   - Quick checks for PR (spec-lint dedup + fmt + vet)"
    echo "  slow   - Full checks for main (spec-lint refs/circular + fmt + vet)"
    echo "  smoke  - Phase 0 baseline (fmt + vet + flake check)"
    exit 1
    ;;
esac
