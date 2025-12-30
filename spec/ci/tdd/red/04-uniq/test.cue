// DoD4: 重複なし - REDテスト
// Purpose: detector.Uniq.report が expected と一致することを検証
// RED段階: detector.report が _|_ なので必ず失敗する

package red_04_uniq

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Unify detector with input and expected
_test: detector.Uniq & {
	input:  input,
	report: expected,
}
