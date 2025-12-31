// Responsibility detector
// Purpose: Detect forbidden responsibilities in feat definitions
// Design: Input-injection型 detector, RED段階では report: _|_ で必ず落ちる

package detector

#ResponsibilityInput: {
	// Feat definition to validate
	feat: {
		id:   string
		slug: string
		
		// Optional repository configuration
		repo?: {
			enabled: bool
			if enabled {
				path: string // Required when enabled
			}
		}
		
		// Forbidden responsibilities (should not exist)
		contractOverride?: _   // Feat must not redefine contracts
		schemaOverride?:   _   // Feat must not inject custom schemas
		exportOverride?:   _   // Feat must not override exports
	}
}

#ResponsibilityReport: {
	violations: [...{
		category: "contract-override" | "schema-override" | "export-override" | "required-field-missing"
		field:    string
		message:  string
	}]
}

Responsibility: {
	input:  #ResponsibilityInput
	report: _|_ // RED段階: 未実装（必ず落とす）
	// GREEN段階: 実装により禁止責務検出ロジックを入れる
}
