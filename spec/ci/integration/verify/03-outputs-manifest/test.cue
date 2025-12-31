// DoD3: Integration-Verify - テスト（正常系）
// Purpose: manifest.cue (SSOT) と self.spec (公開API) の一致検証
// Design: input.cue（Nix生成の実データ）+ expected.cue（一致期待）
// Note: Uses 'integrationInput' to avoid CUE scope resolution issues

package integration_verify_03

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Detector invocation with real data (renamed to avoid scope issues)
_detector: detector.#OutputsManifest & {
	input: integrationInput
}

// Verify report matches expected (clean state)
_test: _detector.report & expected
