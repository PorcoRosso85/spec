// DoD4: 重複なし - GREEN期待出力（RED期待と同じ）
// Purpose: 重複検出レポートの期待値

package green_04_uniq

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

expected: det.#UniqReport & {
	duplicateFeatIDs: ["urn:feat:duplicate-target"]
	duplicateSlugs:   ["duplicate-target"]
}
