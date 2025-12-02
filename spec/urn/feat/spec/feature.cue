package feat

import "spec/schema"

// spec: 仕様・URN・マッピング・CIルールの SSOT リポジトリ
// - urn:feat:spec
// - このリポジトリ自身
feature: schema.#Feature & {
	slug: "spec"
	// id: "urn:feat:spec" は自動導出される

	artifact: repoEnabled: true
}
