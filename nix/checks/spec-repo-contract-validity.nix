{
  pkgs,
  self,
  cue,
}:
pkgs.runCommand "spec-repo-contract-validity"
  {
    description = "Validate spec/urn/spec-repo/contract.cue against schema";
  }
  ''
    set -euo pipefail

    echo "=== spec_repo_contract_validity ==="

    CONTRACT="${self}/spec/urn/spec-repo/contract.cue"
    SCHEMA="${self}/spec/ci/contract/contract.cue"

    if [ ! -f "$CONTRACT" ]; then
      echo "FAIL: found at contract.cue not $CONTRACT"
      exit 1
    fi

    if [ ! -f "$SCHEMA" ]; then
      echo "FAIL: schema not found at $SCHEMA"
      exit 1
    fi

    if ${cue}/bin/cue vet "$CONTRACT" "$SCHEMA" 2>&1; then
      echo "PASS: contract.cue is valid"
      mkdir -p $out && echo "ok" > $out/result
    else
      echo "FAIL: contract.cue validation failed"
      exit 1
    fi
  ''
