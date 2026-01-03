// Outputs Manifest - spec-repo outputs catalog (SSOT)
// Purpose: Define all published outputs that consumers can reference
//
// Responsibility separation:
//   DoD2: Validates existence of this file path (self.spec.outputsManifestPath)
//   DoD3: Validates content consistency (manifest SSOT vs self.spec actual)
//
// DoD3 validation strategy:
//   - SSOT: This manifest defines expected public API
//   - Actual: self.spec (Nix-published API)
//   - Detector: Reports missing/unexpected outputs + version mismatch

package spec

// Manifest schema (SSOT for spec-repo public API)
manifest: {
	// Version: Must match self.spec.version
	version: string

	// Outputs: List of public output paths (dot notation)
	// Note: These are the keys consumers can rely on
	outputs: {
		paths: [...string]
	}
}

// Current manifest definition (P0: minimum required outputs)
// Note: Paths use "spec." prefix to match self.spec key structure
manifest: {
	version: "0.1.0" // TODO: Sync with actual version management

	outputs: {
		paths: [
			"spec.cuePath",
			"spec.schemaPath",
			"spec.urn.featPath",
			"spec.urn.envPath",
			"spec.adapter.gitRepoPath",
			"spec.adapter.gitBranchPath",
			"spec.adapter.sessionRulesPath",
			"spec.mappingPath",
			"spec.externalStdPath",
			"spec.ciChecksPath",
			"spec.outputsManifestPath",
			"spec.version",
		]
	}
}
