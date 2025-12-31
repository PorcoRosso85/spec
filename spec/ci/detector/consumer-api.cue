// Consumer API detector
// Purpose: Detect missing or extra attributes in consumer-facing API
// Design: Input-injection型 detector, RED段階では report: _|_ で必ず落ちる

package detector

import "list"

// SSOT: Consumer API Minimum Keys
// These are the minimum attributes that spec-repo MUST provide to consumers
// Source: Unit test specification (spec/ci/tdd/green/02-consumer-api/input.cue)
// Note: Integration tests MUST use this SSOT to avoid spec drift
#ConsumerAPIMinimumKeys: [
	"spec.cuePath",
	"spec.schemaPath",
	"spec.urn.featPath",
	"spec.urn.envPath",
	"spec.outputsManifestPath",
	"spec.version",
]

#ConsumerAPIInput: {
	// Required minimum API attributes
	required: [...string]
	
	// Actual provided attributes
	actual: [...string]
}

#ConsumerAPIReport: {
	missingAttributes: [...string] // Required but not provided
	extraAttributes:   [...string] // Provided but not required (warning)
}

#ConsumerAPI: {
	input!:  #ConsumerAPIInput
	report: #ConsumerAPIReport & {
		// Missing attributes: required but not in actual
		missingAttributes: [
			for attr in input.required
			if !list.Contains(input.actual, attr) {
				attr
			},
		]
		
		// Extra attributes: in actual but not in required
		extraAttributes: [
			for attr in input.actual
			if !list.Contains(input.required, attr) {
				attr
			},
		]
	}
}

// Backward compatibility alias
ConsumerAPI: #ConsumerAPI
