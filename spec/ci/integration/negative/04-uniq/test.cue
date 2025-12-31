// DoD4: Integration-Negative - テスト（悪性検出）
// Purpose: 配線の実効性確認（実データを見ているか）+ detector契約の検証
// Design: input.cue（Nix生成: 実データ + 重複1件）+ expected.cue（具体的な検出期待）
// Note: Uses 'integrationInput' to avoid scope issues

package integration_negative_04

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Detector invocation with malicious data (renamed to avoid scope issues)
_detector: detector.#Uniq & {
	input: integrationInput
}

// Verify report matches expected (specific duplicate detected)
_test: _detector.report & expected
