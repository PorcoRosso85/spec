// DoD3: Integration-Verify - 期待値（正常系）
// Purpose: manifest (SSOT) defines minimum required outputs
// Design: No missing paths (all manifest paths exist in self.spec)
//         Unexpected paths allowed (self.spec can have extras)
//         Version mismatch allowed (manifest version is aspirational)

package integration_verify_03

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

expected: det.#OutputsManifestReport & {
	// Critical: No missing paths (manifest requirements met)
	missingPaths: []
	
	// Unexpected paths allowed (self.spec can extend manifest)
	unexpectedPaths: [...]
	
	// Version mismatch: true (manifest "0.1.0" vs self.spec "dirty")
	// Note: Version validation is relaxed in P0, will be enforced in future
	versionMismatch: true
}
