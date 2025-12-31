// Outputs Manifest detector
// Purpose: Detect mismatches between declared manifest and actual flake outputs
// Design: Input-injection型 detector, RED段階では report: _|_ で必ず落ちる

package detector

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

OutputsManifest: {
	input:  #OutputsManifestInput
	report: _|_ // RED段階: 未実装（必ず落とす）
	// GREEN段階: 実装により差分検出ロジックを入れる
}
