#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-./bundle}"
SPEC_ROOT="${2:-./spec}"

echo "=== Export Feat Contracts Bundle ==="
echo "Output: $OUT_DIR"
echo "Source: $SPEC_ROOT"
echo ""

mkdir -p "$OUT_DIR"

CONTRACTS=$(find "$SPEC_ROOT/urn/feat" -mindepth 2 -maxdepth 2 -name contract.cue -print 2>/dev/null | sort)

if [ -z "$CONTRACTS" ]; then
	echo "No contract.cue found in $SPEC_ROOT/urn/feat/"
	exit 1
fi

INDEX_ENTRIES=()
SLUGS=()

for CONTRACT in $CONTRACTS; do
	SLUG=$(basename "$(dirname "$CONTRACT")")
	SLUGS+=("$SLUG")

	echo "Processing: $SLUG"
	echo "  Contract: $CONTRACT"

	mkdir -p "$OUT_DIR/$SLUG"

	if ! cue eval "$CONTRACT" 2>&1 >/dev/null; then
		echo "  ❌ FAIL: CUE syntax error"
		exit 1
	fi
	echo "  ✅ CUE syntax OK"

	if ! cue export "$CONTRACT" -e requiredChecks --out json 2>/dev/null | grep -q '"'; then
		echo "  ❌ FAIL: requiredChecks missing or empty"
		exit 1
	fi
	echo "  ✅ requiredChecks present"

	JSON_CONTENT=$(cue export "$CONTRACT" -e requiredChecks --out json 2>/dev/null)
	echo "$JSON_CONTENT" >"$OUT_DIR/$SLUG/contract.json"

	SHA256=$(sha256sum "$OUT_DIR/$SLUG/contract.json" | cut -d' ' -f1)
	echo "$SHA256" >"$OUT_DIR/$SLUG/contract.json.sha256"
	echo "  📦 Generated: contract.json + sha256"

	INDEX_ENTRIES+=("{\"slug\": \"$SLUG\", \"sha256\": \"$SHA256\", \"file\": \"$SLUG/contract.json\"}")
	echo ""
done

echo "=== Generating index.json ==="
printf '%s\n' "${INDEX_ENTRIES[@]}" | jq -s '.' >"$OUT_DIR/index.json"
echo "Index entries: ${#INDEX_ENTRIES[@]}"

echo ""
echo "=== Bundle Complete ==="
echo "Output directory: $OUT_DIR"
echo ""
echo "Contents:"
ls -la "$OUT_DIR/"
if [ -f "$OUT_DIR/index.json" ]; then
	echo ""
	echo "index.json:"
	cat "$OUT_DIR/index.json" | jq '.'
fi
