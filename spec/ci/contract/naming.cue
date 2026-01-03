package contract

import "github.com/porcorosso85/spec-repo/spec/schema"

// Naming convention SSOT
// All slug fields MUST match kebab-case pattern

// Kebab-case pattern: lowercase letters, digits, and hyphens
#KebabCasePattern: =~schema.#Patterns.kebabCase.pattern

// Feature slug constraint
#FeatureSlug: string & #KebabCasePattern

// URN format (DRY: id derived from slug)
#FeatureURN: =~schema.#Patterns.featureURN.pattern

// Validation: feature slug and id consistency
#Feature: {
	slug: #FeatureSlug
	id:   #FeatureURN
	// Note: id construction "urn:feat:\(slug)" is enforced in schema/feature.cue
}
