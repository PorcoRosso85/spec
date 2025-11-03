// Package catalog defines all concrete slot instances
package catalog

// All available slots in the system
slots: {
	// NIST 800-53 slots
	"nist80053.AC-access-control": #Slot & {
		id:             "nist80053.AC-access-control"
		responsibility: "Enforce authorization policies to control who can access what resources in the system"
		status:         "abstract"
		tier:           "infra"
		dependsOn: []
		standardRef: ["NIST SP 800-53 Rev 5 AC-1"]
		notes: "Initially abstract - will be activated via ADR when access control implementation begins"
	}

	"nist80053.AU-audit-accountability": #Slot & {
		id:             "nist80053.AU-audit-accountability"
		responsibility: "Create, protect, and maintain audit records to enable monitoring, analysis, investigation, and reporting of security events"
		status:         "abstract"
		tier:           "infra"
		dependsOn: []
		standardRef: ["NIST SP 800-53 Rev 5 AU-1"]
		notes: "Initially abstract - audit logging implementation pending"
	}

	// Custom slots
	"custom.repo-structure-guard": #Slot & {
		id:             "custom.repo-structure-guard"
		responsibility: "Enforce repository structure integrity through automated CI validation of catalog, ADR, and skeleton alignment"
		status:         "abstract"
		tier:           "infra"
		dependsOn: []
		standardRef: []
		notes: "This is the meta-responsibility that implements the 3-SSOT guard system itself"
	}
}
