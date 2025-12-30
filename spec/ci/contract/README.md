# CUE Contract SSOT

**Purpose**: Single source of truth for spec-repo validation rules

**Location**: `spec/ci/contract/*.cue`

## Current Implementation

### `naming.cue`
- Kebab-case slug validation
- URN format validation (`urn:feat:<slug>`)
- DRY guarantee: `id` derived from `slug`

### `uniq.cue`
- ID uniqueness constraints
- Structural uniqueness (CUE imports enforce unique paths)

### `refs.cue`
- Reference integrity specification
- Circular dependency prevention specification

### `contract.cue`
- Aggregated contract entrypoint
- JSON export support

## Validation

```bash
# All spec validation
cue vet ./spec/... ./spec/ci/contract/...
```

## Current Limitations

### Circular Dependency Detection
**Status**: ⚠️ **Not implemented** (CUE-only structural detection difficult)

**Reason**: CUE's type system does not inherently detect cycles in `deps` field

**Future**: 
- Option A: Implement in CUE via structural constraints (kind: atomic/composite)
- Option B: External tool reading CUE contract (spec-check v2)

### Broken Reference Detection
**Status**: ⚠️ **Not implemented** (requires cross-file URN collection)

**Reason**: CUE vet does not validate string references across files

**Future**:
- Option A: CUE tooling enhancement
- Option B: External validator reading CUE contract

## Design Principles

- ✅ **CUE = SSOT**: All rules defined in CUE
- ✅ **No MD contracts**: Documentation only, not normative
- ✅ **No logic in tools**: Tools execute CUE, don't implement rules
- ✅ **Reproducible**: `nix develop -c cue vet` deterministic
