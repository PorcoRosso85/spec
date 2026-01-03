// DoD2: Integration-Verify - 期待値（正常系）
// Purpose: Minimum API (6 keys) is provided, extra keys are allowed (non-breaking)
// Design: missingAttributes must be empty, extraAttributes can contain additional keys

package integration_verify_02

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

expected: det.#ConsumerAPIReport & {
	// Required: No missing keys (minimum API must be complete)
	missingAttributes: []
	
	// Extra attributes are allowed (non-breaking additions)
	// Note: DoD2 only guarantees minimum 6 keys, not complete API coverage
	extraAttributes: [...]
}
