// Fixtures - Contract/Checks Validation Test Cases
//
// Purpose:
//   - Prove that CUE contracts (contract/*.cue + checks/*.cue) are enforced
//   - Provide regression test cases for constraint validation
//
// Structure:
//   pass/  - Fixtures expected to PASS validation
//   fail/  - Fixtures expected to FAIL validation
//
// Import Policy (SSOT):
//   ✅ Runner (nix/checks.nix) injects contract+checks
//   ❌ Fixtures MUST NOT import contract/checks directly
//
// Why:
//   - Prevents import omission (false PASS)
//   - Prevents partial import (false FAIL)
//   - Single responsibility: fixtures = pure data
//
// Validation:
//   nix flake check  → runs spec-fast with fixture validation
//
// Example Runner Command:
//   cue vet \
//     ./spec/ci/fixtures/pass/minimal-valid/... \
//     ./spec/ci/contract/... \
//     ./spec/ci/checks/...

package fixtures

// This file exists only for documentation
// Actual fixtures are in pass/ and fail/ subdirectories
