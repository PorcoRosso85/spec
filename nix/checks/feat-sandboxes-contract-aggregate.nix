{
  pkgs,
  self,
  cue,
}:
let
  sandboxesRoot = self + "/spec/urn/feat/sandboxes";
in
pkgs.runCommand "feat-sandboxes-contract-aggregate"
  {
    description = "Validate all sandboxes/*/contract.cue files";
  }
  ''
    set -euo pipefail

    echo "=== feat_sandboxes_contract_aggregate ==="

    SCHEMA="${self}/spec/ci/contract/contract.cue"

    if [ ! -d "${sandboxesRoot}" ]; then
      echo "PASS: sandboxes directory empty (no contracts to validate)"
      mkdir -p $out && echo "ok" > $out/result
      exit 0
    fi

    CONTRACTS=$(find "${sandboxesRoot}" -mindepth 2 -maxdepth 2 -name contract.cue -print 2>/dev/null || true)

    if [ -z "$CONTRACTS" ]; then
      echo "PASS: no contract.cue files in sandboxes"
      mkdir -p $out && echo "ok" > $out/result
      exit 0
    fi

    echo "Found contracts:"
    echo "$CONTRACTS"
    echo ""

    FAILED=""
    for CONTRACT in $CONTRACTS; do
      echo "Validating: $CONTRACT"
      if ! ${cue}/bin/cue vet "$CONTRACT" "$SCHEMA" 2>&1; then
        echo "  FAIL: $CONTRACT"
        FAILED="$FAILED$CONTRACT"$'\n'
      else
        echo "  OK"
      fi
    done

    if [ -n "$FAILED" ]; then
      echo ""
      echo "FAIL: validation errors:"
      echo -e "$FAILED"
      exit 1
    fi

    echo ""
    echo "PASS: all sandboxes contracts valid"
    mkdir -p $out && echo "ok" > $out/result
  ''
