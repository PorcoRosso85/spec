// DoD3: outputs明確 - REDテスト
// Purpose: detector.OutputsManifest.report が expected と一致することを検証
// RED段階: detector.report が _|_ なので必ず失敗する

package red_03_outputs_manifest

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Unify detector with input and expected
_test: detector.OutputsManifest & {
	input:  input
	report: expected
}
