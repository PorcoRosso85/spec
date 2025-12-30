package contract

// Naming convention SSOT
// All slug fields MUST match kebab-case pattern

// Kebab-case pattern: lowercase letters, digits, and hyphens
#KebabCasePattern: =~"^[a-z0-9]+(-[a-z0-9]+)*$"

// Feature slug constraint
#FeatureSlug: string & #KebabCasePattern

// URN format (DRY: id derived from slug)
#FeatureURN: =~"^urn:feat:[a-z0-9]+(-[a-z0-9]+)*$"

// Validation: feature slug and id consistency
#Feature: {
	slug: #FeatureSlug
	id:   #FeatureURN
	// Note: id construction "urn:feat:\(slug)" is enforced in schema/feature.cue
}
