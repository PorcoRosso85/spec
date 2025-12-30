#!/usr/bin/env bash
set -euo pipefail

# Entry point: CUE contract executor (NO RULES ALLOWED)
# SSOT: spec/ci/contract/*.cue
# Usage: check.sh [smoke|fast|slow|unit]
# Design: ルール禁止、cue vet実行のみ

MODE="${1:-fast}"

case "$MODE" in
  smoke)
    echo "🔍 Phase 0: smoke checks"
    cue fmt --check ./spec
    cue vet ./spec/...
    echo "✅ smoke PASS"
    ;;
    
  fast|slow)
    echo "🏃 Phase 1: $MODE checks"
    # ルールは全てCUE契約に存在、ここは実行のみ
    cue vet ./spec/... ./spec/ci/contract/...
    echo "✅ $MODE PASS"
    ;;
    
  unit)
    echo "🧪 Phase 2: unit tests"
    bash tests/unit/run.sh
    echo "✅ unit PASS"
    ;;
    
  *)
    echo "Usage: check.sh [smoke|fast|slow|unit]"
    exit 1
    ;;
esac
