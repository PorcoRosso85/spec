package schema

// Naming convention patterns (SSOT)
// ✅ Bug 6対応: このファイルが唯一の正規表現パターン定義場所
#Patterns: {
	kebabCase: {
		pattern:     "^[a-z0-9]+(-[a-z0-9]+)*$"
		description: "Lowercase alphanumeric with hyphens"
		examples: ["my-feature", "user-auth", "api-v2"]
	}

	featureURN: {
		pattern:     "^urn:feat:[a-z0-9]+(-[a-z0-9]+)*$"
		description: "Feature URN format"
		examples: ["urn:feat:user-auth", "urn:feat:api-gateway"]
	}

	branchName: {
		pattern:     "^[a-z0-9-]+(\\+[a-z0-9-]+)?$"
		description: "Branch name with optional overlay"
		examples: ["main", "dev", "feat-auth+overlay"]
	}
}

// Apply patterns to schema fields
#KebabCaseName: string & =~#Patterns.kebabCase.pattern
#FeatureURN:    string & =~#Patterns.featureURN.pattern
#BranchName:    string & =~#Patterns.branchName.pattern
