#!/usr/bin/env bash
set -euo pipefail

# spec-lint: Phase 1 reference integrity checks
# IF: spec-lint.sh <spec-root> [--mode fast|slow]
# This is a wrapper script that calls the Go binary
# Exit 0 if all checks pass, exit 1 if any fail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if the Go binary exists
if [ ! -f "$SCRIPT_DIR/spec-lint" ]; then
  echo "ERROR: spec-lint binary not found at $SCRIPT_DIR/spec-lint" >&2
  echo "Please run 'go build -o spec-lint cmd/main.go' in $SCRIPT_DIR" >&2
  exit 1
fi

# Pass all arguments to the Go binary
exec "$SCRIPT_DIR/spec-lint" "$@"
