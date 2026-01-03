package sandboxes

// Schema for sandbox repo.cue
// Only CI requiredChecks data is allowed
// Extra fields will FAIL (SRP enforcement)

Repo: {
	requiredChecks: [...string]
	// Note: no other fields allowed
}
