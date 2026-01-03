// DoD3: Integration-Negative - テスト（異常系）
// Purpose: manifest vs self.spec の差分検出配線確認
// Design: input.cue（Nix生成、差分注入）+ expected.cue（検出期待）
// Note: Uses 'integrationInput' to avoid CUE scope resolution issues

package integration_negative_03

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Detector invocation with malicious data (diff injected)
_detector: detector.#OutputsManifest & {
	input: integrationInput
}

// Verify report matches expected (detection = success)
_test: _detector.report & expected
