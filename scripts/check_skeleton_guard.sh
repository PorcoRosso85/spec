#!/usr/bin/env bash
# Check that new directories are authorized in skeleton.json
# Used by CI: skeleton-guard job

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKELETON="$REPO_ROOT/docs/structure/.gen/skeleton.json"

echo "🔍 Checking skeleton guard..."

# Check if skeleton.json exists
if [ ! -f "$SKELETON" ]; then
    echo "❌ Error: skeleton.json not found at $SKELETON"
    exit 1
fi

# Get base branch (default: origin/main)
BASE_BRANCH="${BASE_BRANCH:-origin/main}"

# Get authorized paths from skeleton.json (supports both string and object values)
AUTHORIZED_PATHS=$(jq -r '
  to_entries
  | map(select(.key | startswith("_") | not))
  | map(
      if (.value | type) == "object"
      then .value.placement // ""
      else .value
      end
    )
  | .[]
' "$SKELETON" 2>/dev/null || echo "")

# Get excluded paths
EXCLUDED_PATHS=$(jq -r '._meta.excludeFromGuard[]? // empty' "$SKELETON" 2>/dev/null || echo "")

echo "  Authorized paths:"
if [ -n "$AUTHORIZED_PATHS" ]; then
    echo "$AUTHORIZED_PATHS" | sed 's/^/    - /'
else
    echo "    (none - all new paths will be rejected)"
fi

echo ""
echo "  Excluded paths (always allowed):"
if [ -n "$EXCLUDED_PATHS" ]; then
    echo "$EXCLUDED_PATHS" | sed 's/^/    - /'
else
    echo "    (none)"
fi

# Get list of changed files in this PR/commit
if git rev-parse "$BASE_BRANCH" >/dev/null 2>&1; then
    CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || echo "")
else
    echo "⚠️  Warning: Base branch $BASE_BRANCH not found, checking all tracked files"
    CHANGED_FILES=$(git ls-files)
fi

if [ -z "$CHANGED_FILES" ]; then
    echo "✅ No changed files detected"
    exit 0
fi

echo ""
echo "  Changed files in this PR:"
echo "$CHANGED_FILES" | sed 's/^/    /'

# Extract top-level directories from changed files
NEW_PATHS=$(echo "$CHANGED_FILES" | grep -E '^[^/]+/' | sed 's|^\([^/]*\)/.*|\1/|' | sort -u)

if [ -z "$NEW_PATHS" ]; then
    echo "✅ No new top-level directories"
    exit 0
fi

echo ""
echo "  Top-level paths touched:"
echo "$NEW_PATHS" | sed 's/^/    - /'

# Check each new path
UNAUTHORIZED=()

for path in $NEW_PATHS; do
    # Check if in excluded paths
    IS_EXCLUDED=false
    while IFS= read -r excluded; do
        if [[ "$path" == "$excluded"* ]]; then
            IS_EXCLUDED=true
            break
        fi
    done <<< "$EXCLUDED_PATHS"

    if [ "$IS_EXCLUDED" = true ]; then
        echo "  ✓ $path (excluded - always allowed)"
        continue
    fi

    # Check if authorized by skeleton.json
    IS_AUTHORIZED=false
    while IFS= read -r auth; do
        if [[ "$path" == "$auth"* ]] || [[ "$auth" == "$path"* ]]; then
            IS_AUTHORIZED=true
            break
        fi
    done <<< "$AUTHORIZED_PATHS"

    if [ "$IS_AUTHORIZED" = true ]; then
        echo "  ✓ $path (authorized by skeleton.json)"
    else
        echo "  ✗ $path (UNAUTHORIZED)"
        UNAUTHORIZED+=("$path")
    fi
done

# Report results
if [ ${#UNAUTHORIZED[@]} -gt 0 ]; then
    echo ""
    echo "❌ Unauthorized paths detected:"
    printf '  - %s\n' "${UNAUTHORIZED[@]}"
    echo ""
    echo "To fix this issue:"
    echo "  1. Add slot to docs/catalog/slots/*.cue"
    echo "  2. Create ADR in docs/adr/adr-NNNN.cue declaring activation"
    echo "  3. Update docs/structure/.gen/skeleton.json with placement"
    echo "  4. Or add to _meta.excludeFromGuard if this is a non-responsibility path"
    exit 1
fi

echo ""
echo "✅ All paths are authorized by skeleton.json"
