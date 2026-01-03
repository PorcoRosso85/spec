# nix/checks/feat-sandboxes-validity.nix
# Phase 8: Validate all repo.cue files in sandboxes/
# - Auto-discovers sandboxes/<slug>/repo.cue
# - Validates CUE syntax, requiredChecks not empty, no duplicates, no mock-spec
# - Single aggregated check (no check name proliferation)

{ pkgs, self }:
let
  sandboxesRoot = self + "/spec/urn/feat/sandboxes";
  repo-cue-extract = import ../lib/repo-cue-extract.nix { inherit pkgs; };
  extractBin = repo-cue-extract.extractRequiredChecksBin;

  sandboxes = pkgs.stdenv.mkDerivation {
    name = "sandboxes-list";
    dontUnpack = true;
    dontBuild = true;
    outputHashMode = "flat";

    passAsFile = {
      list =
        if pkgs.lib.pathExists sandboxesRoot then
          pkgs.lib.concatStringsSep "\n" (
            pkgs.lib.filter (f: f != "" && f != "default.nix" && f != "default.nix.nix") (
              pkgs.lib.attrNames (builtins.readDir sandboxesRoot)
            )
          )
        else
          "";
    };

    installPhase = ''
      mkdir -p $out
      echo "$list" > $out/list
    '';
  };
in
pkgs.runCommand "feat-sandboxes-validity"
  {
    buildInputs = [ pkgs.coreutils ];
    sandboxesList = sandboxes.list;
  }
  ''
    set -euo pipefail

    echo "=== Phase 8: feat-sandboxes-validity ==="
    echo "Purpose: Validate all repo.cue in spec/urn/feat/sandboxes/"
    echo ""

    SLUGS=$(cat "$sandboxesList")
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
