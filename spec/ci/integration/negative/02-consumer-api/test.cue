// DoD2: Integration-Negative - テスト（異常系）
// Purpose: 欠落属性の検出配線確認（detector有効性検証）
// Design: input.cue（Nix生成、1キー欠落）+ expected.cue（検出期待）
// Note: Uses 'integrationInput' to avoid CUE scope resolution issues

package integration_negative_02

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Detector invocation with malicious data (missing key injected)
_detector: detector.#ConsumerAPI & {
	input: integrationInput
}

// Verify report matches expected (detection = success)
_test: _detector.report & expected
