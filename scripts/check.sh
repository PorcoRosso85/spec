#!/usr/bin/env bash
set -euo pipefail

# Entry point: Single entry validation (NO LOGIC ALLOWED)
# SSOT: nix/checks.nix (all validation logic lives there)
# Usage: check.sh [smoke|fast|slow|unit]
# Design: ロジック禁止、nix flake check呼び出しのみ
#
# Rationale:
#   - 単一入口化: 同じ手順で同じ判定
#   - 循環防止: nix checks → cue vet直接実行
#   - 再現性: CI/ローカルで完全に同一の検証

MODE="${1:-fast}"

# Detect system (避けられないロジック - systemは環境依存)
SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')

case "$MODE" in
  smoke)
    echo "🔍 Phase 0: smoke checks"
    nix build .#checks.${SYSTEM}.spec-smoke --no-link --print-build-logs
    ;;
    
  fast)
    echo "🏃 Phase 1: fast checks (includes fixtures)"
    nix build .#checks.${SYSTEM}.spec-fast --no-link --print-build-logs
    ;;

  slow)
    echo "🐢 Phase 1: slow checks"
    nix build .#checks.${SYSTEM}.spec-slow --no-link --print-build-logs
    ;;
    
  unit)
    echo "🧪 Phase 2: unit tests"
    nix build .#checks.${SYSTEM}.spec-unit --no-link --print-build-logs
    ;;
    
  *)
    echo "Usage: check.sh [smoke|fast|slow|unit]"
    exit 1
    ;;
esac
