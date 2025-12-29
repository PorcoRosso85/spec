#!/usr/bin/env bash
set -euo pipefail

# Entry point dispatcher for all spec checks
# SSOT: nix/checks.nix
# Usage: check.sh [smoke|fast|slow|unit|e2e]
# All checks must use this entry point (DO NOT bypass)

MODE="${1:-fast}"

# For now: execute scripts directly (no nix check integration yet)
# Future: can switch to `nix build .#checks...spec-${MODE}`

case "$MODE" in
  smoke)
    echo "🔍 Phase 0: smoke checks"
    echo "  ① cue fmt --check"
    cue fmt --check --files ./spec
    echo "  ② cue vet"
    cue vet ./spec/...
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
