{
  pkgs,
  self,
  cue,
  checksAttrNames,
}:

pkgs.runCommand "repo-cue-validity"
  {
    buildInputs = [
      cue
      pkgs.jq
    ];
    # checksAttrNames is a list of check names passed from flake.nix
    checksJson = pkgs.writeText "checks.json" (builtins.toJSON checksAttrNames);
  }
  ''
    set -euo pipefail
    cd ${self}

    echo "🔍 repo-cue-validity check"
    echo ""

    # 1. repo.cue exists and is valid CUE
    echo "→ Checking repo.cue exists and evaluates..."
    if [ ! -f "./repo.cue" ]; then
      echo "❌ FAIL: repo.cue not found"
      exit 1
    fi

    ${cue}/bin/cue eval ./repo.cue > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo "❌ FAIL: repo.cue is not valid CUE"
      exit 1
    fi
    echo "✅ repo.cue exists and is valid"
    echo ""

    # 2. Extract requiredChecks from repo.cue
    echo "→ Extracting requiredChecks..."
    REQUIRED_CHECKS=$(${cue}/bin/cue export ./repo.cue -e 'repo.requiredChecks' --out json 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
    if [ -z "$REQUIRED_CHECKS" ]; then
      echo "❌ FAIL: repo.requiredChecks not found or empty"
      exit 1
    fi

    echo "Found $(echo "$REQUIRED_CHECKS" | wc -l) required checks"
    echo ""

    # 3. Check for duplicates in requiredChecks
    echo "→ Checking for duplicates in requiredChecks..."
    DUPLICATES=$(echo "$REQUIRED_CHECKS" | sort | uniq -d)
    if [ -n "$DUPLICATES" ]; then
      echo "❌ FAIL: Duplicate checks found:"
      echo "$DUPLICATES"
      exit 1
    fi
    echo "✅ No duplicates found"
    echo ""

    # 4. Get flake checks names from JSON (passed from flake.nix)
    echo "→ Getting flake checks names..."
    FLAKE_CHECKS=$(cat "$checksJson" | jq -r '.[]' 2>/dev/null | sort -u || echo "")

    if [ -z "$FLAKE_CHECKS" ]; then
      echo "⚠️  Could not get flake checks, using empty list"
      FLAKE_CHECKS=""
    fi

    echo "Found $(echo "$FLAKE_CHECKS" | wc -l) flake checks"
    echo ""

    # 5. Verify all requiredChecks exist in flake checks
    echo "→ Verifying requiredChecks are in flake checks..."
    MISSING=""
    for check in $REQUIRED_CHECKS; do
      if ! echo "$FLAKE_CHECKS" | grep -qx "$check"; then
        MISSING="$MISSING$check\n"
        echo "  ❌ Missing: $check"
      fi
    done

    if [ -n "$MISSING" ]; then
      echo ""
      echo "❌ FAIL: Some requiredChecks not in flake checks"
      exit 1
    fi
    echo "✅ All required checks found in flake"
    echo ""

    # 6. Check deliverablesRefs paths exist
    echo "→ Checking deliverablesRefs paths..."
    DELIVERABLES_REFS=$(${cue}/bin/cue export ./repo.cue -e 'repo.deliverablesRefs' --out json 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")

    if [ -n "$DELIVERABLES_REFS" ]; then
      BROKEN=""
      for ref in $DELIVERABLES_REFS; do
        if [ ! -e "$ref" ]; then
          BROKEN="$BROKEN$ref\n"
          echo "  ❌ Broken ref: $ref"
        fi
      done

      if [ -n "$BROKEN" ]; then
        echo ""
        echo "❌ FAIL: Some deliverablesRefs are broken"
        exit 1
      fi
    fi
    echo "✅ All deliverablesRefs exist"
    echo ""

    echo "✅ repo-cue-validity PASS"
    mkdir -p $out && echo "ok" > $out/result
  ''
