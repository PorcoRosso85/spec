## Change Overview
<!-- Brief description of what this PR does -->

## Slot Operations
<!-- Check all that apply -->

### Catalog Changes
- [ ] Added new slot(s) to `docs/catalog/slots/*.cue`
- [ ] Modified existing slot definition(s)
- [ ] No catalog changes

**Slot IDs affected:**
<!-- List slot IDs, e.g., custom.repo-structure-guard -->
-

### ADR Changes
- [ ] Created new ADR: `docs/adr/adr-XXXX.cue`
- [ ] Updated existing ADR
- [ ] No ADR changes

**ADR ID:**
<!-- e.g., ADR-0001 -->
-

**Activations:**
<!-- List slot.id activations from abstract → active -->
-

### Skeleton Changes
- [ ] Updated `docs/structure/.gen/skeleton.json` with new placement
- [ ] Removed placement from skeleton
- [ ] No skeleton changes

**Placement changes:**
<!-- e.g., custom.repo-structure-guard → .github/workflows/repo-guard.yml -->
-

## Impact Assessment

### Responsibility Boundary Impact
<!-- Which responsibilities are affected by this change? -->
-

### Affected Components
<!-- Which directories/modules are touched? -->
-

### Breaking Changes
- [ ] This PR contains breaking changes
- [ ] This PR is backward compatible

**If breaking, describe migration path:**
<!-- How do existing users/systems need to adapt? -->
-

## Validation

### Pre-submission Checklist
- [ ] I followed the 3-step process: catalog → ADR → skeleton
- [ ] I did not manually edit files in `.gen/` directories
- [ ] I verified `cue vet` passes locally (if CUE is available)
- [ ] I reviewed the generated `.gen/*.md` files (if applicable)

### CI Checks
<!-- These will be validated automatically -->
- [ ] catalog-validate
- [ ] adr-validate
- [ ] skeleton-guard
- [ ] traceability-gen

## Additional Context
<!-- Any additional information that reviewers should know -->

---

### For Reviewers

**Review focus areas:**
1. Does the slot definition follow SRP (Single Responsibility Principle)?
2. Is the ADR rationale clear and justified?
3. Is the placement in skeleton.json appropriate for the slot's tier and dependencies?
4. Are there any unintended side effects on existing responsibilities?

**Documentation:**
- [ ] Changes are reflected in generated documentation
- [ ] No manual edits to `.gen/` files detected
- [ ] All scripts execute successfully
