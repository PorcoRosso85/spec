// DoD2: Integration-Verify - 期待値（正常系）
// Purpose: クリーンな実データでは属性の過不足なし
// Design: 空リストを期待（missingAttributes/extraAttributes両方）

package integration_verify_02

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

expected: det.#ConsumerAPIReport & {
	missingAttributes: []
	extraAttributes:   []
}
