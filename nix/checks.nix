# Check definitions for Phase 0/1
# SSOT: CUE契約（spec/ci/contract/*.cue）
# Design: cue vet実行器（ルール禁止）

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
      ${pkgs.cue}/bin/cue vet ./spec/...
      
      echo "✅ smoke PASS"
      mkdir -p $out && echo "ok" > $out/result
    '';

  # Phase 1 fast: CUE契約による全検証（PR mode）
  spec-fast = pkgs.runCommand "spec-fast"
    {
      buildInputs = with pkgs; [ cue ];
    }
    ''
      set -euo pipefail
      cd ${self}
      
      echo "🏃 Phase 1: fast checks"
      ${pkgs.cue}/bin/cue vet ./spec/... ./spec/ci/contract/...
      
      echo "✅ fast PASS"
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
      ${pkgs.cue}/bin/cue vet ./spec/... ./spec/ci/contract/...
      
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
}
