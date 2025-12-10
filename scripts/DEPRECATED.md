# DEPRECATED

**This directory is deprecated as of issue #42.**

## Reason

All generation and validation scripts have been made obsolete by the new architecture:
- **gen_skeleton_from_adr.sh**: No longer needed (adr repository generates tree-final-nar-*.json)
- **check_skeleton_guard.sh**: Replaced by `.github/workflows/spec-guard.yml`
- **gen_adr_md.sh**: Moved to adr repository
- **gen_traceability.sh**: Moved to adr repository

## Migration Path

New architecture:
- **adr repository**: Handles all ADR/catalog/skeleton generation
- **spec repository**: Only contract validation via `spec-guard.yml`

## Removal Timeline

This directory will be completely removed in a future commit after E2E testing confirms the new architecture works correctly.

---

**Last updated**: 2025-11-11
