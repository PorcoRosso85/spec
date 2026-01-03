package schema

// #FeatExternalMapping: 機能URN ↔ 外部標準URN のマッピング型
// - 内部URNと外部標準を完全分離し、ここだけで橋渡しする
#FeatExternalMapping: {
	// 内部機能URN（"urn:feat:..."）
	internal: string
	internal: =~#Patterns.featureURN.pattern

	// 外部標準URN（"urn:ietf:...", "urn:cloudflare:..." 等）
	external: string

	// YAGNI: 1:1/1:N/N:1 の多重度は実際に紐づけるときに決める
}
