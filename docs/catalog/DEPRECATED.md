# DEPRECATED

**This directory is deprecated as of issue #42.**

## Reason

Catalog management (slot definitions) has been moved to the `adr` repository as part of the responsibility separation:
- **adr repository**: Manages catalog (hundreds of URIs, each with single responsibility)
- **spec repository**: Only validates contracts (no catalog management)

## Migration Path

All catalog content from this directory has been migrated to:
- Repository: `github:PorcoRosso85/adr`
- Location: `catalog/` directory
- Format: CUE-based slot definitions

## Removal Timeline

This directory will be completely removed in a future commit after E2E testing confirms the new architecture works correctly.

---

**Last updated**: 2025-11-11
