{ pkgs }:
pkgs.runCommand "no-repo-cue-tracked"
  {
    description = "FAIL if repo.cue exists in tracked files";
  }
  ''
    set -euo pipefail

    echo "=== no_repo_cue_tracked ==="

    VIOLATIONS=$(git ls-files | grep -E '(^|/)repo\.cue$' || true)

    if [ -n "$VIOLATIONS" ]; then
      echo "FAIL: repo.cue found in tracked files:"
      echo "$VIOLATIONS"
      exit 1
    fi

    echo "PASS: no repo.cue in tracked files"
    mkdir -p $out && echo "ok" > $out/result
  ''
