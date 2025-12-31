// DoD2: consumer API - REDテスト
// Purpose: detector.ConsumerAPI.report が expected と一致することを検証
// RED段階: detector.report が _|_ なので必ず失敗する

package red_02_consumer_api

import "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Unify detector with input and expected
_test: detector.ConsumerAPI & {
	input:  input
	report: expected
}
