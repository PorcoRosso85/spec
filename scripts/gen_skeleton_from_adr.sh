#!/usr/bin/env bash
# Generate skeleton.json from ADR activations
# Output: skeleton.generated.json (deterministic, for comparison)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ADR_DIR="$REPO_ROOT/docs/adr"
OUTPUT="$REPO_ROOT/docs/structure/.gen/skeleton.generated.json"
CURRENT_SKELETON="$REPO_ROOT/docs/structure/.gen/skeleton.json"

echo "🔨 Generating skeleton.json from ADR activations..."

# Check if CUE is available
if ! command -v cue &> /dev/null; then
    echo "❌ Error: 'cue' command not found"
    echo "   Install CUE: https://cuelang.org/docs/install/"
    exit 1
fi

cd "$REPO_ROOT"

# Collect all activations from all ADRs
echo "  Scanning ADR files..."

ALL_ACTIVATIONS="[]"

for adr_cue in "$ADR_DIR"/adr-*.cue; do
    if [ ! -f "$adr_cue" ]; then
        continue
    fi

    basename=$(basename "$adr_cue" .cue)
    adr_id=$(echo "$basename" | sed 's/adr-//')

    echo "    Processing: $basename"

    # Export CUE to JSON
    json=$(cd "$ADR_DIR" && cue export "$(basename "$adr_cue")" 2>/dev/null || echo "{}")

    if [ "$json" = "{}" ]; then
        echo "      ⚠️  Warning: Empty or invalid CUE file"
        continue
    fi

    # Extract activations array
    activations=$(echo "$json" | jq -c ".adr${adr_id}.activations // []" 2>/dev/null || echo "[]")

    if [ "$activations" != "[]" ]; then
        activation_count=$(echo "$activations" | jq 'length')
        echo "      Found $activation_count activation(s)"

        # Merge into ALL_ACTIVATIONS
        ALL_ACTIVATIONS=$(jq -n --argjson all "$ALL_ACTIVATIONS" --argjson new "$activations" '$all + $new')
    fi
done

echo ""
echo "  Total activations collected: $(echo "$ALL_ACTIVATIONS" | jq 'length')"

# Validate: Check for duplicate slotIds
echo "  Validating activations..."

DUPLICATE_SLOTS=$(echo "$ALL_ACTIVATIONS" | jq -r '.[].slotId' | sort | uniq -d)

if [ -n "$DUPLICATE_SLOTS" ]; then
    echo "❌ Error: Duplicate slot activations found:"
    echo "$DUPLICATE_SLOTS" | sed 's/^/    - /'
    echo ""
    echo "  Each slot can only be activated once across all ADRs."
    exit 1
fi

# Validate: Check for conflicting placements (different slots → same path)
echo "  Checking for placement conflicts..."

PLACEMENTS=$(echo "$ALL_ACTIVATIONS" | jq -r '.[].placement' | sort)
DUPLICATE_PLACEMENTS=$(echo "$PLACEMENTS" | uniq -d)

if [ -n "$DUPLICATE_PLACEMENTS" ]; then
    echo "⚠️  Warning: Multiple slots targeting the same placement:"
    echo "$DUPLICATE_PLACEMENTS" | sed 's/^/    - /'
    echo ""
    echo "  This may indicate a design issue (multiple responsibilities in one location)"
fi

# Generate skeleton.generated.json
echo "  Generating skeleton.generated.json..."

# Read _meta from current skeleton.json if it exists
if [ -f "$CURRENT_SKELETON" ]; then
    CURRENT_META=$(jq '._meta // {}' "$CURRENT_SKELETON")
else
    CURRENT_META='{
        "version": "0.1.0",
        "description": "Repository structure skeleton - authorized placement map",
        "lastUpdated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
        "excludeFromGuard": [
            "docs/",
            ".github/",
            "scripts/",
            "README.md",
            "LICENSE"
        ]
    }'
fi

# Build skeleton.json structure
jq -n \
  --argjson meta "$CURRENT_META" \
  --argjson activations "$ALL_ACTIVATIONS" \
  '{
    _meta: ($meta | .lastUpdated = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))),
  } + (
    $activations | map({
      key: .slotId,
      value: (
        .placement |
        # Normalize: ensure trailing slash for directories
        if test("/[^/]+\\.[a-zA-Z0-9]+$") then . else (. + "/") end
      )
    }) | from_entries
  )' > "$OUTPUT"

echo "✅ skeleton.generated.json created"
echo "   Location: $OUTPUT"

# Show summary
SLOT_COUNT=$(jq -r 'keys | map(select(startswith("_") | not)) | length' "$OUTPUT")
echo ""
echo "📊 Summary:"
echo "   Total slots: $SLOT_COUNT"

# Compare with current skeleton.json if exists
if [ -f "$CURRENT_SKELETON" ]; then
    echo ""
    echo "🔍 Comparing with current skeleton.json..."

    # Extract non-meta fields for comparison
    GENERATED_SLOTS=$(jq -S 'del(._meta)' "$OUTPUT")
    CURRENT_SLOTS=$(jq -S 'del(._meta)' "$CURRENT_SKELETON")

    if [ "$GENERATED_SLOTS" = "$CURRENT_SLOTS" ]; then
        echo "✅ No changes detected - skeleton.json is up to date"
    else
        echo "⚠️  Changes detected:"
        echo ""

        # Show added slots
        ADDED=$(jq -n --argjson gen "$GENERATED_SLOTS" --argjson cur "$CURRENT_SLOTS" \
          '$gen | keys - ($cur | keys) | .[]' 2>/dev/null || echo "")

        if [ -n "$ADDED" ]; then
            echo "  ➕ Added slots:"
            echo "$ADDED" | sed 's/^/    - /'
        fi

        # Show removed slots
        REMOVED=$(jq -n --argjson gen "$GENERATED_SLOTS" --argjson cur "$CURRENT_SLOTS" \
          '$cur | keys - ($gen | keys) | .[]' 2>/dev/null || echo "")

        if [ -n "$REMOVED" ]; then
            echo "  ➖ Removed slots:"
            echo "$REMOVED" | sed 's/^/    - /'
        fi

        # Show modified placements
        COMMON=$(jq -n --argjson gen "$GENERATED_SLOTS" --argjson cur "$CURRENT_SLOTS" \
          '($gen | keys) - (($gen | keys) - ($cur | keys))' 2>/dev/null || echo "[]")

        MODIFIED=$(echo "$COMMON" | jq -r '.[]' | while read -r slot; do
            GEN_PLACE=$(echo "$GENERATED_SLOTS" | jq -r --arg s "$slot" '.[$s]')
            CUR_PLACE=$(echo "$CURRENT_SLOTS" | jq -r --arg s "$slot" '.[$s]')
            if [ "$GEN_PLACE" != "$CUR_PLACE" ]; then
                echo "$slot: $CUR_PLACE → $GEN_PLACE"
            fi
        done)

        if [ -n "$MODIFIED" ]; then
            echo "  🔄 Modified placements:"
            echo "$MODIFIED" | sed 's/^/    /'
        fi

        echo ""
        echo "  To apply changes:"
        echo "    cp $OUTPUT $CURRENT_SKELETON"
        echo "    git add $CURRENT_SKELETON"
    fi
else
    echo ""
    echo "ℹ️  No existing skeleton.json found"
    echo "   To initialize:"
    echo "     cp $OUTPUT $CURRENT_SKELETON"
    echo "     git add $CURRENT_SKELETON"
fi

echo ""
echo "✅ Skeleton generation complete"
