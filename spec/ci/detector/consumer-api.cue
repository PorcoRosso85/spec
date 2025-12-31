// Consumer API detector
// Purpose: Detect missing or extra attributes in consumer-facing API
// Design: Input-injection型 detector, RED段階では report: _|_ で必ず落ちる

package detector

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

ConsumerAPI: {
	input:  #ConsumerAPIInput
	report: _|_ // RED段階: 未実装（必ず落とす）
	// GREEN段階: 実装により差分検出ロジックを入れる
}
