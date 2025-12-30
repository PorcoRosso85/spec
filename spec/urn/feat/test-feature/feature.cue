package feat_test_feature

import "github.com/porcorosso85/spec-repo/spec/schema"

// Test feature for policy validation
feature: schema.#Feature & {
	slug: "test-feature"
	id:   "urn:feat:test-feature"
	artifact: {
		repoEnabled: false
	}
}
