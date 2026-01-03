package schema

// #RepoMapping: 機能URN ↔ Git repo の1:1マッピング型
// - 1urn1feature1repo 原則を保証
#RepoMapping: {
	// 内部機能URN（"urn:feat:..."）
	internal: string
	internal: =~#Patterns.featureURN.pattern

	// Git forge（github.com, codeberg.org 等）
	forge: string
	forge: "github.com" | "codeberg.org" | string

	// Organization/User名
	org: string

	// Repository名（slug と一致すること）
	repo: string
	repo: =~#Patterns.kebabCase.pattern
}

// #BranchMapping: 機能URN ↔ branch 名規則のマッピング型
// - required:true なのに Git に無い場合は CI で WARN
#BranchMapping: {
	// 内部機能URN（"urn:feat:..."）
	internal: string
	internal: =~#Patterns.featureURN.pattern

	// Branch名（slug または slug + "+" + variant）
	name: string
	name: =~#Patterns.branchName.pattern

	// この branch が必須かどうか
	required: bool
}
