package rules

import "github.porcorosso85/spec-repo/spec/schema"

// session.title の文法・逆引きロジックの契約定義
// - CUEだけで動的パースはしない（契約として定義）
// - 実際の検証はエージェント/CI側で実装
rules: schema.#SessionTitleRule & {
	// title の正規表現パターン
	// 文法: title = slug または slug + ": " + humanLabel
	pattern: "^([a-z0-9-]+)(:.*)?$"

	// slug 抽出ロジック（実装側への指示）
	// 実装側は ":" の前までを抽出すること
	// 例:
	//   - "decide-ci-score-matrix" → slug = "decide-ci-score-matrix"
	//   - "spec: add URN structure" → slug = "spec"
	extractSlug: "$1"
}

// 逆引きフロー（実装側が従うべき仕様）:
// 1. session.title から slug を抽出（":" の前まで）
// 2. slug → "urn:feat:" + slug で機能URNを構築
// 3. adapter/git/repo で機能URN → forge/org/repo を引く
// 4. この定義に従わない title は「URN管理外」として扱う
