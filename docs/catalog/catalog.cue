// Package catalog aggregates all slot definitions
// This is the single source of truth (SSOT) for all responsibility slots
package catalog

// All available slots in the system (reference to slots defined in slots.cue)
// This map is the authoritative source for slot definitions
allSlots: slots

// Metadata
_meta: {
	version:     "0.1.0"
	description: "Slot catalog for 3-SSOT guard system - Phase 0+1 minimal set"
	lastUpdated: "2025-11-03"
}
