// Package catalog defines validation rules for the slot catalog
package catalog

import "list"

// #ValidationRules defines CI checks for slot catalog integrity
#ValidationRules: {
	// Rule 1: Active slots must have an owner
	// Verified at slot level in schema.cue

	// Rule 2: Abstract slots must not appear in skeleton.json
	// Verified by CI script (check_skeleton_guard.sh)

	// Rule 3: dependsOn must reference valid slot IDs
	// Verified by CI (catalog-validate job)

	// Rule 4: Circular dependencies are prohibited
	// Verified by CI (catalog-validate job)

	// Rule 5: responsibility must be unique (DRY principle)
	// Warning only in Phase-0+1, enforced in Phase-3

	// Rule 6: Slot IDs must follow naming conventions
	// Verified by regex pattern in schema.cue
}

// Helper functions for validation (used by CI scripts)
#ValidateDependencies: {
	allSlots: {...}
	slot: #Slot

	// Check that all dependencies exist
	validDeps: [
		for dep in slot.dependsOn {
			if allSlots[dep] != _|_ {
				true
			}
			if allSlots[dep] == _|_ {
				false
			}
		}
	]

	valid: list.And(validDeps)
}
