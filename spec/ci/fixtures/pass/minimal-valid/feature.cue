package fixtures

import "github.com/porcorosso85/spec-repo/spec/schema"

// Minimal valid feature fixture
// - Satisfies all contract constraints (naming, uniq, refs)
// - Satisfies all checks constraints (dry, 1urn1repo, etc.)
// - Minimal required fields only (YAGNI)

feature: schema.#Feature & {
	slug: "minimal-valid"
	id:   "urn:feat:minimal-valid"
	artifact: {
		repoEnabled: false // 最小構成: repoなし
	}
	// deps省略可能
}
