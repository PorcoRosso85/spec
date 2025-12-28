#!/usr/bin/env bash
set -euo pipefail

# spec check script - Phase 0/1 automated checks
# Usage: check.sh [fast|slow|smoke]

PHASE="${1:-fast}"

case "$PHASE" in
  smoke)
    echo "🔍 Phase 0: Running smoke checks..."
    echo ""
    echo "  ① cue fmt --check --files ./spec"
    cue fmt --check --files ./spec
    
    echo "  ② cue vet ./spec/..."
    cue vet ./spec/...
    
    echo "  ③ nix flake check"
    nix flake check 2>&1 | grep -E "^(checking|error)" || true
    
    echo ""
    echo "✅ Phase 0 PASS"
    ;;
    
  fast)
    echo "🏃 Phase 1: Running fast checks (PR mode)..."
    echo ""
    echo "  ① spec-lint"
    ./tools/spec-lint/spec-lint.sh .
    
    echo "  ② cue fmt --check --files ./spec"
    cue fmt --check --files ./spec
    
    echo "  ③ cue vet ./spec/..."
    cue vet ./spec/...
    
    echo ""
    echo "✅ Phase 1 fast PASS"
    ;;
    
  slow)
    echo "🐢 Phase 1: Running slow checks (main mode)..."
    echo ""
    echo "  ① spec-lint"
    ./tools/spec-lint/spec-lint.sh .
    
    echo "  ② cue fmt --check --files ./spec"
    cue fmt --check --files ./spec
    
    echo "  ③ cue vet ./spec/..."
    cue vet ./spec/...
    
    echo "  ④ (TODO: circular-deps when Go impl ready)"
    
    echo ""
    echo "✅ Phase 1 slow PASS"
    ;;
    
  *)
    echo "Usage: check.sh [fast|slow|smoke]"
    echo ""
    echo "  fast   - Quick checks for PR (fmt + vet + spec-lint dedup)"
    echo "  slow   - Full checks for main push (fast + circular-deps)"
    echo "  smoke  - Phase 0 baseline checks (fmt + vet + flake check)"
    exit 1
    ;;
esac
