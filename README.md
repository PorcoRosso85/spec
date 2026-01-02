# spec-repo

TDD-based specification repository with DoD (Definition of Done) validation.

**Design**: CUE (SSOT) + Nix (mechanical verification) = Third-party one-command reproducibility.

---

## Entry Point

```bash
nix flake check
```

**Single command, zero parameters** - Validates all DoD contracts (21 checks).

---

## Writing a New Feature

**Location**: `spec/urn/feat/<slug>/feature.cue`

**Template**:
```cue
package feat

import "github.com/porcorosso85/spec-repo/spec/schema"

feature: schema.#Feature & {
	slug: "my-feature"  // Auto-derives id: "urn:feat:my-feature"
	
	artifact: repoEnabled: true  // If feature has implementation repo
}
```

**Forbidden** (DoD1 validation):
- `contractOverride` - Features must not redefine contracts
- `schemaOverride` - Features must not inject custom schemas  
- `exportOverride` - Features must not override exports

**Validation**:
```bash
nix flake check  # Automatically validates DoD1-4
```

---

## Adding a New DoD

DoDs are validated in two tiers:

1. **Unit (GREEN)**: `spec/ci/tdd/green/<NN-dod-name>/`
   - `input.cue` - Test fixture (malicious data)
   - `expected.cue` - Expected detector output
   - `test.cue` - Detector invocation + validation

2. **Integration (Real Data)**:
   - **Verify**: `spec/ci/integration/verify/<NN-dod-name>/`
     - Validates real spec-repo data is clean
   - **Negative**: `spec/ci/integration/negative/<NN-dod-name>/`
     - Injects malicious data, confirms detection

**Steps**:
1. Write detector: `spec/ci/detector/<dod-name>.cue`
2. Write unit tests (GREEN): Pass with malicious fixture
3. Add integration functions: `nix/lib/integration.nix`
4. Register packages: `flake.nix` (verify/negative)
5. Register checks: `nix/checks.nix`
6. Verify: `nix flake check`

---

## Forbidden Patterns

**No shell logic in builders**:
```nix
# ❌ FORBIDDEN
if [ -z "$var" ]; then echo "fail"; exit 1; fi

# ✅ ALLOWED
${cue-v15}/bin/cue vet input.cue test.cue expected.cue && touch $out
```

**No patches**: Use language/tool features correctly (正攻法のみ).

**No manual documentation**: Documentation is CUE-generated or CUE itself is readable.

---

## DoD Contracts (Current)

| DoD | Responsibility | SSOT |
|-----|----------------|------|
| DoD1 | Forbidden responsibility detection | `detector/responsibility.cue` |
| DoD2 | Minimum consumer API guarantee | `detector/consumer-api.cue` |
| DoD3 | Outputs manifest consistency | `spec/manifest.cue` |
| DoD4 | Feature ID uniqueness | `detector/uniq.cue` |

All contracts validated via `nix flake check` (21 checks).

---

## Principles

1. **CUE as SSOT** - All validation logic in CUE
2. **Nix as executor** - Mechanical verification only (no logic)
3. **Single entry point** - `nix flake check` for third-party reproducibility
4. **Verify + Negative** - Both clean state and detection capability tested
5. **正攻法のみ** - No patches, use tools correctly

---

## Local Development

```bash
# Full validation (21 checks)
nix flake check

# Individual checks
nix build .#checks.x86_64-linux.unit-green-dod1
nix build .#checks.x86_64-linux.integration-verify-dod2

# Smoke/fast validation
bash scripts/check.sh smoke  # CUE fmt + basic vet
bash scripts/check.sh fast   # Full CUE contract validation
```

---

## Structure

- `repo.cue` - **CI要件SSOT（唯一）**
  - `requiredChecks`: 必須チェック一覧（flake.checks と対照）
  - `deliverablesRefs`: 必須参照一覧（実装・素材の所在）
  - **Rule**: CI要件はrepo.cueにのみ記述すること

- `spec/` - CUE specifications (素材・実装)
  - `urn/feat/` - Feature definitions (素材)
  - `schema/` - Type definitions (素材)
  - `ci/detector/` - DoD detectors (実装)
  - `ci/contract/` - Contract definitions (素材)
  - `ci/tdd/green/` - Unit tests (GREEN) (素材)
  - `ci/integration/` - Integration tests (verify/negative) (素材)
  - `ci/checks/` - Check definitions (素材)
  - `ci/fixtures/` - Test fixtures (素材)
  - `manifest.cue` - Outputs manifest (素材)

- `nix/` - Nix validation infrastructure (具現)
  - `lib/integration.nix` - Data extraction + CUE generation (具現)
  - `checks.nix` - Check definitions (具現)
  - `checks/*.nix` - Individual check implementations (具現)

- `flake.nix` - Entry point + package definitions (具現)
  - **Rule**: Nixは「具現」のみ。ロジック禁止。
