// DoD4: 重複なし - GREENテスト
// Purpose: detector.Uniq が重複を正しく検出することを検証
// GREEN段階: reportは計算結果、expectedと一致を確認
// Note: Uses 'testInput' to avoid CUE scope resolution issues with 'input: input'

package green_04_uniq

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Rename to avoid scope collision (testInput instead of input)
testInput: input

// Run detector
_detector: detector.#Uniq & {
	input: testInput
}

// Verify report matches expected
_test: _detector.report & expected
