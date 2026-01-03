// DoD2: Integration-Verify - テスト（正常系）
// Purpose: 実データ接続の配線確認 + spec-repo実体のクリーンさ検証
// Design: input.cue（Nix生成の実データ）+ expected.cue（空リスト期待）
// Note: Uses 'integrationInput' to avoid CUE scope resolution issues

package integration_verify_02

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Detector invocation with real data (renamed to avoid scope issues)
_detector: detector.#ConsumerAPI & {
	input: integrationInput
}

// Verify report matches expected (clean state)
_test: _detector.report & expected
