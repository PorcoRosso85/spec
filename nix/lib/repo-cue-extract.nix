# nix/lib/repo-cue-extract.nix
# Format-independent extraction of requiredChecks from repo.cue
# Used by: repo-cue-format-independence, feat-sandboxes-validity
#
# I/F:
#   extractRequiredChecks: -> writeShellScriptBin (executable)
#   Usage: extract-required-checks /path/to/repo.cue
#   Output: newline-separated list of check names (sorted, unique)

{ pkgs }:
let
  extractRequiredChecksBin = pkgs.writeShellScriptBin "extract-required-checks" ''
    set -euo pipefail

    REPO_CUE="$1"
    if [ ! -f "$REPO_CUE" ]; then
      echo "ERROR: file not found: $REPO_CUE" >&2
      exit 1
    fi

    sed -n "/requiredChecks:/,/^[[:space:]]*\]/p" "$REPO_CUE" \
      | sed 's,//.*$,,' \
      | grep -oE '"[^"]+"' \
      | tr -d '"' \
      | sort -u
  '';
in
{
  inherit extractRequiredChecksBin;
}
