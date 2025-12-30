# Check definitions for Phase 0/1
# SSOT: CUE契約（spec/ci/contract/*.cue + spec/ci/checks/*.cue）
# Design: cue vet実行器（ルール禁止）
#
# Fixture Import Policy (SSOT - 混在禁止):
#   ✅ Runner側でcontract+checksを注入
#   ❌ Fixture側でimport文を記述（偽PASS/FAIL防止）
#
# Implementation:
#   cue vet \
#     ./spec/ci/fixtures/{pass,fail}/*/... \
#     ./spec/ci/contract/... \
#     ./spec/ci/checks/...

{ pkgs, self }:

{
  # Phase 0: Baseline smoke checks
  spec-smoke = pkgs.runCommand "spec-smoke"
    {
      buildInputs = with pkgs; [ cue ];
    }
    ''
      set -euo pipefail
      cd ${self}
      
      echo "🔍 Phase 0: smoke checks"
      ${pkgs.cue}/bin/cue fmt --check ./spec
      # Note: fixtures除外（意図的PASS/FAIL検証はspec-fastで実施）
      ${pkgs.cue}/bin/cue vet \
        ./spec/urn/... \
        ./spec/schema/... \
        ./spec/adapter/... \
        ./spec/mapping/... \
        ./spec/external/... \
        ./spec/ci/checks/... \
        ./spec/ci/contract/...
      
      echo "✅ smoke PASS"
      mkdir -p $out && echo "ok" > $out/result
    '';

  # Phase 1 fast: CUE契約による全検証 + fixture検証（PR mode）
  # Design:
  #   - cueを直接実行（check.sh経由禁止 - 循環防止）
  #   - runner側でcontract+checksを注入（fixture側import禁止）
  #   - PASS期待: spec/ci/fixtures/pass/** → exit 0で成功
  #   - FAIL期待: spec/ci/fixtures/fail/** → exit 1を確認して成功
  spec-fast = pkgs.runCommand "spec-fast"
    {
      buildInputs = with pkgs; [ cue bash ];
    }
    ''
      set -euo pipefail
      cd ${self}
      
      echo "🏃 Phase 1: fast checks"
      echo ""
      
      # 1. 本体spec検証（contract + checks適用）
      echo "→ Validating main spec with contracts..."
      ${pkgs.cue}/bin/cue vet \
        ./spec/urn/... \
        ./spec/schema/... \
        ./spec/adapter/... \
        ./spec/mapping/... \
        ./spec/external/... \
        ./spec/ci/checks/... \
        ./spec/ci/contract/...
      echo "✅ Main spec PASS"
      echo ""
      
      # 2. PASS fixture検証（将来用 - 現在は空でOK）
      if [ -d "./spec/ci/fixtures/pass" ] && [ -n "$(find ./spec/ci/fixtures/pass -name '*.cue' 2>/dev/null)" ]; then
        echo "→ Validating PASS fixtures (expect success)..."
        ${pkgs.cue}/bin/cue vet \
          ./spec/ci/fixtures/pass/... \
          ./spec/ci/contract/... \
          ./spec/ci/checks/...
        echo "✅ PASS fixtures validated"
        echo ""
      else
        echo "ℹ️  No PASS fixtures found (will be added in S1)"
        echo ""
      fi
      
      # 3. FAIL fixture検証（失敗が期待される）
      if [ -d "./spec/ci/fixtures/fail" ]; then
        echo "→ Validating FAIL fixtures (expect failures)..."
        fail_count=0
        success_count=0
        
        # シェルのglob展開を有効化
        shopt -s nullglob
        for fixture_dir in ./spec/ci/fixtures/fail/*/; do
          if [ -d "$fixture_dir" ]; then
            fixture_name=$(basename "$fixture_dir")
            echo "  Testing: $fixture_name"
            
            # FAIL期待なので、exit 1が正常
            if ${pkgs.cue}/bin/cue vet \
              "$fixture_dir"... \
              ./spec/ci/contract/... \
              ./spec/ci/checks/... 2>&1 | head -20; then
              echo "    ❌ Expected failure but got success"
              fail_count=$((fail_count + 1))
            else
              echo "    ✅ Failed as expected"
              success_count=$((success_count + 1))
            fi
            echo ""
          fi
        done
        
        if [ $fail_count -gt 0 ]; then
          echo "❌ $fail_count FAIL fixture(s) did not fail as expected"
          exit 1
        fi
        
        echo "✅ All $success_count FAIL fixtures failed as expected"
      else
        echo "ℹ️  No FAIL fixtures directory found"
      fi
      echo ""
      echo "✅ fast PASS (spec + fixtures verified)"
      mkdir -p $out && echo "ok" > $out/result
    '';

  # Phase 1 slow: fast同等（main push mode）
  spec-slow = pkgs.runCommand "spec-slow"
    {
      buildInputs = with pkgs; [ cue ];
    }
    ''
      set -euo pipefail
      cd ${self}
      
      echo "🐢 Phase 1: slow checks"
      # Note: fixtures除外（意図的PASS/FAIL検証はspec-fastで実施）
      ${pkgs.cue}/bin/cue vet \
        ./spec/urn/... \
        ./spec/schema/... \
        ./spec/adapter/... \
        ./spec/mapping/... \
        ./spec/external/... \
        ./spec/ci/checks/... \
        ./spec/ci/contract/...
      
      echo "✅ slow PASS"
      mkdir -p $out && echo "ok" > $out/result
    '';

  # Placeholder: unit tests (future)
  spec-unit = pkgs.runCommand "spec-unit"
    { }
    ''
      echo "ℹ️  spec:unit: placeholder (tests/unit/run.sh integration pending)"
      mkdir -p $out && echo "ok" > $out/result
    '';

  # Placeholder: e2e tests (future)
  spec-e2e = pkgs.runCommand "spec-e2e"
    { }
    ''
      echo "ℹ️  spec:e2e: placeholder (integration tests pending)"
      mkdir -p $out && echo "ok" > $out/result
    '';
}
