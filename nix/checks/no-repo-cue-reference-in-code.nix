{ pkgs, self }:
let
  excludePatterns = [
    "snapshot.log"
    "phase6_submission_pack.md"
    "phase7_work_order.md"
    "phase6_9_work_order.md"
  ];
in
pkgs.runCommand "no-repo-cue-reference-in-code"
  {
    description = "FAIL if repo.cue is referenced in code/scripts";
  }
  ''
    set -euo pipefail

    echo "=== no_repo_cue_reference_in_code ==="

    VIOLATIONS=$(git grep -n 'repo\.cue' -- ':(exclude)*.log' ':(exclude)*.md' ':(exclude)nix/checks/no-repo-cue-reference-in-code.nix' 2>/dev/null || true)

    if [ -n "$VIOLATIONS" ]; then
      echo "FAIL: repo.cue referenced in code:"
      echo "$VIOLATIONS"
      exit 1
    fi

    echo "PASS: no repo.cue reference in code"
    mkdir -p $out && echo "ok" > $out/result
  ''
