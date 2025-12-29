#!/usr/bin/env bash
set -euo pipefail

# Thin dispatcher: routes to nix check or runs directly
# SSOT: nix/checks.nix
# Usage: check.sh [smoke|fast|slow|unit|e2e]

MODE="${1:-fast}"

# For now: execute scripts directly (no nix check integration yet)
# Future: can switch to `nix build .#checks...spec-${MODE}`

case "$MODE" in
  smoke)
    echo "🔍 Phase 0: smoke checks"
    cue fmt --check --files ./spec
    cue vet ./spec/...
    nix flake check
    echo "✅ Phase 0 smoke PASS"
    ;;
    
  fast)
    echo "🏃 Phase 1: fast checks"
    ./tools/spec-lint/spec-lint.sh . --mode fast
    cue fmt --check --files ./spec
    cue vet ./spec/...
    echo "✅ Phase 1 fast PASS"
    ;;
    
  slow)
    echo "🐢 Phase 1: slow checks"
    ./tools/spec-lint/spec-lint.sh . --mode slow
    cue fmt --check --files ./spec
    cue vet ./spec/...
    echo "✅ Phase 1 slow PASS"
    ;;
    
  unit)
    echo "ℹ️  spec:unit: placeholder (no tests yet)"
    ;;
    
  e2e)
    echo "ℹ️  spec:e2e: placeholder (future nightly)"
    ;;
    
  *)
    echo "Usage: check.sh [smoke|fast|slow|unit|e2e]"
    exit 1
    ;;
esac
