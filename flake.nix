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
      in
      {
        # 開発環境（CUEツールを含む）
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cue
            git
          ];

          shellHook = ''
            echo "🚀 Spec repo development environment"
            echo ""
            echo "Available commands:"
            echo "  cue eval ./spec/...           - Evaluate all spec definitions"
            echo "  cue vet ./spec/ci/checks/...  - Validate CI checks"
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
