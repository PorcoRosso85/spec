{
  description = "Spec repo - URN-based SSOT for features, environments, and adapters";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # CUE v0.15.1 固定（TDD-RED設計の前提）
        cue = pkgs.buildGoModule rec {
          pname = "cue";
          version = "0.15.1";
          
          src = pkgs.fetchFromGitHub {
            owner = "cue-lang";
            repo = "cue";
            rev = "v${version}";
            hash = "sha256-0DxJK5S1uWR5MbI8VzUxQv+YTwIIm1yK77Td+Qf278I=";
          };
          
          vendorHash = "sha256-ivFw62+pg503EEpRsdGSQrFNah87RTUrRXUSPZMFLG4=";
          
          subPackages = [ "cmd/cue" ];
          
          ldflags = [
            "-s"
            "-w"
            "-X cuelang.org/go/cmd/cue/cmd.version=v${version}"
          ];
        };
        
        checks-defs = import ./nix/checks.nix { inherit pkgs self cue; };
      in
      {
        # 開発環境（CUEツールを含む）
        devShells.default = pkgs.mkShell {
          buildInputs = [
            cue
            pkgs.git
            pkgs.bash
            pkgs.go
          ];

          shellHook = ''
            export PATH="$PWD/scripts:$PATH"
            
            echo "🚀 Spec repo development environment"
            echo ""
            echo "Phase 0 (Smoke):"
            echo "  bash scripts/check.sh smoke  - cue fmt --check + cue vet"
            echo ""
            echo "Phase 1 (CUE Contract Validation):"
            echo "  bash scripts/check.sh fast   - cue vet (CUE契約による全検証)"
            echo "  bash scripts/check.sh slow   - cue vet (fast同等)"
            echo ""
            echo "Utilities:"
            echo "  cue eval ./spec/...           - Evaluate all spec definitions"
            echo "  cue vet ./spec/...            - Type validation"
            echo ""
            echo "Spec structure:"
            echo "  - schema/: Type definitions"
            echo "  - urn/: Internal URN registry (feat/, env/)"
            echo "  - external/std/: External standard URN catalog"
            echo "  - mapping/: Internal ↔ External URN bridge"
            echo "  - adapter/: Git, session adapters"
            echo "  - ci/checks/: CI validation rules"
          '';
        };

        # パッケージ: CUE検証スクリプト
        packages.validate = pkgs.writeShellScriptBin "validate-spec" ''
          set -e
          echo "🔍 Validating CUE spec..."
          echo ""

          echo "→ cue eval ./spec/..."
          ${cue}/bin/cue eval ./spec/...

          echo ""
          echo "→ cue vet ./spec/ci/checks/..."
          ${cue}/bin/cue vet ./spec/ci/checks/... ./spec/...

          echo ""
          echo "✅ All validations passed"
        '';

        packages.default = self.packages.${system}.validate;
        
        # TDD-RED verification (expected to FAIL when built)
        # Purpose: Verify detectors fail correctly in RED phase (report: _|_)
        # Design: Direct `cue vet` - NO logic inversion, pure failure expected
        # 
        # Usage:
        #   nix build .#verify-red-01-responsibility  ← MUST fail (exit 1)
        #   Failure = RED working correctly
        #
        # Note: `nix flake check` only evaluates these (doesn't build),
        #       so check passes. Actual verification requires explicit build.
        packages.verify-red-01-responsibility = pkgs.stdenv.mkDerivation {
          name = "verify-red-01-responsibility";
          src = self;
          buildInputs = [ cue ];
          
          buildPhase = ''
            echo "🔴 TDD-RED: DoD1 (責務配分3カテゴリ)"
            echo "Expected: BUILD FAILS (cue vet fails due to _|_)"
            cd spec/ci/tdd/red/01-responsibility
            ${cue}/bin/cue vet .
            # Unreachable - cue vet fails above
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "unreachable" > $out/result
          '';
        };
        
        packages.verify-red-02-consumer-api = pkgs.stdenv.mkDerivation {
          name = "verify-red-02-consumer-api";
          src = self;
          buildInputs = [ cue ];
          
          buildPhase = ''
            echo "🔴 TDD-RED: DoD2 (consumer API)"
            echo "Expected: BUILD FAILS (cue vet fails due to _|_)"
            cd spec/ci/tdd/red/02-consumer-api
            ${cue}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "unreachable" > $out/result
          '';
        };
        
        packages.verify-red-03-outputs-manifest = pkgs.stdenv.mkDerivation {
          name = "verify-red-03-outputs-manifest";
          src = self;
          buildInputs = [ cue ];
          
          buildPhase = ''
            echo "🔴 TDD-RED: DoD3 (outputs明確)"
            echo "Expected: BUILD FAILS (cue vet fails due to _|_)"
            cd spec/ci/tdd/red/03-outputs-manifest
            ${cue}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "unreachable" > $out/result
          '';
        };
        
        packages.verify-red-04-uniq = pkgs.stdenv.mkDerivation {
          name = "verify-red-04-uniq";
          src = self;
          buildInputs = [ cue ];
          
          buildPhase = ''
            echo "🔴 TDD-RED: DoD4 (重複なし)"
            echo "Expected: BUILD FAILS (cue vet fails due to _|_)"
            cd spec/ci/tdd/red/04-uniq
            ${cue}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "unreachable" > $out/result
          '';
        };

        # Check definitions (SSOT for CI)
        # Note: TDD-RED checks removed - use packages.verify-red-* instead
        checks = checks-defs;
      }
    ) // {
      # **重要: spec/ を flake outputs として露出**
      # - 他の impl repo が inputs.spec として参照可能
      # - forge 問わず同じ定義を受け取れる
      spec = {
        # CUE定義のパス
        cuePath = ./spec;

        # URN定義
        urn = {
          featPath = ./spec/urn/feat;
          envPath = ./spec/urn/env;
        };

        # スキーマ定義
        schemaPath = ./spec/schema;

        # アダプター定義
        adapter = {
          gitRepoPath = ./spec/adapter/git/repo;
          gitBranchPath = ./spec/adapter/git/branch;
          sessionRulesPath = ./spec/adapter/session/rules;
        };

        # マッピング定義
        mappingPath = ./spec/mapping/feat-external;

        # 外部標準カタログ
        externalStdPath = ./spec/external/std;

        # CI チェック
        ciChecksPath = ./spec/ci/checks;

        # バージョン情報
        version = self.rev or "dirty";
      };
    };
}
