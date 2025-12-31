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
        cue-v15 = pkgs.buildGoModule rec {
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
        
        # Integration test utilities (Phase 6)
        integration = import ./nix/lib/integration.nix { inherit pkgs self; cue = cue-v15; };
        
        checks-defs = import ./nix/checks.nix { inherit pkgs self; cue = cue-v15; };
      in
      {
        # 開発環境（CUEツールを含む）
        devShells.default = pkgs.mkShell {
          buildInputs = [
            cue-v15
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
          ${cue-v15}/bin/cue eval ./spec/...

          echo ""
          echo "→ cue vet ./spec/ci/checks/..."
          ${cue-v15}/bin/cue vet ./spec/ci/checks/... ./spec/...

          echo ""
          echo "✅ All validations passed"
        '';

        # Expose cue v0.15.1 for external use
        packages.cue = cue-v15;
        
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
          buildInputs = [ cue-v15 ];
          
          buildPhase = ''
            echo "🔴 TDD-RED: DoD1 (責務配分3カテゴリ)"
            echo "Expected: BUILD FAILS (cue vet fails due to _|_)"
            cd spec/ci/tdd/red/01-responsibility
            ${cue-v15}/bin/cue vet .
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
          buildInputs = [ cue-v15 ];
          
          buildPhase = ''
            echo "🔴 TDD-RED: DoD2 (consumer API)"
            echo "Expected: BUILD FAILS (cue vet fails due to _|_)"
            cd spec/ci/tdd/red/02-consumer-api
            ${cue-v15}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "unreachable" > $out/result
          '';
        };
        
        packages.verify-red-03-outputs-manifest = pkgs.stdenv.mkDerivation {
          name = "verify-red-03-outputs-manifest";
          src = self;
          buildInputs = [ cue-v15 ];
          
          buildPhase = ''
            echo "🔴 TDD-RED: DoD3 (outputs明確)"
            echo "Expected: BUILD FAILS (cue vet fails due to _|_)"
            cd spec/ci/tdd/red/03-outputs-manifest
            ${cue-v15}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "unreachable" > $out/result
          '';
        };
        
        packages.verify-red-04-uniq = pkgs.stdenv.mkDerivation {
          name = "verify-red-04-uniq";
          src = self;
          buildInputs = [ cue-v15 ];
          
          buildPhase = ''
            echo "🔴 TDD-RED: DoD4 (重複なし)"
            echo "Expected: BUILD FAILS (cue vet fails due to _|_)"
            cd spec/ci/tdd/red/04-uniq
            ${cue-v15}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "unreachable" > $out/result
          '';
        };
        
        # Phase 6: Integration Verification (実データ接続の検証)
        # 2-tier structure: Verify (clean) + Negative (malicious detection)
        
        # Tier 1: Verify (正常系) - spec-repo実体がクリーンであることを確認
        packages.integration-verify-dod4 = pkgs.stdenv.mkDerivation {
          name = "integration-verify-dod4";
          src = self;
          buildInputs = [ cue-v15 ];
          
          buildPhase =
            let
              # Extract all feats and generate clean CUE
              feats = integration.extractAllFeats;
              inputCue = pkgs.writeText "input.cue" (integration.genFeatListVerifyCue feats);
            in ''
            echo "🔍 Integration-Verify: DoD4 (実データがクリーン)"
            echo "Expected: SUCCESS (no duplicates in spec/urn/feat/*)"
            
            # Copy integration test files
            mkdir -p integration-test
            cp ${inputCue} integration-test/input.cue
            cp ${self}/spec/ci/integration/verify/04-uniq/expected.cue integration-test/
            cp ${self}/spec/ci/integration/verify/04-uniq/test.cue integration-test/
            
            cd integration-test
            ${cue-v15}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "verify-success" > $out/result
          '';
        };
        
        # Tier 2: Negative (悪性検出) - 配線の実効性確認
        packages.integration-negative-dod4 = pkgs.stdenv.mkDerivation {
          name = "integration-negative-dod4";
          src = self;
          buildInputs = [ cue-v15 ];
          
          buildPhase =
            let
              # Extract all feats and generate CUE with duplicate (malicious)
              feats = integration.extractAllFeats;
              inputCue = pkgs.writeText "input.cue" (integration.genFeatListNegativeCue feats);
            in ''
            echo "🔍 Integration-Negative: DoD4 (悪性注入→検出確認)"
            echo "Expected: SUCCESS (duplicate detected correctly)"
            
            # Copy integration test files
            mkdir -p integration-test
            cp ${inputCue} integration-test/input.cue
            cp ${self}/spec/ci/integration/negative/04-uniq/expected.cue integration-test/
            cp ${self}/spec/ci/integration/negative/04-uniq/test.cue integration-test/
            
            cd integration-test
            ${cue-v15}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "negative-success" > $out/result
          '';
        };
        
        # DoD2: Consumer API Integration Tests
        
        # Tier 1: Verify (正常系) - self.spec keys完全性確認
        packages.integration-verify-dod2 = pkgs.stdenv.mkDerivation {
          name = "integration-verify-dod2";
          src = self;
          buildInputs = [ cue-v15 ];
          
          buildPhase =
            let
              # Extract spec keys and generate clean CUE
              specKeys = integration.extractSpecKeys self.spec;
              inputCue = pkgs.writeText "input.cue" (integration.genConsumerAPIVerifyCue specKeys);
            in ''
            mkdir -p integration-test
            cp ${inputCue} integration-test/input.cue
            cp ${self}/spec/ci/integration/verify/02-consumer-api/expected.cue integration-test/
            cp ${self}/spec/ci/integration/verify/02-consumer-api/test.cue integration-test/
            
            cd integration-test
            ${cue-v15}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "verify-success" > $out/result
          '';
        };
        
        # Tier 2: Negative (異常系) - 欠落検出確認
        packages.integration-negative-dod2 = pkgs.stdenv.mkDerivation {
          name = "integration-negative-dod2";
          src = self;
          buildInputs = [ cue-v15 ];
          
          buildPhase =
            let
              # Extract spec keys and generate CUE with missing key (malicious)
              specKeys = integration.extractSpecKeys self.spec;
              missingKey = "spec.urn.envPath";
              inputCue = pkgs.writeText "input.cue" (integration.genConsumerAPINegativeCue specKeys missingKey);
            in ''
            mkdir -p integration-test
            cp ${inputCue} integration-test/input.cue
            cp ${self}/spec/ci/integration/negative/02-consumer-api/expected.cue integration-test/
            cp ${self}/spec/ci/integration/negative/02-consumer-api/test.cue integration-test/
            
            cd integration-test
            ${cue-v15}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "negative-success" > $out/result
          '';
        };
        
        # DoD1: Responsibility Integration Tests
        
        # Tier 1: Verify (正常系) - Real feats have no forbidden fields
        packages.integration-verify-dod1 = pkgs.stdenv.mkDerivation {
          name = "integration-verify-dod1";
          src = self;
          buildInputs = [ cue-v15 ];
          
          buildPhase =
            let
              # Extract first feat as representative (all feats are clean)
              feats = integration.extractAllFeats;
              firstFeat = builtins.head feats;
              inputCue = pkgs.writeText "input.cue" (integration.genResponsibilityVerifyCue firstFeat);
            in ''
            mkdir -p integration-test
            cp ${inputCue} integration-test/input.cue
            cp ${self}/spec/ci/integration/verify/01-responsibility/expected.cue integration-test/
            cp ${self}/spec/ci/integration/verify/01-responsibility/test.cue integration-test/
            
            cd integration-test
            ${cue-v15}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "verify-success" > $out/result
          '';
        };
        
        # Tier 2: Negative (異常系) - Inject forbidden field and detect
        packages.integration-negative-dod1 = pkgs.stdenv.mkDerivation {
          name = "integration-negative-dod1";
          src = self;
          buildInputs = [ cue-v15 ];
          
          buildPhase =
            let
              # Use first feat + inject contractOverride
              feats = integration.extractAllFeats;
              firstFeat = builtins.head feats;
              inputCue = pkgs.writeText "input.cue" (integration.genResponsibilityNegativeCue firstFeat);
            in ''
            mkdir -p integration-test
            cp ${inputCue} integration-test/input.cue
            cp ${self}/spec/ci/integration/negative/01-responsibility/expected.cue integration-test/
            cp ${self}/spec/ci/integration/negative/01-responsibility/test.cue integration-test/
            
            cd integration-test
            ${cue-v15}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "negative-success" > $out/result
          '';
        };
        
        # DoD3: Outputs Manifest Integration Tests
        
        # Tier 1: Verify (正常系) - manifest.cue vs self.spec一致確認
        packages.integration-verify-dod3 = pkgs.stdenv.mkDerivation {
          name = "integration-verify-dod3";
          src = self;
          buildInputs = [ cue-v15 ];
          
          buildPhase =
            let
              # Extract manifest and spec keys
              manifest = integration.extractManifest;
              specKeys = integration.extractSpecKeys self.spec;
              inputCue = pkgs.writeText "input.cue" (integration.genOutputsManifestVerifyCue manifest specKeys);
            in ''
            mkdir -p integration-test
            cp ${inputCue} integration-test/input.cue
            cp ${self}/spec/ci/integration/verify/03-outputs-manifest/expected.cue integration-test/
            cp ${self}/spec/ci/integration/verify/03-outputs-manifest/test.cue integration-test/
            
            cd integration-test
            ${cue-v15}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "verify-success" > $out/result
          '';
        };
        
        # Tier 2: Negative (異常系) - 欠落検出確認
        packages.integration-negative-dod3 = pkgs.stdenv.mkDerivation {
          name = "integration-negative-dod3";
          src = self;
          buildInputs = [ cue-v15 ];
          
          buildPhase =
            let
              # Extract manifest and spec keys, inject missing path
              manifest = integration.extractManifest;
              specKeys = integration.extractSpecKeys self.spec;
              missingPath = "spec.cuePath";
              inputCue = pkgs.writeText "input.cue" (integration.genOutputsManifestNegativeCue manifest specKeys missingPath);
            in ''
            mkdir -p integration-test
            cp ${inputCue} integration-test/input.cue
            cp ${self}/spec/ci/integration/negative/03-outputs-manifest/expected.cue integration-test/
            cp ${self}/spec/ci/integration/negative/03-outputs-manifest/test.cue integration-test/
            
            cd integration-test
            ${cue-v15}/bin/cue vet .
          '';
          
          installPhase = ''
            mkdir -p $out
            echo "negative-success" > $out/result
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
        
        # Outputs Manifest (DoD2: Consumer API minimum requirement)
        # Note: Content validation is DoD3's responsibility
        outputsManifestPath = ./spec/manifest.cue;

        # バージョン情報
        version = self.rev or "dirty";
      };
    };
}
