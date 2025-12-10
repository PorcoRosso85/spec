# DEPRECATED

**This directory is deprecated as of issue #42.**

## Reason

ADR management has been moved to the `adr` repository as part of the responsibility separation:
- **adr repository**: Manages decisions (ADR), catalog (slot definitions), and generates `tree-final-nar-*.json`
- **spec repository**: Only validates contracts from `tree-final-nar-*.json`

## Migration Path

All ADR content from this directory has been migrated to:
- Repository: `github:PorcoRosso85/adr`
- Format: CUE-based ADR with `state: provisional | final`

## Removal Timeline

This directory will be completely removed in a future commit after E2E testing confirms the new architecture works correctly.

---

**Last updated**: 2025-11-11
