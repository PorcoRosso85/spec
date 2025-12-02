package schema

// #CiCheck: CI検査ルールの型定義（将来用）
// - 現時点では ci/checks/ 以下で CUE 制約を直接記述
// - 将来的に検査ルール自体をデータとして管理する場合に使用
#CiCheck: {
	// 検査ID
	id: string

	// 検査名
	name: string

	// 検査の説明
	description: string

	// YAGNI: severity, enabled などは将来追加
}
