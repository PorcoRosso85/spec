package contract

// Reference integrity SSOT
// Defines what constitutes valid/broken references

#ReferenceCheck: {
	// Reference pattern: urn:feat:<slug>
	// Engine responsibility: Extract all urn:feat:* references and verify
	// they point to existing feature definitions
	
	validFeatURNPattern: "^urn:feat:[a-z0-9]+(-[a-z0-9]+)*$"
	
	// Paths to scan for references
	scanPaths: [
		"spec/adapter/...",
		"spec/mapping/...",
	]
	
	// Reference source: spec/urn/feat/*/feature.cue
	featDefinitionPath: "spec/urn/feat"
}

#CircularDependencyCheck: {
	// Dependency field: feature.deps (list of URNs)
	// Engine responsibility: Build dependency graph and detect cycles using DFS
	
	dependencyField: "deps"
	
	// Source of dependency data
	featDefinitionPath: "spec/urn/feat"
}
