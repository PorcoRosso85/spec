// DoD4: Integration-Verify - 期待出力（正常系）
// Purpose: 実データ（spec/urn/feat/*）がクリーンであることを確認
// Design: spec-repoに重複がない場合、空リストが返される

package integration_verify_04

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

// Expected report: NO duplicates (clean state)
expected: det.#UniqReport & {
	duplicateFeatIDs: [] // Empty = no duplicate IDs
	duplicateSlugs:   [] // Empty = no duplicate slugs
}
