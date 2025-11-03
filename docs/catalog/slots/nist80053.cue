// Package slots defines NIST SP 800-53 security control slots
package slots

import "../schema"

// NIST 800-53 Access Control family
slots: {
	"nist80053.AC-access-control": schema.#Slot & {
		id:             "nist80053.AC-access-control"
		responsibility: "Enforce authorization policies to control who can access what resources in the system"
		status:         "abstract"
		tier:           "infra"
		dependsOn: []
		standardRef: ["NIST SP 800-53 Rev 5 AC-1"]
		notes: "Initially abstract - will be activated via ADR when access control implementation begins"
	}

	"nist80053.AU-audit-accountability": schema.#Slot & {
		id:             "nist80053.AU-audit-accountability"
		responsibility: "Create, protect, and maintain audit records to enable monitoring, analysis, investigation, and reporting of security events"
		status:         "abstract"
		tier:           "infra"
		dependsOn: []
		standardRef: ["NIST SP 800-53 Rev 5 AU-1"]
		notes: "Initially abstract - audit logging implementation pending"
	}
}
