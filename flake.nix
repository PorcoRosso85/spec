{
  description = "Spec repo - URN-based SSOT for features, environments, and adapters";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
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

        # Phase 0: Factory + Validator (Bug 1-9 + U1-U2 fixes)
        builders = import ./nix/lib/builders.nix {
          inherit pkgs self;
          cue = cue-v15;
        };

        # Integration test utilities (Phase 6)
        integration = import ./nix/lib/integration.nix {
          inherit pkgs self;
          cue = cue-v15;
        };

        # Phase 10: DoD5/DoD6 - feat-repo contract validation
        dod5FeatInputs = import ./nix/lib/dod5-feat-inputs.nix { inherit pkgs; };
        dod6ExpectedOutputs = import ./nix/lib/dod6-expected-outputs.nix { inherit pkgs; };

        # Phase 5: flakeChecksList - Auto-generated from self.checks (no external command)
        # Using attrNames for pure, deterministic, no-fragile generation
        flakeChecksList = builtins.attrNames (self.checks.${system} or { });

        checks-defs = import ./nix/checks.nix {
          inherit pkgs self;
          cue = cue-v15;
        };
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

        # Phase 7: CI Requirements Export
        packages.ci-requirements =
          pkgs.runCommand "ci-requirements-export"
            {
              nativeBuildInputs = [
                pkgs.bash
                pkgs.jq
                pkgs.coreutils
              ];
            }
            ''
              ${pkgs.bash}/bin/bash ${./scripts/export-ci-requirements.sh} ${./repo.cue} $out
            '';

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

        # ✅ Phase 8: Integration tests - Reference checks (no duplication)
        packages.integration-verify-dod1 = self.checks.${system}.integration-verify-dod1;
        packages.integration-negative-dod1 = self.checks.${system}.integration-negative-dod1;
        packages.integration-verify-dod2 = self.checks.${system}.integration-verify-dod2;
        packages.integration-negative-dod2 = self.checks.${system}.integration-negative-dod2;
        packages.integration-verify-dod3 = self.checks.${system}.integration-verify-dod3;
        packages.integration-negative-dod3 = self.checks.${system}.integration-negative-dod3;
        packages.integration-verify-dod4 = self.checks.${system}.integration-verify-dod4;
        packages.integration-negative-dod4 = self.checks.${system}.integration-negative-dod4;

        # Check definitions (SSOT for CI)
        # Note: TDD-RED checks removed - use packages.verify-red-* instead
        checks = checks-defs // {
          # Phase 0: Meta-DoD checks (9 bugs + U1-U2 fixes)
          dod0-factory-only = import ./nix/checks/dod0-factory-only.nix { inherit pkgs self; };
          dod0-flake-srp = import ./nix/checks/dod0-flake-srp.nix { inherit pkgs self; };
          dod8-patterns-ssot = import ./nix/checks/dod8-patterns-ssot.nix { inherit pkgs self; };

          # Phase 8: DoD7 - Integration test duplication detection
          dod7-no-integration-duplication = import ./nix/checks/dod7-no-integration-duplication.nix {
            inherit pkgs self;
          };

          # Phase 10: DoD5/DoD6 TDD tests - Positive tests (must PASS in both RED and GREEN)
          test-dod5-positive = import ./nix/checks/test-dod5-positive.nix {
            inherit pkgs self builders;
            inherit dod5FeatInputs;
          };
          test-dod6-positive = import ./nix/checks/test-dod6-positive.nix {
            inherit pkgs self builders;
            inherit dod6ExpectedOutputs;
          };

          # Phase 2: repo-cue-validity (Repo DoD - CI要件SSOT成立条件)
          repo-cue-validity = import ./nix/checks/repo-cue-validity.nix {
            inherit pkgs self;
            cue = cue-v15;
            checksAttrNames = flakeChecksList;
          };

          # Phase 6: Format independence regression test (検証 requiredChecks formatting で壊れないこと)
          repo-cue-format-independence = import ./nix/checks/repo-cue-format-independence.nix {
            inherit pkgs self system;
          };

          # Phase 7.2: CI Requirements Consistency Check
          ci-requirements-consistency =
            pkgs.runCommand "ci-requirements-consistency"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.jq
                  pkgs.coreutils
                ];
                ciReq = self.packages.${system}.ci-requirements;
                dontUnpack = true;
              }
              ''
                cp -r $ciReq ci-requirements
                ${pkgs.bash}/bin/bash ${./scripts/check-ci-consistency.sh} ${./repo.cue} \
                  ci-requirements/ci-requirements.json ci-requirements/ci-requirements.sha256
                touch $out
              '';

          # Phase 8: feat-sandboxes-validity
          feat-sandboxes-validity = import ./nix/checks/feat-sandboxes-validity.nix {
            inherit pkgs self;
            cue = cue-v15;
          };
        };

        # RED-phase checks: Expected to FAIL during RED, PASS during GREEN
        # Separated from regular checks to avoid breaking CI during RED phase
        checksRed = {
          # Phase 10: DoD5/DoD6 Negative-verify tests (FAIL in RED, PASS in GREEN)
          test-dod5-negative-verify = import ./nix/checks/test-dod5-negative-verify.nix {
            inherit pkgs self builders;
            inherit dod5FeatInputs;
          };
          test-dod6-negative-verify = import ./nix/checks/test-dod6-negative-verify.nix {
            inherit pkgs self builders;
            inherit dod6ExpectedOutputs;
          };
        };

        # Expose lib for external use and testing
        lib = {
          inherit builders;
          inherit dod5FeatInputs;
          inherit dod6ExpectedOutputs;
        };
      }
    )
    // {
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
