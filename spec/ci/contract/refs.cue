package contract

// Reference Shape SSOT (形状のみ)
//
// Scope:
//   ✅ 目的: URN参照の**形状**検証（文字列パターン）
//   ❌ 非目的: 参照先の存在確認（文字列参照の制約）
//
// Rationale:
//   - CUE vet は文字列URN参照の整合性を検証できない
//   - 参照整合性検証は構造参照化（P2）後に実現可能
//   - 現時点では形状（regex）のみを仕様として定義
//
// Future (P2):
//   - 構造参照化: kind: "atomic" | "composite" で型安全に
//   - その時点で参照整合性検証が可能になる

#ReferenceCheck: {
	// Reference pattern: urn:feat:<slug>
	// 形状のみを検証（存在確認はP2）
	
	validFeatURNPattern: "^urn:feat:[a-z0-9]+(-[a-z0-9]+)*$"
	
	// Paths to scan for references (将来のvalidator用メタ情報)
	scanPaths: [
		"spec/adapter/...",
		"spec/mapping/...",
	]
	
	// Reference source (将来のvalidator用メタ情報)
	featDefinitionPath: "spec/urn/feat"
}

#CircularDependencyCheck: {
	// Dependency field: feature.deps (list of URNs)
	//
	// Scope:
	//   ❌ 非目的: 循環依存検出（CUE型システムの制約）
	//   ✅ 目的: deps配列の**形状**定義（将来のvalidator用）
	//
	// Rationale:
	//   - CUEはdepsフィールドの循環を検出しない
	//   - 循環検出は外部validator（DFS実装）が必要
	//   - この定義は将来validator向けのメタ情報
	
	dependencyField: "deps"
	
	// Source of dependency data (validator用メタ情報)
	featDefinitionPath: "spec/urn/feat"
}
