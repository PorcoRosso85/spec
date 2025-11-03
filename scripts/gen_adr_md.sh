#!/usr/bin/env bash
# Generate Markdown from CUE ADR files
# Output: docs/adr/.gen/adr-*.md (deterministic)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ADR_DIR="$REPO_ROOT/docs/adr"
GEN_DIR="$ADR_DIR/.gen"

mkdir -p "$GEN_DIR"

echo "🔨 Generating ADR Markdown files..."

# Check if CUE is available
if ! command -v cue &> /dev/null; then
    echo "❌ Error: 'cue' command not found"
    echo "   Install CUE: https://cuelang.org/docs/install/"
    exit 1
fi

# Export all ADR CUE files to JSON
cd "$REPO_ROOT"

for adr_cue in "$ADR_DIR"/adr-*.cue; do
    if [ ! -f "$adr_cue" ]; then
        continue
    fi

    basename=$(basename "$adr_cue" .cue)
    adr_id=$(echo "$basename" | sed 's/adr-//')

    echo "  Processing: $basename"

    # Export CUE to JSON (from ADR directory to resolve any relative imports)
    json=$(cd "$(dirname "$adr_cue")" && cue export "$(basename "$adr_cue")" 2>/dev/null || echo "{}")

    if [ "$json" = "{}" ]; then
        echo "    ⚠️  Warning: Empty or invalid CUE file"
        continue
    fi

    # Extract fields using jq
    title=$(echo "$json" | jq -r ".adr${adr_id}.title // \"Untitled\"")
    status=$(echo "$json" | jq -r ".adr${adr_id}.status // \"unknown\"")
    date=$(echo "$json" | jq -r ".adr${adr_id}.date // \"unknown\"")
    scope=$(echo "$json" | jq -r ".adr${adr_id}.scope // \"\"")
    background=$(echo "$json" | jq -r ".adr${adr_id}.background // \"\"")
    decision=$(echo "$json" | jq -r ".adr${adr_id}.decision // \"\"")
    effects=$(echo "$json" | jq -r ".adr${adr_id}.effects // [] | map(\"- \" + .) | join(\"\n\")")
    activations=$(echo "$json" | jq -r ".adr${adr_id}.activations // [] | map(\"### \\(.slotId)\n- **Owner**: \\(.owner)\n- **Placement**: \\(.placement)\n- **Rationale**: \\(.rationale)\") | join(\"\n\n\")")
    references=$(echo "$json" | jq -r ".adr${adr_id}.references // [] | map(\"- \\(.)\") | join(\"\n\")")

    # Generate Markdown (deterministic format)
    cat > "$GEN_DIR/$basename.md" <<EOF
# ADR-${adr_id}: ${title}

**Status**: ${status}
**Date**: ${date}
$([ -n "$scope" ] && echo "**Scope**: ${scope}" || echo "")

---

## Background

${background}

## Decision

${decision}

## Effects

${effects}

$([ -n "$activations" ] && echo "## Slot Activations" && echo "" && echo "${activations}" || echo "")

$([ -n "$references" ] && echo "## References" && echo "" && echo "${references}" || echo "")

---

*This file is auto-generated from \`docs/adr/${basename}.cue\`. Do not edit manually.*
EOF

    echo "    ✅ Generated: $GEN_DIR/$basename.md"
done

echo "✅ All ADR Markdown files generated successfully"
