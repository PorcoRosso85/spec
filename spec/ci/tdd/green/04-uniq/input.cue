// DoD4: 重複なし - GREEN入力（RED入力と同じ）
// Purpose: 重複を含むfeatリスト

package green_04_uniq

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

input: det.#UniqInput & {
	feats: [
		{id: "urn:feat:duplicate-target", slug: "duplicate-target"},
		{id: "urn:feat:duplicate-target", slug: "duplicate-target"},
	]
}
