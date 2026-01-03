// DoD2: consumer API - GREENテスト
// Purpose: detector.ConsumerAPI が属性の過不足を正しく検出することを検証
// GREEN段階: reportは計算結果、expectedと一致を確認

package green_02_consumer_api

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Alias input to avoid name collision
_input: input

// Run detector
_detector: detector.#ConsumerAPI & {
	input: _input
}

// Verify report matches expected
_test: _detector.report & expected
