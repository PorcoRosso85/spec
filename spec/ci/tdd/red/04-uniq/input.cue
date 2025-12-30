// DoD4: 重複なし - RED入力（重複を含むfixture）
// Purpose: 同一ID/slugを持つfeat参照を入力として与える

package red_04_uniq

import det "github.com/porcorosso85/spec-repo/spec/ci/detector"

input: det.#UniqInput & {
	feats: [
		{id: "urn:feat:duplicate-target", slug: "duplicate-target"},
		{id: "urn:feat:duplicate-target", slug: "duplicate-target"},
	]
}
