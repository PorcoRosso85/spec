package contract

// Uniqueness constraints SSOT
// Enforced by CUE unification (definitions will conflict if duplicated)

// Feature ID uniqueness: Each feat-id MUST appear exactly once
// Implementation: CUE evaluation will fail if same id appears in multiple files
// Engine responsibility: Collect all feature IDs and detect duplicates

#UniquenessCheck: {
	// This is a marker for the engine to perform deduplication check
	// CUE itself enforces uniqueness within a single unified tree,
	// but cross-file detection requires engine support
	checkDuplicateFeatIDs: true
	checkDuplicateEnvIDs:  true
}
