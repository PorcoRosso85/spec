{ pkgs }:
pkgs.runCommand "no-repo-cue-any"
  {
    description = "FAIL if repo.cue exists anywhere (including untracked)";
  }
  ''
    set -euo pipefail

    echo "=== no_repo_cue_any ==="

    VIOLATIONS=$(find . -path './.git' -prune -o -name repo.cue -print 2>/dev/null || true)

    if [ -n "$VIOLATIONS" ]; then
      echo "FAIL: repo.cue found:"
      echo "$VIOLATIONS"
      exit 1
    fi

    echo "PASS: no repo.cue anywhere"
    mkdir -p $out && echo "ok" > $out/result
  ''
