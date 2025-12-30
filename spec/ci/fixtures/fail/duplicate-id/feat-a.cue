package fixtures

import "github.com/porcorosso85/spec-repo/spec/schema"

// Duplicate ID fixture: Same field name
// Expected: CUE unification conflict

feature: schema.#Feature & {
	slug: "duplicate-a"
	artifact: repoEnabled: false
}
