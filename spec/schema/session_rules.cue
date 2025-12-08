package schema

// #SessionTitleRule: session.title の文法・逆引きロジックの契約定義
// - session.title から slug を抽出し、URN → repo へ逆引きする仕様
// - CUEだけで動的パースはしない（契約として定義）
// - 実際の検証はエージェント/CI側で実装
#SessionTitleRule: {
	// title の正規表現パターン
	// 文法: title = slug または slug + ": " + humanLabel
	pattern: string

	// slug 抽出ロジック（実装側への指示）
	// 実装側は ":" の前までを抽出すること
	extractSlug: string
}
