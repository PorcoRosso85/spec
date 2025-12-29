# Check definitions for Phase 0/1
# SSOT: What constitutes "fast", "slow", "unit", "e2e"

{ pkgs, self }:

{
  # Phase 0: Baseline smoke checks
  spec-smoke = pkgs.runCommand "spec-smoke"
    {
      buildInputs = with pkgs; [ cue git ];
    }
    ''
      set -euo pipefail
      cd ${self}
      
      echo "🔍 Phase 0: smoke checks"
      
      echo "  ① cue fmt --check"
      ${pkgs.cue}/bin/cue fmt --check --files ./spec
      
      echo "  ② cue vet"
      ${pkgs.cue}/bin/cue vet ./spec/...
      
      echo "  ③ nix flake check"
      ${pkgs.nix}/bin/nix flake check
      
      echo "✅ Phase 0 smoke PASS"
      mkdir -p $out && echo "ok" > $out/result
    '';

  # Phase 1 fast: feat-id/env-id dedup only (PR mode)
  spec-fast = pkgs.runCommand "spec-fast"
    {
      buildInputs = with pkgs; [ cue git bash go ];
    }
    ''
      set -euo pipefail
      export HOME=$(mktemp -d)
      cd ${self}
      
      echo "🏃 Phase 1: fast checks"
      
      echo "  ① Building spec-lint..."
      cd ./tools/spec-lint
      # Build to temp location since ${self} is immutable in sandbox
      SPEC_LINT_BIN=$(mktemp --suffix=spec-lint)
      go build -mod=readonly -o $SPEC_LINT_BIN cmd/main.go
      SPEC_LINT_PATH=$SPEC_LINT_BIN
      cd ${self}
      
      echo "  ② spec-lint --mode fast"
      $SPEC_LINT_PATH . --mode fast
      
      echo "  ③ cue fmt --check"
      ${pkgs.cue}/bin/cue fmt --check --files ./spec
      
      echo "  ④ cue vet"
      ${pkgs.cue}/bin/cue vet ./spec/...
      
      echo "✅ Phase 1 fast PASS"
      mkdir -p $out && echo "ok" > $out/result
    '';

  # Phase 1 slow: fast + broken refs (main push mode)
  spec-slow = pkgs.runCommand "spec-slow"
    {
      buildInputs = with pkgs; [ cue git bash go ];
    }
    ''
      set -euo pipefail
      export HOME=$(mktemp -d)
      cd ${self}
      
      echo "🐢 Phase 1: slow checks"
      
      echo "  ① Building spec-lint..."
      cd ./tools/spec-lint
      SPEC_LINT_BIN=$(mktemp --suffix=spec-lint)
      go build -mod=readonly -o $SPEC_LINT_BIN cmd/main.go
      SPEC_LINT_PATH=$SPEC_LINT_BIN
      cd ${self}
      
      echo "  ② spec-lint --mode slow"
      $SPEC_LINT_PATH . --mode slow
      
      echo "  ③ cue fmt --check"
      ${pkgs.cue}/bin/cue fmt --check --files ./spec
      
      echo "  ④ cue vet"
      ${pkgs.cue}/bin/cue vet ./spec/...
      
      echo "✅ Phase 1 slow PASS"
      mkdir -p $out && echo "ok" > $out/result
    '';

  # Placeholder: unit tests (future)
  spec-unit = pkgs.runCommand "spec-unit"
    { }
    ''
      echo "ℹ️  spec:unit: placeholder (no tests yet)"
      mkdir -p $out && echo "ok" > $out/result
    '';

  # Placeholder: e2e tests (future)
  spec-e2e = pkgs.runCommand "spec-e2e"
    { }
    ''
      echo "ℹ️  spec:e2e: placeholder (future nightly)"
      mkdir -p $out && echo "ok" > $out/result
    '';
}
