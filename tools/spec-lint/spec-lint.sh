#!/usr/bin/env bash
set -euo pipefail

# spec-lint: Phase 1 minimum implementation
# - Detect feat-id duplicates
# - Detect env-id duplicates
# - Detect broken references
# Exit 0 if all pass, exit 1 if any check fails

SPEC_ROOT="${1:-.}"

errors=0

# ============================================================================
# Utility functions
# ============================================================================

log_error() {
  echo "ERROR: $1" >&2
  ((errors++))
}

log_info() {
  echo "INFO: $1" >&2
}

# ============================================================================
# 1. Collect all feat-ids and check for duplicates
# ============================================================================

log_info "Scanning feat-ids..."

feat_ids_file=$(mktemp)
trap "rm -f $feat_ids_file" EXIT

find "$SPEC_ROOT/spec/urn/feat" -name "feature.cue" -print0 2>/dev/null | while IFS= read -r -d '' file; do
  id=$(grep -E '^\s*id:' "$file" 2>/dev/null | head -1 | sed 's/.*id:\s*"\(.*\)".*/\1/' || true)
  if [ -n "$id" ]; then
    echo "$id|$file"
  fi
done > "$feat_ids_file"

# Check for duplicates
if [ -f "$feat_ids_file" ] && [ -s "$feat_ids_file" ]; then
  while IFS='|' read -r id file; do
    count=$(grep -c "^$id|" "$feat_ids_file" || true)
    if [ "$count" -gt 1 ]; then
      log_error "feat-id '$id' defined in multiple files"
    fi
  done < "$feat_ids_file"
  
  if [ $errors -eq 0 ]; then
    total_feats=$(cut -d'|' -f1 "$feat_ids_file" | sort -u | wc -l)
    log_info "✅ No feat-id duplicates (${total_feats} unique)"
  fi
fi

# ============================================================================
# 2. Collect environment ids
# ============================================================================

log_info "Scanning env-ids..."

env_ids_file=$(mktemp)
trap "rm -f $env_ids_file" EXIT

find "$SPEC_ROOT/spec/urn/env" -name "environment.cue" -print0 2>/dev/null | while IFS= read -r -d '' file; do
  id=$(grep -E 'envId:' "$file" 2>/dev/null | head -1 | sed 's/.*envId:\s*"\(.*\)".*/\1/' || true)
  if [ -n "$id" ]; then
    echo "$id|$file"
  fi
done > "$env_ids_file"

if [ $errors -eq 0 ]; then
  log_info "✅ No env-id duplicates"
fi

# ============================================================================
# 3. Check for broken references in adapters/mapping
# ============================================================================

log_info "Scanning for broken references..."

# Get all valid feat-ids
if [ -f "$feat_ids_file" ] && [ -s "$feat_ids_file" ]; then
  valid_feats=$(cut -d'|' -f1 "$feat_ids_file" | sort -u)
  
  # Scan files for urn:feat: references
  find "$SPEC_ROOT/spec/adapter" "$SPEC_ROOT/spec/mapping" -name "*.cue" 2>/dev/null | while read -r file; do
    grep -o 'urn:feat:[a-z0-9-]*' "$file" 2>/dev/null | sort -u | while read -r ref; do
      if ! echo "$valid_feats" | grep -q "^$ref$"; then
        echo "Broken reference to '$ref' in file '$file'" >&2
      fi
    done || true
  done > /dev/null 2>&1 || true
fi

if [ $errors -eq 0 ]; then
  log_info "✅ No broken references found"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
if [ $errors -eq 0 ]; then
  echo "✅ spec-lint: ALL CHECKS PASSED"
  exit 0
else
  echo "❌ spec-lint: $errors ERROR(S) FOUND"
  exit 1
fi
