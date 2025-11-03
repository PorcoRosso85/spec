// Package schema defines the core slot type for responsibility allocation
package schema

// #Slot represents a single responsibility unit in the system
// Each slot has a unique ID, clear responsibility, and ownership
#Slot: {
	// Unique identifier following <source>.<duty[.sub...]> pattern
	// Examples: "nist80053.AC-access-control", "sre.slo-definition"
	id: string & =~"^[a-z0-9]+\\.[a-zA-Z0-9_-]+(\\.[a-zA-Z0-9_-]+)*$"

	// Single-sentence responsibility description (SRP - Single Responsibility Principle)
	// Must be clear, actionable, and describe what this slot is responsible for
	responsibility: string & !=""

	// Single owner responsible for this slot
	// Required when status is "active"
	owner?: string

	// Current lifecycle status of this slot
	status: "abstract" | "active" | "deprecated"

	// Tier classification for organizational purposes
	tier: "business" | "app" | "infra"

	// List of other slot IDs that this slot depends on
	// Circular dependencies are prohibited by CI validation
	dependsOn: [...string]

	// References to external standards or frameworks
	// Examples: ["NIST 800-53 AC-1", "ISO 27001 A.9.1"]
	standardRef: [...string]

	// Additional notes or context (optional)
	notes?: string

	// Validation: active slots must have an owner
	if status == "active" {
		owner: string & !=""
	}
}
