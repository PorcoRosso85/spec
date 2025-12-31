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

#Responsibility: {
	input!:  #ResponsibilityInput
	report: #ResponsibilityReport & {
		violations: [
			// Check for contract override
			if (input.feat.contractOverride & {}) != _|_ {
				{
					category: "contract-override"
					field:    "contractOverride"
					message:  "Feat must not redefine contracts"
				}
			},
			// Check for schema override
			if (input.feat.schemaOverride & {}) != _|_ {
				{
					category: "schema-override"
					field:    "schemaOverride"
					message:  "Feat must not inject custom schemas"
				}
			},
			// Check for export override
			if (input.feat.exportOverride & {}) != _|_ {
				{
					category: "export-override"
					field:    "exportOverride"
					message:  "Feat must not override exports"
				}
			},
		]
	}
}

// Backward compatibility alias
Responsibility: #Responsibility
