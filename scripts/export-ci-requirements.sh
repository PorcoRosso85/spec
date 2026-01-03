#!/usr/bin/env bash
set -euo pipefail

CONTRACT_CUE="${1:-./spec/urn/spec-repo/contract.cue}"
OUTPUT_DIR="${2:-.}"

mkdir -p "$OUTPUT_DIR"

echo "=== CI Requirements Export ==="
echo ""

ITEMS=$(
	sed -n "/requiredChecks:/,/^[[:space:]]*\]/p" "$CONTRACT_CUE" |
		sed 's,//.*$,,' |
		grep -oE '"[^"]+"' |
		tr -d '"' |
		sort |
		while IFS= read -r item; do
			echo "\"$item\""
		done |
		tr '\n' ',' |
		sed 's/,$//'
)
echo "Extracted items: $ITEMS"
echo ""

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat >"$OUTPUT_DIR/ci-requirements.json" <<JSONEOF
{
  "version": "1.0.0",
  "requiredChecks": [$ITEMS],
  "generatedAt": "$TIMESTAMP"
}
JSONEOF

echo "JSON content:"
cat "$OUTPUT_DIR/ci-requirements.json"
echo ""

if jq empty "$OUTPUT_DIR/ci-requirements.json" 2>/dev/null; then
	echo "JSON is valid"
else
	echo "JSON is invalid"
	exit 1
fi

SHA256=$(sha256sum "$OUTPUT_DIR/ci-requirements.json" | cut -d' ' -f1)
echo ""
echo "SHA256: $SHA256"
echo "$SHA256" >"$OUTPUT_DIR/ci-requirements.sha256"

echo ""
echo "=== Export Complete ==="

ls -la "$OUTPUT_DIR/"
