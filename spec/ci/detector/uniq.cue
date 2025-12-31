// Uniqueness detector
// Purpose: Detect duplicate feat IDs and slugs across all features
// Design: Input-injection型 detector, RED段階では report: _|_ で必ず落ちる

package detector

#FeatRef: {
	id:   string
	slug: string
}

#UniqInput: {
	feats: [...#FeatRef]
}

#UniqReport: {
	duplicateFeatIDs: [...string]
	duplicateSlugs:   [...string]
}

// Uniq detector definition
#Uniq: {
	input!: #UniqInput
	
	// GREEN implementation: Detect duplicates
	report: #UniqReport & {
		// Find duplicate IDs: collect IDs that appear more than once
		duplicateFeatIDs: [
			for id, _ in {
				for f in input.feats {
					(f.id): f.id
				}
			} {
				let count = len([for feat in input.feats if feat.id == id {1}])
				if count > 1 {
					id
				}
			},
		]
		
		// Find duplicate slugs: collect slugs that appear more than once
		duplicateSlugs: [
			for slug, _ in {
				for f in input.feats {
					(f.slug): f.slug
				}
			} {
				let count = len([for feat in input.feats if feat.slug == slug {1}])
				if count > 1 {
					slug
				}
			},
		]
	}
}

// Uniq: Alias for #Uniq (use #Uniq directly in new code)
Uniq: #Uniq
