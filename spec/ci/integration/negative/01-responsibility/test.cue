// DoD1: Integration-Negative - テスト（異常系）
// Purpose: 禁止責務の注入が検出されることを確認
// Design: input.cue（contractOverride注入）+ expected.cue（violation検出期待）
// Note: Uses 'integrationInput' to avoid CUE scope resolution issues

package integration_negative_01

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Detector invocation with malicious feat data
_detector: detector.#Responsibility & {
	input: integrationInput
}

// Verify violation is detected
_test: _detector.report & expected
