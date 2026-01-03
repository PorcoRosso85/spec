package sandboxes

# Closed schema for sandbox repo.cue
# - Only CI要件データ（requiredChecks）を許可
# - 余計なフィールドはFAIL（SRP強制）

Repo: {
	requiredChecks: [...string]
	# Closed: no other fields allowed
}
