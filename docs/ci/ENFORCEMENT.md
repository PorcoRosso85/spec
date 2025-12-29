# CI Enforcement Rules (Normative)

**Purpose**: Define how to enforce spec-lint checks via GitHub CI  
**Authority**: spec-repo maintainers  
**Binding**: YES (required for production deployment)  
**Date**: 2025-12-29

---

## 1. Core Enforcement Contract

**Invariant**: PR cannot merge without fast PASS, main cannot advance without slow PASS.

| Event | Required Check | Enforcement Method |
|-------|----------------|-------------------|
| **Pull Request** | fast mode | GitHub branch protection (required status check) |
| **Push to main** | slow mode | GitHub branch protection (required status check) |

**Rationale**: Prevents manual bypass, ensures "破れないゲート" (unbreakable gate).

---

## 2. GitHub Workflow Configuration

### 2.1 Job Names (MUST NOT CHANGE)

**File**: `.github/workflows/spec-ci.yml`

**Job names** (FIXED, used in branch protection):
```yaml
jobs:
  fast:    # ← Required check name for PR
  slow:    # ← Required check name for main
  smoke:   # ← Baseline check (always runs)
```

**CRITICAL**: These job names are referenced in GitHub branch protection settings. Changing them breaks enforcement.

---

### 2.2 Workflow Structure (Current)

```yaml
name: spec-ci

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  # Phase 1 fast checks for all PRs
  fast:
    if: github.event_name == 'pull_request' || github.ref != 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
        with:
          nix_path: nixpkgs=channel:nixos-unstable
      - name: Run spec:check:fast
        run: nix develop -c bash scripts/check.sh fast

  # Phase 1 slow checks for main branch pushes
  slow:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
        with:
          nix_path: nixpkgs=channel:nixos-unstable
      - name: Run spec:check:slow
        run: nix develop -c bash scripts/check.sh slow

  # Phase 0 baseline smoke check (always)
  smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
        with:
          nix_path: nixpkgs=channel:nixos-unstable
      - name: Run spec:check:smoke
        run: nix develop -c bash scripts/check.sh smoke
```

**Key points**:
- Job name = required check identifier
- `if` conditions ensure correct mode per event
- Command MUST be: `nix develop -c bash scripts/check.sh <mode>`

---

## 3. GitHub Branch Protection Setup

**WARNING**: Workflow YAML alone does NOT enforce checks. GitHub branch protection is required.

### 3.1 Settings Location

```
Repository → Settings → Branches → Branch protection rules → Add rule
```

### 3.2 Protection Rule for `main`

**Branch name pattern**: `main`

**Required settings**:
1. ✅ **Require a pull request before merging**
   - Require approvals: 0 (or as needed)
   
2. ✅ **Require status checks to pass before merging**
   - ✅ Require branches to be up to date before merging
   
3. **Status checks that are required**:
   - ✅ `fast` (CRITICAL: must match job name exactly)
   - ✅ `smoke` (baseline check)
   
4. ✅ **Do not allow bypassing the above settings**
   - Ensures admins cannot bypass (if org policy allows)

---

### 3.3 Enforcement Verification

**How to verify enforcement is working**:

1. **Create test PR with breaking change**:
   ```bash
   # Add duplicate feat-id
   echo 'feature: {id: "urn:feat:existing"}' > spec/urn/feat/test/feature.cue
   git checkout -b test-enforcement
   git add . && git commit -m "test: duplicate feat-id"
   git push origin test-enforcement
   ```

2. **Expected behavior**:
   - PR created
   - `fast` job runs
   - `fast` job FAILS (exit 1 due to duplicate)
   - PR shows "Some checks were not successful"
   - **"Merge pull request" button is DISABLED** ← Enforcement proof

3. **If button is NOT disabled**:
   - Branch protection not configured correctly
   - Check required status check settings
   - Verify job name matches exactly (`fast`, not `Fast`)

---

## 4. Bypass Prevention

**Goal**: Make it impossible to bypass checks accidentally or intentionally.

### 4.1 What GitHub Settings Prevent

✅ **Cannot merge PR without fast PASS**
- Branch protection blocks merge button
- Even admins cannot bypass (if "Include administrators" enabled)

✅ **Cannot push to main without slow check**
- main branch is protected
- Direct pushes rejected

### 4.2 What Settings DO NOT Prevent

❌ **Force push to main** (if "Allow force pushes" enabled)
- Solution: Disable force pushes in branch protection

❌ **Admin bypass** (if "Include administrators" NOT enabled)
- Solution: Enable "Do not allow bypassing the above settings"

❌ **Changing workflow file to skip checks**
- Partial solution: Protect `.github/workflows/` via CODEOWNERS
- Full solution: Use GitHub Enterprise "required workflows"

---

## 5. Job Name Stability Contract

**BINDING RULE**: Job names in `.github/workflows/spec-ci.yml` are API contracts.

### 5.1 Protected Job Names

| Job Name | Purpose | Can Rename? |
|----------|---------|-------------|
| `fast` | PR gate | ❌ NO (branch protection depends on this) |
| `slow` | main gate | ❌ NO (branch protection depends on this) |
| `smoke` | baseline | ⚠️ CAUTION (required check, but less critical) |

### 5.2 How to Rename (Emergency Only)

If you MUST rename a job:
1. Add new job name to workflow
2. Run workflow once (creates new check)
3. Update branch protection to require new name
4. Remove old job name from workflow
5. Wait 24h (ensure no in-flight PRs)
6. Verify branch protection works with new name

**Better approach**: Never rename. Add new jobs instead.

---

## 6. Enforcement Monitoring

### 6.1 How to Audit Enforcement Status

**Check 1: Workflow runs correctly**
```bash
# View recent workflow runs
gh run list --workflow=spec-ci.yml --limit 10

# Expected: fast runs on PR events, slow runs on main pushes
```

**Check 2: Branch protection is active**
```bash
# Check branch protection status
gh api repos/:owner/:repo/branches/main/protection

# Expected: required_status_checks includes "fast"
```

**Check 3: PRs are blocked when checks fail**
- Create test PR with intentional failure
- Verify merge button is disabled
- Close PR without merging

---

### 6.2 Common Failure Modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| fast job doesn't run on PR | `if` condition wrong | Check `github.event_name == 'pull_request'` |
| slow job doesn't run on main push | `if` condition wrong | Check `github.ref == 'refs/heads/main'` |
| Merge button enabled despite fast FAIL | Branch protection not set | Add `fast` to required checks |
| Check name not found | Job name mismatch | Verify exact match (case-sensitive) |

---

## 7. Enforcement Evolution

**When to update enforcement rules**:
1. Adding new check (Phase 2: unit tests)
   - Add job to workflow
   - Add job name to required checks
   - Document here

2. Changing check contract (see SPEC-LINT-CONTRACT.md)
   - Update contract first
   - Verify jobs still comply
   - No enforcement rule change needed (unless job name changes)

3. Adding new branch (e.g., `develop`)
   - Copy protection rule
   - Adjust required checks as needed
   - Document in this file

---

## 8. Disaster Recovery

**Scenario**: Enforcement is blocking legitimate merges

### 8.1 Emergency Bypass (Last Resort)

**ONLY IF**: Critical hotfix needed and checks are genuinely broken

**Procedure**:
1. Verify checks are actually broken (not just failing on bad code)
2. Admin temporarily disables branch protection
3. Merge hotfix
4. **IMMEDIATELY** re-enable branch protection
5. Post-mortem: Why did checks break? How to prevent?

**Record**: Document every bypass in `docs/ci/BYPASS-LOG.md` (create if needed)

---

### 8.2 Degraded Mode (Partial Enforcement)

**Scenario**: One check is broken, others work

**Option 1**: Remove broken check from required list temporarily
- Merge window opens (lower safety)
- Fix check ASAP
- Re-add to required list

**Option 2**: Fix check in emergency PR
- Fast-track review
- Maintain full enforcement

**Recommendation**: Option 2 (maintain enforcement)

---

## 9. Integration with Phase 2+

**When Phase 2 (unit tests) is added**:

### 9.1 Update workflow
```yaml
jobs:
  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
      - run: nix develop -c bash tests/unit/run.sh
```

### 9.2 Update branch protection
- Add `unit` to required status checks
- Decision: PR-only or main-too?
  - Recommendation: PR-only (fast feedback, unit tests catch regressions early)

---

## 10. Compliance Checklist

**Before claiming "Enforcement Complete"**:

- [ ] `.github/workflows/spec-ci.yml` has stable job names (`fast`, `slow`, `smoke`)
- [ ] Branch protection configured for `main`
- [ ] Required checks include `fast`
- [ ] Required checks include `smoke`
- [ ] "Do not allow bypassing" is enabled
- [ ] Verified: Test PR with failure blocks merge
- [ ] Verified: fast runs on PR events
- [ ] Verified: slow runs on main pushes
- [ ] Documented: How to verify enforcement (section 3.3)
- [ ] Documented: Disaster recovery (section 8)

---

**Enforcement Status**: ✅ BINDING (required for production)  
**Last Updated**: 2025-12-29  
**Next Review**: When adding Phase 2 checks
