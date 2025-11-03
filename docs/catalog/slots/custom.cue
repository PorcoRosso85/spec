// Package slots defines custom internal responsibility slots
package slots

import "../schema"

// Custom responsibilities specific to this project
slots: {
	"custom.repo-structure-guard": schema.#Slot & {
		id:             "custom.repo-structure-guard"
		responsibility: "Enforce repository structure integrity through automated CI validation of catalog, ADR, and skeleton alignment"
		status:         "abstract"
		tier:           "infra"
		dependsOn: []
		standardRef: []
		notes: "This is the meta-responsibility that implements the 3-SSOT guard system itself"
	}
}
