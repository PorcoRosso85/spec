package sandboxes

# Closed schema for sandbox repo.cue
# Only CI requiredChecks data is allowed
# Extra fields will FAIL (SRP enforcement)

Repo: {
	requiredChecks: [...string]
	# Closed: no other fields allowed
}
