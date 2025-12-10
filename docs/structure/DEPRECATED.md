# DEPRECATED

**This directory is deprecated as of issue #42.**

## Reason

Structure/skeleton management has been moved to the `adr` repository as part of the responsibility separation:
- **adr repository**: Generates `tree-final-nar-*.json` (skeleton/structure output)
- **spec repository**: Only validates the generated tree

## Migration Path

The `skeleton.json` concept has been replaced by:
- Repository: `github:PorcoRosso85/adr`
- Output: `tree-final-nar-<narHash>.json` (content-addressed)
- Format: JSON with per-node manifests and narHash

## Removal Timeline

This directory will be completely removed in a future commit after E2E testing confirms the new architecture works correctly.

---

**Last updated**: 2025-11-11
