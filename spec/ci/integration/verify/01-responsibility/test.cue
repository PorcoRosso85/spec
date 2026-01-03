// DoD1: Integration-Verify - テスト（正常系）
// Purpose: 実featに禁止責務がないことを確認
// Design: input.cue（Nix生成の実データ）+ expected.cue（violations空期待）
// Note: Uses 'integrationInput' to avoid CUE scope resolution issues

package integration_verify_01

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Detector invocation with real feat data
_detector: detector.#Responsibility & {
	input: integrationInput
}

// Verify report matches expected (clean state)
_test: _detector.report & expected
