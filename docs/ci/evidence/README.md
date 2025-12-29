# CI Evidence Directory

**Purpose**: Store immutable evidence of CI configuration and enforcement

## Files

### phase15-branch-protection-config.json
**What**: GitHub branch protection configuration for `main` branch  
**When**: Phase 1.5 completion  
**How to apply**:
```bash
# Apply protection settings to main branch
gh api repos/PorcoRosso85/spec/branches/main/protection \
  --method PUT \
  --input docs/ci/evidence/phase15-branch-protection-config.json

# Verify settings
gh api repos/PorcoRosso85/spec/branches/main/protection \
  > docs/ci/evidence/phase15-branch-protection-applied.json
```

**How to verify**:
```bash
# Fetch current protection settings
gh api repos/PorcoRosso85/spec/branches/main/protection

# Compare with expected config
diff docs/ci/evidence/phase15-branch-protection-config.json \
     docs/ci/evidence/phase15-branch-protection-applied.json
```

## Audit Trail

All evidence files are:
- ✅ JSON format (machine-readable)
- ✅ Committed to git (immutable history)
- ✅ Reproducible (gh CLI commands documented)
- ✅ Verifiable (diff against current state)

**No screenshots needed** - JSON is the证拠.
