#!/usr/bin/env bash
set -euo pipefail

# Unit test runner for spec-lint golden fixtures
# Usage: nix develop -c bash tests/unit/run.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_DIR="${REPO_ROOT}/tests/unit/spec-lint/golden"

echo "🧪 Running spec-lint unit tests"
echo ""

PASS=0
FAIL=0

run_test() {
    local test_path="$1"
    local test_name="$(basename "$test_path")"
    
    echo "Testing: $test_name"
    
    # Check test structure
    if [[ ! -d "$test_path/spec" ]] || [[ ! -f "$test_path/cue.mod/module.cue" ]]; then
        echo "  ⚠️  SKIP: Missing spec/ or cue.mod/module.cue"
        return
    fi
    
    # Build spec-lint if needed
    if [[ ! -f "$REPO_ROOT/tools/spec-lint/spec-lint" ]]; then
        echo "  Building spec-lint..."
        (cd "$REPO_ROOT/tools/spec-lint" && go build -mod=readonly -o spec-lint cmd/main.go)
    fi
    
    # Determine test mode (default: fast)
    local mode="fast"
    [[ -f "$test_path/test-mode" ]] && mode=$(cat "$test_path/test-mode")
    
    # Run spec-lint directly (spec-lint validates repo root)
    local log_file="/tmp/test-${mode}-${test_name}.log"
    set +e
    "$REPO_ROOT/tools/spec-lint/spec-lint.sh" "$test_path" --mode "$mode" > "$log_file" 2>&1
    local exit_code=$?
    set -e
    
    local test_passed=true
    
    # Check exit code
    if [[ -f "$test_path/expected-exit-code" ]]; then
        local expected_exit=$(cat "$test_path/expected-exit-code")
        if [[ "$exit_code" == "$expected_exit" ]]; then
            echo "  ✅ Exit code: $exit_code"
        else
            echo "  ❌ Exit code: $exit_code (expected: $expected_exit)"
            test_passed=false
        fi
    fi
    
    # Check stderr contains expected error tag
    if [[ -f "$test_path/expected-stderr-contains" ]]; then
        local expected_tag=$(cat "$test_path/expected-stderr-contains")
        if grep -qi "$expected_tag" "$log_file"; then
            echo "  ✅ Error tag: '$expected_tag' found"
        else
            echo "  ❌ Error tag: '$expected_tag' NOT found"
            echo "     Log: $log_file"
            test_passed=false
        fi
    fi
    
    if $test_passed; then
        ((PASS++))
    else
        ((FAIL++))
    fi
}

# Find and run all golden tests
if [[ -d "$TEST_DIR" ]]; then
    for test_path in "$TEST_DIR"/*; do
        [[ -d "$test_path" ]] && run_test "$test_path"
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

[[ $FAIL -gt 0 ]] && exit 1 || exit 0
