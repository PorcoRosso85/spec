#!/usr/bin/env bash
set -euo pipefail

# Unit test runner for spec-lint
# Usage: bash tests/unit/run.sh [test-dir]

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_DIR="${REPO_ROOT}/tests/unit/spec-lint/golden"

echo "🧪 Running spec-lint unit tests"
echo "Repository root: $REPO_ROOT"
echo "Test directory: $TEST_DIR"
echo ""

PASS=0
FAIL=0

run_test() {
    local test_path="$1"
    local test_name="$(basename "$test_path")"
    
    echo "Testing: $test_name"
    
    # Check test structure
    if [[ ! -d "$test_path/spec" ]]; then
        echo "  ❌ SKIP: No spec/ directory"
        return
    fi
    
    if [[ ! -f "$test_path/cue.mod/module.cue" ]]; then
        echo "  ❌ SKIP: No cue.mod/module.cue"
        return
    fi
    
    # Build spec-lint if needed
    if [[ ! -f "$REPO_ROOT/tools/spec-lint/spec-lint" ]]; then
        echo "  Building spec-lint..."
        cd "$REPO_ROOT/tools/spec-lint"
        go build -mod=readonly -o spec-lint cmd/main.go
        cd "$REPO_ROOT"
    fi
    
    # Run spec-lint from test directory
    cd "$test_path"
    set +e
    "$REPO_ROOT/tools/spec-lint/spec-lint.sh" . --mode fast > /tmp/test-fast-$test_name.log 2>&1
    local exit_code=$?
    set -e
    cd "$REPO_ROOT"
    
    # Check expected exit code
    if [[ -f "$test_path/expected-exit-code" ]]; then
        local expected_exit=$(cat "$test_path/expected-exit-code")
        if [[ "$exit_code" == "$expected_exit" ]]; then
            echo "  ✅ Exit code: $exit_code (expected: $expected_exit)"
            ((PASS++))
        else
            echo "  ❌ Exit code: $exit_code (expected: $expected_exit)"
            echo "     Log: /tmp/test-fast-$test_name.log"
            ((FAIL++))
        fi
    else
        echo "  ⚠️  No expected-exit-code file"
    fi
}

# Find all golden test directories
if [[ -d "$TEST_DIR" ]]; then
    for test_path in "$TEST_DIR"/*; do
        if [[ -d "$test_path" ]]; then
            run_test "$test_path"
        fi
    done
else
    echo "❌ Test directory not found: $TEST_DIR"
    exit 1
fi

echo ""
echo "===================="
echo "Test Summary:"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "===================="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
