package skeleton

// tree-final-nar-*.json の型定義
#TreeFinal: {
	schema_version: "1" // 文字列として厳密に"1"のみ

	// rootレベルのnarHash（必須）
	narHash: string & =~"^sha256-[A-Za-z0-9+/]+=*$"

	generated_at: string // ISO 8601
	generator:    "adr-repository"
	source_uri:   string & =~"^github:"

	slots: [...#Slot]
}

#Slot: {
	slotId:    string & =~"^[a-z0-9]+\\.[a-z0-9-]+(\\.[a-z0-9-]+)*$"
	owner:     string & !=""
	placement: string & !=""
	status:    "active" // treeFinalでは"active"のみ許可（provisionalは含まれない）
	rationale: string

	// per-node manifest（必須）
	manifest: #PerNodeManifest
}

#PerNodeManifest: {
	narHash:    string & =~"^sha256-[A-Za-z0-9+/]+=*$"
	created_at: string // ISO 8601
	adr_ref:    string & =~"^adr-[0-9]+"
}
