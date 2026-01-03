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

{
  pkgs,
  self,
  cue,
}:

let
  # Integration test utilities (Phase 6)
  integration = import ./lib/integration.nix { inherit pkgs self cue; };

  # Per-feat derivation splitting for parallel validation
  # Exclude 'sandboxes' (Phase 8 special directory for CI要件データ only)
  featDirs = builtins.filter (d: d != "sandboxes") (
    builtins.attrNames (builtins.readDir (self + "/spec/urn/feat"))
  );

  mkFeatCheck =
    slug:
    pkgs.runCommand "feat-${slug}"
      {
        buildInputs = [ cue ];
      }
      ''
        set -euo pipefail
        cd ${self}

        echo "→ Validating feat: ${slug}"
        ${cue}/bin/cue vet \
          ./spec/urn/feat/${slug}/... \
          ./spec/schema/... \
          ./spec/ci/contract/...

        echo "✅ feat-${slug} PASS"
        mkdir -p $out && echo "ok" > $out/result
      '';

  featChecks = builtins.listToAttrs (
    map (slug: {
      name = "feat-${slug}";
      value = mkFeatCheck slug;
    }) featDirs
  );

  # Global uniqueness check: Detect duplicate feat IDs across all feats
  # DoD論点4: CUE乱立でも4原則（重複なし）担保
  global-uniq-fixtures =
    pkgs.runCommand "global-uniq-fixtures"
      {
        buildInputs = [
          cue
          pkgs.jq
        ];
      }
      ''
        set -euo pipefail
        cd ${self}

        echo "🔍 Global uniqueness check (fixtures)"

        # Extract all feat IDs from duplicate-feat-id fixtures
        FIXTURE_DIR="./spec/ci/fixtures/fail/duplicate-feat-id"

        if [ ! -d "$FIXTURE_DIR" ]; then
          echo "⚠️  No duplicate-feat-id fixtures, skipping"
          mkdir -p $out && echo "skipped" > $out/result
          exit 0
        fi

        # Extract IDs from all subdirectories
        IDS_FILE=$(mktemp)
        for feat_dir in "$FIXTURE_DIR"/*/; do
          if [ -d "$feat_dir" ]; then
            echo "  Checking: $(basename "$feat_dir")"
            # Use cue eval with -e to extract specific field
            CUE_OUT=$(${cue}/bin/cue eval "$feat_dir"/feature.cue -e feature.id 2>&1 || true)
            echo "    CUE output: $CUE_OUT"
            ID=$(echo "$CUE_OUT" | tr -d '"' | grep -E '^urn:' || true)
            if [ -n "$ID" ]; then
              echo "    ✅ Extracted ID: $ID"
              echo "$ID" >> "$IDS_FILE"
            else
              echo "    ⚠️  Failed to extract ID"
            fi
          fi
        done

        echo ""
        echo "All extracted IDs:"
        cat "$IDS_FILE"
        echo ""

        # Check for duplicates
        DUPLICATES=$(sort "$IDS_FILE" | uniq -d)

        if [ -n "$DUPLICATES" ]; then
          echo "✅ Duplicate IDs detected (as expected for FAIL fixture):"
          echo "$DUPLICATES"
          mkdir -p $out && echo "ok" > $out/result
        else
          echo "❌ No duplicates found - fixture should contain duplicate IDs!"
          exit 1
        fi
      '';

  # Policy check: dev branch scope validation
  policy-dev-scope =
    pkgs.runCommand "policy-dev-scope"
      {
        buildInputs = with pkgs; [
          git
          bash
        ];
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

featChecks
// {
  # Global checks (cross-feat constraints)
  inherit global-uniq-fixtures;

  # Policy checks
  inherit policy-dev-scope;

  # Phase 0: Baseline smoke checks
  spec-smoke =
    pkgs.runCommand "spec-smoke"
      {
        buildInputs = [ cue ];
      }
      ''
        set -euo pipefail
        cd ${self}

        echo "🔍 Phase 0: smoke checks"
        ${cue}/bin/cue fmt --check ./spec
        # Note: fixtures除外（意図的PASS/FAIL検証はspec-fastで実施）
        # Note: checks/除外（未実装、次フェーズで対応）
        ${cue}/bin/cue vet \
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
  spec-fast =
    pkgs.runCommand "spec-fast"
      {
        buildInputs = [
          cue
          pkgs.bash
        ]
        ++ (builtins.attrValues featChecks)
        ++ [ policy-dev-scope ];
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
        ${cue}/bin/cue vet \
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
          ${cue}/bin/cue vet \
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
              
              # Skip duplicate-feat-id (tested by global-uniq-fixtures)
              if [ "$fixture_name" = "duplicate-feat-id" ]; then
                echo "  Skipping: $fixture_name (cross-feat check, tested by global-uniq-fixtures)"
                continue
              fi
              
              echo "  Testing: $fixture_name"
              
              # FAIL期待なので、exit 1が正常
              if ${cue}/bin/cue vet \
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
  spec-slow =
    pkgs.runCommand "spec-slow"
      {
        buildInputs = [ cue ];
      }
      ''
        set -euo pipefail
        cd ${self}

        echo "🐢 Phase 1: slow checks"
        # Note: fixtures除外（意図的PASS/FAIL検証はspec-fastで実施）
        # Note: checks/除外（未実装、次フェーズで対応）
        ${cue}/bin/cue vet \
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
  spec-unit = pkgs.runCommand "spec-unit" { } ''
    echo "ℹ️  spec:unit: placeholder (tests/unit/run.sh integration pending)"
    mkdir -p $out && echo "ok" > $out/result
  '';

  # Placeholder: e2e tests (future)
  spec-e2e = pkgs.runCommand "spec-e2e" { } ''
    echo "ℹ️  spec:e2e: placeholder (integration tests pending)"
    mkdir -p $out && echo "ok" > $out/result
  '';

  # Phase 5: TDD Unit GREEN checks (DoD1-4 detector契約検証)
  # Design: fixture入力でdetectorが正しく動作することを検証
  # Note: RED verification は packages.verify-red-* に分離済み

  unit-green-dod1 =
    pkgs.runCommand "unit-green-dod1"
      {
        buildInputs = [ cue ];
      }
      ''
        set -euo pipefail
        cd ${self}

        echo "✅ Unit GREEN: DoD1 (責務配分3カテゴリ)"
        ${cue}/bin/cue vet ./spec/ci/tdd/green/01-responsibility/...

        mkdir -p $out && echo "ok" > $out/result
      '';

  unit-green-dod2 =
    pkgs.runCommand "unit-green-dod2"
      {
        buildInputs = [ cue ];
      }
      ''
        set -euo pipefail
        cd ${self}

        echo "✅ Unit GREEN: DoD2 (consumer API)"
        ${cue}/bin/cue vet ./spec/ci/tdd/green/02-consumer-api/...

        mkdir -p $out && echo "ok" > $out/result
      '';

  unit-green-dod3 =
    pkgs.runCommand "unit-green-dod3"
      {
        buildInputs = [ cue ];
      }
      ''
        set -euo pipefail
        cd ${self}

        echo "✅ Unit GREEN: DoD3 (outputs manifest)"
        ${cue}/bin/cue vet ./spec/ci/tdd/green/03-outputs-manifest/...

        mkdir -p $out && echo "ok" > $out/result
      '';

  unit-green-dod4 =
    pkgs.runCommand "unit-green-dod4"
      {
        buildInputs = [ cue ];
      }
      ''
        set -euo pipefail
        cd ${self}

        echo "✅ Unit GREEN: DoD4 (重複なし)"
        ${cue}/bin/cue vet ./spec/ci/tdd/green/04-uniq/...

        mkdir -p $out && echo "ok" > $out/result
      '';

  # Phase 6: Integration checks (実データ接続検証)
  # Design: spec-repo実体（spec/urn/feat/*, self.spec等）を入力として検証
  # Note: verify=クリーン検証, negative=悪性検出検証（両方とも成功=PASS）

  integration-verify-dod4 = pkgs.stdenv.mkDerivation {
    name = "integration-verify-dod4";
    src = self;
    buildInputs = [ cue ];

    buildPhase =
      let
        feats = integration.extractAllFeats;
        inputCue = pkgs.writeText "input.cue" (integration.genFeatListVerifyCue feats);
      in
      ''
        echo "✅ Integration Verify: DoD4 (実データクリーン)"

        mkdir -p integration-test
        cp ${inputCue} integration-test/input.cue
        cp ${self}/spec/ci/integration/verify/04-uniq/expected.cue integration-test/
        cp ${self}/spec/ci/integration/verify/04-uniq/test.cue integration-test/

        cd integration-test
        ${cue}/bin/cue vet .
      '';

    installPhase = ''
      mkdir -p $out
      echo "verify-success" > $out/result
    '';
  };

  integration-negative-dod4 = pkgs.stdenv.mkDerivation {
    name = "integration-negative-dod4";
    src = self;
    buildInputs = [ cue ];

    buildPhase =
      let
        feats = integration.extractAllFeats;
        inputCue = pkgs.writeText "input.cue" (integration.genFeatListNegativeCue feats);
      in
      ''
        echo "✅ Integration Negative: DoD4 (悪性検出)"

        mkdir -p integration-test
        cp ${inputCue} integration-test/input.cue
        cp ${self}/spec/ci/integration/negative/04-uniq/expected.cue integration-test/
        cp ${self}/spec/ci/integration/negative/04-uniq/test.cue integration-test/

        cd integration-test
        ${cue}/bin/cue vet .
      '';

    installPhase = ''
      mkdir -p $out
      echo "negative-success" > $out/result
    '';
  };

  # DoD2: Consumer API Integration

  integration-verify-dod2 = pkgs.stdenv.mkDerivation {
    name = "integration-verify-dod2";
    src = self;
    buildInputs = [ cue ];

    buildPhase =
      let
        specKeys = integration.extractSpecKeys self.spec;
        inputCue = pkgs.writeText "input.cue" (integration.genConsumerAPIVerifyCue specKeys);
      in
      ''
        mkdir -p integration-test
        cp ${inputCue} integration-test/input.cue
        cp ${self}/spec/ci/integration/verify/02-consumer-api/expected.cue integration-test/
        cp ${self}/spec/ci/integration/verify/02-consumer-api/test.cue integration-test/

        cd integration-test
        ${cue}/bin/cue vet .
      '';

    installPhase = ''
      mkdir -p $out
      echo "verify-success" > $out/result
    '';
  };

  integration-negative-dod2 = pkgs.stdenv.mkDerivation {
    name = "integration-negative-dod2";
    src = self;
    buildInputs = [ cue ];

    buildPhase =
      let
        specKeys = integration.extractSpecKeys self.spec;
        missingKey = "spec.urn.envPath";
        inputCue = pkgs.writeText "input.cue" (integration.genConsumerAPINegativeCue specKeys missingKey);
      in
      ''
        mkdir -p integration-test
        cp ${inputCue} integration-test/input.cue
        cp ${self}/spec/ci/integration/negative/02-consumer-api/expected.cue integration-test/
        cp ${self}/spec/ci/integration/negative/02-consumer-api/test.cue integration-test/

        cd integration-test
        ${cue}/bin/cue vet .
      '';

    installPhase = ''
      mkdir -p $out
      echo "negative-success" > $out/result
    '';
  };

  # DoD1: Responsibility Integration

  integration-verify-dod1 = pkgs.stdenv.mkDerivation {
    name = "integration-verify-dod1";
    src = self;
    buildInputs = [ cue ];

    buildPhase =
      let
        feats = integration.extractAllFeats;
        firstFeat = builtins.head feats;
        inputCue = pkgs.writeText "input.cue" (integration.genResponsibilityVerifyCue firstFeat);
      in
      ''
        mkdir -p integration-test
        cp ${inputCue} integration-test/input.cue
        cp ${self}/spec/ci/integration/verify/01-responsibility/expected.cue integration-test/
        cp ${self}/spec/ci/integration/verify/01-responsibility/test.cue integration-test/

        cd integration-test
        ${cue}/bin/cue vet .
      '';

    installPhase = ''
      mkdir -p $out
      echo "verify-success" > $out/result
    '';
  };

  integration-negative-dod1 = pkgs.stdenv.mkDerivation {
    name = "integration-negative-dod1";
    src = self;
    buildInputs = [ cue ];

    buildPhase =
      let
        feats = integration.extractAllFeats;
        firstFeat = builtins.head feats;
        inputCue = pkgs.writeText "input.cue" (integration.genResponsibilityNegativeCue firstFeat);
      in
      ''
        mkdir -p integration-test
        cp ${inputCue} integration-test/input.cue
        cp ${self}/spec/ci/integration/negative/01-responsibility/expected.cue integration-test/
        cp ${self}/spec/ci/integration/negative/01-responsibility/test.cue integration-test/

        cd integration-test
        ${cue}/bin/cue vet .
      '';

    installPhase = ''
      mkdir -p $out
      echo "negative-success" > $out/result
    '';
  };

  # DoD3: Outputs Manifest Integration

  integration-verify-dod3 = pkgs.stdenv.mkDerivation {
    name = "integration-verify-dod3";
    src = self;
    buildInputs = [ cue ];

    buildPhase =
      let
        manifest = integration.extractManifest;
        specKeys = integration.extractSpecKeys self.spec;
        inputCue = pkgs.writeText "input.cue" (integration.genOutputsManifestVerifyCue manifest specKeys);
      in
      ''
        mkdir -p integration-test
        cp ${inputCue} integration-test/input.cue
        cp ${self}/spec/ci/integration/verify/03-outputs-manifest/expected.cue integration-test/
        cp ${self}/spec/ci/integration/verify/03-outputs-manifest/test.cue integration-test/

        cd integration-test
        ${cue}/bin/cue vet .
      '';

    installPhase = ''
      mkdir -p $out
      echo "verify-success" > $out/result
    '';
  };

  integration-negative-dod3 = pkgs.stdenv.mkDerivation {
    name = "integration-negative-dod3";
    src = self;
    buildInputs = [ cue ];

    buildPhase =
      let
        manifest = integration.extractManifest;
        specKeys = integration.extractSpecKeys self.spec;
        missingPath = "spec.cuePath";
        inputCue = pkgs.writeText "input.cue" (
          integration.genOutputsManifestNegativeCue manifest specKeys missingPath
        );
      in
      ''
        mkdir -p integration-test
        cp ${inputCue} integration-test/input.cue
        cp ${self}/spec/ci/integration/negative/03-outputs-manifest/expected.cue integration-test/
        cp ${self}/spec/ci/integration/negative/03-outputs-manifest/test.cue integration-test/

        cd integration-test
        ${cue}/bin/cue vet .
      '';

    installPhase = ''
      mkdir -p $out
      echo "negative-success" > $out/result
    '';
  };
}
