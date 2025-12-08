package feat

import "spec/schema"

// decide-ci-score-matrix: CI スコアマトリックス判定機能
// - urn:feat:decide-ci-score-matrix
// - repo を持つ実装機能
feature: schema.#Feature & {
	slug: "decide-ci-score-matrix"
	// id: "urn:feat:decide-ci-score-matrix" は自動導出される

	artifact: repoEnabled: true
}
