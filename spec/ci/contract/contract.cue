package contract

import "github.com/porcorosso85/spec-repo/spec/schema"

// Contract SSOT - Single source of truth for spec-repo validation
// NO MD CONTRACTS: All rules defined in CUE only

// Scope Definition (目的/非目的の固定)
//
// 目的（spec-repo完成要件に含む）:
//   - Naming: kebab-case slug, URN format validation
//   - Uniqueness: ID uniqueness (structural via CUE imports)
//   - Boundary: Directory responsibility (future)
//
// 非目的（spec-repo完成要件に含めない）:
//   - 参照先存在確認 (文字列参照のため静的検証不可・P2で対応)
//   - 循環依存検出 (CUE型システムの制約・外部validator必要)
//
// refs.cueの責務 (明確化):
//   ✅ 目的: URN参照の**形状**検証のみ（regex pattern）
//   ❌ 非目的: 参照整合性検証（存在確認・循環検出）
//
// Future (P2):
//   - 構造参照化: kind: "atomic" | "composite" で型安全に
//   - 参照整合性検証が可能になる（構造参照なら存在確認できる）
//   - 循環検出は外部validator（DFS）またはCUE list comprehension

// Contract definition
#Contract: {
	// Naming rules (kebab-case, URN format)
	naming: {
		slugPattern: string
		urnPattern:  string
	}
	
	// Uniqueness rules (no duplicate IDs)
	uniqueness: #UniquenessCheck
	
	// Reference integrity (specification only, not enforced by CUE vet)
	references: #ReferenceCheck
	circular:   #CircularDependencyCheck
}

// Export for engine consumption
contract: #Contract & {
	naming: {
		slugPattern: schema.#Patterns.kebabCase.pattern
		urnPattern:  schema.#Patterns.featureURN.pattern
	}
}
