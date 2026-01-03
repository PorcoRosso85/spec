package feat_dup_2

import "github.com/porcorosso85/spec-repo/spec/schema"

// Duplicate feat-id fixture 2
// Expected: global-uniq check should detect duplicate slug (which generates duplicate ID)

feature: schema.#Feature & {
	slug: "duplicate-target"  // ← Same slug as feat-dup-1
	artifact: {
		repoEnabled: false
	}
}
