# Feat Contracts Bundle Export Script

## Purpose
Export feat contracts (`spec/urn/feat/*/contract.cue`) as a bundle with:
- `index.json`: List of all contracts (slug, sha256, file)
- `<slug>/contract.json`: Individual contract data
- `<slug>/contract.json.sha256`: SHA256 hash for verification

## Usage
```bash
./scripts/export-feat-contracts-bundle.sh <output_dir> <spec_root>

# Example
./scripts/export-feat-contracts-bundle.sh ./bundle ./spec
```

## Output Structure
```
bundle/
├── index.json
├── decide-ci-score-matrix/
│   ├── contract.json
│   └── contract.json.sha256
└── dx-ux-test/
    ├── contract.json
    └── contract.json.sha256
```

## TDD Tests
| Test | Description | Expected |
|------|-------------|----------|
| (A) Normal 2 feats | 2 valid contracts | PASS |
| (B) requiredChecks absence | Missing required field | FAIL + path |
| (C) import/mock | External import | FAIL + path |
| (D) Order stability | Deterministic output | Same index.json |

## External Repo Consumption
```nix
# In external feat-repo's flake.nix
let
  spec-repo = inputs.spec-repo;
in
{
  # Run the bundle script
  bundles = pkgs.runCommand "feat-contracts" {
    nativeBuildInputs = [ spec-repo.packages.cue ];
  } ''
    ${spec-repo}/scripts/export-feat-contracts-bundle.sh $out ${spec-repo}
  '';
}
```

## Constraints
- No `flake.nix` changes required
- Script only, no Nix derivation outputs
- Works with any spec-repo version (pin via flake inputs)
