# Branch Protection Setup

This guide explains how to configure GitHub branch protection for the 3-SSOT guard system.

## Prerequisites

- Repository admin access
- At least one successful CI run (to populate available check names)

## Step 1: Initial CI Run

Before configuring branch protection, merge the Phase-0+1 PR to `main` so that GitHub Actions runs at least once. This populates the list of available status checks.

## Step 2: Navigate to Branch Protection

1. Go to your repository on GitHub
2. Click **Settings** → **Branches**
3. Click **Add rule** (or **Edit** if a rule exists)

## Step 3: Configure Rule

### Branch name pattern
```
main
```

### Protect matching branches

Check the following options:

- ☑️ **Require a pull request before merging**
  - ☑️ Require approvals: **1** (or more, as needed)

- ☑️ **Require status checks to pass before merging**
  - ☑️ Require branches to be up to date before merging

### Required status checks

Select these 4 checks:
1. `catalog-validate`
2. `adr-validate`
3. `skeleton-guard`
4. `traceability-gen`

**Note**: These checks will appear in the list only after the workflow runs at least once.

### Additional recommended settings

- ☑️ **Require conversation resolution before merging**
- ☑️ **Do not allow bypassing the above settings**

## Step 4: Save

Click **Create** (or **Save changes**)

## Phase-0+1: Observation Mode

During Phase-0+1, all CI jobs have `continue-on-error: true`, so they will show as "passed" even if validation fails. This is intentional for the observation phase.

**What to observe:**
- Check CI logs for warnings
- Verify that validation logic works correctly
- Identify any false positives

## Phase-2: Remove continue-on-error

Once you've verified the checks are working correctly (2-3 PRs):

1. Edit `.github/workflows/repo-guard.yml`
2. Remove `continue-on-error: true` from all 4 jobs
3. Merge this change

**From this point forward**, PRs will fail if any validation check fails.

## Phase-3: Full Enforcement

At this stage:
- ✅ Branch protection is active
- ✅ All 4 checks are required
- ✅ No `continue-on-error` overrides
- ✅ Unauthorized paths are blocked
- ✅ Manual `.gen` edits are blocked

## Troubleshooting

### Checks don't appear in the list

**Problem**: Required status checks list is empty

**Solution**:
1. The workflow must run at least once
2. Check `.github/workflows/repo-guard.yml` is on `main` branch
3. Verify workflow triggered for a PR

### Checks are always green even with errors

**Problem**: Jobs have `continue-on-error: true`

**Solution**: This is expected in Phase-0+1. Check the job logs to see actual validation results.

### Cannot merge even though all checks pass

**Problem**: "Required status checks" not configured correctly

**Solution**:
1. Verify the exact job names match what's in the workflow
2. Job names are case-sensitive
3. Check workflow syntax is correct

---

## Quick Reference

| Phase | continue-on-error | Branch Protection | Expected Behavior |
|-------|-------------------|-------------------|-------------------|
| Phase-0+1 | `true` | Recommended (optional) | Always green, check logs |
| Phase-2 | `false` | Recommended | Fails on validation errors |
| Phase-3 | `false` | **Required** | Full enforcement |

---

## Next Steps

After branch protection is configured:
1. Test with a "bad" PR (unauthorized path) to verify blocking works
2. Document any custom adjustments in this file
3. Consider adding CODEOWNERS for `docs/**` paths
