# spec-lint CLI Contract (Normative)

**Purpose**: Define the immutable contract for spec-lint behavior  
**Authority**: spec-repo maintainers  
**Binding**: YES (implementation must preserve this contract)  
**Date**: 2025-12-29

---

## 1. Core Contract: fast ⊂ slow

**Invariant**: slow mode MUST include all fast mode checks.

```
fast = dedup + naming validation (<30s target)
slow = fast + refs + circular deps (completeness priority)
```

**Verification method**:
- slow mode log MUST show fast mode execution
- Example: `INFO: Mode: SLOW` followed by `INFO: Mode: FAST`

**Rationale**: Ensures PR gate (fast) validates subset of main gate (slow).

---

## 2. Exit Code Contract

| Exit Code | Meaning | When |
|-----------|---------|------|
| **0** | ALL checks PASS | No duplicates, no broken refs, no cycles, all naming valid |
| **1** | ANY check FAIL | Duplicate IDs, broken refs, cycles, naming violations, OR extraction failure |

**Special case: featCount==0**
- MUST exit 1 (FAIL)
- Rationale: Cannot verify "no duplicates" if extraction failed
- Log MUST show: `ERROR: No features extracted (cannot verify dedup)`

**Contract guarantee**: Implementation language can change (Go → other), but exit codes remain invariant.

---

## 3. Mode Responsibilities

### 3.1 fast mode (PR gate)

**Checks** (MUST include all):
1. feat-id deduplication
2. env-id deduplication
3. slug naming validation (kebab-case)

**Performance target**: <30s on typical repo

**Exit 0 conditions**:
- featCount > 0 (extraction succeeded)
- 0 duplicate feat-ids
- 0 duplicate env-ids
- All slugs match `^[a-z0-9]+(-[a-z0-9]+)*$`

**Exit 1 conditions**:
- featCount == 0 (extraction failed)
- Any duplicate feat-id
- Any duplicate env-id
- Any slug violates kebab-case

---

### 3.2 slow mode (main gate)

**Checks** (MUST include all):
1. All fast checks (inclusion contract)
2. Broken reference detection
3. Circular dependency detection (DFS)

**Performance target**: <2min (completeness priority)

**Exit 0 conditions**:
- All fast checks PASS
- 0 broken references
- 0 circular dependencies

**Exit 1 conditions**:
- Any fast check FAIL
- Any broken reference found
- Any circular dependency found

---

## 4. Log Contract (Mandatory Lines)

### 4.1 fast mode logs (MUST include)

```
INFO: Mode: FAST (feat-id/env-id dedup + naming validation)
INFO: Scanning feat-ids...
INFO: cue eval extracted N features via canonical approach
INFO: ✅ No feat-id duplicates (N unique)
INFO: Validating feat slug naming...
INFO: ✅ All feat slugs are valid (kebab-case)
INFO: Scanning env-ids...
INFO: ✅ No env-id duplicates
```

**Critical line**: `INFO: cue eval extracted N features`
- N MUST be > 0 for exit 0
- If N == 0, log MUST show `ERROR: No features extracted`

---

### 4.2 slow mode logs (MUST include)

```
INFO: Mode: SLOW (feat-id/env-id dedup + refs + circular-deps)
INFO: Mode: FAST (...)                    ← fast inclusion proof
[... all fast mode logs ...]
INFO: Scanning for broken references...
INFO: ✅ No broken references found
INFO: Scanning for circular dependencies...
INFO: ✅ No circular dependencies found
```

**Critical line**: `INFO: Mode: FAST`
- Proves slow includes fast (contract verification)

---

## 5. Error Categories & Messages

### 5.1 Extraction failure (exit 1)
```
ERROR: No features extracted (cannot verify dedup)
ERROR: cue eval failed: <reason>
```

### 5.2 Duplicate ID (exit 1)
```
ERROR: Duplicate feat-id found: <id>
  - <file1>:<line>
  - <file2>:<line>
```

### 5.3 Broken reference (exit 1, slow only)
```
ERROR: Broken reference in <file>:<line>
  Reference: <urn:feat:unknown>
  Available: [list of valid feat-ids]
```

### 5.4 Circular dependency (exit 1, slow only)
```
ERROR: Circular dependency detected:
  <feat-a> → <feat-b> → <feat-c> → <feat-a>
```

### 5.5 Naming violation (exit 1, fast only)
```
ERROR: Invalid slug in <file>:<line>
  Slug: <My-Feat>
  Expected: kebab-case (e.g., my-feat)
```

---

## 6. Implementation Independence

**Contract-preserving changes** (allowed):
- Change implementation language (Go → Rust/Python/etc.)
- Change CUE evaluation method (as long as canonical)
- Optimize performance
- Improve error messages (as long as categories remain)

**Contract-breaking changes** (FORBIDDEN):
- Remove any mandatory check from fast/slow
- Change exit code meanings
- Remove mandatory log lines
- Break fast ⊂ slow inclusion

**Migration rule**: If implementation changes, this contract MUST be verified via:
1. Golden log comparison tests
2. Exit code regression tests
3. Audit of fast ⊂ slow inclusion

---

## 7. Entry Point Contract

**SSOT**: `scripts/check.sh <mode>`

**Mandatory behavior**:
- check.sh MUST validate repo root (via spec-lint)
- spec-lint MUST fail-fast if `cue.mod/module.cue` missing
- No auto-discovery of specRoot (explicit contract)

**Dispatcher responsibility** (check.sh):
- Route to spec-lint binary
- NO validation logic (SRP: dispatcher only)

**Validator responsibility** (spec-lint):
- All checks (dedup, refs, cycles, naming)
- Repo root validation (NewChecker)
- Exit code enforcement

---

## 8. Auditability Requirements

**For each mode, logs MUST enable verification of**:
- Feature count (featCount > 0)
- Check results (duplicates, refs, cycles, naming)
- Exit code (0 or 1)
- Mode inclusion (slow shows fast execution)

**Audit-friendly log format**:
```
INFO: <informational messages>
ERROR: <failure messages>
✅ <success summary>
```

---

## 9. Version & Evolution

**Contract version**: 1.0 (2025-12-29)

**How to update this contract**:
1. Propose changes via PR
2. Verify no existing usage breaks
3. Update contract version
4. Update implementation to match
5. Add golden tests for new contract

**Deprecation policy**:
- Contracts are immutable once established
- New features = additive only (no removals)
- Breaking changes require Phase version bump

---

## 10. Compliance Verification

**How to verify implementation complies**:
1. Run: `nix develop -c bash scripts/check.sh fast`
   - Check log includes all mandatory lines (section 4.1)
   - Check exit code matches conditions (section 3.1)
2. Run: `nix develop -c bash scripts/check.sh slow`
   - Check log includes fast execution proof (section 4.2)
   - Check exit code matches conditions (section 3.2)
3. Test edge cases:
   - featCount==0 → exit 1
   - Duplicate ID → exit 1
   - Broken ref → exit 1 (slow only)
   - Circular dep → exit 1 (slow only)

**Golden test location**: `tests/unit/spec-lint/golden/`

---

**Contract Status**: ✅ BINDING (implementation must comply)  
**Last Updated**: 2025-12-29  
**Next Review**: When implementation changes proposed
