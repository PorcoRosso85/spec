// DoD4: Integration-Negative - 期待出力（悪性検出）
// Purpose: 意図的な重複注入が正しく検出されることを確認
// Design: 実データ + 重複1件 → detector が正しく指摘

package integration_negative_04

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Expected report: Specific duplicate detected
// Note: The first feat in the list is duplicated by Nix helper
expected: det.#UniqReport & {
	// Must contain the duplicated ID (decide-ci-score-matrix is alphabetically first)
	duplicateFeatIDs: ["urn:feat:decide-ci-score-matrix"]
	duplicateSlugs:   ["decide-ci-score-matrix"]
}
