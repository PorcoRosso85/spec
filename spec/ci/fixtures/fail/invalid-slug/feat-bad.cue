package fixtures

import "github.com/porcorosso85/spec-repo/spec/schema"

// Invalid slug fixture: NOT kebab-case
// Expected: cue vet should FAIL (slug constraint violation)

feat_bad: schema.#Feature & {
	slug: "Bad_Slug"  // ← NOT kebab-case (contains underscore + capital)
	artifact: repoEnabled: false
}
