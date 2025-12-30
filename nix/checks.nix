# Check definitions for Phase 0/1
# SSOT: CUE契約（spec/ci/contract/*.cue + spec/ci/checks/*.cue）
# Design: cue vet実行器（ルール禁止）
#
# Fixture Import Policy (SSOT - 混在禁止):
#   ✅ Runner側でcontract+checksを注入
#   ✅ Fixture側でschema/* importは許可（#Feature型制約のため必要）
#   ❌ Fixture側でcontract/checks import禁止（偽PASS/FAIL防止）
#
# Fixture責務: schema型に適合するデータ定義
# Runner責務: contract/checks制約の検証
#
# Implementation:
#   cue vet \
#     ./spec/ci/fixtures/{pass,fail}/*/... \
#     ./spec/ci/contract/... \
#     ./spec/ci/checks/...

{ pkgs, self }:

let
  # Per-feat derivation splitting for parallel validation
  featDirs = builtins.attrNames (builtins.readDir (self + "/spec/urn/feat"));
  
  mkFeatCheck = slug: pkgs.runCommand "feat-${slug}"
    {
      buildInputs = with pkgs; [ cue ];
    }
    ''
      set -euo pipefail
      cd ${self}
      
      echo "→ Validating feat: ${slug}"
      ${pkgs.cue}/bin/cue vet \
        ./spec/urn/feat/${slug}/... \
        ./spec/schema/... \
        ./spec/ci/contract/...
      
      echo "✅ feat-${slug} PASS"
      mkdir -p $out && echo "ok" > $out/result
    '';
  
  featChecks = builtins.listToAttrs (
    map (slug: { name = "feat-${slug}"; value = mkFeatCheck slug; }) featDirs
  );
  
  # Policy check: dev branch scope validation
  policy-dev-scope = pkgs.runCommand "policy-dev-scope"
    {
      buildInputs = with pkgs; [ git bash ];
    }
    ''
      set -euo pipefail
      cd ${self}
      
      echo "🔍 dev branch scope policy check"
      
      # Check if main branch exists
      if ! git rev-parse main >/dev/null 2>&1; then
        echo "⚠️  main branch not found, skipping policy check"
        mkdir -p $out && echo "skipped" > $out/result
        exit 0
      fi
      
      # Get changed files
      CHANGED="$(git diff --name-only main...HEAD || echo "")"
      
      if [[ -z "$CHANGED" ]]; then
        echo "ℹ️  No changes from main"
        mkdir -p $out && echo "ok" > $out/result
        exit 0
      fi
      
      # Check for forbidden changes to spec/urn/feat/
      DENY="$(echo "$CHANGED" | grep -E '^spec/urn/feat/' || true)"
      
      if [[ -n "$DENY" ]]; then
        echo "❌ NG: dev branch modified spec/urn/feat/"
        echo "$DENY"
        exit 1
      fi
      
      echo "✅ OK: dev branch scope compliant"
      mkdir -p $out && echo "ok" > $out/result
    '';

in

featChecks // {
  # Policy checks
  inherit policy-dev-scope;
  
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
      # Note: checks/除外（未実装、次フェーズで対応）
      ${pkgs.cue}/bin/cue vet \
        ./spec/urn/... \
        ./spec/schema/... \
        ./spec/adapter/... \
        ./spec/mapping/... \
        ./spec/external/... \
        ./spec/ci/contract/...
      
      echo "✅ smoke PASS (contract constraints verified)"
      mkdir -p $out && echo "ok" > $out/result
    '';

  # Phase 1 fast: Aggregated validation with per-feat parallelism
  # Design:
  #   - Per-feat validation runs in parallel (via Nix derivation deps)
  #   - spec-fast aggregates all feat checks + other spec areas
  #   - Policy checks enforced as dependencies
  spec-fast = pkgs.runCommand "spec-fast"
    {
      buildInputs = with pkgs; [ cue bash ] ++ (builtins.attrValues featChecks) ++ [ policy-dev-scope ];
    }
    ''
      set -euo pipefail
      cd ${self}
      
      echo "🏃 Phase 1: fast checks (aggregated)"
      echo ""
      
      # 1. Per-feat validations (already completed via buildInputs deps)
      echo "✅ All feat validations completed (${toString (builtins.length featDirs)} feats)"
      echo ""
      
      # 2. Other spec areas validation
      echo "→ Validating other spec areas..."
      ${pkgs.cue}/bin/cue vet \
        ./spec/schema/... \
        ./spec/adapter/... \
        ./spec/mapping/... \
        ./spec/external/... \
        ./spec/ci/contract/...
      echo "✅ Other spec areas PASS"
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
      # Note: checks/除外（未実装、次フェーズで対応）
      ${pkgs.cue}/bin/cue vet \
        ./spec/urn/... \
        ./spec/schema/... \
        ./spec/adapter/... \
        ./spec/mapping/... \
        ./spec/external/... \
        ./spec/ci/contract/...
      
      echo "✅ slow PASS (contract constraints verified)"
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
