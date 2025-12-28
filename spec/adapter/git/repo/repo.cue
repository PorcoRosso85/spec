package repo

import "github.com/porcorosso85/spec-repo/spec/schema"

// 機能URN ↔ Git repo の1:1マッピング
// - 1urn1feature1repo 原則を保証
// - ここに出てこない repo は「野良」として管理対象外
repos: [...schema.#RepoMapping]
repos: [
	{
		internal: "urn:feat:decide-ci-score-matrix"
		forge:    "github.com"
		org:      "porcorosso85"
		repo:     "decide-ci-score-matrix"
	},
	{
		internal: "urn:feat:spec"
		forge:    "github.com"
		org:      "porcorosso85"
		repo:     "spec"
	},
]
