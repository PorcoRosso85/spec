package contract

// Contract SSOT - Aggregates all validation rules
// This is the single source of truth for spec-repo validation logic

// All contract rules are defined in this package
// (naming.cue, uniq.cue, refs.cue are in same package)

// Contract definition
#Contract: {
	// Naming rules (kebab-case, URN format)
	naming: #Feature
	
	// Uniqueness rules (no duplicate IDs)
	uniqueness: #UniquenessCheck
	
	// Reference integrity (no broken refs, no cycles)
	references: #ReferenceCheck
	circular:   #CircularDependencyCheck
}

// Export for engine consumption
contract: #Contract
