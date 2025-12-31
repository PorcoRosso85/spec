// DoD4: 重複なし - GREENテスト
// Purpose: detector.Uniq が重複を正しく検出することを検証
// GREEN段階: reportは計算結果、expectedと一致を確認

package green_04_uniq

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Alias input to avoid name collision
_input: input

// Run detector
_detector: detector.#Uniq & {
	input: _input
}

// Verify report matches expected
_test: _detector.report & expected
