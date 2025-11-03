// ADR-0001: Activate repo-structure-guard for 3-SSOT enforcement
package adr

adr0001: {
	id:     "0001"
	title:  "Activate repo-structure-guard for 3-SSOT enforcement"
	status: "accepted"
	date:   "2025-11-03"
	scope:  "repo structure and CI validation"

	// Background: Why this decision is needed
	background: """
		Development proceeds with 1 person + AI.
		When improvements or new features are added directly to code without clear responsibility boundaries,
		the system grows in an uncontrolled manner with unclear ownership.
		Once boundaries blur, it becomes nearly impossible to restore them because the line between
		"who is responsible for what" disappears, and future self cannot re-separate them.

		The worst pattern is: "only I can break production, but even I don't know which part breaks what."
		This becomes a revenue-stopping risk.

		This ADR prevents that collapse structurally.
		"""

	// Decision: What we are doing
	decision: """
		This repository maintains three separate sources of truth (3-SSOT) and never mixes them:

		1. Catalog (docs/catalog/**):
		   The complete set of possible responsibility slots.
		   Each slot has a stable ID, single responsibility, single owner, and dependencies.
		   If a slot doesn't exist in the catalog, it's considered invalid.

		2. ADR (docs/adr/**):
		   Time-series log of which slots to use, where to place them, and why.
		   Without an ADR, a slot cannot be adopted into production.

		3. Skeleton (docs/structure/.gen/skeleton.json):
		   Snapshot of the current configuration showing which slot.id maps to which directory/service/layer.
		   Any PR attempting to add new paths outside skeleton.json is rejected by CI.

		This 3-SSOT system is itself a responsibility, so we activate the slot:
		  custom.repo-structure-guard

		This slot will be placed in CI validation (not in app/domain/infra code).
		"""

	// Effects: What this enables
	effects: [
		"Free to add features, but uncontrolled growth is physically prevented",
		"Current correct state and rationale are instantly explainable",
		"Future self and AI can safely work within boundaries",
		"Compliance and audit responses are generated automatically from traceability.json",
	]

	// Slot activations
	activations: [{
		slotId:    "custom.repo-structure-guard"
		owner:     "PorcoRosso85"
		placement: ".github/workflows/repo-guard.yml"
		rationale: "CI enforcement is the appropriate layer for structural validation"
	}]

	// References
	references: [
		"docs/structure/structure-1人AI体制で壊さず拡張し続ける2.md",
		"docs/adr/adr-1人AI体制で壊さず拡張し続ける2.md",
	]
}
