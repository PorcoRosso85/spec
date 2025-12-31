// DoD3: Integration-Negative - 期待値（異常系）
// Purpose: 意図的差分がdetectorに検出されることを確認
// Design: missingPathsに具体的なパス名を指定

package integration_negative_03

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Expected: Detector must find the missing "spec.cuePath"
expected: det.#OutputsManifestReport & {
	missingPaths: ["spec.cuePath"]  // Injected missing path
	
	// Unexpected paths may vary (allow any)
	unexpectedPaths: [...]
	
	// Version mismatch: true (manifest "0.1.0" vs self.spec "dirty")
	versionMismatch: true
}
