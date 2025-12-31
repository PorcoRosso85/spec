// DoD2: consumer API - RED期待出力
// Purpose: 不足/過剰属性検出レポートの期待値を定義

package red_02_consumer_api

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

expected: det.#ConsumerAPIReport & {
	missingAttributes: ["spec.urn.envPath"] // 必須だが提供されていない
	extraAttributes:   ["spec.extraAttribute"] // 必須でないが提供されている
}
