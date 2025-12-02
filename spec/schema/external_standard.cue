package schema

// #ExternalStandard: 外部標準の型定義
// - 外部標準URN箪笥（external/std/）で使用する型
// - IETF/ISO/Cloudflare等の外部URNをカタログ化
#ExternalStandard: {
	// 外部標準の名前（例: "RFC 9110", "Cloudflare Account"）
	name: string

	// 外部標準のURN（例: "urn:ietf:rfc:9110", "urn:cloudflare:account:xxxx"）
	urn: string

	// YAGNI: 詳細情報（description, url等）は将来追加
}
