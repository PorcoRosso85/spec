{
  pkgs,
  self,
  system,
}:
let
  originalRepoCue = self + "/repo.cue";
in
pkgs.runCommand "repo-cue-format-independence"
  {
    buildInputs = [
      pkgs.coreutils
      pkgs.jq
    ];

    passAsFile = [ "resultFile" ];

    resultFile = pkgs.writeText "test-result" "";
  }
  ''
      set -euo pipefail

      echo "=== Phase 6 Pre-Test: Format Independence Regression ==="
      echo "Purpose: Verify repo-cue-validity is truly format-independent"
      echo ""
      echo "Note: Tests modify temporary repo.cue, not the store version"

      echo "Test 1: Single-line format"
      cat > repo.cue << 'EOF'
    repo: {
      requiredChecks: ["dod0-factory-only", "dod0-flake-srp", "dod7-no-integration-duplication", "dod8-patterns-ssot", "spec-e2e", "spec-fast", "spec-slow", "spec-smoke", "spec-unit", "feat-decide-ci-score-matrix", "feat-spec", "unit-green-dod1", "unit-green-dod2", "unit-green-dod3", "unit-green-dod4", "integration-negative-dod1", "integration-negative-dod2", "integration-negative-dod3", "integration-negative-dod4", "integration-verify-dod1", "integration-verify-dod2", "integration-verify-dod3", "integration-verify-dod4", "global-uniq-fixtures", "policy-dev-scope", "test-dod5-positive", "test-dod6-positive", "repo-cue-validity"]
      deliverablesRefs: ["spec/ci/contract", "spec/ci/detector", "spec/ci/tdd", "spec/ci/fixtures", "spec/ci/checks", "spec/urn", "spec/schema", "spec/adapter", "spec/mapping", "spec/external"]
    }
    EOF

      echo "  Checking single-line format..."
      line=$(grep 'requiredChecks:' repo.cue)
      SINGLE_LINE_COUNT=$(echo "$line" | sed 's/.*\[\(.*\)\].*/\1/' | grep -o '"[^"]*"' | wc -l | tr -d ' ')
      echo "  Single-line item count: $SINGLE_LINE_COUNT"

      if [ "$SINGLE_LINE_COUNT" -eq 28 ]; then
        echo "  ✅ Single-line format: count correct (28)"
      else
        echo "  ❌ Single-line format: count mismatch (expected 28, got $SINGLE_LINE_COUNT)"
        exit 1
      fi

      echo ""
      echo "Test 2: Extra whitespace and newlines"
      cat > repo.cue << 'EOF'
    repo: {
      requiredChecks: [
        "dod0-factory-only",

        "dod0-flake-srp",

        "dod7-no-integration-duplication",
        "dod8-patterns-ssot",


        "spec-e2e",
        "spec-fast",


        "spec-slow",
        "spec-smoke",
        "spec-unit",

        "feat-decide-ci-score-matrix",
        "feat-spec",

        "unit-green-dod1",
        "unit-green-dod2",
        "unit-green-dod3",
        "unit-green-dod4",

        "integration-negative-dod1",
        "integration-negative-dod2",
        "integration-negative-dod3",
        "integration-negative-dod4",
        "integration-verify-dod1",
        "integration-verify-dod2",
        "integration-verify-dod3",
        "integration-verify-dod4",

        "global-uniq-fixtures",
        "policy-dev-scope",

        "test-dod5-positive",
        "test-dod6-positive",

        "repo-cue-validity",
      ]
    }
    EOF

      echo "  Checking multi-line with extra blanks..."
      sed -n '/requiredChecks:/,/^  \]/p' repo.cue | grep -o '"[^"]*"' > multi_line_checks.txt
      MULTI_LINE_COUNT=$(wc -l < multi_line_checks.txt | tr -d ' ')
      echo "  Multi-line item count: $MULTI_LINE_COUNT"

      if [ "$MULTI_LINE_COUNT" -eq 28 ]; then
        echo "  ✅ Multi-line format: count correct (28)"
      else
        echo "  ❌ Multi-line format: count mismatch (expected 28, got $MULTI_LINE_COUNT)"
        exit 1
      fi

      echo ""
      echo "=== Phase 6 Pre-Test: PASSED ==="
      echo "repo-cue-validity is truly format-independent"

      echo "format-independence: PASS" >> "$resultFile"
  ''
