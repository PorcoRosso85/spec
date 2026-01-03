{ pkgs, self }:
let
  contractsDir = self + "/spec/urn";
in
pkgs.runCommand "contract-srp-policy"
  {
    description = "Enforce SRP: no import and no mock-spec in contract files";
  }
  ''
    set -euo pipefail

    echo "=== contract_srp_policy ==="

    if [ ! -d "${contractsDir}" ]; then
      echo "PASS: no contracts directory"
      mkdir -p $out && echo "ok" > $out/result
      exit 0
    fi

    CONTRACTS=$(find "${contractsDir}" -name "contract.cue" -print 2>/dev/null || true)

    if [ -z "$CONTRACTS" ]; then
      echo "PASS: no contract.cue files"
      mkdir -p $out && echo "ok" > $out/result
      exit 0
    fi

    FAILED=""

    for CONTRACT in $CONTRACTS; do
      echo "Checking: $CONTRACT"

      if grep -qE '^\s*import\s+"' "$CONTRACT" 2>/dev/null; then
        echo "  FAIL: import detected"
        FAILED="$FAILED$CONTRACT: import detected"$'\n'
      elif grep -q 'mock-spec' "$CONTRACT" 2>/dev/null; then
        echo "  FAIL: mock-spec detected"
        FAILED="$FAILED$CONTRACT: mock-spec detected"$'\n'
      else
        echo "  OK"
      fi
    done

    if [ -n "$FAILED" ]; then
      echo ""
      echo "FAIL: SRP violations found:"
      echo -e "$FAILED"
      exit 1
    fi

    echo ""
    echo "PASS: all contracts follow SRP policy"
    mkdir -p $out && echo "ok" > $out/result
  ''
