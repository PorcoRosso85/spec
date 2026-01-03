package schema

// #Feature: 機能の型定義（1urn1feature1repo原則）
// - id: 機能URN（"urn:feat:" + slug の形式で自動導出）
// - slug: kebab-case の識別子（repo名と一致）
// - artifact.repoEnabled: repo を持つかどうかの bool
#Feature: {
	// slug（kebab-case、repo名と一致）
	slug: string
	slug: =~#Patterns.kebabCase.pattern

	// id は slug から自動導出（DRY保証）
	id: "urn:feat:\(slug)"

	// artifact: repo を持つかどうか（必須フィールド）
	artifact: {
		repoEnabled: bool
	}

	// deps: 依存する他の feature（オプション、循環依存検知用）
	deps?: [...string]

	// YAGNI: description, purpose, tags などは将来追加
}
