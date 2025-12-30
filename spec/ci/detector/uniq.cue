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

Uniq: {
	input:  #UniqInput,
	report: _|_, // RED段階: 未実装（必ず落とす）
	// GREEN段階: 実装により重複検出ロジックを入れる
}
