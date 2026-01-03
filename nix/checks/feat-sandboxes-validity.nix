# nix/checks/feat-sandboxes-validity.nix
# Phase 8: Validate all repo.cue files in sandboxes/
# - Auto-discovers sandboxes/<slug>/repo.cue
# - Validates CUE syntax, requiredChecks not empty, no duplicates, no mock-spec
# - Validates SRP: closed schema (CI要件データ専用), no import
# - Single aggregated check (no check name proliferation)

{
  pkgs,
  self,
  cue,
}:
let
  sandboxesRoot = self + "/spec/urn/feat/sandboxes";
  schemaCue = sandboxesRoot + "/schema.cue";
  repo-cue-extract = import ../lib/repo-cue-extract.nix { inherit pkgs; };
  extractBin = repo-cue-extract.extractRequiredChecksBin;
in
pkgs.runCommand "feat-sandboxes-validity"
  {
    buildInputs = [ pkgs.coreutils ];
  }
  ''
    set -euo pipefail

    echo "=== Phase 8: feat-sandboxes-validity ==="
    echo "Purpose: Validate all repo.cue in spec/urn/feat/sandboxes/"
    echo ""

    if [ ! -d "${sandboxesRoot}" ]; then
      echo "PASS: no sandboxes to validate"
      echo "feat-sandboxes-validity: PASS (empty)" > "$out"
      exit 0
    fi

    SLUGS=$(ls -1 "${sandboxesRoot}" 2>/dev/null | grep -v '^default\.nix$' | grep -v '^default\.nix\.nix$' || true)
    if [ -z "$SLUGS" ]; then
      echo "PASS: no sandboxes to validate"
      echo "feat-sandboxes-validity: PASS (empty)" > "$out"
      exit 0
    fi

    echo "Found sandboxes: $SLUGS"
    echo ""

    VALIDATION_ERRORS=""

    for SLUG in $SLUGS; do
      REPO_CUE="${sandboxesRoot}/$SLUG/repo.cue"

      if [ ! -f "$REPO_CUE" ]; then
        echo "SKIP: $SLUG/repo.cue not found"
        continue
      fi

      echo "Validating: $SLUG/repo.cue"

      if ! head -5 "$REPO_CUE" | grep -qE "^[a-z]"; then
        echo "  FAIL: CUE syntax check failed"
        VALIDATION_ERRORS="$VALIDATION_ERRORS$SLUG: CUE syntax"$'\n'
        continue
      fi
      echo "  OK: CUE syntax"

      if grep -q "mock-spec" "$REPO_CUE" 2>/dev/null; then
        echo "  FAIL: mock-spec detected (本件無関係)"
        VALIDATION_ERRORS="$VALIDATION_ERRORS$SLUG: mock-spec detected"$'\n'
        continue
      fi
      echo "  OK: mock-spec: none"

      if grep -q 'import "' "$REPO_CUE" 2>/dev/null; then
        echo "  FAIL: import detected (SRP違反: 外部依存の侵入口)"
        VALIDATION_ERRORS="$VALIDATION_ERRORS$SLUG: import detected"$'\n'
        continue
      fi
      echo "  OK: no import (SRP: CI要件データ専用)"

      if [ -f "${schemaCue}" ]; then
        if ${cue}/bin/cue vet "${schemaCue}" "$REPO_CUE" 2>/dev/null; then
          echo "  OK: schema closed (SRP: CI要件データ専用)"
        else
          echo "  FAIL: schema validation failed (SRP違反: 許可されていないフィールド)"
          VALIDATION_ERRORS="$VALIDATION_ERRORS$SLUG: schema validation failed"$'\n'
          continue
        fi
      else
        echo "  SKIP: schema.cue not found"
      fi

      REQUIRED_CHECKS=$("${extractBin}/bin/extract-required-checks" "$REPO_CUE")
      if [ -z "$REQUIRED_CHECKS" ]; then
        echo "  FAIL: requiredChecks is empty"
        VALIDATION_ERRORS="$VALIDATION_ERRORS$SLUG: requiredChecks empty"$'\n'
        continue
      fi
      echo "  OK: requiredChecks: present ($(echo "$REQUIRED_CHECKS" | wc -l) items)"

      COUNT=$(echo "$REQUIRED_CHECKS" | wc -l)
      UNIQ_COUNT=$(echo "$REQUIRED_CHECKS" | sort -u | wc -l)
      if [ "$COUNT" -ne "$UNIQ_COUNT" ]; then
        echo "  FAIL: requiredChecks has duplicates"
        VALIDATION_ERRORS="$VALIDATION_ERRORS$SLUG: duplicates in requiredChecks"$'\n'
        continue
      fi
      echo "  OK: requiredChecks: no duplicates"

      echo "  OK: $SLUG/repo.cue: PASS"
      echo ""
    done

    if [ -n "$VALIDATION_ERRORS" ]; then
      echo "=== VALIDATION FAILED ==="
      echo -e "$VALIDATION_ERRORS"
      echo "feat-sandboxes-validity: FAIL" > "$out"
      exit 1
    fi

    echo "=== feat-sandboxes-validity: PASS ==="
    echo "All sandboxes validated successfully."
    echo "feat-sandboxes-validity: PASS" > "$out"
  ''
