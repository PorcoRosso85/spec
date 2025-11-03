// Package catalog aggregates all slot definitions
// This is the single source of truth (SSOT) for all responsibility slots
package catalog

import (
	"./slots"
)

// All available slots in the system
// This map is the authoritative source for slot definitions
allSlots: slots.slots

// Metadata
_meta: {
	version:     "0.1.0"
	description: "Slot catalog for 3-SSOT guard system - Phase 0+1 minimal set"
	lastUpdated: "2025-11-03"
}
