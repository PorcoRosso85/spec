// DoD2: Integration-Negative - 期待値（異常系）
// Purpose: 意図的に欠落させたキーがdetectorに検出されることを確認
// Design: missingAttributesに具体的なキー名を指定

package integration_negative_02

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Expected: Detector must find the missing "spec.urn.envPath"
expected: det.#ConsumerAPIReport & {
	missingAttributes: ["spec.urn.envPath"]
	extraAttributes:   []
}
