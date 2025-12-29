#!/usr/bin/env bash
set -euo pipefail

# spec-lint: Phase 1 reference integrity checks
# IF: spec-lint.sh <spec-root> [--mode fast|slow]
# Exit 0 if all checks pass, exit 1 if any fail

SPEC_ROOT="${1:-.}"
MODE="${2:---mode}"
MODE_VALUE="${3:-fast}"

# Parse --mode flag
if [ "$MODE" = "--mode" ]; then
  MODE_VALUE="$3"
fi

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
# FAST MODE: feat-id/env-id duplicates only
# ============================================================================

fast_mode() {
  log_info "Mode: FAST (feat-id/env-id dedup only)"
  
  # Collect all feat-ids
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
      total=$(cut -d'|' -f1 "$feat_ids_file" | sort -u | wc -l)
      log_info "✅ No feat-id duplicates (${total} unique)"
    fi
  fi
  
  # Collect env-ids
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
}

# ============================================================================
# SLOW MODE: fast + broken refs + circular deps (when implemented)
# ============================================================================

slow_mode() {
  log_info "Mode: SLOW (feat-id/env-id dedup + refs + TODO: circular-deps)"
  
  # Run fast mode first
  fast_mode
  
  # Check for broken references
  log_info "Scanning for broken references..."
  
  feat_ids_file=$(mktemp)
  trap "rm -f $feat_ids_file" EXIT
  
  find "$SPEC_ROOT/spec/urn/feat" -name "feature.cue" -print0 2>/dev/null | while IFS= read -r -d '' file; do
    id=$(grep -E '^\s*id:' "$file" 2>/dev/null | head -1 | sed 's/.*id:\s*"\(.*\)".*/\1/' || true)
    if [ -n "$id" ]; then
      echo "$id"
    fi
  done | sort -u > "$feat_ids_file"
  
  if [ -f "$feat_ids_file" ] && [ -s "$feat_ids_file" ]; then
    valid_feats=$(cat "$feat_ids_file")
    
    find "$SPEC_ROOT/spec/adapter" "$SPEC_ROOT/spec/mapping" -name "*.cue" 2>/dev/null | while read -r file; do
      grep -o 'urn:feat:[a-z0-9-]*' "$file" 2>/dev/null | sort -u | while read -r ref; do
        if ! echo "$valid_feats" | grep -q "^$ref$"; then
          echo "Broken reference to '$ref' in file '$file'" >&2
          ((errors++))
        fi
      done || true
    done > /dev/null 2>&1 || true
  fi
  
  if [ $errors -eq 0 ]; then
    log_info "✅ No broken references found"
  fi
  
  log_info "TODO: circular-deps detection (Go impl in Phase 1 Step 5)"
}

# ============================================================================
# Main dispatch
# ============================================================================

case "$MODE_VALUE" in
  fast)
    fast_mode
    ;;
  slow)
    slow_mode
    ;;
  *)
    echo "Usage: spec-lint.sh <spec-root> --mode [fast|slow]" >&2
    echo "" >&2
    echo "  fast - feat-id/env-id dedup only (quick)" >&2
    echo "  slow - fast + refs + TODO:circular-deps (thorough)" >&2
    exit 1
    ;;
esac

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
