#!/usr/bin/env bash
# Generate traceability.json from catalog and skeleton
# Output: docs/structure/.gen/traceability.json (deterministic, CI-only)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKELETON="$REPO_ROOT/docs/structure/.gen/skeleton.json"
TRACEABILITY="$REPO_ROOT/docs/structure/.gen/traceability.json"

echo "🔨 Generating traceability.json..."

# Check if CUE is available
if ! command -v cue &> /dev/null; then
    echo "❌ Error: 'cue' command not found"
    echo "   Install CUE: https://cuelang.org/docs/install/"
    exit 1
fi

# Check if skeleton.json exists
if [ ! -f "$SKELETON" ]; then
    echo "❌ Error: skeleton.json not found at $SKELETON"
    exit 1
fi

cd "$REPO_ROOT"

# Export all slots from catalog
echo "  Exporting catalog slots..."
cue export ./docs/catalog -e allSlots > /tmp/slots.json 2>/dev/null || {
    echo "❌ Error: Failed to export catalog"
    exit 1
}

# Combine catalog and skeleton to generate traceability
echo "  Combining catalog and skeleton..."

jq -n \
  --slurpfile slots /tmp/slots.json \
  --slurpfile skeleton "$SKELETON" \
  '{
    _meta: {
      version: "0.1.0",
      description: "Auto-generated traceability map (DO NOT EDIT MANUALLY)",
      generated: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
      generator: "scripts/gen_traceability.sh"
    },
    slots: (
      $slots[0] as $allSlots |
      $skeleton[0] as $skel |
      $allSlots | to_entries | map({
        id: .key,
        status: .value.status,
        owner: (.value.owner // null),
        responsibility: .value.responsibility,
        tier: .value.tier,
        placement: ($skel[.key] // null),
        dependsOn: .value.dependsOn,
        standardRef: .value.standardRef
      })
    )
  }' > "$TRACEABILITY"

echo "✅ traceability.json generated successfully"
echo "   Location: $TRACEABILITY"

# Validate JSON syntax
if ! jq empty "$TRACEABILITY" 2>/dev/null; then
    echo "❌ Error: Generated traceability.json is not valid JSON"
    exit 1
fi

echo "✅ traceability.json validated"

# Cleanup
rm -f /tmp/slots.json
