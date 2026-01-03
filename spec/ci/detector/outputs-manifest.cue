// Outputs Manifest detector
// Purpose: Detect mismatches between declared manifest and actual flake outputs
// Design: Input-injection型 detector, RED段階では report: _|_ で必ず落ちる

package detector

import "list"

#OutputsManifestInput: {
	// Expected outputs structure (from manifest.cue)
	expected: {
		paths: [...string]
		version: string
	}
	
	// Actual outputs structure (from flake evaluation)
	actual: {
		paths: [...string]
		version: string
	}
}

#OutputsManifestReport: {
	missingPaths:    [...string] // In manifest but not in actual
	unexpectedPaths: [...string] // In actual but not in manifest
	versionMismatch: bool
}

#OutputsManifest: {
	input!:  #OutputsManifestInput
	report: #OutputsManifestReport & {
		// Missing paths: in expected but not in actual
		missingPaths: [
			for path in input.expected.paths
			if !list.Contains(input.actual.paths, path) {
				path
			},
		]
		
		// Unexpected paths: in actual but not in expected
		unexpectedPaths: [
			for path in input.actual.paths
			if !list.Contains(input.expected.paths, path) {
				path
			},
		]
		
		// Version mismatch
		versionMismatch: input.expected.version != input.actual.version
	}
}

// Backward compatibility alias
OutputsManifest: #OutputsManifest
