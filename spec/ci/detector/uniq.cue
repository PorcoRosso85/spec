// Uniqueness detector
// Purpose: Detect duplicate feat IDs and slugs across all features
// Design: Input-injection型 detector, Sort→隣接比較で宣言的に実装

package detector

import "list"

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
	
	// GREEN implementation: Detect duplicates via Pairwise comparison (O(n^2))
	// Algorithm: Compare all pairs → deduplicate via set → sort output
	// Note: Sufficient for small feat counts; avoids index-based access issues
	
	// Find duplicate IDs via pairwise comparison
	_duplicateIDsRaw: [
		for i, f1 in input.feats
		for j, f2 in input.feats
		if i < j && f1.id == f2.id {
			f1.id
		}
	]
	
	// Deduplicate using struct keys (set operation)
	_duplicateIDSet: {
		for id in _duplicateIDsRaw {
			(id): id
		}
	}
	
	// Find duplicate slugs via pairwise comparison
	_duplicateSlugsRaw: [
		for i, f1 in input.feats
		for j, f2 in input.feats
		if i < j && f1.slug == f2.slug {
			f1.slug
		}
	]
	
	// Deduplicate slugs
	_duplicateSlugSet: {
		for slug in _duplicateSlugsRaw {
			(slug): slug
		}
	}
	
	// Final report with sorted output for stability
	report: #UniqReport & {
		duplicateFeatIDs: list.Sort([for _, id in _duplicateIDSet {id}], list.Ascending)
		duplicateSlugs:   list.Sort([for _, slug in _duplicateSlugSet {slug}], list.Ascending)
	}
}

// Uniq: Alias for #Uniq (use #Uniq directly in new code)
Uniq: #Uniq
