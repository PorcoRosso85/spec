#!/usr/bin/env bash
set -euo pipefail

REPO_CUE="${1:-./repo.cue}"
CI_JSON="${2:-./ci-requirements.json}"
CI_SHA256="${3:-./ci-requirements.sha256}"

echo "=== Phase 7.2: CI Requirements Consistency Check ==="
echo "Purpose: Verify ci-requirements.json matches repo.cue"
echo ""

echo "Step 1: Extracting requiredChecks from repo.cue..."
CURRENT_CHECKS=$(
	sed -n "/requiredChecks:/,/^[[:space:]]*\]/p" "$REPO_CUE" |
		sed 's,//.*$,,' |
		grep -oE '"[^"]+"' |
		tr -d '"' |
		sort |
		tr '\n' ',' |
		sed 's/,$//'
)
echo "  Current repo.cue checks: $CURRENT_CHECKS"
echo ""

echo "Step 2: Reading requiredChecks from ci-requirements.json..."
if [ ! -f "$CI_JSON" ]; then
	echo "  ERROR: ci-requirements.json not found at $CI_JSON"
	echo "  Run 'nix build .#packages.x86_64-linux.ci-requirements' first"
	exit 1
fi

EXPORTED_CHECKS=$(
	jq -r '.requiredChecks | sort | join(",")' "$CI_JSON"
)
echo "  Exported checks: $EXPORTED_CHECKS"
echo ""

echo "Step 3: Comparing..."
if [ "$CURRENT_CHECKS" = "$EXPORTED_CHECKS" ]; then
	echo "  CONSISTENT: ci-requirements.json matches repo.cue"
else
	echo "  INCONSISTENT: ci-requirements.json does not match repo.cue"
	echo ""
	echo "  Missing in ci-requirements.json:"
	comm -23 <(echo "$CURRENT_CHECKS" | tr ',' '\n' | sort) <(echo "$EXPORTED_CHECKS" | tr ',' '\n' | sort) | sed 's/^/    - /'
	echo ""
	echo "  Extra in ci-requirements.json:"
	comm -13 <(echo "$CURRENT_CHECKS" | tr ',' '\n' | sort) <(echo "$EXPORTED_CHECKS" | tr ',' '\n' | sort) | sed 's/^/    - /'
	exit 1
fi

echo ""
echo "Step 4: Validating ci-requirements.json..."
if jq empty "$CI_JSON" 2>/dev/null; then
	echo "  JSON is valid"
else
	echo "  JSON is invalid"
	exit 1
fi

echo ""
echo "Step 5: Verifying SHA256..."
COMPUTED_SHA256=$(sha256sum "$CI_JSON" | cut -d' ' -f1)
EXPECTED_SHA256=$(tr -d '\n' <"$CI_SHA256" 2>/dev/null)

if [ "$COMPUTED_SHA256" = "$EXPECTED_SHA256" ]; then
	echo "  SHA256 matches"
else
	echo "  SHA256 mismatch"
	echo "    Computed: $COMPUTED_SHA256"
	echo "    Expected: $EXPECTED_SHA256"
	exit 1
fi

echo ""
echo "=== Phase 7.2: CONSISTENCY CHECK PASSED ==="

echo "ci-requirements-consistency: PASS"
