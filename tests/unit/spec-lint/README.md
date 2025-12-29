# spec-lint Unit Tests

**Purpose**: Verify spec-lint behavior via golden fixtures  
**Method**: Test critical edge cases with known-good/known-bad inputs  
**Location**: `tests/unit/spec-lint/golden/`

---

## Test Coverage (Minimum Set)

### 1. featCount==0 Detection
**File**: `golden/empty-spec/`  
**Expected**: Exit 1, error message about extraction failure

### 2. Duplicate feat-id Detection
**File**: `golden/duplicate-feat-id/`  
**Expected**: Exit 1, error showing duplicate ID + file locations

### 3. Broken Reference Detection
**File**: `golden/broken-ref/`  
**Expected**: Exit 1 (slow only), error showing undefined URN

### 4. Circular Dependency Detection
**File**: `golden/circular-deps/`  
**Expected**: Exit 1 (slow only), error showing cycle path

### 5. Kebab-case Validation
**File**: `golden/invalid-slug/`  
**Expected**: Exit 1 (fast), error showing invalid slug

---

## Test Structure

Each golden test directory contains:
- `spec/` - Minimal CUE spec triggering the condition
- `cue.mod/module.cue` - Valid module declaration
- `expected-fast.log` - Expected output for fast mode
- `expected-slow.log` - Expected output for slow mode (if different)
- `expected-exit-code` - Expected exit code (0 or 1)

---

## Running Tests

```bash
# Run all unit tests
bash tests/unit/run.sh

# Run specific test
bash tests/unit/run.sh golden/empty-spec
```

---

## Adding New Tests

1. Create directory: `golden/<test-name>/`
2. Add minimal spec that triggers condition
3. Run spec-lint manually, capture output
4. Save as `expected-*.log`
5. Document expected behavior in this README

---

**Status**: Not Yet Implemented (Phase 2.0)
