package skeleton

// per-node manifest の追加検証
#ValidManifests: {
	slots: [...{
		manifest: {
			// narHashフォーマット検証
			narHash: string & =~"^sha256-[A-Za-z0-9+/]+=*$"

			// created_at 存在確認（ISO 8601形式推奨）
			created_at: string & !=""

			// adr_ref フォーマット検証
			adr_ref: string & =~"^adr-[0-9]+"
		}
	}]
}
