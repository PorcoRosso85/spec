package branch

import "github.porcorosso85/spec-repo/spec/schema"

// 機能URN ↔ branch 名規則のマッピング
// - branch 名の文法: slug または slug + "+" + variant
// - required:true なのに Git 上に無い場合は CI で WARN
// - ここに出てこない branch は「野良」として管理対象外
branches: [...schema.#BranchMapping]
branches: [
	{
		internal: "urn:feat:decide-ci-score-matrix"
		name:     "decide-ci-score-matrix" // main 相当
		required: true
	},
	{
		internal: "urn:feat:spec"
		name:     "spec" // main 相当
		required: true
	},
]

// 将来の拡張例（variant付き）:
// {
//     internal: "urn:feat:spec"
//     name:     "spec+experimental"
//     required: false
// }
