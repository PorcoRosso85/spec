// docs/phase7/compatibility.cue
// Phase 7 互換ルール（CUEが正本、MDはポインタ）

package phase7

compatibility: {
	summary: "Phase7 配信物の互換ルール"

	// このルールが対象とするもの
	scope: [
		"配信物フォーマット（JSON schema）",
		"sha256算出対象（JSONファイル全体）",
	]

	// 互換な変更（後方互換性を維持）
	rules: {
		compatible: [
			"任意フィールドの追加（既存フィールドの意味は不変）",
			"フィールドの順序変更（JSONは順序非依存）",
			"ドキュメント/コメントの追加・更新",
		]

		// 破壊的変更（後方互換性を壊す）
		breaking: [
			"必須フィールドの削除",
			"フィールド名の変更（rename）",
			"フィールドの型変更",
			"意味論の変更（同じキーで異なる意味になる）",
			"sha256算出対象の変更",
		]
	}

	// バージョニング方針
	versioning: {
		tagPattern: "phase7-*"
		breakingPolicy: "破壊的変更は新タグで明示。旧タグは不変。"
	}
}
