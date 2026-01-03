// DoD4: 重複なし - RED期待出力
// Purpose: 重複検出レポートの期待値を定義

package red_04_uniq

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

expected: det.#UniqReport & {
	duplicateFeatIDs: ["urn:feat:duplicate-target"]
	duplicateSlugs:   ["duplicate-target"]
}
