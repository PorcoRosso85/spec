// DoD1: 責務配分 - REDテスト
// Purpose: detector.Responsibility.report が expected と一致することを検証
// RED段階: detector.report が _|_ なので必ず失敗する

package red_01_responsibility

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Unify detector with input and expected
_test: detector.Responsibility & {
	input:  input
	report: expected
}
