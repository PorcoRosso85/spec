package feat_dup_1

import "github.com/porcorosso85/spec-repo/spec/schema"

// Duplicate feat-id fixture 1
// Expected: global-uniq check should detect duplicate slug (which generates duplicate ID)

feature: schema.#Feature & {
	slug: "duplicate-target"  // ← Same slug generates same ID
	artifact: {
		repoEnabled: false
	}
}
