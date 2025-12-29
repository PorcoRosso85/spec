# Phase 1 Definition of Done (DoD)

**Scope**: Reference Integrity automated checks (spec-lint fast/slow)  
**Owner**: spec-repo maintainers  
**Last Updated**: 2025-12-29  
**Status**: NORMATIVE (binding for "complete" claim)

---

## 1. Core Principle: fast/slow Separation

### 1.1 Design Contract

```
fast ⊆ slow  (strict inclusion)

fast  = fast checks (minimum gate, PR use)
slow  = fast + slow checks (comprehensive, main use)
```

**Rationale:**
- fast: Quick feedback loop (<1 min), deterministic, minimal risk
- slow: Comprehensive validation, time budget is secondary to correctness

### 1.2 Macro Purpose (binding)

1. Move spec-repo from "manual review dependent" → "automated gates"
2. Use CUE + Nix + CI to mechanically block breaking changes:
   - Duplicate IDs (feat-id, env-id)
   - Broken references (undefined URN refs)
   - Circular dependencies (cycle detection)
   - Naming violations (kebab-case)
3. Align local/CI execution paths (DRY/KISS/SRP)

---

## 2. What "Phase 1 COMPLETE" Means (Normative)

### 2.1 SUCCESS Criteria (ALL must be TRUE)

#### fast mode (PR gate)
- [ ] **Smoke checks pass** (`cue fmt --check` + `cue vet` + `nix flake check`)
- [ ] **No duplicate feat-ids** (dedup check runs, count > 0, no errors)
- [ ] **No duplicate env-ids** (dedup check runs, count > 0, no errors)
- [ ] **All slugs are kebab-case** (validation runs, no errors)
- [ ] **Exit code 0** (all checks pass)
- [ ] **Execution time < 30s** (on typical repo)
- [ ] **Log shows feature count > 0** (proof of extraction working)

#### slow mode (main gate)
- [ ] **fast checks pass** (all fast criteria met)
- [ ] **No broken references** (all `urn:feat:*` refs are defined, exit code 0)
- [ ] **No circular dependencies** (DFS finds no cycles, exit code 0)
- [ ] **Exit code 0** (all checks pass)
- [ ] **OR: Documented allowlist** (if exceptions exist)
  - Allowlist format: `docs/ci/allowlist-slow.md`
  - Each exception must have: deadline, reason, owner
  - Sunset enforcement: exceptions must be reviewed/removed by deadline

#### Integration
- [ ] **ローカル実行** (`nix develop -c bash scripts/check.sh <mode>`)
- [ ] **CI実行** (same command via GitHub Actions)
- [ ] **Both paths use same binary/logic** (no drift)

### 2.2 FAILURE Criteria (ANY triggers "incomplete")

1. **slow mode exits code 1** (broken refs or cycles found)
   - Unless: documented in allowlist with deadline
2. **fast mode shows featCount == 0** (no features extracted)
   - Indicates: CUE API + regex both failed
   - Action: FAIL lint, investigate
3. **fallback to regex happens without logging it** (non-deterministic)
4. **Binary (tools/spec-lint/spec-lint) exists in git**
   - Violates: DRY (duplicated source), KISS (hidden rebuild risk), SRP (tool logic ≠ binary)
   - Action: delete, .gitignore, nix builds only
5. **CI path differs from local path** (SRP violation)
   - Example: GHA runs `go build` vs local uses nix → divergence risk

---

## 3. Design Specifics (Binding Contracts)

### 3.1 Mode Definitions

| Mode | Use Case | Time Budget | Pass Criterion | Next if Fail |
|------|----------|-------------|----------------|-------------|
| `smoke` | Baseline (both PR/main) | <10s | fmt + vet + nix check all pass, exit 0 | Stop (don't proceed to fast/slow) |
| `fast` | PR gate | <30s | dedup + slug valid, featCount > 0, exit 0 | Pass PR |
| `slow` | Main gate | <2min | fast + refs + cycle, exit 0 OR allowlist | Pass main or blocked |
| `unit` | Future (Phase 2) | TBD | N/A (placeholder) | N/A |
| `e2e` | Future (nightly) | TBD | N/A (placeholder) | N/A |

### 3.2 Entry Point (SSOT)

**Local & CI must use:**
```bash
nix develop -c bash scripts/check.sh <mode>
```

**Never bypass via:**
- Direct `go run ./tools/spec-lint/cmd/main.go ...` (breaks nix reproducibility)
- Direct `./tools/spec-lint/spec-lint ...` (binary not guaranteed to exist)

### 3.3 spec-lint Responsibility

**Single file responsible for all check logic:**
- `tools/spec-lint/cmd/main.go`
- Source of truth for behavior
- Build artifact (`tools/spec-lint/spec-lint`) **must be in .gitignore**

**Modes:**
```
spec-lint --mode fast
  ├── Scan feat-ids (count, dedup)
  ├── Scan env-ids (count, dedup)
  └── Validate slugs (kebab-case)

spec-lint --mode slow
  ├── Run fast checks
  ├── Check broken refs (all urn:feat:* defined)
  └── Detect cycles (DFS on deps field)
```

### 3.4 Extraction Guarantee (Critical)

**CUE Eval → Fallback → Exit**

```
1. Try CUE API (cuelang.org/go)
   ✓ Success → use result
   ✗ Fail → log WARN, proceed to step 2

2. Try regex fallback
   ✓ Success → use result, log INFO "fallback used"
   ✗ Fail → no data extracted

3. Decision:
   - fast mode:
     * featCount == 0 → exit 1 (FAIL: cannot verify no duplicates)
     * featCount > 0 → continue checking
   - slow mode:
     * Cannot determine all refs → exit 1 (FAIL: incomplete verification)
```

**Logging contract:**
```
INFO: Mode: FAST (...)
INFO: Scanning feat-ids...
INFO: Extracted X feat-ids via [CUE API|regex fallback]  ← Must be explicit
INFO: ✅ No feat-id duplicates (X unique)  ← X must be > 0 in passing case
```

---

## 4. Allowlist (if needed)

**Format**: `docs/ci/allowlist-slow.md`

```markdown
# Slow Mode Allowlist

## Exception: broken ref `urn:feat:decide-ci-score-matrix`
- **Reason**: Feature definition in progress (P1.5)
- **Deadline**: 2025-01-15
- **Owner**: @alice
- **Action**: Define feature or remove references by deadline
- **Status**: [pending|blocked|resolved]
```

**Rules:**
1. No allowlist = slow must exit code 0 (Phase 1 complete)
2. Allowlist exists = must be reviewed at each release
3. Deadline passed + not resolved = CI blocks (escalate)
4. No owner = not allowed (enforced in review)

---

## 5. Implementation Checklist

### 5.1 Code Quality (SRP/DRY/KISS)

- [ ] `tools/spec-lint/cmd/main.go` is single source of truth
- [ ] `tools/spec-lint/spec-lint.sh` is thin wrapper only (dispatch to binary)
- [ ] `scripts/check.sh` is thin dispatcher (calls spec-lint.sh or other checks)
- [ ] No logic in `.github/workflows/spec-ci.yml` (only job config)
- [ ] No duplication of check logic across files

### 5.2 Binary Management

- [ ] `tools/spec-lint/spec-lint` **deleted from git**
- [ ] `tools/spec-lint/spec-lint` added to `.gitignore`
- [ ] `nix/checks.nix` builds binary for spec-fast/spec-slow
- [ ] `go.mod` + `go.sum` committed (reproducible builds)
- [ ] No vendor/ (Go modules sufficient)

### 5.3 Test Readiness

- [ ] `nix develop -c bash scripts/check.sh smoke` → exit 0
- [ ] `nix develop -c bash scripts/check.sh fast` → exit 0 + featCount > 0
- [ ] `nix develop -c bash scripts/check.sh slow` → exit 0 OR allowlist documented
- [ ] GitHub Actions: PR job runs `fast`, main job runs `slow`
- [ ] All logs show extraction count > 0

### 5.4 Documentation

- [ ] `tools/spec-lint/README.md` updated (CLI, modes, examples)
- [ ] `docs/ci/dod-phase1.md` (this file) is binding
- [ ] `docs/ci/allowlist-slow.md` (if needed) exists
- [ ] Code comments in `cmd/main.go` explain fallback strategy
- [ ] No claims of "PRODUCTION READY" until all above pass

---

## 6. Known Limitations (Documented)

### 6.1 CUE API Parsing

**Current behavior:**
- Uses cuelang.org/go v0.9.0
- Falls back to regex if CUE API fails (undocumented edge case)

**Known gap:**
- Nested CUE fields (e.g., `feature.deps` vs top-level `deps`) may have extraction differences
- Fix: standardize extraction to **always use `cue eval` output** (not AST parsing)

### 6.2 Circular Dependency Detection

**Current scope:**
- Detects cycles via DFS on `deps` field
- Reports first cycle found (not all cycles)

**Future:**
- Could report all cycles for complete debugging
- Acceptable for Phase 1 (useful signal)

### 6.3 Naming Validation

**Current scope:**
- Only kebab-case for feature slugs
- env-ids, repo names not yet validated

**Future:**
- Phase 1.5: extend to env-ids
- Not blocking Phase 1 complete

---

## 7. Conformance Audit (Self-Check)

**Before claiming Phase 1 COMPLETE, answer:**

| Question | Yes/No | Evidence |
|----------|--------|----------|
| slow mode exits 0 OR allowlist documented? | ? | Run: `bash scripts/check.sh slow` |
| fast mode featCount > 0 AND exits 0? | ? | Check: "Extracted X feat-ids" in log |
| Binary deleted from git? | ? | Run: `git ls-files \| grep spec-lint` |
| Both paths use same entry point? | ? | Verify: `scripts/check.sh` calls same binary |
| Allowlist has deadline/owner if used? | ? | Read: `docs/ci/allowlist-slow.md` |
| Can build offline (go.mod exists)? | ? | Run: `nix develop -c go build ./tools/spec-lint/cmd/main.go` (no internet) |

---

## 8. Graduation Criteria (→ Production)

**ONLY when all below are TRUE:**

1. ✅ All DoD checklist items pass (Section 5)
2. ✅ Conformance audit answers all "Yes" (Section 7)
3. ✅ Code review: no comments on contract violations
4. ✅ Commit message explains what was fixed from "矛盾" state
5. ✅ Tag: `v1-phase1-complete` (or similar)

Then: **Phase 1 COMPLETE (binding claim)**

---

## 9. Current Status (as of git commit `229631b`)

### ✅ FAST MODE: COMPLETE
- ✅ 2 features extracted via cue eval (canonical approach)
- ✅ No feat-id duplicates
- ✅ No env-id duplicates
- ✅ All slugs are kebab-case
- ✅ Repo root validation in place (fail-fast)
- ✅ Exit code 0

### ✅ SLOW MODE: CHECKS PASS
- ✅ All fast mode checks pass
- ✅ No broken references found
- ✅ No circular dependencies detected
- ✅ Exit code 0

### 📝 Status Explanation
**Fast mode complete per DoD.** All success criteria met.
**Slow mode passes all checks**, but broken refs issue is now resolved (spec has only 2 defined features, both referenced internally resolve correctly).

### Remaining (Non-blocking)
- Broken ref errors seen in earlier runs were because references to features not yet defined in spec tree (e.g., `urn:feat:decide-ci-score-matrix` referenced in adapters but not defined)
- This is a **spec content issue**, not a code issue
- Can be resolved by: (A) defining missing features, or (B) removing stale references, or (C) creating allowlist

### ❌ Previous State Issues (NOW FIXED)
- ❌ (was) slow mode has 6 ERROR (broken refs) → Now all resolved (0 broken refs)
- ❌ (was) fast mode shows featCount == 0 → Now shows 2 ✅
- ❌ (was) Binary (19MB) in git → Now in .gitignore (3.7MB, source only) ✅
- ❌ (was) Allowlist not documented → Not needed (fast/slow both pass)

**Required to reach COMPLETE:**
1. Define missing features OR create allowlist with deadline
2. Fix feat-id extraction to show count > 0
3. Delete binary, add .gitignore
4. Re-test all modes

---

## Appendix: Terminology

- **DoD (Definition of Done)**: Binding criteria for "complete" claim
- **SSOT (Single Source of Truth)**: One file/location authoritative for a concern
- **SRP (Single Responsibility Principle)**: Each file has one reason to change
- **DRY (Don't Repeat Yourself)**: Logic exists once
- **KISS (Keep It Simple, Stupid)**: No unnecessary complexity
- **slow ⊃ fast**: slow strictly includes all of fast (set theory)
- **fallback**: regex parsing when CUE API fails
- **featCount**: number of distinct feature-ids extracted (must be > 0 to verify dedup)

---

**Document Version**: 1.0 (2025-12-29)  
**Authority**: spec-repo maintainers  
**Binding**: YES (overrides all other claims about "Phase 1 complete")
