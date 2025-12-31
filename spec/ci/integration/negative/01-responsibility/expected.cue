// DoD1: Integration-Negative - 期待値（異常系）
// Purpose: Injected contractOverride must be detected
// Design: Specific violation expected

package integration_negative_01

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Expected: Detector must find the contractOverride violation
expected: det.#ResponsibilityReport & {
	violations: [{
		category: "contract-override"
		field:    "contractOverride"
		message:  "Feat must not redefine contracts"
	}]
}
