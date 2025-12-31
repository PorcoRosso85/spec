// DoD1: Integration-Verify - 期待値（正常系）
// Purpose: Real feats have no forbidden responsibilities
// Design: violations must be empty (clean state)

package integration_verify_01

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

expected: det.#ResponsibilityReport & {
	// Critical: No violations (real feats are clean)
	violations: []
}
