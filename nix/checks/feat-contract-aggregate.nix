{
  pkgs,
  self,
  cue,
}:
let
  featRoot = self + "/spec/urn/feat";
in
pkgs.runCommand "feat-contract-aggregate"
  {
    buildInputs = [ cue ];
  }
  ''
    set -euo pipefail

    echo "=== feat_contract_aggregate ==="

    CONTRACTS=$(find "${featRoot}" -mindepth 2 -maxdepth 2 -name contract.cue -print 2>/dev/null || true)

    if [ -z "$CONTRACTS" ]; then
      echo "PASS: no feat contracts found"
      mkdir -p $out && echo "ok" > $out/result
      exit 0
    fi

    FAILED=""
    for CONTRACT in $CONTRACTS; do
      echo "Validating: $CONTRACT"

      if ! ${cue}/bin/cue eval "$CONTRACT" 2>&1 > /dev/null; then
        echo "  FAIL: CUE syntax error"
        FAILED="$FAILED$CONTRACT: CUE syntax"$'\n'
        continue
      fi

      if ! ${cue}/bin/cue export "$CONTRACT" -e requiredChecks --out json 2>/dev/null | grep -q '"'; then
        echo "  FAIL: requiredChecks missing or empty"
        FAILED="$FAILED$CONTRACT: requiredChecks missing"$'\n'
        continue
      fi

      echo "  OK"
    done

    if [ -n "$FAILED" ]; then
      echo ""
      echo "FAIL:"
      echo -e "$FAILED"
      exit 1
    fi

    echo "PASS: all feat contracts valid"
    mkdir -p $out && echo "ok" > $out/result
  ''
