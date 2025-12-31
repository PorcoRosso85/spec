// DoD4: Integration-Verify - テスト（正常系）
// Purpose: 実データ接続の配線確認 + spec-repo実体のクリーンさ検証
// Design: input.cue（Nix生成の実データ）+ expected.cue（空リスト期待）

package integration_verify_04

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Detector invocation with real data
_detector: detector.#Uniq & {
	input: input
}

// Verify report matches expected (clean state)
_test: _detector.report & expected
