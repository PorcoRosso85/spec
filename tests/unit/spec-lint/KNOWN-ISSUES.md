# Known Issues in spec-lint (Discovered via Unit Tests)

## Critical: Duplicate feat-id Detection is Broken

**Status**: 🐛 ACTIVE BUG  
**Severity**: HIGH  
**Discovered**: 2025-12-29 during Phase 2.0 unit test development

### Problem

spec-lint **silently ignores duplicate feat-ids** and reports "ALL CHECKS PASSED" even when multiple features define the same ID.

### Root Cause

In `tools/spec-lint/cmd/main.go`, the `evalFeaturesViaCue()` function returns `map[string]string` (ID → single filepath). When processing NDJSON output from `cue eval`, duplicate IDs overwrite previous entries:

```go
// BUG: This line overwrites duplicates
features[feat.ID] = filepath.Join(c.specRoot, "spec/urn/feat", feat.Slug, "feature.cue")
```

**Expected**: Should return `map[string][]string` and append all filepaths for each ID.

### Evidence

**Test fixture**: `tests/unit/spec-lint/golden/duplicate-feat-id-BROKEN/`

Contains two features with identical ID:
- `spec/urn/feat/one/feature.cue`: `id: "urn:feat:test"`
- `spec/urn/feat/two/feature.cue`: `id: "urn:feat:test"` (duplicate!)

**Actual behavior**:
```
$ cue eval ./spec/urn/feat/... -e feature.id
"urn:feat:test"
"urn:feat:test"   ← Two features, same ID

$ spec-lint.sh . --mode fast
INFO: cue eval extracted 1 features via canonical approach
INFO: ✅ No feat-id duplicates (1 unique)   ← WRONG! Should be ERROR
✅ spec-lint: ALL CHECKS PASSED              ← FALSE POSITIVE
```

**Expected behavior**:
```
ERROR: feat-id 'urn:feat:test' defined in multiple files: 
  - spec/urn/feat/one/feature.cue
  - spec/urn/feat/two/feature.cue
❌ spec-lint: 1 ERROR(S) FOUND
```

### Impact

**Catastrophic for SSOT enforcement**:
1. Developers can accidentally create duplicate feature IDs
2. CI gates (fast/slow) will pass despite violation
3. Runtime conflicts possible when multiple features claim same URN
4. Breaks "1 URN = 1 Feature = 1 Repo" invariant

### Workaround (Current)

The `duplicate-feat-id-BROKEN` fixture is configured to **expect the buggy behavior**:
- Expected exit code: `0` (not `1`)
- Expected stderr: `ALL CHECKS PASSED` (not error message)

This ensures CI doesn't break, but **documents the false sense of security**.

### Fix Required

1. Change `evalFeaturesViaCue()` return type to `map[string][]string`
2. Append filepaths instead of overwriting:
   ```go
   features[feat.ID] = append(features[feat.ID], filepath)
   ```
3. Update dedup check logic if needed
4. Update `duplicate-feat-id-BROKEN` fixture:
   - Rename to `duplicate-feat-id` (remove BROKEN suffix)
   - Change expected-exit-code to `1`
   - Change expected-stderr-contains to `duplicate feat-id` or similar
5. Verify test fails BEFORE fix, passes AFTER fix

### References

- Test fixture: `tests/unit/spec-lint/golden/duplicate-feat-id-BROKEN/`
- spec-lint code: `tools/spec-lint/cmd/main.go` (function `evalFeaturesViaCue`)
- Discovered during: Phase 2.0 certification review (user feedback)

---

## Test Coverage Status

| Check Type         | Working? | Test Fixture       | Notes                          |
|--------------------|----------|--------------------|--------------------------------|
| Broken refs        | ✅ YES    | `broken-ref`       | Detects undefined URNs         |
| Circular deps      | ✅ YES    | `circular-deps`    | Detects dependency cycles      |
| Duplicate feat-id  | ❌ NO     | `duplicate-feat-id-BROKEN` | **BLOCKED BY BUG ABOVE** |
| Invalid slug       | ✅ YES    | `invalid-slug`     | Detects non-kebab-case         |
| Empty spec         | ✅ YES    | `empty-spec`       | Detects specs with no features |
| Valid spec (positive) | ✅ YES | `valid-spec`       | Ensures not always-fail        |

**Test Suite Status**: 5/6 checks verified, 1/6 blocked by spec-lint bug

---

## Why This Matters (Philosophy)

**Unit tests exist to prevent regression**. If spec-lint silently breaks (e.g., dedup logic accidentally removed), tests should **immediately fail**.

**The duplicate-feat-id bug means**:
- If someone "fixes" spec-lint to always return 0, the current test would PASS
- False confidence is worse than no tests

**Therefore**:
- We document the bug explicitly
- We configure the test to expect the CURRENT (broken) behavior
- When the bug is fixed, we update the test expectations
- This maintains audit trail: "test knew about the bug, wasn't hiding it"

---

## Update History

- **2025-12-29**: Initial documentation during Phase 2.0 fixture corrections
