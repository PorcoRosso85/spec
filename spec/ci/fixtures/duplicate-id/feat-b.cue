package fixtures

import "github.com/porcorosso85/spec-repo/spec/schema"

// Duplicate ID fixture: Same field name, different slug
// Expected: CUE unification conflict (same field, different values)

feature: schema.#Feature & {
	slug: "duplicate-b"  // ← Same field "feature", different slug → conflict
	artifact: repoEnabled: false
}
