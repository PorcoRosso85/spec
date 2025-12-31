// DoD3: outputs明確 - GREEN期待出力
// Purpose: 不一致検出レポートの期待値を定義

package green_03_outputs_manifest

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

expected: det.#OutputsManifestReport & {
	missingPaths:    [] // manifestにあってactualにないパス
	unexpectedPaths: ["spec.undeclaredPath"] // actualにあってmanifestにないパス
	versionMismatch: false
}
