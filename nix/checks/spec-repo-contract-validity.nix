{
  pkgs,
  self,
  cue,
}:
pkgs.runCommand "spec-repo-contract-validity"
  {
    description = "Validate spec/urn/spec-repo/contract.cue";
  }
  ''
    set -euo pipefail

    echo "=== spec_repo_contract_validity ==="

    CONTRACT="${self}/spec/urn/spec-repo/contract.cue"

    if [ ! -f "$CONTRACT" ]; then
      echo "FAIL: contract.cue not found at $CONTRACT"
      exit 1
    fi

    if ${cue}/bin/cue eval "$CONTRACT" 2>&1; then
      echo "PASS: contract.cue is valid CUE"
      mkdir -p $out && echo "ok" > $out/result
    else
      echo "FAIL: contract.cue validation failed"
      exit 1
    fi
  ''
