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
        checks-defs = import ./nix/checks.nix { inherit pkgs self; };
      in
      {
        # 開発環境（CUEツールを含む）
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cue
            git
            bash
            go
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
          ${pkgs.cue}/bin/cue eval ./spec/...

          echo ""
          echo "→ cue vet ./spec/ci/checks/..."
          ${pkgs.cue}/bin/cue vet ./spec/ci/checks/... ./spec/...

          echo ""
          echo "✅ All validations passed"
        '';

        packages.default = self.packages.${system}.validate;

        # Check definitions (SSOT for CI)
        checks = {
          spec-smoke = checks-defs.spec-smoke;
          spec-fast = checks-defs.spec-fast;
          spec-slow = checks-defs.spec-slow;
          spec-unit = checks-defs.spec-unit;
          spec-e2e = checks-defs.spec-e2e;
        };
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
