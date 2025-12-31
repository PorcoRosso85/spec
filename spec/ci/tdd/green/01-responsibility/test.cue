// DoD1: 責務配分 - GREENテスト
// Purpose: detector.Responsibility が禁止責務を正しく検出することを検証
// GREEN段階: reportは計算結果、expectedと一致を確認

package green_01_responsibility

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Alias input to avoid name collision
_input: input

// Run detector
_detector: detector.#Responsibility & {
	input: _input
}

// Verify report matches expected
_test: _detector.report & expected
