package contract

// Contract SSOT - Single source of truth for spec-repo validation
// NO MD CONTRACTS: All rules defined in CUE only

// Scope Definition (目的/非目的の固定)
//
// 目的（spec-repo完成要件に含む）:
//   - Naming: kebab-case slug, URN format validation
//   - Uniqueness: ID uniqueness (structural via CUE imports)
//   - Boundary: Directory responsibility (future)
//
// 非目的（spec-repo完成要件に含めない）:
//   - Circular dependency detection (CUE type system limitation)
//   - Broken reference detection (string reference validation limitation)
//   - These require external tooling reading CUE contract
//
// Current Limitations (実装注記):
//   - Circular deps: CUE does not detect cycles in deps field
//   - Broken refs: CUE vet does not validate string URN references
//   - Future: External validator OR CUE structural constraints (kind: atomic/composite)

// Contract definition
#Contract: {
	// Naming rules (kebab-case, URN format)
	naming: {
		slugPattern: string
		urnPattern:  string
	}
	
	// Uniqueness rules (no duplicate IDs)
	uniqueness: #UniquenessCheck
	
	// Reference integrity (specification only, not enforced by CUE vet)
	references: #ReferenceCheck
	circular:   #CircularDependencyCheck
}

// Export for engine consumption
contract: #Contract & {
	naming: {
		slugPattern: "^[a-z0-9]+(-[a-z0-9]+)*$"
		urnPattern:  "^urn:feat:[a-z0-9]+(-[a-z0-9]+)*$"
	}
}
