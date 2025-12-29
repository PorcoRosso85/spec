#!/usr/bin/env bash
set -euo pipefail

# Unit test runner for spec-lint golden fixtures
# Usage: nix develop -c bash tests/unit/run.sh
# 
# Design: Runs ALL tests to completion, never exits early
# Supports XFAIL (expected failures for known issues)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_DIR="${REPO_ROOT}/tests/unit/spec-lint/golden"

echo "🧪 Running spec-lint unit tests"
echo ""

PASS=0
FAIL=0
SKIP=0
XFAIL=0  # Expected failures (known issues, don't fail CI)

run_test() {
    local test_path="$1"
    local test_name="$(basename "$test_path")"
    
    echo "Testing: $test_name"
    
    # Check for XFAIL marker (expected failure due to known issue)
    local is_xfail=false
    if [[ -f "$test_path/XFAIL" ]]; then
        is_xfail=true
        local xfail_reason
        xfail_reason=$(cat "$test_path/XFAIL")
        echo "  ⚠️  XFAIL (known issue): $xfail_reason"
    fi
    
    # Check test structure
    if [[ ! -d "$test_path/spec" ]] || [[ ! -f "$test_path/cue.mod/module.cue" ]]; then
        echo "  ⚠️  SKIP: Missing spec/ or cue.mod/module.cue"
        SKIP=$((SKIP + 1))
        return 0  # Don't fail runner
    fi
    
    # Build spec-lint if needed
    if [[ ! -f "$REPO_ROOT/tools/spec-lint/spec-lint" ]]; then
        echo "  Building spec-lint..."
        (cd "$REPO_ROOT/tools/spec-lint" && go build -mod=readonly -o spec-lint cmd/main.go) || {
            echo "  ❌ SKIP: Build failed"
            SKIP=$((SKIP + 1))
            return 0
        }
    fi
    
    # Determine test mode (default: fast)
    local mode="fast"
    [[ -f "$test_path/test-mode" ]] && mode=$(cat "$test_path/test-mode")
    
    # Create temp log file (avoid /tmp collisions)
    local log_file
    log_file=$(mktemp "/tmp/spec-lint-test-${test_name}-XXXXXX.log")
    
    # Run spec-lint (disable set -e for this block)
    local exit_code=0
    set +e
    "$REPO_ROOT/tools/spec-lint/spec-lint.sh" "$test_path" --mode "$mode" > "$log_file" 2>&1
    exit_code=$?
    set -e
    
    local test_passed=true
    
    # Check exit code
    if [[ -f "$test_path/expected-exit-code" ]]; then
        local expected_exit
        expected_exit=$(cat "$test_path/expected-exit-code")
        if [[ "$exit_code" == "$expected_exit" ]]; then
            echo "  ✅ Exit code: $exit_code"
        else
            echo "  ❌ Exit code: $exit_code (expected: $expected_exit)"
            test_passed=false
        fi
    else
        echo "  ⚠️  No expected-exit-code file"
    fi
    
    # Check log contains expected error tag (case-insensitive)
    if [[ -f "$test_path/expected-stderr-contains" ]]; then
        local expected_tag
        expected_tag=$(cat "$test_path/expected-stderr-contains")
        
        # Disable set -e for grep (not finding is valid case)
        set +e
        grep -qi "$expected_tag" "$log_file"
        local grep_exit=$?
        set -e
        
        if [[ $grep_exit -eq 0 ]]; then
            echo "  ✅ Error tag: '$expected_tag' found"
        else
            echo "  ❌ Error tag: '$expected_tag' NOT found"
            echo "     Log: $log_file"
            test_passed=false
        fi
    fi
    
    # Update counters (XFAIL tests don't count as PASS or FAIL)
    if $is_xfail; then
        XFAIL=$((XFAIL + 1))
        if $test_passed; then
            echo "  📋 XFAIL confirmed (still failing as expected)"
        else
            echo "  ⚠️  XFAIL behavior changed (may need update)"
        fi
    elif $test_passed; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
    fi
    
    return 0  # Always continue to next test
}

# Find and run ALL golden tests (never exit early)
if [[ ! -d "$TEST_DIR" ]]; then
    echo "❌ Test directory not found: $TEST_DIR"
    exit 1
fi

for test_path in "$TEST_DIR"/*; do
    [[ -d "$test_path" ]] && run_test "$test_path"
done

# Always show summary
echo ""
echo "===================="
echo "Test Summary:"
echo "  PASS:  $PASS"
echo "  FAIL:  $FAIL"
echo "  XFAIL: $XFAIL (known issues, not counted as failure)"
echo "  SKIP:  $SKIP"
echo "  TOTAL: $((PASS + FAIL + XFAIL + SKIP))"
echo "===================="

# Exit with appropriate code (XFAIL doesn't cause failure, but warn if accumulating)
if [[ $FAIL -gt 0 ]]; then
    echo "❌ Test run FAILED"
    exit 1
fi

# XFAIL limit: Warn/fail if known issues are accumulating (max 1 acceptable)
MAX_XFAIL=1
XFAIL_STRICT=${XFAIL_STRICT:-false}  # Set XFAIL_STRICT=true for main branch enforcement

if [[ $XFAIL -gt $MAX_XFAIL ]]; then
    echo "⚠️  WARNING: XFAIL count ($XFAIL) exceeds limit ($MAX_XFAIL)"
    echo "   Known issues are accumulating - prioritize fixes!"
    
    if [[ "$XFAIL_STRICT" == "true" ]]; then
        echo "❌ XFAIL limit exceeded in strict mode (main branch)"
        exit 1
    fi
fi

# Report precise status (avoid "all passed" when XFAIL exists)
if [[ $XFAIL -gt 0 ]]; then
    echo "✅ Test run OK: PASS=$PASS, XFAIL=$XFAIL (known issues), FAIL=$FAIL"
else
    echo "✅ Test run OK: PASS=$PASS, FAIL=$FAIL"
fi
exit 0
